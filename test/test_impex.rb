# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2025 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require 'minitest/autorun'
require 'tmpdir'
require 'loog'
require_relative '../lib/judges'
require_relative '../lib/judges/impex'

# Test.
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2024-2025 Yegor Bugayenko
# License:: MIT
class TestImpex < Minitest::Test
  def test_basic
    Dir.mktmpdir do |d|
      f = File.join(d, 'foo.rb')
      impex = Judges::Impex.new(Loog::NULL, f)
      impex.import(strict: false)
      impex.export(Factbase.new)
    end
  end

  def test_strict_import
    Dir.mktmpdir do |d|
      f = File.join(d, 'x.rb')
      impex = Judges::Impex.new(Loog::NULL, f)
      impex.import(strict: false)
      impex.export(Factbase.new)
      impex.import
    end
  end
end
