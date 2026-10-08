# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require 'factbase'
require 'loog'
require 'webmock/minitest'
require_relative '../../lib/judges'
require_relative '../../lib/judges/commands/pull'
require_relative '../test__helper'

# Test.
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2024-2026 Yegor Bugayenko
# License:: MIT
class TestPull < Minitest::Test
  def test_wait_uses_monotonic_time
    checks = 0
    baza = Object.new
    baza.define_singleton_method(:finished?) do |_id|
      checks += 1
      checks > 3
    end
    pull = Judges::Pull.new(Loog::NULL)
    tick = 0
    wall = Time.now
    Process.stub(:clock_gettime, ->(_clock) { tick += 1 }) do
      Time.stub(:now, -> { wall -= 3600 }) do
        pull.stub(:sleep, ->(_seconds) {}) do
          assert_includes(
            assert_raises(StandardError) { pull.__send__(:wait, 'foo', baza, 42, 1.5) }.message,
            'Time is over'
          )
        end
      end
    end
  end

  def test_pull_simple_factbase
    WebMock.disable_net_connect!
    stub_request(:get, 'http://example.org/csrf').to_return(body: 'test-csrf-token')
    stub_request(:post, %r{http://example.org/lock/foo}).to_return(status: 302)
    stub_request(:get, 'http://example.org/exists/foo').to_return(body: 'yes')
    stub_request(:get, 'http://example.org/recent/foo.txt').to_return(body: '42')
    stub_request(:get, 'http://example.org/finished/42').to_return(body: 'yes')
    stub_request(:get, 'http://example.org/exit/42.txt').to_return(body: '0')
    stub_request(:post, %r{http://example.org/unlock/foo}).to_return(status: 302)
    fb = Factbase.new
    fb.insert.foo = 42
    stub_request(:get, 'http://example.org/pull/42.fb').to_return(body: fb.export, headers: {})
    Dir.mktmpdir do |d|
      file = File.join(d, 'base.fb')
      Judges::Pull.new(Loog::NULL).run(
        {
          'token' => '000',
          'host' => 'example.org',
          'port' => 80,
          'ssl' => false,
          'wait' => 10,
          'owner' => 'none'
        },
        ['foo', file]
      )
      fb = Factbase.new
      fb.import(File.binread(file))
    end
  end

  def test_unlocks_baza_on_success
    WebMock.disable_net_connect!
    stub_request(:get, 'http://example.org/csrf').to_return(body: 'test-csrf-token')
    stub_request(:post, %r{http://example.org/lock/foo}).to_return(status: 302)
    stub_request(:get, 'http://example.org/exists/foo').to_return(body: 'yes')
    stub_request(:get, 'http://example.org/recent/foo.txt').to_return(body: '42')
    stub_request(:get, 'http://example.org/finished/42').to_return(body: 'yes')
    stub_request(:get, 'http://example.org/exit/42.txt').to_return(body: '0')
    unlock = stub_request(:post, %r{http://example.org/unlock/foo}).to_return(status: 302)
    fb = Factbase.new
    fb.insert.foo = 42
    stub_request(:get, 'http://example.org/pull/42.fb').to_return(body: fb.export, headers: {})
    Dir.mktmpdir do |d|
      Judges::Pull.new(Loog::NULL).run(
        {
          'token' => '000',
          'host' => 'example.org',
          'port' => 80,
          'ssl' => false,
          'wait' => 10,
          'owner' => 'none'
        },
        ['foo', File.join(d, 'base.fb')]
      )
    end
    assert_requested(unlock)
  end

  def test_fail_pull_when_job_is_broken
    WebMock.disable_net_connect!
    stub_request(:get, 'http://example.org/csrf').to_return(body: 'test-csrf-token')
    stub_request(:post, %r{http://example.org/lock/foo}).to_return(status: 302)
    stub_request(:get, 'http://example.org/exists/foo').to_return(body: 'yes')
    stub_request(:get, 'http://example.org/recent/foo.txt').to_return(body: '42')
    stub_request(:get, 'http://example.org/finished/42').to_return(body: 'yes')
    stub_request(:get, 'http://example.org/exit/42.txt').to_return(body: '1')
    stub_request(:get, 'http://example.org/stdout/42.txt').to_return(body: 'oops, some trouble here')
    stub_request(:post, %r{http://example.org/unlock/foo}).to_return(status: 302)
    Dir.mktmpdir do |d|
      file = File.join(d, 'base.fb')
      e =
        assert_raises(StandardError) do
          Judges::Pull.new(Loog::NULL).run(
            {
              'token' => '000',
              'host' => 'example.org',
              'port' => 80,
              'ssl' => false,
              'wait' => 10,
              'owner' => 'none'
            },
            ['foo', file]
          )
        end
      assert_includes(e.message, 'expire it', e)
    end
  end
end
