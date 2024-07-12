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
require 'loog'
require 'socket'
require 'random-port'
require_relative '../lib/judges'
require_relative '../lib/judges/baza'

# Test.
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2024 Yegor Bugayenko
# License:: MIT
class TestBaza < Minitest::Test
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
    WebMock.enable_net_connect!
    req = []
    host = '127.0.0.1'
    RandomPort::Pool::SINGLETON.acquire do |port|
      server = TCPServer.new(host, port)
      t = Thread.new do
        socket = server.accept
        loop do
          line = socket.gets
          break if line == "\r\n"
          req << line
        end
        socket.puts "HTTP/1.1 200 OK\r\nContent-Length: 3\r\n\r\nyes"
        socket.close
      end
      Judges::Baza.new(host, port, '0000', ssl: false, timeout: 1).name_exists?('simple')
      t.join
    end
    assert(req.include?("User-Agent: judges #{Judges::VERSION}\r\n"))
  end
end
