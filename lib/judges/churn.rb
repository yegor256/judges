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

require_relative '../judges'

# How many facts were modified.
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2024 Yegor Bugayenko
# License:: MIT
class Judges::Churn
  attr_reader :added, :removed, :errors

  def initialize(added, removed, errors = [])
    @added = added
    @removed = removed
    @errors = errors
  end

  def to_s
    "#{@added}/#{@removed}#{@errors.empty? ? '' : "/#{@errors.size}"}"
  end

  def zero?
    @added.zero? && @removed.zero? && @errors.empty?
  end

  def <<(error)
    @errors << error
    nil
  end

  def +(other)
    if other.is_a?(Judges::Churn)
      Judges::Churn.new(@added + other.added, @removed + other.removed, @errors + other.errors)
    else
      Judges::Churn.new(@added + other, @removed, @errors)
    end
  end

  def -(other)
    if other.is_a?(Judges::Churn)
      Judges::Churn.new(@added - other.added, @removed - other.removed, @errors + other.errors)
    else
      Judges::Churn.new(@added, @removed + other, @errors)
    end
  end
end
