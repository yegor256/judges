# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2025 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require 'backtrace'
require 'elapsed'
require 'factbase'
require 'factbase/churn'
require 'tago'
require 'timeout'
require_relative '../../judges'
require_relative '../../judges/impex'
require_relative '../../judges/judges'
require_relative '../../judges/options'
require_relative '../../judges/to_rel'

# The +update+ command.
#
# This class is instantiated by the +bin/judge+ command line interface. You
# are not supposed to instantiate it yourself.
#
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2024-2025 Yegor Bugayenko
# License:: MIT
class Judges::Update
  def initialize(loog)
    @loog = loog
    @start = Time.now
  end

  # Run it (it is supposed to be called by the +bin/judges+ script.
  #
  # @param [Hash] opts Command line options (start with '--')
  # @param [Array] args List of command line arguments
  def run(opts, args)
    raise 'Exactly two arguments required' unless args.size == 2
    dir = args[0]
    raise "The directory is absent: #{dir.to_rel}" unless File.exist?(dir)
    start = Time.now
    impex = Judges::Impex.new(@loog, args[1])
    fb = impex.import(strict: false)
    if opts['log']
      require 'factbase/logged'
      fb = Factbase::Logged.new(fb, @loog)
    end
    options = Judges::Options.new(opts['option'])
    if opts['options-file']
      options += Judges::Options.new(
        File.readlines(opts['options-file'])
          .compact
          .reject(&:empty?)
          .map { |ln| ln.strip.split('=', 1).map(&:strip).join('=') }
      )
      @loog.debug("Options loaded from #{opts['options-file']}")
    end
    if options.empty?
      @loog.debug('No options provided by the --option flag')
    else
      @loog.debug("The following options provided:\n\t#{options.to_s.gsub("\n", "\n\t")}")
    end
    judges = Judges::Judges.new(dir, opts['lib'], @loog, start:, shuffle: opts['shuffle'])
    c = 0
    churn = Factbase::Churn.new
    errors = []
    elapsed(@loog, level: Logger::INFO) do
      loop do
        c += 1
        if c > 1
          @loog.info("\nStarting cycle ##{c}#{opts['max-cycles'] ? " (out of #{opts['max-cycles']})" : ''}...")
        end
        delta = cycle(opts, judges, fb, options, start, errors)
        churn += delta
        impex.export(fb)
        if delta.zero?
          @loog.info("The update cycle ##{c} has made no changes to the factbase, let's stop")
          break
        end
        if !opts['max-cycles'].nil? && c >= opts['max-cycles']
          @loog.info("Too many cycles already, as set by --max-cycles=#{opts['max-cycles']}, breaking")
          break
        end
        @loog.info("The cycle #{c} did #{delta}")
      end
      throw :"Update finished in #{c} cycle(s), did #{churn}"
    end
    return unless opts['summary']
    fb.query('(eq what "judges-summary")').delete!
    f = fb.insert
    f.what = 'judges-summary'
    f.when = Time.now
    f.version = Judges::VERSION
    f.seconds = Time.now - start
    f.cycles = c
    f.inserted = churn.inserted.size
    f.deleted = churn.deleted.size
    f.added = churn.added.size
    errors.each { |e| f.error = e }
    impex.export(fb)
  end

  private

  # Run all judges in a full cycle, one by one.
  #
  # @param [Hash] opts The command line options
  # @param [Judges::Judges] judges The judges
  # @param [Factbase] fb The factbase
  # @param [Judges::Options] options The options
  # @param [Float] start When we started
  # @param [Array<String>] errors List of errors
  # @return [Factbase::Churn] How many modifications have been made
  def cycle(opts, judges, fb, options, start, errors)
    churn = Factbase::Churn.new
    global = {}
    elapsed(@loog, level: Logger::INFO) do
      done =
        judges.each_with_index do |judge, i|
          next unless include?(opts, judge.name)
          @loog.info("\n👉 Running #{judge.name} (##{i}) at #{judge.dir.to_rel} (#{start.ago} already)...")
          elapsed(@loog, level: Logger::INFO) do
            c = one_judge(opts, fb, judge, global, options, errors)
            churn += c
            throw :"👍 The '#{judge.name}' judge #{c} out of #{fb.size}"
          end
        rescue StandardError, SyntaxError => e
          @loog.warn(Backtrace.new(e))
          errors << e.message
        end
      throw :"👍 #{done} judge(s) processed" if errors.empty?
      throw :"❌ #{done} judge(s) processed with #{errors.size} errors"
    end
    unless errors.empty?
      raise "Failed to update correctly (#{errors.size} errors)" unless opts['quiet']
      @loog.info('Not failing because of the --quiet flag provided')
    end
    churn
  end

  # Run a single judge.
  #
  # @param [Hash] opts The command line options
  # @param [Factbase] fb The factbase
  # @param [Judges::Judge] judge The judge
  # @param [Hash] global Global options
  # @param [Judges::Options] options The options
  # @param [Array<String>] errors List of errors
  # @return [Churn] How many modifications have been made
  def one_judge(opts, fb, judge, global, options, errors)
    local = {}
    begin
      if opts['lifetime'] && Time.now - @start > opts['lifetime']
        throw :"👎 The '#{judge.name}' judge skipped, no time left"
      end
      Timeout.timeout(opts['timeout']) do
        judge.run(fb, global, local, options)
      end
    rescue Timeout::Error => e
      errors << "Judge #{judge.name} stopped by timeout: #{e.message}"
      throw :"👎 The '#{judge.name}' judge timed out: #{e.message}"
    end
  end

  def include?(opts, name)
    judges = opts['judge'] || []
    return true if judges.empty?
    judges.any?(name)
  end
end
