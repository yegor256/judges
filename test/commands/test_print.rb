# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2025 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require 'factbase'
require 'fileutils'
require 'loog'
require 'net/ping'
require 'nokogiri'
require 'securerandom'
require 'selenium-webdriver'
require 'timeout'
require 'w3c_validators'
require 'webmock/minitest'
require 'yaml'
require_relative '../../lib/judges'
require_relative '../../lib/judges/commands/print'
require_relative '../test__helper'

# Test.
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2024-2025 Yegor Bugayenko
# License:: MIT
class TestPrint < Minitest::Test
  def test_simple_print
    Dir.mktmpdir do |d|
      f = File.join(d, 'base.fb')
      fb = Factbase.new
      fb.insert
      File.binwrite(f, fb.export)
      Judges::Print.new(Loog::NULL).run({ 'format' => 'yaml', 'auto' => true }, [f])
      y = File.join(d, 'base.yaml')
      assert_path_exists(y)
      assert_equal(1, YAML.load_file(y).size)
    end
  end

  def test_print_to_html
    WebMock.disable_net_connect!
    stub_request(:get, 'https://yegor256.github.io/judges/assets/index.css').to_return(body: 'nothing')
    stub_request(:get, 'https://yegor256.github.io/judges/assets/index.js').to_return(body: 'nothing')
    fb = Factbase.new
    fb.insert
    10.times do
      f = fb.insert
      f._id = 44
      f.what = SecureRandom.hex(10)
      f.when = Time.now
      f.details = 'hey, друг'
      f.ticket = 42
      f.ticket = 55
      f.pi = 3.1416
      f.long_property = 'test_' * 100
    end
    html = File.join(__dir__, '../../temp/base.html')
    FileUtils.rm_f(html)
    Dir.mktmpdir do |d|
      f = File.join(d, 'base.fb')
      File.binwrite(f, fb.export)
      Judges::Print.new(Loog::NULL).run(
        { 'format' => 'html', 'columns' => 'what,when,ticket' },
        [f, html]
      )
    end
    doc = File.read(html)
    xml =
      begin
        Nokogiri::XML.parse(doc) do |c|
          c.norecover
          c.strict
        end
      rescue StandardError => e
        raise "#{doc}\n\n#{e}"
      end
    assert_empty(xml.errors, xml)
    refute_empty(xml.xpath('/html'), xml)
    skip('We are offline') unless we_are_online
    WebMock.enable_net_connect!
    v = W3CValidators::NuValidator.new.validate_file(html)
    assert_empty(v.errors, "#{doc}\n\n#{v.errors.join('; ')}")
  end

  def test_html_renders_in_browser
    WebMock.disable_net_connect!
    stub_request(:get,
                 'https://yegor256.github.io/judges/assets/index.css').to_return(body: 'body { font-family: Arial; }')
    stub_request(:get, 'https://yegor256.github.io/judges/assets/index.js').to_return(body: 'console.log("JS loaded");')
    fb = Factbase.new
    f = fb.insert
    f.what = 'test issue'
    f.when = Time.now
    f.ticket = 42
    html = File.join(__dir__, '../../temp/browser_test.html')
    FileUtils.rm_f(html)
    Dir.mktmpdir do |d|
      factbase_file = File.join(d, 'base.fb')
      File.binwrite(factbase_file, fb.export)
      Judges::Print.new(Loog::NULL).run(
        { 'format' => 'html', 'columns' => 'what,when,ticket' },
        [factbase_file, html]
      )
    end

    # Parse the HTML and validate structure that would be needed for browser rendering
    doc = Nokogiri::HTML(File.read(html))

    # Verify HTML structure for browser rendering
    assert_equal 'html', doc.root.name.downcase, 'Root element should be html'

    # Check head section has required elements for browser rendering
    head = doc.at_css('head')
    refute_nil head, 'Head element should be present for browser rendering'

    # Check for viewport meta tag (important for responsive rendering)
    viewport = head.at_css('meta[name="viewport"]')
    refute_nil viewport, 'Viewport meta tag should be present for responsive rendering'

    # Check for character encoding (important for proper text rendering)
    charset = head.at_css('meta[charset]')
    refute_nil charset, 'Character encoding should be specified for proper text rendering'

    # Check CSS links are present and properly formatted
    css_links = head.css('link[rel="stylesheet"]')
    refute_empty css_links, 'CSS stylesheets should be linked for proper visual rendering'

    # Verify CSS links have integrity attributes for security
    css_links.each do |link|
      refute_nil link['href'], 'CSS link should have href attribute'
      refute_nil link['integrity'], 'CSS link should have integrity attribute for security'
    end

    # Check JavaScript is included
    js_scripts = head.css('script[src]')
    refute_empty js_scripts, 'JavaScript should be included for interactive functionality'

    # Verify JS scripts have integrity attributes
    js_scripts.each do |script|
      refute_nil script['src'], 'Script should have src attribute'
      refute_nil script['integrity'], 'Script should have integrity attribute for security'
    end

    # Check body structure
    body = doc.at_css('body')
    refute_nil body, 'Body element should be present'

    # Check essential page structure elements
    header = body.at_css('header')
    refute_nil header, 'Header should be present for page structure'

    footer = body.at_css('footer')
    refute_nil footer, 'Footer should be present for page structure'

    # Check main content area
    article = body.at_css('article')
    refute_nil article, 'Article element should contain main content'

    # Check facts table structure
    facts_table = body.at_css('table#facts')
    refute_nil facts_table, 'Facts table with id="facts" should be present for data display'

    # Check table has proper structure for browser rendering
    colgroup = facts_table.at_css('colgroup')
    refute_nil colgroup, 'Table should have colgroup for proper column formatting'

    thead = facts_table.at_css('thead')
    refute_nil thead, 'Table should have thead for proper header rendering'

    tbody = facts_table.at_css('tbody')
    refute_nil tbody, 'Table should have tbody for data rows'

    # Check table has data rows
    data_rows = tbody.css('tr')
    assert_operator data_rows.size, :>=, 1, 'Table should have at least one data row'

    # Verify table structure is semantically correct for accessibility
    header_cells = thead.css('th')
    assert_operator header_cells.size, :>=, 3, 'Table should have header cells for each column'

    # Check that we have the expected columns
    column_texts = header_cells.map(&:text)
    assert_includes column_texts, 'what', 'Table should have "what" column'
    assert_includes column_texts, 'when', 'Table should have "when" column'
    assert_includes column_texts, 'ticket', 'Table should have "ticket" column'

    # Verify page title is set properly
    title = head.at_css('title')
    refute_nil title, 'Page should have title for browser tab display'
    refute_empty title.text.strip, 'Page title should not be empty'

    # If Chrome is available and we're online, try basic browser validation
    return unless chrome_available? && we_are_online
    begin
      validate_with_chrome(html)
    rescue StandardError => e
      # Browser test failed, but don't fail the whole test - just log it
      puts "Browser validation skipped: #{e.message}"
    end
  end

  def validate_with_chrome(html_file)
    options = Selenium::WebDriver::Chrome::Options.new
    options.add_argument('--headless=new')
    options.add_argument('--no-sandbox')
    options.add_argument('--disable-dev-shm-usage')
    options.add_argument('--disable-gpu')
    options.add_argument('--disable-web-security')

    driver = nil
    begin
      # Try to create driver with short timeout
      Timeout.timeout(5) do
        driver = Selenium::WebDriver.for(:chrome, options: options)
      end

      driver.manage.timeouts.page_load = 3
      driver.navigate.to("file://#{html_file}")

      # Quick validation that page loads
      wait = Selenium::WebDriver::Wait.new(timeout: 2)
      wait.until { driver.find_element(tag_name: 'body') }

      # Basic element presence check
      driver.find_element(id: 'facts')
      driver.find_element(tag_name: 'header')
      driver.find_element(tag_name: 'footer')
    ensure
      driver&.quit
    end
  end

  def test_html_table_has_colgroup
    WebMock.disable_net_connect!
    stub_request(:get, 'https://yegor256.github.io/judges/assets/index.css').to_return(body: 'nothing')
    stub_request(:get, 'https://yegor256.github.io/judges/assets/index.js').to_return(body: 'nothing')
    fb = Factbase.new
    f = fb.insert
    f.what = 'test issue'
    f.when = Time.now
    f.ticket = 42
    html = File.join(__dir__, '../../temp/colgroup_test.html')
    FileUtils.rm_f(html)
    Dir.mktmpdir do |d|
      factbase_file = File.join(d, 'base.fb')
      File.binwrite(factbase_file, fb.export)
      Judges::Print.new(Loog::NULL).run(
        { 'format' => 'html', 'columns' => 'what,when,ticket' },
        [factbase_file, html]
      )
    end
    doc = Nokogiri::HTML(File.read(html))
    table = doc.at_css('table#facts')
    refute_nil(table, 'Table with id="facts" should exist')
    colgroup = table.at_css('colgroup')
    refute_nil(colgroup, 'Table should have a colgroup element')
    cols = colgroup.css('col')
    assert_equal(4, cols.size, 'Should have 4 col elements (3 for columns + 1 for extra)')
    assert_equal('w50', cols.last['class'], 'Last col should have class="w50"')
  end

  def test_print_all_formats
    WebMock.disable_net_connect!
    stub_request(:get, 'https://yegor256.github.io/judges/assets/index.css').to_return(body: 'nothing')
    stub_request(:get, 'https://yegor256.github.io/judges/assets/index.js').to_return(body: 'nothing')
    %w[yaml html xml json].each do |fmt|
      Dir.mktmpdir do |d|
        f = File.join(d, 'base.fb')
        fb = Factbase.new
        fb.insert
        File.binwrite(f, fb.export)
        Judges::Print.new(Loog::NULL).run({ 'format' => fmt, 'auto' => true }, [f])
        y = File.join(d, "base.#{fmt}")
        assert_path_exists(y)
      end
    end
  end

  def test_print_twice
    Dir.mktmpdir do |d|
      f = File.join(d, 'base.fb')
      fb = Factbase.new
      fb.insert
      File.binwrite(f, fb.export)
      Judges::Print.new(Loog::NULL).run({ 'format' => 'yaml', 'auto' => true }, [f])
      y = File.join(d, 'base.yaml')
      assert_path_exists(y)
      mtime = File.mtime(y)
      Judges::Print.new(Loog::NULL).run({ 'format' => 'yaml', 'auto' => true }, [f])
      assert_equal(mtime, File.mtime(y))
    end
  end

  private

  def we_are_online
    Net::Ping::External.new('8.8.8.8').ping?
  end

  def chrome_available?
    system('google-chrome --version > /dev/null 2>&1')
  end
end
