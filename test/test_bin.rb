# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative 'test__helper'

# Test.
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2024-2026 Yegor Bugayenko
# License:: MIT
class TestBin < Minitest::Test
  def setup
    return if defined?(JudgesGLI)
    ENV.store('GLI_TESTING', 'yes')
    load(File.join(__dir__, '../bin/judges'))
  end

  def test_simple_run
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

  def test_update_lifetime_flag_type
    assert_equal(Float, JudgesGLI.commands[:update].flags[:lifetime].type)
  end

  def test_update_timeout_flag_type
    assert_equal(Float, JudgesGLI.commands[:update].flags[:timeout].type)
  end

  def test_push_timeout_flag_type
    assert_equal(Float, JudgesGLI.commands[:push].flags[:timeout].type)
  end

  def test_pull_timeout_flag_type
    assert_equal(Float, JudgesGLI.commands[:pull].flags[:timeout].type)
  end

  def test_download_timeout_flag_type
    assert_equal(Float, JudgesGLI.commands[:download].flags[:timeout].type)
  end

  def test_upload_timeout_flag_type
    assert_equal(Float, JudgesGLI.commands[:upload].flags[:timeout].type)
  end

  def test_fractional_timeout_parsing
    [
      JudgesGLI.commands[:update].flags[:lifetime],
      JudgesGLI.commands[:update].flags[:timeout],
      JudgesGLI.commands[:push].flags[:timeout],
      JudgesGLI.commands[:pull].flags[:timeout],
      JudgesGLI.commands[:download].flags[:timeout],
      JudgesGLI.commands[:upload].flags[:timeout]
    ].each do |flag|
      assert_in_delta(0.5, Kernel.public_send(flag.type.to_s.to_sym, '0.5'))
    end
  end

  def test_flag_methods
    flag = JudgesGLI.commands[:update].flags[:timeout]
    assert_respond_to(flag, :type)
    assert_equal(Float, flag.type)
  end
end
