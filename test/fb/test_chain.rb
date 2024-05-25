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
require 'factbase'
require 'factbase/to_xml'
require_relative '../../lib/judges'
require_relative '../../lib/judges/fb/chain'

# Test.
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2024 Yegor Bugayenko
# License:: MIT
class TestChain < Minitest::Test
  def test_simple_use
    fb = Factbase.new
    f1 = fb.insert
    f1.foo = 42
    f1.v = 7
    f2 = fb.insert
    f2.bar = 7
    assert_equal(1, chain(fb, '(eq foo 42)', '(eq bar {f0.v})', judge: 'foo').to_a.size)
  end

  def test_seen_property
    fb = Factbase.new
    f1 = fb.insert
    f1.foo = 42
    assert_equal(1, chain(fb, '(eq foo 42)', judge: 'x').to_a.size)
    assert(chain(fb, '(eq foo 42)', judge: 'x').to_a.empty?)
  end

  def test_passes_facts
    fb = Factbase.new
    f1 = fb.insert
    f1.foo = 42
    f2 = fb.insert
    f2.bar = 55
    chain(fb, '(exists foo)', '(exists bar)', judge: 'x').each do |fs|
      assert_equal(42, fs[0].foo)
      assert_equal(55, fs[1].bar)
    end
  end

  def test_with_modifications
    fb = Factbase.new
    f1 = fb.insert
    f1.foo = 42
    chain(fb, '(exists foo)', judge: 'xx').each do |fs|
      fs[0].bar = 1
    end
    assert_equal(1, fb.query('(exists bar)').each.to_a.size)
  end

  def test_with_txn
    fb = Factbase.new
    f1 = fb.insert
    f1.foo = 42
    chain(fb, '(exists foo)', judge: 'xx').each do |fs|
      fb.txn do |fbt|
        f = fbt.insert
        f.bar = 1
      end
      fs[0].xyz = 'hey'
    end
    assert_equal(1, fb.query('(exists seen)').each.to_a.size)
    assert_equal(1, fb.query('(exists bar)').each.to_a.size)
    assert_equal(1, fb.query('(exists xyz)').each.to_a.size)
  end
end
