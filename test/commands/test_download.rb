# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2025 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require 'loog'
require 'webmock/minitest'
require_relative '../../lib/judges'
require_relative '../../lib/judges/commands/download'
require_relative '../test__helper'

# Test.
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2024-2025 Yegor Bugayenko
# License:: MIT
class TestDownload < Minitest::Test
  def test_download_simple_durable
    WebMock.disable_net_connect!
    content = 'Hello, World!'
    stub_request(:get, 'https://example.org/durables/find?file=downloaded.txt&jname=myjudge').to_return(
      status: 200, body: '42'
    )
    stub_request(:get, 'https://example.org/durables/42/lock?owner=default').to_return(status: 302)
    stub_request(:get, 'https://example.org/durables/42').to_return(
      status: 200, body: content
    )
    stub_request(:get, 'https://example.org/durables/42/unlock?owner=default').to_return(status: 302)
    Dir.mktmpdir do |d|
      file = File.join(d, 'downloaded.txt')
      Judges::Download.new(Loog::NULL).run(
        {
          'token' => '000',
          'host' => 'example.org',
          'port' => 443,
          'ssl' => true,
          'owner' => 'default'
        },
        ['myjudge', file]
      )
      assert_equal(content, File.read(file))
    end
  end

  def test_download_with_custom_owner
    WebMock.disable_net_connect!
    content = 'Custom content'
    stub_request(:get, 'http://example.org/durables/find?file=data.bin&jname=judge1').to_return(
      status: 200, body: '123'
    )
    stub_request(:get, 'http://example.org/durables/123/lock?owner=custom').to_return(status: 302)
    stub_request(:get, 'http://example.org/durables/123').to_return(
      status: 200, body: content
    )
    stub_request(:get, 'http://example.org/durables/123/unlock?owner=custom').to_return(status: 302)
    Dir.mktmpdir do |d|
      file = File.join(d, 'data.bin')
      Judges::Download.new(Loog::NULL).run(
        {
          'token' => '000',
          'host' => 'example.org',
          'port' => 80,
          'ssl' => false,
          'owner' => 'custom'
        },
        ['judge1', file]
      )
      assert_equal(content, File.read(file))
    end
  end

  def test_fails_on_http_error
    WebMock.disable_net_connect!
    stub_request(:get, 'http://example.org/durables/find?file=test.txt&jname=somejudge').to_return(
      status: 200, body: '99'
    )
    stub_request(:get, 'http://example.org/durables/99/lock?owner=none').to_return(status: 302)
    stub_request(:get, 'http://example.org/durables/99').to_return(status: 404)
    stub_request(:get, 'http://example.org/durables/99/unlock?owner=none').to_return(status: 302)
    Dir.mktmpdir do |d|
      file = File.join(d, 'test.txt')
      assert_raises(StandardError) do
        Judges::Download.new(Loog::NULL).run(
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
      Judges::Download.new(Loog::NULL).run({}, ['only_one_arg'])
    end
    assert_raises(RuntimeError) do
      Judges::Download.new(Loog::NULL).run({}, %w[too many args])
    end
  end

  def test_handles_not_found_durable
    WebMock.disable_net_connect!
    stub_request(:get, 'http://example.org/durables/find?file=missing.txt&jname=notfound').to_return(
      status: 404
    )
    Dir.mktmpdir do |d|
      file = File.join(d, 'missing.txt')
      Judges::Download.new(Loog::NULL).run(
        {
          'token' => '000',
          'host' => 'example.org',
          'port' => 80,
          'ssl' => false
        },
        ['notfound', file]
      )
      refute_path_exists(file)
    end
  end
end
