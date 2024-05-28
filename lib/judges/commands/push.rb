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

require 'typhoeus'
require 'iri'
require_relative '../../judges'
require_relative '../../judges/impex'

# Push.
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2024 Yegor Bugayenko
# License:: MIT
class Judges::Push
  def initialize(loog)
    @loog = loog
  end

  def run(opts, args)
    raise 'Exactly two arguments required' unless args.size == 2
    name = args[0]
    fb = Judges::Impex.new(@loog, args[1]).import
    ret = Typhoeus::Request.put(
      Iri.new('')
        .host(opts['host'])
        .port(opts['port'].to_i)
        .scheme(opts['ssl'] ? 'https' : 'http')
        .append('push')
        .to_s,
      body: fb.export,
      headers: {
        'Content-Type': 'text/plain',
        'User-Agent': "judges #{Judges::VERSION}",
        'Connection': 'close',
      },
      connecttimeout: (opts['timeout'] || 5).to_i,
      timeout: (opts['timeout'] || 5).to_i
    )
    raise "Failed to push, HTTP response code is #{ret.code}" unless ret.code == 200
    @loog.info("Pushed #{fb.size} facts")
  end
end
