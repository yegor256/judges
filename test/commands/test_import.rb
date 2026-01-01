# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require 'loog'
require 'nokogiri'
require 'factbase/to_xml'
require_relative '../test__helper'
require_relative '../../lib/judges'
require_relative '../../lib/judges/commands/import'

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
end
