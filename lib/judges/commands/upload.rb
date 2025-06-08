# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2025 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require 'typhoeus'
require 'iri'
require 'baza-rb'
require 'elapsed'
require_relative '../../judges'

# The +upload+ command.
#
# This class is instantiated by the +bin/judge+ command line interface. You
# are not supposed to instantiate it yourself.
#
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2024-2025 Yegor Bugayenko
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
  def run(opts, args)
    raise 'Exactly two arguments required' unless args.size == 2
    jname = args[0]
    path = args[1]
    raise "File not found: #{path}" unless File.exist?(path)
    name = File.basename(path)
    baza = BazaRb.new(
      opts['host'], opts['port'].to_i, opts['token'],
      ssl: opts['ssl'],
      timeout: (opts['timeout'] || 30).to_i,
      loog: @loog,
      retries: (opts['retries'] || 3).to_i
    )
    elapsed(@loog, level: Logger::INFO) do
      id = baza.durable_find(jname, name)
      size = File.size(path)
      if id.nil? || id.to_s.strip.empty?
        id = baza.durable_place(jname, path)
        throw :"👍 Uploaded #{path} to new durable '#{name}' in '#{jname}' (ID: #{id}, #{size} bytes)"
      else
        id = id.to_i
        baza.durable_lock(id, opts['owner'] || 'default')
        begin
          baza.durable_save(id, path)
          throw :"👍 Uploaded #{path} to existing durable '#{name}' in '#{jname}' (ID: #{id}, #{size} bytes)"
        ensure
          baza.durable_unlock(id, opts['owner'] || 'default')
        end
      end
    end
  end
end
