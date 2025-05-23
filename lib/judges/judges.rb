# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2025 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require 'time'
require_relative '../judges'
require_relative 'judge'

# Collection of all judges to run.
#
# In the directory +dir+ the following structure must be maintained:
#
#  dir/
#    judge-one/
#      judge-one.rb
#      other files...
#    judge-two/
#      judge-two.rb
#      other files...
#
# The name of a directory of a judge must be exactly the same as the
# name of the +.rb+ script inside the directory.
#
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2024-2025 Yegor Bugayenko
# License:: MIT
class Judges::Judges
  # Initialize.
  # @param [String] dir Directory containing judges
  # @param [String] lib Library directory
  # @param [Loog] loog Logging facility
  # @param [Time] start Start time
  # @param [String] shuffle Prefix for names of judges to shuffle
  # @param [Array<String>] boost Names of judges to boost in priority
  def initialize(dir, lib, loog, start: Time.now, shuffle: '', boost: [])
    @dir = dir
    @lib = lib
    @loog = loog
    @start = start
    @shuffle = shuffle || ''
    @boost = boost
  end

  # Get one judge by name.
  # @param [String] name The name of the judge
  # @return [Judge] The judge object
  # @raise [RuntimeError] If judge doesn't exist
  def get(name)
    d = File.absolute_path(File.join(@dir, name))
    raise "Judge #{name} doesn't exist in #{@dir}" unless File.exist?(d)
    Judges::Judge.new(d, @lib, @loog, start: @start)
  end

  # Iterate over all judges.
  # @yield [Judge] Yields each judge
  # @return [Enumerator] If no block given
  def each(&)
    return to_enum(__method__) unless block_given?
    list =
      Dir.glob(File.join(@dir, '*')).each.to_a.map do |d|
        next unless File.directory?(d)
        b = File.basename(d)
        next unless File.exist?(File.join(d, "#{b}.rb"))
        Judges::Judge.new(File.absolute_path(d), @lib, @loog)
      end
    list.compact!
    list.sort_by!(&:name)
    all = list.each_with_index.to_a
    good = all.dup
    mapping = all
      .map { |a| [a[0].name, a[1], a[1]] }
      .reject { |a| a[0].start_with?(@shuffle) }
      .to_h { |a| [a[1], a[2]] }
    positions = mapping.values.shuffle
    mapping.keys.zip(positions).to_h.each do |before, after|
      good[after] = all[before]
    end
    ret = []
    good.map { |a| a[0] }.each do |j|
      if @boost&.include?(j.name)
        ret.prepend(j)
      else
        ret.append(j)
      end
    end
    ret.each(&)
  end

  # Iterate over all judges with index.
  # @yield [Judge, Integer] Yields each judge with its index
  # @return [Integer] The total count of judges
  def each_with_index
    idx = 0
    each do |p|
      yield [p, idx]
      idx += 1
    end
    idx
  end
end
