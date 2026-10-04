# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require 'baza-rb'
require 'elapsed'
require 'fileutils'
require 'iri'
require 'tmpdir'
require 'typhoeus'
require_relative '../../judges'
require_relative '../durable_placeholder'

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
      baza.durable_lock(id, opts['owner'] || 'default')
      begin
        download(baza, id, path, name)
        throw(:"👍 Downloaded durable ##{id} to #{path} (#{File.size(path)} bytes)")
      ensure
        baza.durable_unlock(id, opts['owner'] || 'default')
      end
    end
  end

  private

  # Download the durable to a temporary location before replacing the target.
  # @param [BazaRb] baza The durable storage client
  # @param [Integer] id The durable ID
  # @param [String] path The destination path
  # @param [String] name The durable file name
  def download(baza, id, path, name)
    Dir.mktmpdir do |dir|
      downloaded = File.join(dir, name)
      baza.durable_load(id, downloaded)
      if Judges::DurablePlaceholder.incomplete?(downloaded)
        raise(StandardError, "Durable ##{id} is an incomplete upload; retry 'judges upload'")
      end
      FileUtils.mkdir_p(File.dirname(path))
      FileUtils.mv(downloaded, path)
    end
  end
end
