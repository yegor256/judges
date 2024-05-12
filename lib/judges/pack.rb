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

require 'yaml'
require_relative '../judges'
require_relative '../judges/fb/once'

# A single pack.
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2024 Yegor Bugayenko
# License:: MIT
class Judges::Pack
  attr_reader :dir

  def initialize(dir)
    @dir = dir
  end

  # Run it with the given Factbase and environment variables.
  def run(fbase, env)
    $fb = fbase
    $judge = File.basename(File.dirname(@dir))
    env.each do |k, v|
      # rubocop:disable Security/Eval
      eval("$#{k} = '#{v}'", binding, __FILE__, __LINE__) # $foo = 42
      # rubocop:enable Security/Eval
    end
    s = File.join(@dir, script)
    raise "Can't load '#{s}'" unless File.exist?(s)
    load s
  end

  # Get the name of the .rb script in the pack.
  def script
    File.basename(Dir.glob(File.join(@dir, '*.rb')).first)
  end

  # Iterate over .yml tests.
  def tests
    Dir.glob(File.join(@dir, '*.yml')).map do |f|
      YAML.load_file(f)
    end
  end
end
