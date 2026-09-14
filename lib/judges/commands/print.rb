# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require 'base64'
require 'digest'
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
# This class is instantiated by the +bin/judges+ command line interface. You
# are not supposed to instantiate it yourself.
#
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2024-2026 Yegor Bugayenko
# License:: MIT
class Judges::Print
  FORMATS = %w[yaml json xml html].freeze
  OUTPUT_OPTIONS = %w[format query title columns hidden highlighted offline].freeze

  # Initialize.
  # @param [Loog] loog Logging facility
  def initialize(loog)
    @loog = loog
  end

  # Run the print command (called by the +bin/judges+ script).
  # @param [Hash] opts Command line options (start with '--')
  # @param [Array] args List of command line arguments
  # @raise [RuntimeError] If no arguments provided
  def run(opts, args)
    raise(ArgumentError, 'At least one argument required') if args.empty?
    fmt = opts['format']&.downcase
    raise(ArgumentError, "Unknown format '#{fmt}', use one of #{FORMATS.join(', ')}") unless FORMATS.include?(fmt)
    f = args[0]
    fb = Judges::Impex.new(@loog, f).import
    fb.query("(not #{opts['query']})").delete! unless opts['query'].nil?
    o = args[1]
    if o.nil?
      raise(ArgumentError, 'Either provide output file name or use --auto') unless opts['auto']
      o = File.join(File.dirname(f), File.basename(f).gsub(/\.[^.]*$/, ''))
      o = "#{o}.#{fmt}"
    end
    FileUtils.mkdir_p(File.dirname(o))
    stamp = stamp(opts, fmt)
    sidecar = "#{o}.judges-options"
    return if skip?(opts, f, o, sidecar, stamp)
    elapsed(@loog, level: Logger::INFO) { write(o, sidecar, stamp, fmt, opts, fb) }
  end

  private

  def write(output, sidecar, stamp, fmt, opts, fb)
    File.binwrite(output, render(fmt, opts, fb))
    File.binwrite(sidecar, stamp)
    throw(:"👍 Factbase printed to #{output.to_rel} (#{File.size(output)} bytes)")
  end

  def render(fmt, opts, fb)
    case fmt
      when 'yaml'
        require('factbase/to_yaml')
        Factbase::ToYAML.new(fb).yaml
      when 'json'
        require('factbase/to_json')
        Factbase::ToJSON.new(fb).json
      when 'xml'
        require('factbase/to_xml')
        Factbase::ToXML.new(fb).xml
      else
        to_html(opts, fb)
    end
  end

  def skip?(opts, factbase, output, sidecar, stamp)
    return false if opts['force'] || !cached?(output, sidecar, stamp)
    if File.mtime(factbase) <= File.mtime(output)
      @loog.info("No need to print to #{output.to_rel}, since it's up to date (#{File.size(output)} bytes)")
      return true
    end
    @loog.debug("The factbase #{factbase.to_rel} is younger than the target #{output.to_rel}, need to print")
    false
  end

  def stamp(opts, fmt)
    Digest::SHA256.hexdigest(
      OUTPUT_OPTIONS.map { |key| "#{key}=#{key == 'format' ? fmt : opts[key].inspect}" }.join("\n")
    )
  end

  def cached?(output, sidecar, stamp)
    File.exist?(output) && File.exist?(sidecar) && File.binread(sidecar) == stamp
  end

  def to_html(opts, fb)
    require('factbase/to_xml')
    Nokogiri::XSLT(File.read(File.join(__dir__, '../../../assets/index.xsl'))).apply_to(
      Nokogiri::XML(Factbase::ToXML.new(fb).xml),
      Nokogiri::XSLT.quote_params(
        'title' => opts['title'],
        'date' => Time.now.utc.iso8601,
        'columns' => opts['columns'] || 'when,what,who',
        'hidden' => opts['hidden'] || '_id,_version,_time,_job',
        'highlighted' => opts['highlighted'] || 'stale,tombstone',
        'version' => Judges::VERSION,
        'css_hash' => sha256(opts, 'index.css'),
        'js_hash' => sha256(opts, 'index.js')
      )
    )
  end

  def sha256(opts, asset)
    return 'sha256-offline' if opts['offline']
    with_retries do
      url = "https://yegor256.github.io/judges/assets/#{asset}"
      http = Typhoeus::Request.get(url)
      raise(StandardError, "Timeout at #{url.inspect}") if http.timed_out?
      raise(StandardError, "Failed to load #{url.inspect}") unless http.code == 200
      "sha256-#{Base64.strict_encode64(Digest::SHA256.digest(http.body))}"
    rescue StandardError => e
      @loog.warn("Failed to fetch #{asset.inspect}, the page will load it without integrity check: #{e.message}")
      ''
    end
  end
end
