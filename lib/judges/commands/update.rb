# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2025 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require 'backtrace'
require 'elapsed'
require 'factbase'
require 'factbase/churn'
require 'factbase/logged'
require 'logger'
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
  # Initialize.
  # @param [Loog] loog Logging facility
  def initialize(loog)
    @loog = loog
    @start = Time.now
  end

  # Run the update command (called by the +bin/judges+ script).
  # @param [Hash] opts Command line options (start with '--')
  # @param [Array] args List of command line arguments
  # @raise [RuntimeError] If not exactly two arguments provided or directory is missing
  def run(opts, args)
    raise 'Exactly two arguments required' unless args.size == 2
    dir = args[0]
    raise "The directory is absent: #{dir.to_rel}" unless File.exist?(dir)
    start = Time.now
    impex = Judges::Impex.new(@loog, args[1])
    fb = impex.import(strict: false)
    fb = Factbase::Logged.new(fb, @loog) if opts['log']
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
    judges = Judges::Judges.new(dir, opts['lib'], @loog, start:, shuffle: opts['shuffle'], boost: opts['boost'])
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
        if opts['fail-fast'] && !errors.empty?
          @loog.info("Due to #{errors.count} errors we must stop at the update cycle ##{c}")
          break
        end
        @loog.info("The cycle #{c} did #{delta}")
      end
      throw :"👍 Update completed in #{c} cycle(s), did #{churn}"
    end
    return unless opts['summary']
    summarize(fb, churn, errors, start, c)
    impex.export(fb)
  end

  private

  # Update the summary.
  # @param [Factbase] fb The factbase
  # @param [Churn] churn The churn
  # @param [Array<String>] errors List of errors
  # @param [Time] start When we started
  # @param [Integer] cycles How many cycles
  def summarize(fb, churn, errors, start, cycles)
    before = fb.query('(eq what "judges-summary")').each.to_a
    if before.empty?
      @loog.info('A summary not found')
      s = fb.insert
      s.what = 'judges-summary'
      s.when = Time.now
      s.version = Judges::VERSION
      s.seconds = Time.now - start
      s.cycles = cycles
      s.inserted = churn.inserted.size
      s.deleted = churn.deleted.size
      s.added = churn.added.size
    else
      s = before.first
      errs = s['errors']&.size || 0
      @loog.info(
        "A summary found, with #{errs || 'no'} error#{'s' if errs > 1}: " \
        "#{%w[when cycles version inserted deleted added].map { |a| "#{a}=#{s[a]&.first}" }.join(', ')}"
      )
    end
    f =
      s
    if errors.empty?
      @loog.info('No errors added to the summary')
    else
      errors.each { |e| f.error = e }
      @loog.info("#{errors.size} error#{'s' if errors.size > 1} added to the summary")
    end
  end

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
    used = 0
    elapsed(@loog, level: Logger::INFO) do
      done =
        judges.each_with_index do |judge, i|
          if opts['fail-fast'] && !errors.empty?
            @loog.info("Not running #{judge.name.inspect} due to #{errors.count} errors above, in --fail-fast mode")
            next
          end
          next unless include?(opts, judge.name)
          @loog.info("\n👉 Running #{judge.name} (##{i}) at #{judge.dir.to_rel} (#{start.ago} already)...")
          used += 1
          elapsed(@loog, level: Logger::INFO) do
            c = one_judge(opts, fb, judge, global, options, errors)
            churn += c
            throw :"👍 The '#{judge.name}' judge made zero changes to #{fb.size} facts" if c.zero?
            throw :"👍 The '#{judge.name}' judge #{c} out of #{fb.size} facts"
          end
        rescue StandardError, SyntaxError => e
          @loog.warn(Backtrace.new(e))
          errors << e.message
        end
      throw :"👍 #{done} judge(s) processed" if errors.empty?
      throw :"❌ #{done} judge(s) processed with #{errors.size} errors"
    end
    if used.zero?
      raise 'No judges were used, while at least one expected to run' if opts['expect-judges']
      @loog.info('No judges were used (looks like an error); not failing because of --no-expect-judges')
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
  # @return [Factbase::Churn] How many modifications have been made
  def one_judge(opts, fb, judge, global, options, errors)
    local = {}
    start = Time.now
    begin
      if opts['lifetime'] && Time.now - @start > opts['lifetime']
        throw :"👎 The '#{judge.name}' judge skipped, no time left"
      end
      Timeout.timeout(opts['timeout']) do
        judge.run(fb, global, local, options)
      end
    rescue Timeout::Error, Timeout::ExitException => e
      errors << "Judge #{judge.name} stopped by timeout after #{start.ago}: #{e.message}"
      throw :"👎 The '#{judge.name}' judge timed out after #{start.ago}: #{e.message}"
    end
  end

  def include?(opts, name)
    judges = opts['judge'] || []
    return true if judges.empty?
    judges.any?(name)
  end
end
