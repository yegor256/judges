# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2025 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require 'nokogiri'
require 'factbase'
require 'backtrace'
require 'factbase/to_xml'
require 'elapsed'
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
# Copyright:: Copyright (c) 2024-2025 Yegor Bugayenko
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
    validate_layout(dir)
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
        @loog.info("\n👉 Testing #{judge.script} (##{i}) in #{judge.dir.to_rel}...")
        judge.tests.each do |f|
          tname = File.basename(f).gsub(/\.yml$/, '')
          visible << "  #{judge.name}/#{tname}"
          next unless include?(opts, judge.name, tname)
          yaml = YAML.load_file(f, permitted_classes: [Time])
          if yaml['skip']
            @loog.info("Skipped #{f.to_rel}")
            next
          end
          unless Judges::Categories.new(opts['enable'], opts['disable']).ok?(yaml['category'])
            @loog.info("Skipped #{f.to_rel} because of its category")
            next
          end
          @loog.info("🛠️ Testing #{f.to_rel}:")
          start = Time.now
          badge = "#{judge.name}/#{tname}"
          begin
            fb = Factbase.new
            prepare(fb, yaml)
            yaml['before']&.each do |n|
              j = judges.get(n)
              @loog.info("Running #{j.script} judge as a pre-condition...")
              test_one(fb, opts, j, n, yaml, assert: false)
            end
            test_one(fb, opts, judge, tname, yaml)
            yaml['after']&.each do |rb|
              @loog.info("Running #{rb} assertion script...")
              $fb = fb
              $loog = @loog
              load(File.join(judge.dir, rb), true)
            end
            tests += 1
          rescue StandardError => e
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
              format(fmt, script, format('%.3f', sec), errors.include?(script) ? 'ERROR' : 'OK')
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
    (1..runs).each do |r|
      fbx = fb
      if opts['log']
        require 'factbase/logged'
        fbx = Factbase::Logged.new(fb, @loog)
      end
      expected_failure = yaml['expected_failure']
      begin
        judge.run(fbx, {}, {}, options)
        raise 'Exception expected but not raised' if expected_failure
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

  # Validates the directory layout to ensure judges are correctly organized.
  # @param [String] dir The judges directory to validate
  # @raise [RuntimeError] If the directory layout is incorrect
  def validate_layout(dir)
    return unless File.exist?(dir) && File.directory?(dir)
    errors = []
    
    # Check for files in root directory (these should be in subdirectories)
    Dir.glob(File.join(dir, '*')).each do |path|
      next if File.directory?(path)
      # Allow certain config files in root
      basename = File.basename(path)
      next if %w[.gitignore README.md LICENSE.txt].include?(basename)
      next if basename.start_with?('.')
      errors << "File '#{basename}' should be inside a judge directory, not in the root"
    end
    
    # Check each subdirectory for correct structure
    Dir.glob(File.join(dir, '*')).each do |subdir|
      next unless File.directory?(subdir)
      dirname = File.basename(subdir)
      expected_script = File.join(subdir, "#{dirname}.rb")
      
      # Check if the matching .rb file exists
      unless File.exist?(expected_script)
        errors << "Judge directory '#{dirname}' must contain a file named '#{dirname}.rb'"
      end
      
      # Check for nested judge directories (not allowed)
      Dir.glob(File.join(subdir, '*')).each do |nested_path|
        next unless File.directory?(nested_path)
        nested_name = File.basename(nested_path)
        nested_script = File.join(nested_path, "#{nested_name}.rb")
        if File.exist?(nested_script)
          errors << "Nested judge directory '#{dirname}/#{nested_name}' is not allowed"
        end
      end
    end
    
    unless errors.empty?
      raise "Directory layout validation failed:\n  #{errors.join("\n  ")}"
    end
  end
end
