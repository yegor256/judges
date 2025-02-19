# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2025 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require 'minitest/autorun'
require 'loog'
require 'nokogiri'
require 'factbase/to_xml'
require_relative '../../lib/judges'
require_relative '../../lib/judges/commands/join'

# Test.
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2024-2025 Yegor Bugayenko
# License:: MIT
class TestJoin < Minitest::Test
  def test_simple_join
    Dir.mktmpdir do |d|
      master = File.join(d, 'master.fb')
      fb1 = Factbase.new
      fb1.insert.zz = 5
      File.binwrite(master, fb1.export)
      slave = File.join(d, 'slave.fb')
      fb2 = Factbase.new
      fb2.insert.foo_bar = 42
      File.binwrite(slave, fb2.export)
      loog = Loog::Buffer.new
      Judges::Join.new(loog).run({}, [master, slave])
      fb = Factbase.new
      fb.import(File.binread(master))
      xml = Nokogiri::XML.parse(Factbase::ToXML.new(fb).xml)
      refute_empty(xml.xpath('/fb/f[zz="5"]'), xml)
      refute_empty(xml.xpath('/fb/f[foo_bar="42"]'), xml)
      assert_includes(loog.to_s, 'Two factbases joined', loog.to_s)
    end
  end
end
