# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require 'loog'
require 'nokogiri'
require 'time'
require_relative '../../lib/judges'
require_relative '../../lib/judges/commands/trim'
require_relative '../test__helper'

# Test.
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2024-2026 Yegor Bugayenko
# License:: MIT
class TestTrim < Minitest::Test
  def test_trims_factbase
    Dir.mktmpdir do |d|
      file = File.join(d, 'base.fb')
      before = Factbase.new
      kept = before.insert
      kept.name = 'keep'
      kept.time = Time.parse('2026-01-02T00:00:00Z')
      dropped = before.insert
      dropped.name = 'drop'
      dropped.time = Time.parse('2025-12-31T00:00:00Z')
      File.binwrite(file, before.export)
      Judges::Trim.new(Loog::NULL).run(
        { 'query' => "(lt time #{Time.parse('2026-01-01T00:00:00Z').iso8601})" }, [file]
      )
      after = Factbase.new
      after.import(File.binread(file))
      assert_equal(1, after.size)
      assert_equal(['keep'], after.query('(always)').each.to_a.first['name'])
    end
  end
end
