# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require 'loog'
require_relative '../../lib/judges/commands/test'
require_relative '../test__helper'

# Test the number of judge executions.
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2024-2026 Yegor Bugayenko
# License:: MIT
class TestTestRuns < Minitest::Test
  def test_refuses_nonpositive_runs
    [0, -1].product([true, false]).each do |runs, cli|
      Dir.mktmpdir do |dir|
        save_it(File.join(dir, 'foo/foo.rb'), '$fb.insert.what = "greeting"')
        save_it(File.join(dir, 'foo/simple.yml'), "runs: #{cli ? 1 : runs}\nexpected:\n  - /fb/f[what='impossible']")
        loog = Loog::Buffer.new
        opts = cli ? { 'runs' => runs } : {}
        assert_includes(
          assert_raises(StandardError) { Judges::Test.new(loog).run(opts, [dir]) }.message,
          '1 tests failed'
        )
        assert_includes(loog.to_s, 'The runs value must be at least 1')
        assert_match(%r{foo/simple\s+\S+\s+ERROR}, loog.to_s)
      end
    end
  end

  def test_positive_runs_override_invalid_yaml
    Dir.mktmpdir do |dir|
      save_it(File.join(dir, 'foo/foo.rb'), '$fb.insert.what = "greeting"')
      save_it(File.join(dir, 'foo/simple.yml'), "runs: 0\nexpected:\n  - /fb[count(f)=2]")
      loog = Loog::Buffer.new
      Judges::Test.new(loog).run({ 'runs' => 2 }, [dir])
      assert_match(%r{foo/simple\s+\S+\s+OK}, loog.to_s)
    end
  end
end
