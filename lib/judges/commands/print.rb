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

require 'fileutils'
require 'factbase'
require_relative '../../judges'
require_relative '../../judges/packs'

# Update.
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2024 Yegor Bugayenko
# License:: MIT
class Judges::Print
  def initialize(loog)
    @loog = loog
  end

  def run(opts, args)
    raise 'At lease one argument required' if args.empty?
    f = args[0]
    raise "The file is absent: #{f}" unless File.exist?(f)
    o = args[1]
    if o.nil?
      raise 'Either provide output file name or use --auto' unless opts[:auto]
      o = File.join(File.dirname(f), File.basename(f).gsub(/\.[^.]*$/, ''))
      o = "#{o}.#{opts[:format]}"
    end
    fb = Factbase.new
    fb.import(File.read(f))
    @loog.info("Factbase imported from #{f} (#{File.size(f)} bytes)")
    FileUtils.mkdir_p(File.dirname(o))
    output =
      case opts[:format].downcase
        when 'yaml'
          fb.to_yaml
        when 'json'
          fb.to_json
        when 'xml'
          fb.to_xml
      end
    File.write(o, output)
    @loog.info("Factbase printed to #{o} (#{File.size(o)} bytes)")
  end
end
