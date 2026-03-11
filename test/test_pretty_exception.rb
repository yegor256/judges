# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative '../lib/judges/pretty_exception'
require_relative 'test__helper'

# Test.
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2024-2026 Yegor Bugayenko
# License:: MIT
class TestPrettyException < Minitest::Test
  def test_long_message
    txt = 'test ' * 50
    assert_equal(
      txt.ellipsized(100, :right),
      Judges::PrettyException.new(RuntimeError.new(txt)).message
    )
  end

  def test_short_message
    txt = 'test ' * 15
    assert_equal(
      txt,
      Judges::PrettyException.new(RuntimeError.new(txt)).message
    )
  end

  def test_hide_class
    exp = Judges::PrettyException.new(RuntimeError.new('test'))
    assert_equal(exp.class, RuntimeError)
    assert_instance_of(RuntimeError, exp)
    assert_kind_of(RuntimeError, exp)
    assert_kind_of(StandardError, exp)
  end
end
