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
require 'fileutils'
require 'factbase'
require 'nokogiri'
require_relative '../../judges'
require_relative '../../judges/impex'
require_relative '../../judges/elapsed'

# The +print+ command.
#
# This class is instantiated by the +bin/judge+ command line interface. You
# are not supposed to instantiate it yourself.
#
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2024 Yegor Bugayenko
# License:: MIT
class Judges::Print
  def initialize(loog)
    @loog = loog
  end

  # Run it (it is supposed to be called by the +bin/judges+ script.
  # @param [Hash] opts Command line options (start with '--')
  # @param [Array] args List of command line arguments
  def run(opts, args)
    raise 'At lease one argument required' if args.empty?
    f = args[0]
    fb = Judges::Impex.new(@loog, f).import
    fb.query("(not #{opts['query']})").delete! unless opts['query'].nil?
    o = args[1]
    fmt = opts['format']&.downcase
    if o.nil?
      raise 'Either provide output file name or use --auto' unless opts['auto']
      o = File.join(File.dirname(f), File.basename(f).gsub(/\.[^.]*$/, ''))
      o = "#{o}.#{fmt}"
    end
    FileUtils.mkdir_p(File.dirname(o))
    if !opts['force'] && File.exist?(o)
      if File.mtime(f) <= File.mtime(o)
        @loog.info("No need to print to #{o.to_rel}, since it's up to date (#{File.size(o)} bytes)")
        return
      end
      @loog.debug("The factbase #{f.to_rel} is younger than the target #{o.to_rel}, need to print")
    end
    elapsed(@loog) do
      output =
        case fmt
          when 'yaml'
            require 'factbase/to_yaml'
            Factbase::ToYAML.new(fb).yaml
          when 'json'
            require 'factbase/to_json'
            Factbase::ToJSON.new(fb).json
          when 'xml'
            require 'factbase/to_xml'
            Factbase::ToXML.new(fb).xml
          when 'html'
            to_html(opts, fb)
          else
            raise "Unknown format '#{fmt}'"
        end
      File.binwrite(o, output)
      throw :"Factbase printed to #{o.to_rel} (#{File.size(o)} bytes)"
    end
  end

  private

  def to_html(opts, fb)
    xslt = Nokogiri::XSLT(File.read(File.join(__dir__, '../../../assets/index.xsl')))
    require 'factbase/to_xml'
    xml = Factbase::ToXML.new(fb).xml
    xslt.transform(
      Nokogiri::XML(xml),
      Nokogiri::XSLT.quote_params(
        'title' => opts['title'],
        'date' => Time.now.utc.iso8601,
        'columns' => opts['columns'] || 'when,what,who',
        'hidden' => opts['hidden'] || '_id,_version,_time,_job',
        'version' => Judges::VERSION
      )
    )
  end
end
