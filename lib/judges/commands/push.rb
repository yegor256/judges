# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require 'baza-rb'
require 'elapsed'
require 'iri'
require 'typhoeus'
require_relative '../../judges'
require_relative '../../judges/impex'

# The +push+ command.
#
# This class is instantiated by the +bin/judges+ command line interface. You
# are not supposed to instantiate it yourself.
#
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2024-2026 Yegor Bugayenko
# License:: MIT
class Judges::Push
  # Initialize.
  # @param [Loog] loog Logging facility
  def initialize(loog)
    @loog = loog
  end

  # Run the push command (called by the +bin/judges+ script).
  # @param [Hash] opts Command line options (start with '--')
  # @param [Array] args List of command line arguments
  # @raise [RuntimeError] If not exactly two arguments provided
  def run(opts, args)
    raise(ArgumentError, 'Exactly two arguments required: <name> and <path>') unless args.size == 2
    name = args[0]
    fb = Judges::Impex.new(@loog, args[1]).import
    baza = BazaRb.new(
      opts['host'], opts['port'].to_i, opts['token'],
      ssl: opts['ssl'],
      timeout: (opts['timeout'] || 30).to_f,
      loog: @loog,
      retries: (opts['retries'] || 3).to_i,
      compress: opts.fetch('zip', true)
    )
    elapsed(@loog, level: Logger::INFO) do
      baza.lock(name, opts['owner'])
      begin
        marker = Judges::Impex.marker(args[1])
        snapshot(name, baza, marker)
        baza.push(name, fb.export, opts['meta'] || [])
        File.delete(marker) if File.file?(marker)
        throw(:"👍 Pushed #{fb.size} facts to baza")
      ensure
        baza.unlock(name, opts['owner'])
      end
    end
  end

  private

  def snapshot(name, baza, marker)
    return unless baza.name_exists?(name)
    unless File.file?(marker)
      begin
        baza.recent(name)
      rescue BazaRb::ServerFailure => e
        return if e.message.match?(
          /Invalid response code #303.*(?:doesn't have any not-yet-expired jobs|has no jobs, can't find recent one)/
        )
        raise
      end
      raise StandardError, "No pulled snapshot is recorded for #{name.inspect}; run 'judges pull' before pushing"
    end
    expected = File.binread(marker).strip
    return if expected == baza.recent(name).to_s
    raise(
      StandardError,
      "The Baza snapshot for #{name.inspect} changed after job ##{expected}; pull again before pushing"
    )
  end
end
