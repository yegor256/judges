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
require_relative '../judges/to_rel'
require_relative '../judges/elapsed'
require_relative '../judges/fb/once'
require_relative '../judges/fb/if_absent'

# A single pack.
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2024 Yegor Bugayenko
# License:: MIT
class Judges::Pack
  attr_reader :dir

  def initialize(dir, lib, loog)
    @dir = dir
    @lib = lib
    @loog = loog
  end

  # Run it with the given Factbase and environment variables.
  def run(fbase, global, local, options)
    $fb = fbase
    $judge = File.basename(@dir)
    $options = options
    $loog = @loog
    $global = global
    $local = local
    unless @lib.nil?
      raise "Lib dir #{@lib.to_rel} is absent" unless File.exist?(@lib)
      raise "Lib #{@lib.to_rel} is not a directory" unless File.directory?(@lib)
      Dir.glob(File.join(@lib, '*.rb')).each do |f|
        require_relative(File.absolute_path(f))
      end
    end
    s = File.join(@dir, script)
    raise "Can't load '#{s}'" unless File.exist?(s)
    elapsed(@loog) do
      load(s, true)
      throw :"#{name} finished"
    ensure
      $fb = $judge = $options = $loog = nil
    end
  end

  # Get the name of the pack.
  def name
    File.basename(@dir)
  end

  # Get the name of the .rb script in the pack.
  def script
    s = Dir.glob(File.join(@dir, '*.rb')).first
    raise "No *.rb scripts in #{@dir.to_rel}" if s.nil?
    File.basename(s)
  end

  # Return all .yml tests files.
  def tests
    Dir.glob(File.join(@dir, '*.yml'))
  end
end
