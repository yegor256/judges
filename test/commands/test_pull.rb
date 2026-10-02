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
  def test_waits_for_job_before_reading_exit_code
    WebMock.disable_net_connect!
    stub_request(:get, 'http://example.org/csrf').to_return(body: 'test-csrf-token')
    stub_request(:post, %r{http://example.org/lock/foo}).to_return(status: 302)
    stub_request(:get, 'http://example.org/exists/foo').to_return(body: 'yes')
    stub_request(:get, 'http://example.org/recent/foo.txt').to_return(body: '42')
    finished, status = stub_job
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
    assert_requested(finished, times: 2)
    assert_requested(status, times: 1)
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

  private

  def stub_job
    finishes = 0
    finished = stub_request(:get, 'http://example.org/finished/42').to_return do
      finishes += 1
      { body: finishes == 1 ? 'no' : 'yes' }
    end
    status = stub_request(:get, 'http://example.org/exit/42.txt').to_return do
      finishes.zero? ? { status: 404 } : { body: '0' }
    end
    [finished, status]
  end
end
