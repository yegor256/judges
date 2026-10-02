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
    stub_request(:get, 'https://example.org/exists/foo').to_return(body: 'no')
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
      fake.define_singleton_method(:name_exists?) { |_name| false }
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

  def test_fails_on_http_error
    WebMock.disable_net_connect!
    stub_request(:get, 'http://example.org/csrf').to_return(body: 'test-csrf-token')
    stub_request(:get, 'http://example.org/exists/foo').to_return(body: 'no')
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

  def test_rejects_a_stale_snapshot
    Dir.mktmpdir do |d|
      file = File.join(d, 'base.fb')
      File.binwrite(file, Factbase.new.export)
      File.binwrite(Judges::Impex.marker(file), '42')
      sent = false
      fake = Object.new
      fake.define_singleton_method(:lock) { |*| true }
      fake.define_singleton_method(:unlock) { |*| true }
      fake.define_singleton_method(:name_exists?) { |_name| true }
      fake.define_singleton_method(:recent) { |_name| 43 }
      fake.define_singleton_method(:push) { |*| sent = true }
      maker = ->(*_args, **_kwargs) { fake }
      BazaRb.stub(:new, maker) do
        assert_raises(StandardError) do
          Judges::Push.new(Loog::NULL).run(
            { 'token' => '000', 'host' => 'example.org', 'port' => 443, 'ssl' => true, 'owner' => 'none' },
            ['foo', file]
          )
        end
      end
      refute(sent, 'a stale factbase must not be uploaded')
    end
  end

  def test_pushes_a_new_name_without_a_pulled_snapshot
    sent = false
    fake = Object.new
    fake.define_singleton_method(:lock) { |*| true }
    fake.define_singleton_method(:unlock) { |*| true }
    fake.define_singleton_method(:name_exists?) { |_name| true }
    fake.define_singleton_method(:recent) do |_name|
      raise(BazaRb::ServerFailure, "Invalid response code #303: the product doesn't have any not-yet-expired jobs")
    end
    fake.define_singleton_method(:push) { |*| sent = true }
    maker = ->(*_args, **_kwargs) { fake }
    Dir.mktmpdir do |d|
      file = File.join(d, 'base.fb')
      File.binwrite(file, Factbase.new.export)
      BazaRb.stub(:new, maker) do
        Judges::Push.new(Loog::NULL).run(
          { 'token' => '000', 'host' => 'example.org', 'port' => 443, 'ssl' => true, 'owner' => 'none' },
          ['foo', file]
        )
      end
    end
    assert(sent, 'a new remote name has no snapshot that could be stale')
  end

  def test_rejects_missing_snapshot_marker
    sent = false
    fake = Object.new
    fake.define_singleton_method(:lock) { |*| true }
    fake.define_singleton_method(:unlock) { |*| true }
    fake.define_singleton_method(:name_exists?) { |_name| true }
    fake.define_singleton_method(:recent) { |_name| 42 }
    fake.define_singleton_method(:push) { |*| sent = true }
    maker = ->(*_args, **_kwargs) { fake }
    Dir.mktmpdir do |d|
      file = File.join(d, 'base.fb')
      File.binwrite(file, Factbase.new.export)
      BazaRb.stub(:new, maker) do
        assert_raises(StandardError) do
          Judges::Push.new(Loog::NULL).run(
            { 'token' => '000', 'host' => 'example.org', 'port' => 443, 'ssl' => true, 'owner' => 'none' },
            ['foo', file]
          )
        end
      end
    end
    refute(sent, 'an existing remote factbase requires a pull marker')
  end

  def test_pushes_when_the_snapshot_is_current
    sent = false
    fake = Object.new
    fake.define_singleton_method(:lock) { |*| true }
    fake.define_singleton_method(:unlock) { |*| true }
    fake.define_singleton_method(:name_exists?) { |_name| true }
    fake.define_singleton_method(:recent) { |_name| 42 }
    fake.define_singleton_method(:push) { |*| sent = true }
    maker = ->(*_args, **_kwargs) { fake }
    Dir.mktmpdir do |d|
      file = File.join(d, 'base.fb')
      File.binwrite(file, Factbase.new.export)
      marker = Judges::Impex.marker(file)
      File.binwrite(marker, '42')
      BazaRb.stub(:new, maker) do
        Judges::Push.new(Loog::NULL).run(
          { 'token' => '000', 'host' => 'example.org', 'port' => 443, 'ssl' => true, 'owner' => 'none' },
          ['foo', file]
        )
      end
      assert(sent, 'an unchanged remote base allows the factbase to be pushed')
      refute(File.file?(marker), 'a successful push invalidates the old pull marker')
    end
  end
end
