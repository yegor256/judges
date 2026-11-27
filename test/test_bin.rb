# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative 'test__helper'

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
end
