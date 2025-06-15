# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2025 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require 'loog'
require 'webmock/minitest'
require_relative '../../lib/judges'
require_relative '../../lib/judges/commands/push'
require_relative '../test__helper'

# Test.
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2024-2025 Yegor Bugayenko
# License:: MIT
class TestPush < Minitest::Test
  def test_push_simple_factbase
    WebMock.disable_net_connect!
    stub_request(:get, 'https://example.org/csrf').to_return(body: 'test-csrf-token')
    stub_request(:post, %r{https://example.org/lock/foo}).to_return(status: 302)
    stub_request(:post, %r{https://example.org/unlock/foo}).to_return(status: 302)
    stub_request(:put, 'https://example.org/push/foo').to_return(
      status: 200, body: '42'
    )
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
end
