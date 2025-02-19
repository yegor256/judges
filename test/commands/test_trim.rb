# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2025 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require 'minitest/autorun'
require 'loog'
require 'nokogiri'
require 'time'
require_relative '../../lib/judges'
require_relative '../../lib/judges/commands/trim'

# Test.
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2024-2025 Yegor Bugayenko
# License:: MIT
class TestTrim < Minitest::Test
  def test_trims_factbase
    Dir.mktmpdir do |d|
      file = File.join(d, 'base.fb')
      before = Factbase.new
      before.insert.time = Time.now + 1
      before.insert.time = Time.now - (100 * 24 * 60 * 60)
      File.binwrite(file, before.export)
      Judges::Trim.new(Loog::NULL).run({ 'query' => "(lt time #{Time.now.utc.iso8601})" }, [file])
      after = Factbase.new
      after.import(File.binread(file))
      assert_equal(1, after.size)
    end
  end
end
