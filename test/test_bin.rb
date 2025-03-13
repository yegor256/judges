# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2025 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative 'test__helper'

# Test.
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2024-2025 Yegor Bugayenko
# License:: MIT
class TestBin < Minitest::Test
  def test_simple_run
    ENV.store('GLI_TESTING', 'yes')
    load File.join(__dir__, '../bin/judges')
    before = $stdout
    begin
      $stdout = StringIO.new
      JudgesGLI.run(['--version'])
      s = $stdout.string
    ensure
      $stdout = before
    end
    assert_includes(s, Judges::VERSION, s)
  end
end
