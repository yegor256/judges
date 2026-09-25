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

  def test_keeps_the_previous_factbase_on_failure
    Dir.mktmpdir do |d|
      file = File.join(d, 'base.fb')
      impex = Judges::Impex.new(Loog::NULL, file)
      first = Factbase.new
      first.insert.foo = 1
      impex.export(first)
      before = File.binread(file)
      refute_empty(before)
      second = Factbase.new
      second.insert.bar = 2
      second.insert.baz = 3
      File.stub(:rename, ->(*) { raise(StandardError, 'the disk is full') }) do
        assert_raises(StandardError) { impex.export(second) }
      end
      assert_equal(before, File.binread(file), 'the previous factbase must survive a failed replacement')
    end
  end

  def test_leaves_no_leftover_file_behind
    Dir.mktmpdir do |d|
      fb = Factbase.new
      fb.insert.foo = 1
      Judges::Impex.new(Loog::NULL, File.join(d, 'base.fb')).export(fb)
      assert_equal(['base.fb'], Dir.children(d))
    end
  end
end
