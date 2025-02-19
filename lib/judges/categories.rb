# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2025 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative '../judges'

# Categories of tests.
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2024-2025 Yegor Bugayenko
# License:: MIT
class Judges::Categories
  # Ctor.
  # @param [Array<String>] enable List of categories to enable
  # @param [Array<String>] disable List of categories to enable
  def initialize(enable, disable)
    @enable = enable.is_a?(Array) ? enable : []
    @disable = disable.is_a?(Array) ? disable : []
  end

  # This test is good to go, with this list of categories?
  # @param [Array<String>] cats List of them
  # @return [Boolean] True if yes
  def ok?(cats)
    cats = [] if cats.nil?
    cats = [cats] unless cats.is_a?(Array)
    cats.each do |c|
      return false if @disable.any?(c)
      return true if @enable.any?(c)
    end
    return true if @enable.empty?
    false
  end
end
