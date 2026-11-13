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
      %w[keep keep-too].each do |n|
        f = before.insert
        f.name = n
        f.time = Time.parse('2026-01-02T00:00:00Z')
      end
      dropped = before.insert
      dropped.name = 'drop'
      dropped.time = Time.parse('2025-12-31T00:00:00Z')
      File.binwrite(file, before.export)
      Judges::Trim.new(Loog::NULL).run(
        { 'query' => "(lt time #{Time.parse('2026-01-01T00:00:00Z').iso8601})" }, [file]
      )
      after = Factbase.new
      after.import(File.binread(file))
      names = after.query('(always)').each.to_a.map { |f| f['name'].first }
      assert_equal(2, after.size)
      assert_equal(%w[keep keep-too], names.sort)
      refute_includes(names, 'drop')
    end
  end

  def test_keeps_the_file_when_nothing_matches
    Dir.mktmpdir do |d|
      file = File.join(d, 'base.fb')
      before = Factbase.new
      gone = before.insert
      gone.name = 'gone'
      gone.time = Time.parse('2020-01-01T00:00:00Z')
      File.binwrite(file, before.export)
      log = Loog::Buffer.new
      Judges::Trim.new(log).run({ 'query' => "(lt time #{Time.parse('2019-01-01T00:00:00Z').iso8601})" }, [file])
      after = Factbase.new
      after.import(File.binread(file))
      assert_equal(1, after.size)
      assert_equal(['gone'], after.query('(always)').each.to_a.first['name'])
      assert_includes(log.to_s, 'No facts deleted')
    end
  end
end
