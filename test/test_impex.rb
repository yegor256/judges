# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require 'loog'
require 'tmpdir'
require_relative '../lib/judges'
require_relative '../lib/judges/impex'
require_relative 'test__helper'

# Test.
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2024-2026 Yegor Bugayenko
# License:: MIT
class TestImpex < Minitest::Test
  def test_basic
    Dir.mktmpdir do |d|
      impex = Judges::Impex.new(Loog::NULL, File.join(d, 'foo.rb'))
      assert_equal(0, impex.import(strict: false).size)
      fb = Factbase.new
      fb.insert.foo = 1
      impex.export(fb)
      assert_equal(1, impex.import.size)
    end
  end

  def test_strict_import
    Dir.mktmpdir do |d|
      error = assert_raises(StandardError) { Judges::Impex.new(Loog::NULL, File.join(d, 'x.rb')).import }
      assert_includes(error.message, 'The factbase is absent', error.message)
    end
  end

  def test_imports_into_existing_factbase
    Dir.mktmpdir do |d|
      file = File.join(d, 'slave.fb')
      slave = Factbase.new
      slave.insert.foo = 1
      File.binwrite(file, slave.export)
      master = Factbase.new
      master.insert.bar = 1
      Judges::Impex.new(Loog::NULL, file).import_to(master)
      assert_equal(2, master.size)
    end
  end

  def test_refuses_to_import_absent_file_into_factbase
    Dir.mktmpdir do |d|
      assert_raises(StandardError) { Judges::Impex.new(Loog::NULL, File.join(d, 'no.fb')).import_to(Factbase.new) }
    end
  end

  def test_refuses_a_nil_file
    assert_includes(assert_raises(ArgumentError) { Judges::Impex.new(Loog::NULL, nil) }.message, 'The file is nil')
  end
end
