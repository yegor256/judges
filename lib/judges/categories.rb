# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2025 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative '../judges'

# Categories of tests.
#
# This class manages test categories, allowing you to enable or disable
# specific categories of tests. It provides a mechanism to filter which
# tests should be executed based on their associated categories.
#
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2024-2025 Yegor Bugayenko
# License:: MIT
class Judges::Categories
  # Initialize a new Categories instance.
  #
  # Creates a categories filter with lists of enabled and disabled categories.
  # The filter logic works as follows:
  # - If a category is in the disable list, the test is rejected
  # - If a category is in the enable list, the test is accepted
  # - If no categories are enabled (empty enable list), all tests are accepted
  #   unless explicitly disabled
  #
  # @param [Array<String>] enable List of categories to enable
  # @param [Array<String>] disable List of categories to disable
  def initialize(enable, disable)
    @enable = enable.is_a?(Array) ? enable : []
    @disable = disable.is_a?(Array) ? disable : []
  end

  # Check if a test with given categories should be executed.
  #
  # Determines whether a test associated with the provided categories
  # should be executed based on the enable/disable lists configured
  # during initialization.
  #
  # The evaluation logic:
  # 1. If any category is in the disable list, returns false
  # 2. If any category is in the enable list, returns true
  # 3. If the enable list is empty, returns true (all tests allowed)
  # 4. Otherwise, returns false
  #
  # @param [Array<String>, String, nil] cats List of categories associated with the test,
  #   can be a single string or nil
  # @return [Boolean] true if the test should be executed, false otherwise
  # @example Check if a test with categories should run
  #   categories = Judges::Categories.new(['important'], ['experimental'])
  #   categories.ok?(['important', 'slow']) # => true
  #   categories.ok?(['experimental']) # => false
  #   categories.ok?(nil) # => true (if enable list is empty)
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
