# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT
require 'nokogiri'
require 'factbase'
require 'backtrace'
require 'factbase/to_xml'
require 'elapsed'
require 'ellipsized'
require 'timeout'
require_relative '../../judges'
require_relative '../../judges/to_rel'
require_relative '../../judges/judges'
require_relative '../../judges/options'
require_relative '../../judges/categories'

# The +test+ command.
#
# This class is instantiated by the +bin/judge+ command line interface. You
# are not supposed to instantiate it yourself.
#
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2024-2026 Yegor Bugayenko
# License:: MIT
class Judges::Test
  # Initialize.
  # @param [Loog] loog Logging facility
  def initialize(loog)
    @loog = loog
  end

  # Run the test command (called by the +bin/judges+ script).
  # @param [Hash] opts Command line options (start with '--')
  # @param [Array] args List of command line arguments
  # @raise [RuntimeError] If not exactly one argument provided
  def run(opts, args)
    raise 'Exactly one argument required' unless args.size == 1
    dir = args[0]
    @loog.info("Testing judges in #{dir.to_rel}...")
    errors = []
    tested = 0
    tests = 0
    visible = []
    times = {}
    judges = Judges::Judges.new(dir, opts['lib'], @loog)
    elapsed(@loog, level: Logger::INFO) do
      judges.each_with_index do |judge, i|
        visible << judge.name
        next unless include?(opts, judge.name)
        @loog.info("👉 Testing #{judge.script} (##{i}) in #{judge.dir.to_rel}...")
        buf = Loog::Buffer.new
        judge = judge.with_loog(buf)
        judge.tests.each do |f|
          tname = File.basename(f).gsub(/\.yml$/, '')
          visible << "  #{judge.name}/#{tname}"
          next unless include?(opts, judge.name, tname)
          yaml = YAML.load_file(f, permitted_classes: [Time])
          if yaml['skip']
            buf.info("Skipped #{f.to_rel}")
            next
          end
          unless Judges::Categories.new(opts['enable'], opts['disable']).ok?(yaml['category'])
            buf.info("Skipped #{f.to_rel} because of its category")
            next
          end
          buf.info("🛠️ Testing #{f.to_rel}:")
          start = Time.now
          badge = "#{judge.name}/#{tname}"
          begin
            fb = Factbase.new
            prepare(fb, yaml)
            yaml['before']&.each do |n|
              j = judges.get(n).with_loog(buf)
              buf.info("Running #{j.script} judge as a pre-condition...")
              test_one(fb, opts, j, n, yaml, assert: false)
            end
            test_one(fb, opts, judge, tname, yaml)
            yaml['after']&.each do |rb|
              buf.info("Running #{rb} assertion script...")
              $fb = fb
              $loog = buf
              if yaml['timeout']
                Timeout.timeout(yaml['timeout']) do
                  load(File.join(judge.dir, rb), true)
                end
              else
                load(File.join(judge.dir, rb), true)
              end
            end
            tests += 1
          rescue StandardError => e
            @loog.info(buf.to_s)
            @loog.warn(Backtrace.new(e))
            errors << badge
          end
          times[badge] = Time.now - start
        end
        tested += 1
      end
      unless times.empty?
        fmt = "%-60s\t%9s\t%-9s"
        @loog.info(
          [
            'Test summary:',
            format(fmt, 'Script', 'Seconds', 'Result'),
            format(fmt, '---', '---', '---'),
            times.sort_by { |_, v| v }.reverse.map do |script, sec|
              format(fmt, script.ellipsized(50), format('%.3f', sec), errors.include?(script) ? 'ERROR' : 'OK')
            end.join("\n  ")
          ].join("\n  ")
        )
      end
      throw :'👍 No judges tested' if tested.zero?
      throw :"👍 All #{tested} judge(s) but no tests passed" if tests.zero?
      throw :"👍 All #{tested} judge(s) and #{tests} tests passed" if errors.empty?
      throw :"❌ #{tested} judge(s) tested, #{errors.size} of them failed"
    end
    unless errors.empty?
      raise "#{errors.size} tests failed" unless opts['quiet']
      @loog.debug('Not failing the build with tests failures, due to the --quiet option')
    end
    return unless tested.zero? || tests.zero?
    if opts['judge'].nil?
      raise 'There are seems to be no judges' unless opts['quiet']
      @loog.debug('Not failing the build with no judges tested, due to the --quiet option')
    else
      raise 'There are seems to be no judges' if visible.empty?
      @loog.info("The following judges are available to use with the --judge option:\n  #{visible.join("\n  ")}")
    end
  end

  private

  def include?(opts, name, tname = nil)
    judges = opts['judge'] || []
    return true if judges.empty?
    re = tname.nil? ? '.+' : tname
    judges.any? { |n| n.match?(%r{^#{name}(/#{re})?$}) }
  end

  def prepare(fb, yaml)
    id = 1
    inputs = yaml['input']
    (yaml['repeat']&.to_i || 1).times do
      inputs&.each do |i|
        f = fb.insert
        i.each do |k, vv|
          if vv.is_a?(Array)
            vv.each do |v|
              f.send(:"#{k}=", v)
            end
          else
            if k == '_id'
              vv = id
              id += 1
            end
            f.send(:"#{k}=", vv)
          end
        end
      end
    end
  end

  # Test a single test in a single judge and raise exception if the test fails.
  # @param [Factbase] fb The factbase to use
  # @param [Hash] opts The command line options
  # @param [Judges::Judge] judge The judge to run
  # @param [String] tname The name of the test (without .rb suffix)
  # @param [Hash] yaml The YAML to be tested
  # @param [Boolean] assert Should we assert (TRUE) or simply skip (FALSE)?
  # @return [nil] Always NIL
  def test_one(fb, opts, judge, tname, yaml, assert: true)
    options = Judges::Options.new(opts['option']) + Judges::Options.new(yaml['options'])
    runs = opts['runs'] || yaml['runs'] || 1
    timeout = yaml['timeout']
    (1..runs).each do |r|
      fbx = fb
      if opts['log']
        require 'factbase/logged'
        fbx = Factbase::Logged.new(fb, @loog)
      end
      expected_failure = yaml['expected_failure']
      begin
        if timeout
          Timeout.timeout(timeout) do
            judge.run(fbx, {}, {}, options)
          end
        else
          judge.run(fbx, {}, {}, options)
        end
        raise 'Exception expected but not raised' if expected_failure
      rescue Timeout::Error => e
        raise "Test timed out after #{timeout} seconds"
      # rubocop:disable Lint/RescueException
      rescue Exception => e
        # rubocop:enable Lint/RescueException
        raise e unless expected_failure
        if expected_failure.is_a?(Array) && expected_failure.none? { |s| e.message.include?(s) }
          raise "Exception #{e.class} raised with #{e.message.inspect}, but this is not what was expected"
        end
      end
      next unless assert
      assert(judge, tname, fb, yaml) if r == runs || opts['assert_once'].is_a?(FalseClass)
    end
  end

  def assert(judge, tname, fb, yaml)
    xpaths = yaml['expected']
    return if xpaths.nil?
    xml = Nokogiri::XML.parse(Factbase::ToXML.new(fb).xml)
    xpaths.each do |xp|
      raise "#{judge.name}/#{tname} doesn't match '#{xp}':\n#{xml}" if xml.xpath(xp).empty?
    end
  end
end
