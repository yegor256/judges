# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2025 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require 'elapsed'
require 'tago'
require 'timeout'
require 'factbase/tallied'
require_relative '../judges'
require_relative '../judges/to_rel'

# A single judge.
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2024-2025 Yegor Bugayenko
# License:: MIT
class Judges::Judge
  attr_reader :dir

  # Ctor.
  # @param [String] dir The directory with the judge
  # @param [String] lib The directory with the lib/
  # @param [Loog] loog The logging facility
  def initialize(dir, lib, loog, start: Time.now)
    @dir = dir
    @lib = lib
    @loog = loog
    @start = start
  end

  # Returns the string representation of the judge.
  #
  # @return [String] The name of the judge (same as the directory name)
  def to_s
    name
  end

  # A new judge, with a different log.
  #
  # @param [Loog] loog New log
  # @return [Judges::Judge] Similar judge, but log is different
  def with_loog(loog)
    Judges::Judge.new(@dir, @lib, loog, start: @start)
  end

  # Executes the judge script with the provided factbase and configuration.
  #
  # This method sets up the execution environment by creating global variables,
  # loading library files, and running the judge script. It tracks execution time
  # and captures any errors that occur during execution.
  #
  # @param [Factbase] fb The factbase instance to operate on
  # @param [Hash] global Global configuration options shared across all judges
  # @param [Hash] local Local configuration options specific to this judge
  # @param [Judges::Options] options Command-line options object
  # @return [Factbase::Churn] Object containing statistics about the changes made to the factbase
  # @raise [RuntimeError] If the lib directory doesn't exist, the script can't be loaded, or execution fails
  def run(fb, global, local, options)
    $fb = Factbase::Tallied.new(fb)
    $judge = File.basename(@dir)
    $options = options
    $loog = @loog
    $global = global
    $global.delete(:fb) # to make sure Tallied is always actual
    $local = local
    $start = @start
    options.to_h.each { |k, v| ENV.store(k.to_s, v.to_s) }
    unless @lib.nil?
      raise "Lib dir #{@lib.to_rel} is absent" unless File.exist?(@lib)
      raise "Lib #{@lib.to_rel} is not a directory" unless File.directory?(@lib)
      Dir.glob(File.join(@lib, '*.rb')).each do |f|
        require_relative(File.absolute_path(f))
      end
    end
    s = File.join(@dir, script)
    raise "Can't load '#{s}'" unless File.exist?(s)
    elapsed(@loog, good: "#{$judge} completed", level: Logger::INFO) do
      load(s, true)
      $fb.churn
      # rubocop:disable Lint/RescueException
    rescue Exception => e
      # rubocop:enable Lint/RescueException
      @loog.error(Backtrace.new(e))
      raise e if e.is_a?(StandardError)
      raise e if e.is_a?(Timeout::ExitException)
      raise "#{e.message} (#{e.class.name})"
    ensure
      $fb = $judge = $options = $loog = nil
    end
  end

  # Returns the name of the judge.
  #
  # The name is derived from the directory name containing the judge.
  #
  # @return [String] The base name of the judge directory
  def name
    File.basename(@dir)
  end

  # Returns the name of the main Ruby script file for this judge.
  #
  # The script file must have the same name as the judge directory with a .rb extension.
  # For example, if the judge directory is "quality", the script must be "quality.rb".
  #
  # @return [String] The filename of the judge script (e.g., "judge_name.rb")
  # @raise [RuntimeError] If the expected script file is not found in the judge directory
  def script
    b = "#{File.basename(@dir)}.rb"
    files = Dir.glob(File.join(@dir, '*.rb')).map { |f| File.basename(f) }
    raise "No #{b} script in #{@dir.to_rel} among #{files}" unless files.include?(b)
    b
  end

  # Returns all YAML test files in the judge directory.
  #
  # Test files are expected to have a .yml extension and contain test data
  # used to validate the judge's behavior.
  #
  # @return [Array<String>] Array of absolute paths to all .yml files in the judge directory
  def tests
    Dir.glob(File.join(@dir, '*.yml'))
  end
end
