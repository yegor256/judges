# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative '../lib/judges'
require_relative '../lib/judges/durable_name'
require_relative 'test__helper'

# Test.
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2024-2026 Yegor Bugayenko
# License:: MIT
class TestDurableName < Minitest::Test
  def test_accepts_valid_name
    assert_equal('data-1.txt', Judges::DurableName.new('/tmp/dir/data-1.txt').to_s)
  end

  def test_rejects_underscore
    assert_raises(StandardError) { Judges::DurableName.new('http_cache.db').to_s }
  end
end
