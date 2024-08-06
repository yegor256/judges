# frozen_string_literal: true

# Copyright (c) 2024 Yegor Bugayenko
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the 'Software'), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED 'AS IS', WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

require 'minitest/autorun'
require 'webmock/minitest'
require 'webrick'
require 'loog'
require 'socket'
require 'stringio'
require 'random-port'
require 'factbase'
require 'securerandom'
require 'net/ping'
require_relative '../lib/judges'
require_relative '../lib/judges/baza'

# Test.
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2024 Yegor Bugayenko
# License:: MIT
class TestBaza < Minitest::Test
  TOKEN = '00000000-0000-0000-0000-000000000000'
  HOST = 'api.zerocracy.com'
  PORT = 443
  LIVE = Judges::Baza.new(HOST, PORT, TOKEN)

  def test_live_recent_check
    WebMock.enable_net_connect!
    skip unless we_are_online
    assert(LIVE.recent('zerocracy').positive?)
  end

  def test_live_name_exists_check
    WebMock.enable_net_connect!
    skip unless we_are_online
    assert(LIVE.name_exists?('zerocracy'))
  end

  def test_live_push
    WebMock.enable_net_connect!
    skip unless we_are_online
    fb = Factbase.new
    fb.insert.foo = 'test-' * 10_000
    fb.insert
    assert(LIVE.push(fake_name, fb.export, []).positive?)
  end

  def test_live_push_no_compression
    WebMock.enable_net_connect!
    skip unless we_are_online
    fb = Factbase.new
    fb.insert.foo = 'test-' * 10_000
    fb.insert
    baza = Judges::Baza.new(HOST, PORT, TOKEN, compression: false)
    assert(baza.push(fake_name, fb.export, []).positive?)
  end

  def test_live_pull
    WebMock.enable_net_connect!
    skip unless we_are_online
    id = LIVE.recent('zerocracy')
    assert(!LIVE.pull(id).nil?)
  end

  def test_live_check_finished
    WebMock.enable_net_connect!
    skip unless we_are_online
    id = LIVE.recent('zerocracy')
    assert(!LIVE.finished?(id).nil?)
  end

  def test_live_read_stdout
    WebMock.enable_net_connect!
    skip unless we_are_online
    id = LIVE.recent('zerocracy')
    assert(!LIVE.stdout(id).nil?)
  end

  def test_live_read_exit_code
    WebMock.enable_net_connect!
    skip unless we_are_online
    id = LIVE.recent('zerocracy')
    assert(!LIVE.exit_code(id).nil?)
  end

  def test_live_lock_unlock
    WebMock.enable_net_connect!
    skip unless we_are_online
    n = fake_name
    owner = 'judges teesting'
    assert(!LIVE.lock(n, owner).nil?)
    assert(!LIVE.unlock(n, owner).nil?)
  end

  def test_simple_push
    WebMock.disable_net_connect!
    stub_request(:put, 'https://example.org/push/simple').to_return(
      status: 200, body: '42'
    )
    assert_equal(
      42,
      Judges::Baza.new('example.org', 443, '000').push('simple', 'hello, world!', [])
    )
  end

  def test_simple_recent_check
    WebMock.disable_net_connect!
    stub_request(:get, 'https://example.org/recent/simple.txt')
      .with(body: '', headers: { 'User-Agent' => /^judges .*$/ })
      .to_return(status: 200, body: '42')
    assert_equal(
      42,
      Judges::Baza.new('example.org', 443, '000').recent('simple')
    )
  end

  def test_simple_exists_check
    WebMock.disable_net_connect!
    stub_request(:get, 'https://example.org/exists/simple').to_return(
      status: 200, body: 'yes'
    )
    assert(
      Judges::Baza.new('example.org', 443, '000').name_exists?('simple')
    )
  end

  def test_exit_code_check
    WebMock.disable_net_connect!
    stub_request(:get, 'https://example.org/exit/42.txt').to_return(
      status: 200, body: '0'
    )
    assert(
      Judges::Baza.new('example.org', 443, '000').exit_code(42).zero?
    )
  end

  def test_stdout_read
    WebMock.disable_net_connect!
    stub_request(:get, 'https://example.org/stdout/42.txt').to_return(
      status: 200, body: 'hello!'
    )
    assert(
      !Judges::Baza.new('example.org', 443, '000').stdout(42).empty?
    )
  end

  def test_simple_pull
    WebMock.disable_net_connect!
    stub_request(:get, 'https://example.org/pull/333.fb').to_return(
      status: 200, body: 'hello, world!'
    )
    assert(
      Judges::Baza.new('example.org', 443, '000').pull(333).start_with?('hello')
    )
  end

  def test_real_http
    req =
      with_http_server(200, 'yes') do |baza|
        baza.name_exists?('simple')
      end
    assert_equal("judges #{Judges::VERSION}", req['user-agent'])
  end

  def test_push_with_meta
    req =
      with_http_server(200, 'yes') do |baza|
        baza.push('simple', 'hello, world!', ['boom!', 'хей!'])
      end
    assert_equal('Ym9vbSE= 0YXQtdC5IQ==', req['x-zerocracy-meta'])
  end

  def test_push_with_big_meta
    req =
      with_http_server(200, 'yes') do |baza|
        baza.push(
          'simple',
          'hello, world!',
          [
            'pages_url:https://zerocracy.github.io/zerocracy.html',
            'others:https://zerocracy.github.io/zerocracy.html',
            'duration:59595'
          ]
        )
      end
    assert(req['x-zerocracy-meta'])
  end

  def test_push_compressed_content
    skip # this test is not stable, see https://github.com/yegor256/judges/issues/105
    req =
      with_http_server(200, 'yes') do |baza|
        baza.push('simple', 'hello, world!', %w[meta1 meta2 meta3])
      end
    assert_equal('application/zip', req.content_type)
    assert_equal('gzip', req['content-encoding'])
    body = Zlib::GzipReader.zcat(StringIO.new(req.body))
    assert_equal('hello, world!', body)
  end

  def test_push_compression_disabled
    req =
      with_http_server(200, 'yes', compression: false) do |baza|
        baza.push('simple', 'hello, world!', %w[meta1 meta2 meta3])
      end
    assert_equal('application/octet-stream', req.content_type)
    assert_equal('hello, world!', req.body)
  end

  private

  def with_http_server(code, response, opts = {})
    opts = { ssl: false, timeout: 1 }.merge(opts)
    WebMock.enable_net_connect!
    req = WEBrick::HTTPRequest.new(WEBrick::Config::HTTP)
    host = '127.0.0.1'
    RandomPort::Pool::SINGLETON.acquire do |port|
      server = TCPServer.new(host, port)
      t =
        Thread.new do
          socket = server.accept
          req.parse(socket)
          req.body
          socket.puts "HTTP/1.1 #{code} OK\r\nContent-Length: #{response.length}\r\n\r\n#{response}"
          socket.close
        end
      yield Judges::Baza.new(host, port, '0000', **opts)
      t.join
    end
    req
  end

  def fake_name
    "fake-#{SecureRandom.hex(8)}"
  end

  def we_are_online
    Net::Ping::External.new('8.8.8.8').ping?
  end
end
