# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require 'factbase/to_xml'
require 'loog'
require 'nokogiri'
require_relative '../../lib/judges'
require_relative '../../lib/judges/commands/join'
require_relative '../test__helper'

# Test.
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2024-2026 Yegor Bugayenko
# License:: MIT
class TestJoin < Minitest::Test
  def test_simple_join
    Dir.mktmpdir do |d|
      master = File.join(d, 'master.fb')
      one = Factbase.new
      one.insert.zz = 5
      File.binwrite(master, one.export)
      slave = File.join(d, 'slave.fb')
      two = Factbase.new
      two.insert.foo_bar = 42
      File.binwrite(slave, two.export)
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
