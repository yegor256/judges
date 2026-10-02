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

  def test_keeps_the_previous_factbase_if_export_fails
    skip('No process file-size limit') unless Process.respond_to?(:fork) &&
      Process.const_defined?(:RLIMIT_FSIZE) && Signal.list.key?('XFSZ')
    Dir.mktmpdir do |d|
      path = File.join(d, 'base.fb')
      File.binwrite(path, 'previous valid factbase')
      fb = Factbase.new
      fb.insert.what = 'new content'
      child = Process.fork do
        Signal.trap('XFSZ', 'IGNORE')
        Process.setrlimit(Process::RLIMIT_FSIZE, 1, 1)
        begin
          Judges::Impex.new(Loog::NULL, path).export(fb)
        rescue Errno::EFBIG
          exit!(0)
        end
        exit!(1)
      end
      _, status = Process.wait2(child)
      assert_predicate(status, :success?)
      assert_equal('previous valid factbase', File.binread(path))
    end
  end

  def test_refuses_a_nil_file
    assert_includes(assert_raises(ArgumentError) { Judges::Impex.new(Loog::NULL, nil) }.message, 'The file is nil')
  end
end
