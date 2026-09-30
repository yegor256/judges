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
      impex.import(strict: false)
      impex.export(Factbase.new)
    end
  end

  def test_strict_import
    Dir.mktmpdir do |d|
      impex = Judges::Impex.new(Loog::NULL, File.join(d, 'x.rb'))
      impex.import(strict: false)
      impex.export(Factbase.new)
      impex.import
    end
  end

  def test_reports_the_facts_that_came_from_the_file
    Dir.mktmpdir do |d|
      slave = Factbase.new
      2.times { slave.insert.foo = 1 }
      file = File.join(d, 'slave.fb')
      File.binwrite(file, slave.export)
      master = Factbase.new
      3.times { master.insert.bar = 1 }
      loog = Loog::Buffer.new
      Judges::Impex.new(loog, file).import_to(master)
      assert_includes(loog.to_s, '2 facts loaded from', loog.to_s)
    end
  end

  def test_refuses_a_nil_file
    assert_includes(assert_raises(ArgumentError) { Judges::Impex.new(Loog::NULL, nil) }.message, 'The file is nil')
  end
end
