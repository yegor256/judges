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

  def test_ignores_empty_environment_token
    ENV.store('ZEROCRACY_TOKEN', '')
    require('baza-rb')
    seen = :not_set
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
    assert_nil(seen)
  ensure
    ENV.delete('ZEROCRACY_TOKEN')
  end

  def test_does_not_disclose_token_in_help_or_echo
    secret = 'SUPER_SECRET_TOKEN_XYZ'
    ENV.store('ZEROCRACY_TOKEN', secret)
    require('baza-rb')
    fake = Object.new
    fake.define_singleton_method(:name_exists?) { |*| false }
    maker = ->(*_args, **_kwargs) { fake }
    before = $stdout
    begin
      $stdout = StringIO.new
      JudgesGLI.run(['pull', '--help'])
      s = $stdout.string
    ensure
      $stdout = before
    end
    refute_includes(s, secret)
    Dir.mktmpdir do |d|
      before = $stdout
      begin
        $stdout = StringIO.new
        BazaRb.stub(:new, maker) do
          JudgesGLI.run(['--echo', 'pull', 'foo', File.join(d, 'base.fb')])
        end
        echo = $stdout.string
      ensure
        $stdout = before
      end
      refute_includes(echo, secret)
    end
  ensure
    ENV.delete('ZEROCRACY_TOKEN')
  end
end
