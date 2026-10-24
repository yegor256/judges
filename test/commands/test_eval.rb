# frozen_string_literal: true

require 'factbase/to_xml'
# SPDX-FileCopyrightText: Copyright (c) 2024-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require 'loog'
require 'nokogiri'
require_relative '../../lib/judges'
require_relative '../../lib/judges/commands/eval'
require_relative '../test__helper'

# Test.
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2024-2026 Yegor Bugayenko
# License:: MIT
class TestEval < Minitest::Test
  def test_build_factbase_from_scratch
    Dir.mktmpdir do |d|
      file = File.join(d, 'base.fb')
      Judges::Eval.new(Loog::NULL).run({}, [file, '$fb.insert.foo = 42'])
      fb = Factbase.new
      fb.import(File.binread(file))
      xml = Nokogiri::XML.parse(Factbase::ToXML.new(fb).xml)
      refute_empty(xml.xpath('/fb/f[foo="42"]'), xml)
    end
  end

  def test_hides_command_locals_from_expression
    Dir.mktmpdir do |d|
      file = File.join(d, 'base.fb')
      Judges::Eval.new(Loog::NULL).run({}, [file, 'impex = nil; $fb.insert.foo = 7'])
      fb = Factbase.new
      fb.import(File.binread(file))
      assert_equal(1, fb.size)
    end
  end

  def test_reports_invalid_ruby_as_a_command_error
    Dir.mktmpdir do |d|
      error =
        assert_raises(StandardError) do
          Judges::Eval.new(Loog::NULL).run({}, [File.join(d, 'base.fb'), '1 +'])
        end
      assert_includes(error.message, 'is not valid Ruby', error.message)
      assert_instance_of(SyntaxError, error.cause)
    end
  end

  def test_reports_load_error_as_a_command_error
    Dir.mktmpdir do |d|
      fb = File.join(d, 'base.fb')
      error =
        assert_raises(StandardError) do
          Judges::Eval.new(Loog::NULL).run({}, [fb, "require 'nonexistent_gem_lib_xyz_123'"])
        end
      assert_includes(error.message, 'failed:', error.message)
      assert_instance_of(LoadError, error.cause)
    end
  end

  def test_reports_not_implemented_script_error
    Dir.mktmpdir do |d|
      fb = File.join(d, 'base.fb')
      error =
        assert_raises(StandardError) do
          Judges::Eval.new(Loog::NULL).run({}, [fb, "raise NotImplementedError, 'feature pending'"])
        end
      assert_includes(error.message, 'failed: feature pending', error.message)
      assert_instance_of(NotImplementedError, error.cause)
    end
  end

  def test_reports_script_error_with_expression_name
    Dir.mktmpdir do |d|
      expr = "require 'no_such_file_anywhere'"
      error =
        assert_raises(StandardError) do
          Judges::Eval.new(Loog::NULL).run({}, [File.join(d, 'base.fb'), expr])
        end
      assert_includes(error.message, expr, error.message)
    end
  end
end
