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

require 'time'
require_relative '../../judges'
require_relative '../../judges/impex'
require_relative '../../judges/to_rel'

# Import.
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2024 Yegor Bugayenko
# License:: MIT
class Judges::Import
  def initialize(loog)
    @loog = loog
  end

  def run(_opts, args)
    raise 'Exactly two arguments required' unless args.size == 2
    raise "File not found #{args[0].to_rel}" unless File.exist?(args[0])
    start = Time.now
    yaml = YAML.load_file(args[0], permitted_classes: [Time])
    impex = Judges::Impex.new(@loog, args[1])
    fb = impex.import(strict: false)
    fb = Factbase::Looged.new(fb, @loog)
    yaml.each do |i|
      f = fb.insert
      i.each do |p, v|
        f.send("#{p}=", v)
      end
    end
    impex.export(fb)
    @loog.info("Import finished in #{format('%.02f', Time.now - start)}s")
  end
end
