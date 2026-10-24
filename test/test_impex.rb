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

  def test_starts_from_an_empty_factbase_on_a_zero_byte_file
    Dir.mktmpdir do |d|
      file = File.join(d, 'empty.fb')
      FileUtils.touch(file)
      assert_equal(0, Judges::Impex.new(Loog::NULL, file).import(strict: false).size)
    end
  end

  def test_refuses_a_zero_byte_file_in_strict_mode
    Dir.mktmpdir do |d|
      file = File.join(d, 'empty.fb')
      FileUtils.touch(file)
      assert_raises(StandardError) { Judges::Impex.new(Loog::NULL, file).import }
    end
  end

  def test_refuses_a_nil_file
    assert_includes(assert_raises(ArgumentError) { Judges::Impex.new(Loog::NULL, nil) }.message, 'The file is nil')
  end

  def test_imports_from_a_pipe
    skip('No named pipes on Windows') if Gem.win_platform?
    Dir.mktmpdir do |d|
      pipe = File.join(d, 'fifo')
      File.mkfifo(pipe)
      fb = Factbase.new
      fb.insert.foo = 42
      Thread.new { File.binwrite(pipe, fb.export) }
      assert_equal(1, Judges::Impex.new(Loog::NULL, pipe).import.size)
    end
  end
end
