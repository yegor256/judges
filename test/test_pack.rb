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
require 'tmpdir'
require 'factbase'
require_relative '../lib/judges'
require_relative '../lib/judges/pack'

# Test.
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2024 Yegor Bugayenko
# License:: MIT
class TestPack < Minitest::Test
  def test_basic_run
    Dir.mktmpdir do |d|
      File.write(File.join(d, 'foo.rb'), '$fb.insert')
      pack = Judges::Pack.new(d)
      fb = Factbase.new
      pack.run(fb, {})
      assert_equal(1, fb.size)
    end
  end

  def test_run_isolated
    Dir.mktmpdir do |d|
      File.write(File.join(d, 'bar.rb'), '$fb.insert')
      pack = Judges::Pack.new(d)
      fb1 = Factbase.new
      pack.run(fb1, {})
      assert_equal(1, fb1.size)
      fb2 = Factbase.new
      pack.run(fb2, {})
      assert_equal(1, fb2.size)
    end
  end

  def test_with_supplemenary_functions
    Dir.mktmpdir do |d|
      File.write(File.join(d, 'x.rb'), 'once($fb).insert')
      pack = Judges::Pack.new(d)
      pack.run(Factbase.new, {})
    end
  end
end
