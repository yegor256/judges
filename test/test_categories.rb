# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative '../lib/judges'
require_relative '../lib/judges/categories'
require_relative 'test__helper'

# Test.
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2024-2026 Yegor Bugayenko
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

  def test_disable_dominates_no_matter_order
    cats = Judges::Categories.new(%w[foo bar], ['bad'])
    refute(cats.ok?(%w[bad other]))
    refute(cats.ok?(%w[foo bad]))
    refute(cats.ok?(%w[other bad foo]))
  end

  def test_all_enabled
    cats = Judges::Categories.new([], ['bad'])
    assert(cats.ok?(nil))
    assert(cats.ok?('hey'))
    assert(cats.ok?(%w[foo other]))
    assert(cats.ok?(%w[other more bar]))
    refute(cats.ok?(%w[bad other]))
  end

  def test_takes_one_category_as_a_string
    cats = Judges::Categories.new('slow', 'broken')
    refute(cats.ok?(['broken']))
    refute(cats.ok?(['other']))
    assert(cats.ok?(['slow']))
  end

  def test_takes_nil_lists
    assert(Judges::Categories.new(nil, nil).ok?(['anything']))
  end
end
