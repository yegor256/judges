# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2025 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require 'base64'
require 'elapsed'
require 'factbase'
require 'fileutils'
require 'nokogiri'
require 'retries'
require 'time'
require 'typhoeus'
require_relative '../../judges'
require_relative '../../judges/impex'

# The +print+ command.
#
# This class is instantiated by the +bin/judge+ command line interface. You
# are not supposed to instantiate it yourself.
#
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2024-2025 Yegor Bugayenko
# License:: MIT
class Judges::Print
  # Initialize.
  # @param [Loog] loog Logging facility
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
    elapsed(@loog, level: Logger::INFO) do
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
    xslt.apply_to(
      Nokogiri::XML(xml),
      Nokogiri::XSLT.quote_params(
        'title' => opts['title'],
        'date' => Time.now.utc.iso8601,
        'columns' => opts['columns'] || 'when,what,who',
        'hidden' => opts['hidden'] || '_id,_version,_time,_job',
        'version' => Judges::VERSION,
        'css_hash' => sha384('index.css'),
        'js_hash' => sha384('index.js')
      )
    )
  end

  def sha384(asset)
    with_retries do
      url = "https://yegor256.github.io/judges/assets/#{asset}"
      http = Typhoeus::Request.get(url)
      return "Timeout at #{url.inspect}" if http.timed_out?
      raise "Failed to load #{url.inspect}" unless http.code == 200
      sha = Base64.strict_encode64(Digest::SHA256.digest(http.body))
      "sha256-#{sha}"
    rescue RuntimeError => e
      e.message
    end
  end
end
