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

require 'others'
require_relative '../judges'

# Options for Ruby scripts in the judges.
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2024-2025 Yegor Bugayenko
# License:: MIT
class Judges::Options
  # Ctor.
  # @param [Array<String>] pairs List of pairs, like ["token=af73cd3", "max_speed=1"]
  def initialize(pairs = nil)
    @pairs = pairs
  end

  def empty?
    to_h.empty?
  end

  def +(other)
    h = to_h
    other.to_h.each do |k, v|
      h[k] = v
    end
    Judges::Options.new(h)
  end

  # Convert them all to a string (printable in a log).
  def to_s
    to_h.map do |k, v|
      v = v.to_s
      v = "#{v[0..3]}#{'*' * (v.length - 8)}#{v[-4..]}" if v.length > 8
      "#{k} → \"#{v}\""
    end.sort.join("\n")
  end

  def to_h
    @to_h ||=
      begin
        pp = @pairs || []
        pp = pp.split(',') if pp.is_a?(String)
        if pp.is_a?(Array)
          pp = pp
            .compact
            .map(&:strip)
            .reject(&:empty?)
            .map { |s| s.split('=', 2) }
            .map { |a| a.size == 1 ? [a[0], nil] : a }
            .reject { |a| a[0].empty? }
            .to_h
        end
        pp
          .reject { |k, _| k.nil? }
          .reject { |k, _| k.is_a?(String) && k.empty? }
          .to_h
          .transform_values { |v| v.nil? ? 'true' : v }
          .transform_values { |v| v.is_a?(String) ? v.strip : v }
          .transform_values { |v| v.is_a?(String) && v.match?(/^[0-9]+$/) ? v.to_i : v }
          .transform_keys { |k| k.to_s.strip.upcase.to_sym }
      end
  end

  # Get option by name.
  others do |*args|
    to_h[args[0].upcase.to_sym]
  end
end
