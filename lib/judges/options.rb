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

require 'others'
require_relative '../judges'

# Options for Ruby scripts in the judges.
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2024 Yegor Bugayenko
# License:: MIT
class Judges::Options
  # Ctor.
  # @param [Array<String>] pairs List of pairs, like ["token=af73cd3", "max_speed=1"]
  def initialize(pairs = nil)
    @pairs = pairs
  end

  def empty?
    touch # this will trigger method_missing() method, which will create @hash
    @hash.empty?
  end

  def +(other)
    touch # this will trigger method_missing() method, which will create @hash
    h = @hash.dup
    other.touch # this will trigger method_missing() method, which will create @hash
    other.instance_variable_get(:@hash).each do |k, v|
      h[k] = v
    end
    Judges::Options.new(h.map { |k, v| "#{k}=#{v}" })
  end

  # Convert them all to a string (printable in a log).
  def to_s
    touch # this will trigger method_missing() method, which will create @hash
    @hash.map do |k, v|
      v = v.to_s
      v = "#{v[0..3]}#{'*' * (v.length - 4)}" if v.length > 8
      "#{k} → \"#{v}\""
    end.join("\n")
  end

  # Get option by name.
  others do |*args|
    @hash ||= begin
      pp = @pairs || []
      pp = @pairs.map { |k, v| "#{k}=#{v}" } if pp.is_a?(Hash)
      pp = pp.split(',') if pp.is_a?(String)
      pp.compact!
      pp.reject!(&:empty?)
      pp.map! do |pair|
        p = pair.split('=', 2)
        k = p[0].strip.downcase
        v = p[1]
        v = v.nil? ? 'true' : v.strip
        [k.to_sym, v.match?(/^[0-9]+$/) ? v.to_i : v]
      end
      pp.reject { |p| p[0].empty? }.to_h
    end
    k = args[0].downcase
    @hash[k]
  end
end
