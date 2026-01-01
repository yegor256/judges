# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2026 Yegor Bugayenko
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
# Copyright:: Copyright (c) 2024-2026 Yegor Bugayenko
# License:: MIT
class Judges::Judges
  # Initialize.
  # @param [String] dir Directory containing judges
  # @param [String] lib Library directory
  # @param [Loog] loog Logging facility
  # @param [Time] epoch Start time
  # @param [String] shuffle Prefix for names of judges to shuffle
  # @param [Array<String>] boost Names/patterns of judges to boost in priority (supports '*' wildcards)
  # @param [Array<String>] demote Names/patterns of judges to demote in priority (supports '*' wildcards)
  # @param [Integer] seed Random seed for judge ordering (default: 0)
  def initialize(dir, lib, loog, epoch: Time.now, shuffle: '', boost: [], demote: [], seed: 0)
    @dir = dir
    @lib = lib
    @loog = loog
    @epoch = epoch
    @shuffle = shuffle || ''
    @boost = boost
    @demote = demote
    @seed = seed || 0
  end

  # Retrieves a specific judge by its name.
  #
  # The judge must exist as a directory within the judges directory with the given name.
  #
  # @param [String] name The name of the judge to retrieve (directory name)
  # @return [Judges::Judge] The judge object initialized with the found directory
  # @raise [RuntimeError] If no judge directory exists with the given name
  def get(name)
    d = File.absolute_path(File.join(@dir, name))
    raise "Judge #{name} doesn't exist in #{@dir}" unless File.exist?(d)
    Judges::Judge.new(d, @lib, @loog, epoch: @epoch)
  end

  # Iterates over all valid judges in the directory.
  #
  # This method discovers all judge directories, validates them (ensuring they contain
  # a corresponding .rb file), and yields them in a specific order. The order is
  # determined by:
  # 1. Randomly reorder judges (if shuffle prefix is empty, shuffle all judges;
  #    if prefix is not empty, shuffle only those NOT starting with the prefix)
  # 2. Judges whose names match the boost patterns are placed first (supports '*' wildcards)
  # 3. Judges whose names match the demote patterns are placed last (supports '*' wildcards)
  #
  # @yield [Judges::Judge] Yields each valid judge object
  # @return [Enumerator] Returns an enumerator if no block is given
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
      .reject { |a| !@shuffle.empty? && a[0].start_with?(@shuffle) }
      .to_h { |a| [a[1], a[2]] }
    positions = mapping.values.shuffle(random: Random.new(@seed))
    mapping.keys.zip(positions).to_h.each do |before, after|
      good[after] = all[before]
    end
    boosted = []
    demoted = []
    normal = []
    good.map { |a| a[0] }.each do |j|
      if fits?(j.name, @boost)
        boosted.append(j)
      elsif fits?(j.name, @demote)
        demoted.append(j)
      else
        normal.append(j)
      end
    end
    ret = boosted + normal + demoted
    ret.each(&)
  end

  # Iterates over all judges while tracking their index position.
  #
  # This method calls the #each method and additionally provides a zero-based
  # index for each judge yielded. The judges are processed in the same order
  # as determined by the #each method (with boost and shuffle rules applied).
  #
  # @yield [Judges::Judge, Integer] Yields each judge object along with its index (starting from 0)
  # @return [Integer] The total count of judges processed
  def each_with_index
    idx = 0
    each do |p|
      yield [p, idx]
      idx += 1
    end
    idx
  end

  private

  # Checks if a judge name matches any of the given patterns.
  # Patterns can contain '*' wildcards which are converted to '.*' regex patterns.
  #
  # @param [String] name The judge name to check
  # @param [Array<String>, String, nil] patterns Array of patterns, or single pattern string, may contain '*' wildcards
  # @return [Boolean] true if name matches any pattern, false otherwise
  def fits?(name, patterns)
    return false if patterns.nil? || patterns.empty?
    Array(patterns).any? do |pattern|
      name.match?("\\A#{pattern.gsub('*', '.*')}\\z")
    end
  end
end
