# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2025 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require 'backtrace'
require 'elapsed'
require 'factbase/looged'
require 'tago'
require 'timeout'
require_relative '../../judges'
require_relative '../../judges/to_rel'
require_relative '../../judges/judges'
require_relative '../../judges/churn'
require_relative '../../judges/options'
require_relative '../../judges/impex'

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
    fb = Factbase::Looged.new(fb, @loog) if opts['log']
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
    judges = Judges::Judges.new(dir, opts['lib'], @loog, start:)
    c = 0
    churn = Judges::Churn.new(0, 0)
    elapsed(@loog, level: Logger::INFO) do
      loop do
        c += 1
        if c > 1
          @loog.info("\nStarting cycle ##{c}#{opts['max-cycles'] ? " (out of #{opts['max-cycles']})" : ''}...")
        end
        delta = cycle(opts, judges, fb, options, start)
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
        @loog.info("The cycle #{c} modified #{delta} fact(s)")
      end
      throw :"Update finished in #{c} cycle(s), modified #{churn} fact(s)"
    end
    return unless opts['summary']
    fb.query('(eq what "judges-summary")').delete!
    f = fb.insert
    f.what = 'judges-summary'
    f.when = Time.now
    f.version = Judges::VERSION
    f.seconds = Time.now - start
    f.cycles = c
    f.added = churn.added.size
    f.removed = churn.removed.size
    churn.errors.each { |e| f.error = e }
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
  # @return [Churn] How many modifications have been made
  def cycle(opts, judges, fb, options, start)
    churn = Judges::Churn.new(0, 0)
    global = {}
    elapsed(@loog, level: Logger::INFO) do
      done =
        judges.each_with_index do |p, i|
          @loog.info("\n👉 Running #{p.name} (##{i}) at #{p.dir.to_rel} (#{start.ago} already)...")
          elapsed(@loog, level: Logger::INFO) do
            c = one_judge(opts, fb, p, global, options)
            churn += c
            throw :"👍 The '#{p.name}' judge modified #{c} facts out of #{fb.size}"
          end
        rescue StandardError, SyntaxError => e
          @loog.warn(Backtrace.new(e))
          churn << e.message
        end
      throw :"👍 #{done} judge(s) processed" if churn.errors.empty?
      throw :"❌ #{done} judge(s) processed with #{churn.errors.size} errors"
    end
    unless churn.errors.empty?
      raise "Failed to update correctly (#{churn.errors.size} errors)" unless opts['quiet']
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
  # @return [Churn] How many modifications have been made
  def one_judge(opts, fb, judge, global, options)
    local = {}
    before = fb.size
    churn = Judges::Churn.new(0, 0)
    begin
      Timeout.timeout(opts['timeout']) do
        judge.run(fb, global, local, options)
      end
    rescue Timeout::Error => e
      churn << "Judge #{judge.name} stopped by timeout: #{e.message}"
      throw :"👎 The '#{judge.name}' judge timed out: #{e.message}"
    end
    after = fb.size
    diff = after - before
    churn +=
      if diff.positive?
        Judges::Churn.new(diff, 0)
      else
        Judges::Churn.new(0, -diff)
      end
    churn
  end
end
