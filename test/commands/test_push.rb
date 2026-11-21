# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require 'loog'
require 'webmock/minitest'
require_relative '../../lib/judges'
require_relative '../../lib/judges/commands/push'
require_relative '../test__helper'

# Test.
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2024-2026 Yegor Bugayenko
# License:: MIT
class TestPush < Minitest::Test
  def test_push_simple_factbase
    WebMock.disable_net_connect!
    stub_request(:get, 'https://example.org/csrf').to_return(body: 'test-csrf-token')
    stub_request(:post, %r{https://example.org/lock/foo}).to_return(status: 302)
    stub_request(:post, %r{https://example.org/unlock/foo}).to_return(status: 302)
    stub_request(:put, 'https://example.org/push/foo').to_return(status: 200, body: '42')
    Dir.mktmpdir do |d|
      file = File.join(d, 'base.fb')
      fb = Factbase.new
      fb.insert.foo_bar = 42
      File.binwrite(file, fb.export)
      Judges::Push.new(Loog::NULL).run(
        {
          'token' => '000',
          'host' => 'example.org',
          'port' => 443,
          'ssl' => true,
          'owner' => 'none'
        },
        ['foo', file]
      )
      Judges::Push.new(Loog::NULL).run(
        {
          'token' => '000',
          'host' => 'example.org',
          'port' => 443,
          'ssl' => true,
          'owner' => 'none',
          'zip' => false
        },
        ['foo', file]
      )
    end
  end

  def test_keeps_a_fractional_timeout
    Dir.mktmpdir do |d|
      file = File.join(d, 'base.fb')
      fb = Factbase.new
      fb.insert.foo = 1
      File.binwrite(file, fb.export)
      seen = nil
      fake = Object.new
      fake.define_singleton_method(:lock) { |*| true }
      fake.define_singleton_method(:unlock) { |*| true }
      fake.define_singleton_method(:push) { |*| 42 }
      maker =
        lambda do |*_args, **kwargs|
          seen = kwargs[:timeout]
          fake
        end
      BazaRb.stub(:new, maker) do
        Judges::Push.new(Loog::NULL).run(
          {
            'token' => '000',
            'host' => 'example.org',
            'port' => 443,
            'ssl' => true,
            'owner' => 'none',
            'timeout' => 0.5
          },
          ['foo', file]
        )
      end
      assert_in_delta(0.5, seen)
    end
  end

  def test_picks_http_port_without_ssl
    assert_equal(80, connects('ssl' => false))
  end

  def test_picks_https_port_with_ssl
    assert_equal(443, connects('ssl' => true))
  end

  def test_keeps_explicit_port
    assert_equal(8080, connects('ssl' => false, 'port' => 8080))
  end

  def test_fails_on_http_error
    WebMock.disable_net_connect!
    stub_request(:get, 'http://example.org/csrf').to_return(body: 'test-csrf-token')
    stub_request(:post, %r{http://example.org/lock/foo}).to_return(status: 302)
    stub_request(:put, 'http://example.org/push/foo').to_return(status: 500)
    stub_request(:post, %r{http://example.org/unlock/foo}).to_return(status: 302)
    Dir.mktmpdir do |d|
      file = File.join(d, 'base.fb')
      fb = Factbase.new
      fb.insert.foo_bar = 42
      File.binwrite(file, fb.export)
      assert_raises(StandardError) do
        Judges::Push.new(Loog::NULL).run(
          {
            'token' => '000',
            'host' => 'example.org',
            'port' => 80,
            'ssl' => false,
            'owner' => 'none'
          },
          ['foo', file]
        )
      end
    end
  end

  def test_fails_when_offline
    WebMock.disable_net_connect!
    assert_equal(
      'The push command needs the network, while --offline is set',
      assert_raises(StandardError) do
        Judges::Push.new(Loog::NULL).run({ 'offline' => true }, ['foo', 'file.fb'])
      end.message
    )
  end

  private

  def connects(opts)
    Dir.mktmpdir do |d|
      file = File.join(d, 'base.fb')
      File.binwrite(file, Factbase.new.export)
      seen = nil
      fake = Object.new
      fake.define_singleton_method(:lock) { |*| true }
      fake.define_singleton_method(:unlock) { |*| true }
      fake.define_singleton_method(:push) { |*| 42 }
      maker =
        lambda do |_host, port, *_args, **_kwargs|
          seen = port
          fake
        end
      BazaRb.stub(:new, maker) do
        Judges::Push.new(Loog::NULL).run(
          { 'token' => '000', 'host' => 'example.org', 'owner' => 'none' }.merge(opts),
          ['foo', file]
        )
      end
      seen
    end
  end
end
