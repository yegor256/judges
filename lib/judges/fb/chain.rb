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

require_relative 'once'

# Chains queries.
def chain(fb, *queries, judge: $judge, &)
  unless block_given?
    facts = []
    chain_rec(fb, queries, judge) do |f|
      facts << f
    end
    return facts
  end
  chain_rec(fb, queries, judge, &)
end

def chain_rec(fb, queries, judge, facts = [], &block)
  q = queries.shift
  qt = q.gsub(/\{f([0-9]+).([a-z0-9_]+)\}/) do
    facts[Regexp.last_match[1].to_i].send(Regexp.last_match[2])
  end
  once(fb, judge:).query(qt).each do |f|
    if queries.empty?
      yield f
    else
      chain_rec(fb, queries, judge, facts + [f], &block)
    end
  end
end
