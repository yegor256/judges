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
  def initialize(dir, lib, loog, start: Time.now)
    @dir = dir
    @lib = lib
    @loog = loog
    @start = start
  end

  # Get one judge by name.
  # @return [Judge]
  def get(name)
    d = File.absolute_path(File.join(@dir, name))
    raise "Judge #{name} doesn't exist in #{@dir}" unless File.exist?(d)
    Judges::Judge.new(d, @lib, @loog, start: @start)
  end

  # Iterate over them all.
  # @yield [Judge]
  def each
    return to_enum(__method__) unless block_given?
    Dir.glob(File.join(@dir, '*')).each do |d|
      next unless File.directory?(d)
      b = File.basename(d)
      next unless File.exist?(File.join(d, "#{b}.rb"))
      yield Judges::Judge.new(File.absolute_path(d), @lib, @loog)
    end
  end

  # Iterate over them all.
  # @yield [(Judge, Integer)]
  def each_with_index
    idx = 0
    each do |p|
      yield [p, idx]
      idx += 1
    end
    idx
  end
end
