# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative '../lib/judges'
require_relative '../lib/judges/owner'
require_relative 'test__helper'

# Test.
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2024-2026 Yegor Bugayenko
# License:: MIT
class TestOwner < Minitest::Test
  def test_keeps_given_owner
    assert_equal('boss', Judges::Owner.new('boss').to_s)
  end

  def test_makes_different_owners
    refute_equal(Judges::Owner.new(nil).to_s, Judges::Owner.new(nil).to_s)
  end
end
