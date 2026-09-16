# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require 'tmpdir'
require_relative 'test__helper'

# Test.
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2024-2026 Yegor Bugayenko
# License:: MIT
class TestBin < Minitest::Test
  def setup
    ENV.store('GLI_TESTING', 'yes')
    load(File.join(__dir__, '../bin/judges')) unless defined?(JudgesGLI)
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

  def test_reads_the_token_from_the_environment
    ENV.store('ZEROCRACY_TOKEN', 'ZRCY-from-the-environment')
    require('baza-rb')
    seen = nil
    fake = Object.new
    fake.define_singleton_method(:name_exists?) { |*| false }
    maker =
      lambda do |*args, **_kwargs|
        seen = args[2]
        fake
      end
    Dir.mktmpdir do |d|
      BazaRb.stub(:new, maker) do
        JudgesGLI.run(['pull', 'foo', File.join(d, 'base.fb')])
      end
    end
    assert_equal('ZRCY-from-the-environment', seen)
  ensure
    ENV.delete('ZEROCRACY_TOKEN')
  end

  def test_prefers_the_flag_over_the_environment
    ENV.store('ZEROCRACY_TOKEN', 'ZRCY-from-the-environment')
    require('baza-rb')
    seen = nil
    fake = Object.new
    fake.define_singleton_method(:name_exists?) { |*| false }
    maker =
      lambda do |*args, **_kwargs|
        seen = args[2]
        fake
      end
    Dir.mktmpdir do |d|
      BazaRb.stub(:new, maker) do
        JudgesGLI.run(['pull', '--token', 'ZRCY-from-the-flag', 'foo', File.join(d, 'base.fb')])
      end
    end
    assert_equal('ZRCY-from-the-flag', seen)
  ensure
    ENV.delete('ZEROCRACY_TOKEN')
  end
end
