# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require 'elapsed'
require_relative '../../judges'
require_relative '../../judges/impex'

# The +join+ command.
#
# This class is instantiated by the +bin/judges+ command line interface. You
# are not supposed to instantiate it yourself.
#
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2024-2026 Yegor Bugayenko
# License:: MIT
class Judges::Join
  # Initialize.
  # @param [Loog] loog Logging facility
  def initialize(loog)
    @loog = loog
  end

  # Run the join command (called by the +bin/judges+ script).
  #
  # The facts of the second factbase are copied into the first one with new
  # +_id+ values, continuing the numbering of the first one. Both factbases
  # number their facts from one, so a plain concatenation would give every
  # +_id+ twice and break the uniqueness the rest of the system relies on.
  #
  # @param [Hash] _opts Command line options (not used)
  # @param [Array] args List of command line arguments
  # @raise [RuntimeError] If not exactly two arguments provided
  def run(_opts, args)
    raise(ArgumentError, 'Exactly two arguments required') unless args.size == 2
    master = Judges::Impex.new(@loog, args[0])
    slave = Judges::Impex.new(@loog, args[1])
    elapsed(@loog, level: Logger::INFO) do
      fb = master.import
      absorb(fb, slave.import)
      master.export(fb)
      throw(:'👍 Two factbases joined successfully')
    end
  end

  private

  # Copy every fact of one factbase into another one, giving it a new +_id+.
  #
  # A fact that carries no +_id+ is copied as it is, without being given one.
  #
  # @param [Factbase] fb The factbase to copy into
  # @param [Factbase] other The factbase to copy from
  # @return [Factbase] The factbase that was copied into
  def absorb(fb, other)
    max = fb.query('(max _id)').one || 0
    other.query('(always)').each do |f|
      n = fb.insert
      f.all_properties.each do |k|
        next if k == '_id'
        f[k].each { |v| n.public_send(:"#{k}=", v) }
      end
      unless f['_id'].nil?
        max += 1
        n._id = max
      end
    end
    fb
  end
end
