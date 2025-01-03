# frozen_string_literal: true

# Copyright (c) 2024-2025 Yegor Bugayenko
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
require 'factbase'
require_relative '../../lib/judges'
require_relative '../../lib/judges/commands/pull'

# Test.
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2024-2025 Yegor Bugayenko
# License:: MIT
class TestPull < Minitest::Test
  def test_pull_simple_factbase
    WebMock.disable_net_connect!
    stub_request(:get, 'http://example.org/lock/foo?owner=none').to_return(status: 302)
    stub_request(:get, 'http://example.org/exists/foo').to_return(body: 'yes')
    stub_request(:get, 'http://example.org/recent/foo.txt').to_return(body: '42')
    stub_request(:get, 'http://example.org/finished/42').to_return(body: 'yes')
    stub_request(:get, 'http://example.org/exit/42.txt').to_return(body: '0')
    stub_request(:get, 'http://example.org/unlock/foo?owner=none').to_return(status: 302)
    fb = Factbase.new
    fb.insert.foo = 42
    stub_request(:get, 'http://example.org/pull/42.fb').to_return(body: fb.export)
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

  def test_fail_pull_when_job_is_broken
    WebMock.disable_net_connect!
    stub_request(:get, 'http://example.org/lock/foo?owner=none').to_return(status: 302)
    stub_request(:get, 'http://example.org/exists/foo').to_return(body: 'yes')
    stub_request(:get, 'http://example.org/recent/foo.txt').to_return(body: '42')
    stub_request(:get, 'http://example.org/finished/42').to_return(body: 'yes')
    stub_request(:get, 'http://example.org/exit/42.txt').to_return(body: '1')
    stub_request(:get, 'http://example.org/stdout/42.txt').to_return(body: 'oops, some trouble here')
    stub_request(:get, 'http://example.org/unlock/foo?owner=none').to_return(status: 302)
    Dir.mktmpdir do |d|
      file = File.join(d, 'base.fb')
      e =
        assert_raises do
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
      assert(e.message.include?('expire it'), e)
    end
  end
end
