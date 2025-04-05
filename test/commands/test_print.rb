# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2025 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require 'factbase'
require 'fileutils'
require 'loog'
require 'net/ping'
require 'nokogiri'
require 'securerandom'
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
end
