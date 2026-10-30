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
    original = ENV.fetch('GLI_TESTING', nil)
    testing do
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
    if original.nil?
      refute_includes(ENV, 'GLI_TESTING')
    else
      assert_equal(original, ENV.fetch('GLI_TESTING', nil))
    end
  end

  def test_restores_absent_gli_testing
    ENV.delete('GLI_TESTING')
    testing { assert_equal('yes', ENV.fetch('GLI_TESTING', nil)) }
    refute_includes(ENV, 'GLI_TESTING')
  ensure
    ENV.delete('GLI_TESTING')
  end

  def test_restores_previous_gli_testing
    ENV.store('GLI_TESTING', 'no')
    testing { assert_equal('yes', ENV.fetch('GLI_TESTING', nil)) }
    assert_equal('no', ENV.fetch('GLI_TESTING', nil))
  ensure
    ENV.delete('GLI_TESTING')
  end

  def test_restores_gli_testing_on_failure
    ENV.store('GLI_TESTING', 'no')
    assert_raises(RuntimeError) do
      testing { raise(RuntimeError, 'boom') }
    end
    assert_equal('no', ENV.fetch('GLI_TESTING', nil))
  ensure
    ENV.delete('GLI_TESTING')
  end

  def test_fails_when_factbase_differs_from_activated
    out, code = cli('--factbase=0.10.0', 'eval', fake_fb('a'), '$fb.insert.a = 1')
    refute_equal(0, code, "expected a failure, got: #{out}")
    assert_includes(out, 'via --factbase', out)
    assert_includes(out, 'Requested factbase 0.10.0', out)
    assert_includes(out, 'is already activated', out)
  end

  def test_passes_when_factbase_matches_activated
    require('factbase')
    out, code = cli("--factbase=#{Factbase::VERSION}", 'eval', fake_fb('b'), '$fb.insert.a = 1')
    assert_equal(0, code, out)
  end

  def test_refuses_a_garbage_factbase_version
    out, code = cli('--factbase=bogus', 'eval', fake_fb('c'), '$fb.insert.a = 1')
    refute_equal(0, code, "expected a failure, got: #{out}")
    assert_includes(out, 'bogus', out)
  end

  private

  def testing
    before = ENV.fetch('GLI_TESTING', nil)
    ENV.store('GLI_TESTING', 'yes')
    yield
  ensure
    if before.nil?
      ENV.delete('GLI_TESTING')
    else
      ENV.store('GLI_TESTING', before)
    end
  end

  def fake_fb(tag)
    File.join(Dir.tmpdir, "test-886-#{tag}.fb")
  end

  def cli(*)
    out, err, st = Open3.capture3({ 'GLI_TESTING' => nil }, Gem.ruby, File.join(__dir__, '..', 'bin', 'judges'), *)
    [out + err, st.exitstatus]
  end
end
