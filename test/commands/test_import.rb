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
      first = fb.query('(exists foo)').first
      assert_equal([42], first['foo'])
      assert_instance_of(Integer, first['foo'].first)
      assert_instance_of(Time, first['bar'].first)
      assert_instance_of(String, first['t'].first)
      assert_equal([3.14], fb.query('(exists z)').first['z'])
      assert_instance_of(Float, fb.query('(exists z)').first['z'].first)
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

  def test_imports_multi_valued_properties
    Dir.mktmpdir do |d|
      file = File.join(d, 'base.fb')
      yaml = File.join(d, 'input.yml')
      save_it(
        yaml,
        <<-YAML
        -
          tag:
          - first
          - second
        YAML
      )
      Judges::Import.new(Loog::NULL).run({}, [yaml, file])
      fb = Factbase.new
      fb.import(File.binread(file))
      assert_equal(%w[first second], fb.query('(always)').first['tag'])
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

  def test_refuses_an_array_of_scalars
    Dir.mktmpdir do |d|
      yaml = File.join(d, 'input.yml')
      save_it(yaml, "- just a string\n- 42\n")
      error =
        assert_raises(StandardError) do
          Judges::Import.new(Loog::NULL).run({}, [yaml, File.join(d, 'base.fb')])
        end
      assert_includes(error.message, 'must be a map of properties, while String found', error.message)
    end
  end

  def test_refuses_a_directory_as_yaml
    Dir.mktmpdir do |d|
      dir = File.join(d, 'input.yml')
      FileUtils.mkdir_p(dir)
      file = File.join(d, 'base.fb')
      e =
        assert_raises(StandardError) do
          Judges::Import.new(Loog::NULL).run({}, [dir, file])
        end
      assert_instance_of(StandardError, e)
      assert_includes(e.message, 'is a directory', e.message)
      refute_path_exists(file)
    end
  end
end
