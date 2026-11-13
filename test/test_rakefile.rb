# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require 'fileutils'
require 'tmpdir'
require_relative 'test__helper'

# Test.
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2024-2026 Yegor Bugayenko
# License:: MIT
class TestRakefile < Minitest::Test
  load File.expand_path('../Rakefile', __dir__)

  def test_keeps_coverage_when_loaded
    Dir.mktmpdir do |dir|
      FileUtils.mkdir_p(File.join(dir, 'coverage'))
      FileUtils.touch(File.join(dir, 'coverage/report.xml'))
      Dir.chdir(dir) { load(File.expand_path('../Rakefile', __dir__)) }
      assert_path_exists(File.join(dir, 'coverage/report.xml'), 'the Rakefile deleted coverage when loaded')
    end
  end

  def test_test_cleans_the_coverage
    assert_includes(Rake::Task[:test].prerequisites, 'uncover')
  end

  def test_features_cleans_the_coverage
    assert_includes(Rake::Task[:features].prerequisites, 'uncover')
  end
end
