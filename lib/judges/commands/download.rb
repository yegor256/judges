# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require 'baza-rb'
require 'elapsed'
require 'fileutils'
require 'iri'
require 'typhoeus'
require_relative '../../judges'
require_relative '../../judges/owner'

# The +download+ command.
#
# This class is instantiated by the +bin/judges+ command line interface. You
# are not supposed to instantiate it yourself.
#
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2024-2026 Yegor Bugayenko
# License:: MIT
class Judges::Download
  # Initialize.
  # @param [Loog] loog Logging facility
  def initialize(loog)
    @loog = loog
  end

  # Run the download command (called by the +bin/judges+ script).
  # @param [Hash] opts Command line options (start with '--')
  # @param [Array] args List of command line arguments
  # @raise [RuntimeError] If not exactly two arguments provided
  def run(opts, args)
    raise(ArgumentError, 'Exactly two arguments required') unless args.size == 2
    raise(StandardError, 'The download command needs the network, while --offline is set') if opts['offline']
    jname = args[0]
    path = args[1]
    name = File.basename(path)
    baza = BazaRb.new(
      opts['host'], opts['port'].to_i, opts['token'],
      ssl: opts['ssl'],
      timeout: (opts['timeout'] || 30).to_f,
      loog: @loog,
      retries: (opts['retries'] || 3).to_i
    )
    elapsed(@loog, level: Logger::INFO) do
      id = baza.durable_find(jname, name)
      if id.nil?
        @loog.info("Durable '#{name}' not found in '#{jname}'")
        return
      end
      @loog.info("Durable ##{id} ('#{name}') found in '#{jname}'")
      baza.durable_lock(id, owner = Judges::Owner.new(opts['owner']).to_s)
      tmp = "#{path}.part"
      begin
        baza.durable_load(id, tmp)
        FileUtils.mv(tmp, path)
        throw(:"👍 Downloaded durable ##{id} to #{path} (#{File.size(path)} bytes)")
      ensure
        FileUtils.rm_f(tmp)
        baza.durable_unlock(id, owner)
      end
    end
  end
end
