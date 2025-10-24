# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2025 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require 'loog'
require 'webmock/minitest'
require_relative '../../lib/judges'
require_relative '../../lib/judges/commands/upload'
require_relative '../test__helper'

# Test.
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2024-2025 Yegor Bugayenko
# License:: MIT
class TestUpload < Minitest::Test
  def test_upload_simple_durable
    WebMock.disable_net_connect!
    content = 'Hello, World!'
    stub_request(:get, 'https://example.org/durables/find?file=upload.txt&jname=myjudge&pname=myjudge').to_return(
      status: 404
    )
    stub_request(:get, 'https://example.org/csrf').to_return(body: 'test-csrf-token')
    stub_request(:post, 'https://example.org/durables/place').to_return(
      status: 302, headers: { 'X-Zerocracy-DurableId' => '42' }
    )
    stub_request(:post, %r{https://example.org/durables/42/lock}).to_return(status: 302)
    stub_request(:put, %r{https://example.org/durables/42}).to_return(status: 200)
    stub_request(:post, %r{https://example.org/durables/42/unlock}).to_return(status: 302)
    Dir.mktmpdir do |d|
      file = File.join(d, 'upload.txt')
      File.write(file, content)
      Judges::Upload.new(Loog::NULL).run(
        {
          'token' => '000',
          'host' => 'example.org',
          'port' => 443,
          'ssl' => true,
          'owner' => 'default'
        },
        ['myjudge', file]
      )
    end
  end

  def test_upload_with_custom_owner
    WebMock.disable_net_connect!
    content = 'Binary data here'
    stub_request(:get, 'http://example.org/durables/find?file=data.bin&jname=judge1&pname=judge1').to_return(
      status: 200, body: '123'
    )
    stub_request(:get, 'http://example.org/csrf').to_return(body: 'test-csrf-token')
    stub_request(:post, %r{http://example.org/durables/123/lock}).to_return(status: 302)
    stub_request(:put, 'http://example.org/durables/123').to_return(status: 200)
    stub_request(:post, %r{http://example.org/durables/123/unlock}).to_return(status: 302)
    Dir.mktmpdir do |d|
      file = File.join(d, 'data.bin')
      File.write(file, content)
      Judges::Upload.new(Loog::NULL).run(
        {
          'token' => '000',
          'host' => 'example.org',
          'port' => 80,
          'ssl' => false,
          'owner' => 'custom'
        },
        ['judge1', file]
      )
    end
  end

  def test_fails_on_http_error
    WebMock.disable_net_connect!
    stub_request(:get, 'http://example.org/durables/find?file=test.txt&jname=somejudge&pname=somejudge').to_return(
      status: 404
    )
    stub_request(:get, 'http://example.org/csrf').to_return(body: 'test-csrf-token')
    stub_request(:post, 'http://example.org/durables/place').to_return(status: 500)
    Dir.mktmpdir do |d|
      file = File.join(d, 'test.txt')
      File.write(file, 'content')
      assert_raises(StandardError) do
        Judges::Upload.new(Loog::NULL).run(
          {
            'token' => '000',
            'host' => 'example.org',
            'port' => 80,
            'ssl' => false,
            'owner' => 'none'
          },
          ['somejudge', file]
        )
      end
    end
  end

  def test_fails_with_wrong_number_of_arguments
    assert_raises(RuntimeError) do
      Judges::Upload.new(Loog::NULL).run({}, ['only_one_arg'])
    end
    assert_raises(RuntimeError) do
      Judges::Upload.new(Loog::NULL).run({}, %w[too many args])
    end
  end

  def test_fails_when_file_does_not_exist
    assert_raises(RuntimeError) do
      Judges::Upload.new(Loog::NULL).run(
        {
          'token' => '000',
          'host' => 'example.org',
          'port' => 80,
          'ssl' => false
        },
        ['myjudge', '/nonexistent/file.txt']
      )
    end
  end
end
