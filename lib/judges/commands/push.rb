# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2025 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require 'typhoeus'
require 'iri'
require 'baza-rb'
require 'elapsed'
require_relative '../../judges'
require_relative '../../judges/impex'

# The +push+ command.
#
# This class is instantiated by the +bin/judge+ command line interface. You
# are not supposed to instantiate it yourself.
#
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2024-2025 Yegor Bugayenko
# License:: MIT
class Judges::Push
  # Initialize.
  # @param [Loog] loog Logging facility
  def initialize(loog)
    @loog = loog
  end

  # Run it (it is supposed to be called by the +bin/judges+ script.
  # @param [Hash] opts Command line options (start with '--')
  # @param [Array] args List of command line arguments
  def run(opts, args)
    raise 'Exactly two arguments required' unless args.size == 2
    name = args[0]
    fb = Judges::Impex.new(@loog, args[1]).import
    baza = BazaRb.new(
      opts['host'], opts['port'].to_i, opts['token'],
      ssl: opts['ssl'],
      timeout: (opts['timeout'] || 30).to_i,
      loog: @loog,
      retries: (opts['retries'] || 3).to_i,
      compress: opts.fetch('zip', true)
    )
    elapsed(@loog, level: Logger::INFO) do
      baza.lock(name, opts['owner'])
      begin
        id = baza.push(name, fb.export, opts['meta'] || [])
        throw :"Pushed #{fb.size} facts, job ID is #{id}"
      ensure
        baza.unlock(name, opts['owner'])
      end
    end
  end
end
