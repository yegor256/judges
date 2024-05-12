#!/usr/bin/env ruby

# Copyright (c) 2014-2024 Yegor Bugayenko
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

# Update.
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2024 Yegor Bugayenko
# License:: MIT
class Judges::Update
  def initialize(loog)
    @loog = loog
  end

  def run(opts, args)
    raise 'Exactly two arguments required' unless args.size ==2
    dir = args[0]
    file = args[1]
    $fb = Factbase.new
    if File.exist?(file)
      $fb.import(File.read(file))
      @loog.info("Factbase imported from #{file} (#{File.size(file)})")
    else
      @loog.info("There is no Factbase to import from #{file}")
    end
    scripts = Dir.glob(File.join(dir, "**/*.rb")).to_a
    @loog.info("#{scripts.size} .rb scripts found in #{dir}")
    scripts.each do |f|
      next unless base(f).start_with?('_')
      require f
    end
    done = 0
    scripts.each do |f|
      b = base(f)
      next if b.start_with?('_')
      $judge = b
      require f
      done += 1
    end
    @loog.info("#{done} judges processed")
    File.write(file, $fb.export)
    @loog.info("Factbase exported to #{file} (#{File.size(file)})")
  end

  private

  def base(file)
    File::basename(file).gsub(/\.rb$/, '')
  end
end
