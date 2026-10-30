# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative 'test__helper'
require 'open3'
require 'tmpdir'

# Test.
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2024-2026 Yegor Bugayenko
# License:: MIT
class TestBin < Minitest::Test
  def test_simple_run
    ENV.store('GLI_TESTING', 'yes')
    load(File.join(__dir__, '../bin/judges'))
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

  def test_fails_when_requested_factbase_differs_from_activated
    out, code = run_cli('--factbase=0.10.0', 'eval', temp_fb('a'), '$fb.insert.a = 1')
    refute_equal(0, code, "expected a failure, got: #{out}")
    assert_includes(out, 'via --factbase', out)
    assert_includes(out, 'Requested factbase 0.10.0', out)
    assert_includes(out, 'is already activated', out)
  end

  def test_passes_when_requested_factbase_matches_activated
    require 'factbase'
    out, code = run_cli("--factbase=#{Factbase::VERSION}", 'eval', temp_fb('b'), '$fb.insert.a = 1')
    assert_equal(0, code, out)
  end

  def test_refuses_a_garbage_factbase_version
    out, code = run_cli('--factbase=bogus', 'eval', temp_fb('c'), '$fb.insert.a = 1')
    refute_equal(0, code, "expected a failure, got: #{out}")
    assert_includes(out, 'bogus', out)
  end

  private

  def temp_fb(tag)
    File.join(Dir.tmpdir, "test-886-#{tag}.fb")
  end

  def run_cli(*args)
    out, err, st = Open3.capture3(Gem.ruby, File.join(__dir__, '..', 'bin', 'judges'), *args)
    [out + err, st.exitstatus]
  end
end
