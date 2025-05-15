# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2025 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require 'typhoeus'
require 'iri'
require 'baza-rb'
require 'elapsed'
require_relative '../../judges'
require_relative '../../judges/impex'

# The +pull+ command.
#
# This class is instantiated by the +bin/judge+ command line interface. You
# are not supposed to instantiate it yourself.
#
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2024-2025 Yegor Bugayenko
# License:: MIT
class Judges::Pull
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
    fb = Factbase.new
    baza = BazaRb.new(
      opts['host'], opts['port'].to_i, opts['token'],
      ssl: opts['ssl'],
      timeout: (opts['timeout'] || 30).to_i,
      loog: @loog,
      retries: (opts['retries'] || 3).to_i
    )
    name = args[0]
    elapsed(@loog, level: Logger::INFO) do
      if baza.name_exists?(name)
        baza.lock(name, opts['owner'])
        begin
          jid = baza.recent(name)
          unless baza.exit_code(jid).zero?
            @loog.warn("STDOUT of the job ##{jid} (from the server):\n#{baza.stdout(jid)}")
            raise "The job ##{jid} ('#{name}') is broken, maybe you should expire it"
          end
          fb.import(baza.pull(wait(name, baza, jid, opts['wait'])))
          Judges::Impex.new(@loog, args[1]).export(fb)
        rescue StandardError => e
          baza.unlock(name, opts['owner'])
          raise e
        end
        throw :"Pulled #{fb.size} facts by the name '#{name}'"
      else
        throw :"There is nothing to pull, the name '#{name}' is absent on the server"
      end
    end
  end

  private

  def wait(name, baza, id, limit)
    raise 'Waiting time is nil' if limit.nil?
    start = Time.now
    loop do
      break if baza.finished?(id)
      sleep 1
      raise "Time is over, the job ##{id} ('#{name}') is still not finished" if Time.now - start > limit
      lapsed = Time.now - start
      @loog.debug("Still waiting for the job ##{id} ('#{name}') to finish... (#{format('%.2f', lapsed)}s already)")
    end
    id
  end
end
