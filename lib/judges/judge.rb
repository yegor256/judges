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

  # Print it as a string.
  # @return [String] Name of it
  def to_s
    name
  end

  # Run it with the given Factbase and environment variables.
  #
  # @param [Factbase] fb The factbase
  # @param [Hash] global Global options
  # @param [Hash] local Local options
  # @param [Judges::Options] options The options from command line
  # @return [Factbase::Churn] The changes just made
  def run(fb, global, local, options)
    $fb = Factbase::Tallied.new(fb)
    $judge = File.basename(@dir)
    $options = options
    $loog = @loog
    $global = global
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
    elapsed(@loog, intro: "#{$judge} completed", level: Logger::INFO) do
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

  # Get the name of the judge.
  def name
    File.basename(@dir)
  end

  # Get the name of the .rb script in the judge.
  def script
    b = "#{File.basename(@dir)}.rb"
    files = Dir.glob(File.join(@dir, '*.rb')).map { |f| File.basename(f) }
    raise "No #{b} script in #{@dir.to_rel} among #{files}" unless files.include?(b)
    b
  end

  # Return all .yml tests files.
  def tests
    Dir.glob(File.join(@dir, '*.yml'))
  end
end
