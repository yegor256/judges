# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require 'English'
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
    raise(StandardError, 'The push command needs the network, while --offline is set') if opts['offline']
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
        baza.push(name, fb.export, opts['meta'] || [])
        throw(:"👍 Pushed #{fb.size} facts to baza")
      ensure
        inflight = $ERROR_INFO
        begin
          baza.unlock(name, opts['owner'])
        rescue StandardError => e
          raise if inflight.nil? || inflight.is_a?(UncaughtThrowError)
          msg = "Failed to unlock '#{name}': #{e.message}"
          @loog&.warn(msg)
          $loog&.warn(msg) if $loog && $loog != @loog
        end
      end
    end
  end
end
