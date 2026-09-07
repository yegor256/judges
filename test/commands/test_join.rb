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

  def test_renumbers_the_facts_it_takes_in
    Dir.mktmpdir do |d|
      files =
        %w[master slave].map do |name|
          file = File.join(d, "#{name}.fb")
          fb = Factbase.new
          (1..3).each do |i|
            f = fb.insert
            f._id = i
            f.tag = name
          end
          File.binwrite(file, fb.export)
          file
        end
      Judges::Join.new(Loog::NULL).run({}, files)
      fb = Factbase.new
      fb.import(File.binread(files[0]))
      facts = fb.query('(always)').each.to_a
      assert_equal(6, facts.size)
      ids = facts.map { |f| f['_id'].first }
      assert_equal(ids.uniq, ids, "every _id must appear once, got #{ids.inspect}")
      assert_equal([1, 2, 3, 4, 5, 6], ids.sort)
      assert_equal(3, facts.count { |f| f.tag == 'slave' })
    end
  end

  def test_keeps_a_fact_that_has_no_id
    Dir.mktmpdir do |d|
      master = File.join(d, 'master.fb')
      one = Factbase.new
      one.insert.then do |f|
        f._id = 1
        f.zz = 5
      end
      File.binwrite(master, one.export)
      slave = File.join(d, 'slave.fb')
      two = Factbase.new
      two.insert.foo = 42
      File.binwrite(slave, two.export)
      Judges::Join.new(Loog::NULL).run({}, [master, slave])
      fb = Factbase.new
      fb.import(File.binread(master))
      copied = fb.query('(eq foo 42)').each.to_a.first
      refute_nil(copied)
      assert_nil(copied['_id'], 'a fact with no _id must not be given one')
    end
  end
end
