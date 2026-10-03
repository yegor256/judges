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

  def test_rejects_directory_on_import
    Dir.mktmpdir do |d|
      impex = Judges::Impex.new(Loog::NULL, d)
      assert_includes(assert_raises(ArgumentError) { impex.import(strict: false) }.message, 'must be a regular file')
    end
  end

  def test_rejects_directory_on_export
    Dir.mktmpdir do |d|
      impex = Judges::Impex.new(Loog::NULL, d)
      assert_includes(assert_raises(ArgumentError) { impex.export(Factbase.new) }.message, 'must be a regular file')
    end
  end
end
