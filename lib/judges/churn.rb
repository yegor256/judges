# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2025 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative '../judges'

# How many facts were modified.
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2024-2025 Yegor Bugayenko
# License:: MIT
class Judges::Churn
  attr_reader :added, :removed, :errors

  def initialize(added, removed, errors = [])
    @added = added
    @removed = removed
    @errors = errors
  end

  def to_s
    "#{@added}/#{@removed}#{@errors.empty? ? '' : "/#{@errors.size}"}"
  end

  def zero?
    @added.zero? && @removed.zero? && @errors.empty?
  end

  def <<(error)
    @errors << error
    nil
  end

  def +(other)
    if other.is_a?(Judges::Churn)
      Judges::Churn.new(@added + other.added, @removed + other.removed, @errors + other.errors)
    else
      Judges::Churn.new(@added + other, @removed, @errors)
    end
  end

  def -(other)
    if other.is_a?(Judges::Churn)
      Judges::Churn.new(@added - other.added, @removed - other.removed, @errors + other.errors)
    else
      Judges::Churn.new(@added, @removed + other, @errors)
    end
  end
end
