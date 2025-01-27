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

require_relative '../judges'

# Categories of tests.
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2024-2025 Yegor Bugayenko
# License:: MIT
class Judges::Categories
  # Ctor.
  # @param [Array<String>] enable List of categories to enable
  # @param [Array<String>] disable List of categories to enable
  def initialize(enable, disable)
    @enable = enable.is_a?(Array) ? enable : []
    @disable = disable.is_a?(Array) ? disable : []
  end

  # This test is good to go, with this list of categories?
  # @param [Array<String>] cats List of them
  # @return [Boolean] True if yes
  def ok?(cats)
    cats = [] if cats.nil?
    cats = [cats] unless cats.is_a?(Array)
    cats.each do |c|
      return false if @disable.any?(c)
      return true if @enable.any?(c)
    end
    return true if @enable.empty?
    false
  end
end
