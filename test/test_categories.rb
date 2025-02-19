# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2025 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require 'minitest/autorun'
require_relative '../lib/judges'
require_relative '../lib/judges/categories'

# Test.
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2024-2025 Yegor Bugayenko
# License:: MIT
class TestCategories < Minitest::Test
  def test_basic
    cats = Judges::Categories.new(%w[foo bar], ['bad'])
    assert(cats.ok?(%w[foo other]))
    assert(cats.ok?(%w[other more bar]))
    refute(cats.ok?(%w[bad other]))
    refute(cats.ok?(['other']))
    refute(cats.ok?('hey'))
    refute(cats.ok?(nil))
  end

  def test_all_enabled
    cats = Judges::Categories.new([], ['bad'])
    assert(cats.ok?(nil))
    assert(cats.ok?('hey'))
    assert(cats.ok?(%w[foo other]))
    assert(cats.ok?(%w[other more bar]))
    refute(cats.ok?(%w[bad other]))
  end
end
