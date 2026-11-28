# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require 'base64'
require 'digest'
require 'factbase'
require 'ferrum'
require 'fileutils'
require 'loog'
require 'minitest/autorun'
require 'nokogiri'
require 'stringio'
require 'tmpdir'
require 'typhoeus'
require 'uri'
require 'webmock/minitest'
require 'webrick'
require_relative '../../lib/judges/commands/print'

# The printed report with its real styles and scripts in Chromium.
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2024-2026 Yegor Bugayenko
# License:: MIT
class TestPrintBrowser < Minitest::Test
  def setup
    @dir = Dir.mktmpdir('judges-browser')
    @log = StringIO.new
    @errors = []
    @server = WEBrick::HTTPServer.new(
      BindAddress: '127.0.0.1', Port: 0, DocumentRoot: @dir,
      AccessLog: [], Logger: WEBrick::Log.new(@log)
    )
    @thread = Thread.new { @server.start }
    @browser = Ferrum::Browser.new(
      window_size: [1280, 900], timeout: 10, process_timeout: 30, logger: @log, js_errors: true,
      ignore_default_browser_options: true,
      browser_options: { 'headless' => 'new', 'no-first-run' => nil, 'no-default-browser-check' => nil }
    )
    %w[Runtime.exceptionThrown Network.loadingFailed].each do |event|
      @browser.on(event) { |details| @errors << [event, details] }
    end
    @browser.on('Log.entryAdded') do |details|
      @errors << details if details.fetch('entry').fetch('level') == 'error'
    end
    @browser.on('Runtime.consoleAPICalled') do |details|
      @errors << details if details.fetch('type') == 'error'
    end
    @browser.page.command('Log.enable')
    WebMock.allow_net_connect!
  end

  def teardown
    diagnostics unless passed?
    @browser&.quit
    @server&.shutdown
    @thread&.join
    FileUtils.remove_entry(@dir) if @dir
    WebMock.disable_net_connect!
  end

  def test_printed_report_in_chromium
    report
    @browser.go_to("http://127.0.0.1:#{@server.config[:Port]}/report.html")
    @browser.network.wait_for_idle
    assert_equal(%w[what ticket], @browser.css('#facts th.sorter').map(&:text))
    assert_equal(%w[zeta alpha], values)
    assert_equal(%w[20 3], @browser.css('#facts tbody td:nth-child(2)').map { |node| node.text.strip })
    assert(@browser.evaluate(<<~JS))
      Array.from(document.querySelectorAll('#facts th.sorter, #facts tbody td')).every(
        element => element.checkVisibility({checkOpacity: true, checkVisibilityCSS: true})
      )
    JS
    assert_equal(3, @browser.evaluate('document.styleSheets.length'))
    assert(@browser.evaluate('Array.from(document.styleSheets).every(sheet => sheet.cssRules.length > 0)'))
    assert_equal('pointer', @browser.at_css('#facts th.sorter').evaluate('getComputedStyle(this).cursor'))
    assert_match(/\ACurrent time: \d{4}-\d{2}-\d{2}T/, @browser.at_css('#current-time').text)
    @browser.at_css('#facts th:nth-child(2)').click
    await { values == %w[alpha zeta] }
    assert_equal(%w[alpha zeta], values)
    @browser.at_css('#facts th:nth-child(2)').click
    await { values == %w[zeta alpha] }
    assert_equal(%w[zeta alpha], values)
    assert_empty(@errors)
    assert_empty(@browser.network.traffic.reject { |exchange| exchange.response&.status == 200 })
  end

  private

  def values
    @browser.css('#facts tbody td:first-child').map { |node| node.text.strip }
  end

  def await
    deadline = Process.clock_gettime(Process::CLOCK_MONOTONIC) + 10
    until yield
      flunk('Timed out waiting for the printed report') if Process.clock_gettime(Process::CLOCK_MONOTONIC) >= deadline
      sleep(0.05)
    end
  end

  def report
    fb = Factbase.new
    [['zeta', 20], ['alpha', 3]].each do |what, ticket|
      fact = fb.insert
      fact.what = what
      fact.ticket = ticket
    end
    input = File.join(@dir, 'report.fb')
    output = File.join(@dir, 'report.html')
    File.binwrite(input, fb.export)
    %w[index.css index.js].each do |name|
      stub_request(:get, "https://yegor256.github.io/judges/assets/#{name}").to_return(
        body: File.binread(File.join(__dir__, '../../assets', name))
      )
    end
    Judges::Print.new(Loog::NULL).run({ 'format' => 'html', 'columns' => 'what,ticket' }, [input, output])
    doc = Nokogiri::HTML(File.binread(output))
    doc.css('script[src], link[rel="stylesheet"], link[rel="icon"], img[src]').each do |node|
      localize(node)
    end
    File.write(output, doc.to_html)
  end

  def localize(node)
    attribute = node.name == 'link' ? 'href' : 'src'
    url = node[attribute]
    response = Typhoeus.get(url, timeout: 30, connecttimeout: 10)
    assert_equal(200, response.code, "Cannot download #{url}")
    if node.name == 'script' || node['rel'] == 'stylesheet'
      refute_nil(node['integrity'], "Missing integrity for #{url}")
      algorithm, expected = node['integrity'].split('-', 2)
      assert_equal(expected, Base64.strict_encode64(Digest.const_get(algorithm.upcase).digest(response.body)), url)
    end
    path = "/#{Digest::SHA256.hexdigest(url)}#{File.extname(URI(url).path)}"
    File.binwrite(File.join(@dir, path.delete_prefix('/')), response.body)
    node[attribute] = path
  end

  def diagnostics
    dir = File.expand_path('../../temp/browser', __dir__)
    FileUtils.mkdir_p(dir)
    File.write(
      File.join(dir, 'browser.log'),
      [
        @log&.string,
        @errors.inspect,
        Array(@browser&.network&.traffic).map { |exchange| [exchange.request.url, exchange.response&.status] }.inspect,
        failures.map(&:message).join("\n")
      ].join("\n")
    )
    @browser&.screenshot(path: File.join(dir, 'report.png'), full: true)
  rescue Ferrum::Error => e
    File.write(File.join(dir, 'screenshot-error.txt'), e.full_message)
  end
end
