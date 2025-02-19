# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2025 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require 'minitest/autorun'
require_relative '../lib/judges'
require_relative '../lib/judges/churn'

# Test.
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2024-2025 Yegor Bugayenko
# License:: MIT
class TestChurn < Minitest::Test
  def test_basic
    churn = Judges::Churn.new(0, 0)
    assert_equal('0/0', churn.to_s)
    assert_equal('42/0', (churn + 42).to_s)
    assert_equal('0/17', (churn - 17).to_s)
  end

  def test_with_errors
    churn = Judges::Churn.new(0, 0)
    churn << 'oops'
    assert_equal('0/0/1', churn.to_s)
    assert_equal('42/0/1', (churn + 42).to_s)
    assert_equal('0/0/1', (Judges::Churn.new(0, 0) + churn).to_s)
  end
end
