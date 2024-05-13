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

require 'factbase'
require 'fileutils'
require_relative '../../judges'
require_relative '../../judges/packs'
require_relative '../../judges/options'

# Join.
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2024 Yegor Bugayenko
# License:: MIT
class Judges::Join
  def initialize(loog)
    @loog = loog
  end

  def run(_opts, args)
    raise 'Exactly two arguments required' unless args.size == 2
    master = args[0]
    raise "The master factbase is absent: #{master}" unless File.exist?(master)
    slave = args[1]
    raise "The slave factbase is absent: #{slave}" unless File.exist?(slave)
    fb = Factbase.new
    fb.import(File.read(master))
    @loog.info("Master factbase imported from #{master} (#{File.size(master)} bytes)")
    fb.import(File.read(slave))
    @loog.info("Slave factbase imported from #{slave} (#{File.size(slave)} bytes)")
    File.write(master, fb.export)
    @loog.info("Master factbase exported to #{master} (#{File.size(master)} bytes)")
  end
end
