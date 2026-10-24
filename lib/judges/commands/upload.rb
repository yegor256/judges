# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require 'baza-rb'
require 'elapsed'
require 'iri'
require 'typhoeus'
require_relative '../../judges'
require_relative '../../judges/durable_name'

# The +upload+ command, to send a durable to Zerocracy.
#
# This class is instantiated by the +bin/judges+ command line interface. You
# are not supposed to instantiate it yourself.
#
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2024-2026 Yegor Bugayenko
# License:: MIT
class Judges::Upload
  # Initialize.
  # @param [Loog] loog Logging facility
  def initialize(loog)
    @loog = loog
  end

  # Run the upload command (called by the +bin/judges+ script).
  # @param [Hash] opts Command line options (start with '--')
  # @param [Array] args List of command line arguments
  # @raise [RuntimeError] If not exactly two arguments provided
  # rubocop:disable Metrics/MethodLength
  def run(opts, args)
    raise(ArgumentError, 'Exactly two arguments required') unless args.size == 2
    raise(StandardError, 'The upload command needs the network, while --offline is set') if opts['offline']
    jname = args[0]
    path = args[1]
    raise(StandardError, "File not found: #{path}") unless File.file?(path)
    name = Judges::DurableName.new(path).to_s
    baza = BazaRb.new(
      opts['host'], opts['port'].to_i, opts['token'],
      ssl: opts['ssl'],
      timeout: (opts['timeout'] || 30).to_f,
      loog: @loog,
      retries: (opts['retries'] || 3).to_i
    )
    elapsed(@loog, level: Logger::INFO) do
      id = baza.durable_find(jname, name)
      kind = 'existing'
      if id.nil? || id.to_s.strip.empty?
        kind = 'new'
        tmp = Dir.mktmpdir
        begin
          f = File.join(tmp, name)
          File.write(f, 'placeholder')
          id = baza.durable_place(jname, f)
          @loog.info("Placed a placeholder to new durable '#{name}' in '#{jname}' (ID: #{id})")
        ensure
          FileUtils.rm_rf(tmp, secure: true)
        end
      end
      size = File.size(path)
      id = id.to_i
      baza.durable_lock(id, opts['owner'] || 'default')
      begin
        baza.durable_save(id, path)
        throw(:"👍 Uploaded #{path} to #{kind} durable '#{name}' in '#{jname}' (ID: #{id}, #{size} bytes)")
      ensure
        baza.durable_unlock(id, opts['owner'] || 'default')
      end
    end
  end
  # rubocop:enable Metrics/MethodLength
end
