# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require 'factbase'
require 'loog'
require_relative '../../lib/judges'
require_relative '../../lib/judges/commands/inspect'
require_relative '../test__helper'

# Test.
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2024-2026 Yegor Bugayenko
# License:: MIT
class TestInspect < Minitest::Test
  def test_simple_inspect
    Dir.mktmpdir do |d|
      f = File.join(d, 'base.fb')
      fb = Factbase.new
      fb.insert
      fb.insert
      File.binwrite(f, fb.export)
      loog = Loog::Buffer.new
      Judges::Inspect.new(loog).run({}, [f])
      assert_includes(loog.to_s, 'Facts: 2')
    end
  end

  def test_simple_inspect_with_summary
    Dir.mktmpdir do |d|
      f = File.join(d, 'base.fb')
      fb = Factbase.new
      fb.insert.then do |f|
        f.what = 'judges-summary'
        f.error = 'something'
      end
      File.binwrite(f, fb.export)
      loog = Loog::Buffer.new
      Judges::Inspect.new(loog).run({}, [f])
      assert_includes(loog.to_s, 'Facts: 1')
    end
  end

  def test_inspect_uses_latest_summary
    Dir.mktmpdir do |d|
      f = File.join(d, 'base.fb')
      fb = Factbase.new
      fb.insert.then do |fact|
        fact.what = 'judges-summary'
        fact.when = Time.utc(2026, 1, 1)
        fact.error = 'old'
      end
      fb.insert.then do |fact|
        fact.what = 'judges-summary'
        fact.when = Time.utc(2026, 2, 1)
        fact.error = 'new'
      end
      File.binwrite(f, fb.export)
      loog = Loog::Buffer.new
      Judges::Inspect.new(loog).run({}, [f])
      assert_includes(loog.to_s, 'new')
      refute_includes(loog.to_s, 'old')
    end
  end
end
