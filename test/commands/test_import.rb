# frozen_string_literal: true

require 'factbase/to_xml'
# SPDX-FileCopyrightText: Copyright (c) 2024-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require 'loog'
require 'nokogiri'
require_relative '../../lib/judges'
require_relative '../../lib/judges/commands/import'
require_relative '../test__helper'

# Test.
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2024-2026 Yegor Bugayenko
# License:: MIT
class TestImport < Minitest::Test
  def test_import_from_yaml
    Dir.mktmpdir do |d|
      file = File.join(d, 'base.fb')
      yaml = File.join(d, 'input.yml')
      save_it(
        yaml,
        <<-YAML
        -
          foo: 42
          bar: 2024-03-04T22:22:22Z
          t: Hello, world!
        -
          z: 3.14
        YAML
      )
      Judges::Import.new(Loog::NULL).run({}, [yaml, file])
      fb = Factbase.new
      fb.import(File.binread(file))
      xml = Nokogiri::XML.parse(Factbase::ToXML.new(fb).xml)
      refute_empty(xml.xpath('/fb[count(f)=2]'), xml)
    end
  end

  def test_refuses_an_empty_file
    Dir.mktmpdir do |d|
      yaml = File.join(d, 'input.yml')
      File.write(yaml, '')
      e =
        assert_raises(StandardError) do
          Judges::Import.new(Loog::NULL).run({}, [yaml, File.join(d, 'base.fb')])
        end
      assert_includes(e.message, 'is empty, nothing to import', e.message)
    end
  end

  def test_refuses_a_file_that_is_not_an_array
    Dir.mktmpdir do |d|
      yaml = File.join(d, 'input.yml')
      save_it(yaml, "foo: 42\n")
      e =
        assert_raises(StandardError) do
          Judges::Import.new(Loog::NULL).run({}, [yaml, File.join(d, 'base.fb')])
        end
      assert_includes(e.message, 'must hold an array of facts, while Hash found', e.message)
    end
  end
end
