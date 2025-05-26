# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2025 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require 'loog'
require 'nokogiri'
require 'factbase/to_xml'
require_relative '../test__helper'
require_relative '../../lib/judges'
require_relative '../../lib/judges/commands/update'

# Test.
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2024-2025 Yegor Bugayenko
# License:: MIT
class TestUpdate < Minitest::Test
  def test_build_factbase_from_scratch
    Dir.mktmpdir do |d|
      save_it(File.join(d, 'foo/foo.rb'), 'return if $fb.size > 2; $fb.insert.zzz = $options.foo_bar + 1')
      file = File.join(d, 'base.fb')
      Judges::Update.new(Loog::NULL).run({ 'option' => ['foo_bar=42'] }, [d, file])
      fb = Factbase.new
      fb.import(File.binread(file))
      xml = Nokogiri::XML.parse(Factbase::ToXML.new(fb).xml)
      refute_empty(xml.xpath('/fb/f[zzz="43"]'), xml)
    end
  end

  def test_with_only_one_judge
    Dir.mktmpdir do |d|
      save_it(File.join(d, 'foo/foo.rb'), 'return if $fb.size > 2; $fb.insert')
      save_it(File.join(d, 'bar/bar.rb'), '-&- bug here -&-')
      file = File.join(d, 'base.fb')
      Judges::Update.new(Loog::NULL).run({ 'judge' => ['foo'] }, [d, file])
      assert_path_exists(file)
      assert_raises(StandardError) { Judges::Update.new(Loog::NULL).run({}, [d, file]) }
    end
  end

  def test_cancels_slow_judge
    Dir.mktmpdir do |d|
      save_it(File.join(d, 'foo/foo.rb'), 'sleep 10; $fb.insert.foo = 1')
      file = File.join(d, 'base.fb')
      Judges::Update.new(Loog::NULL).run({ 'timeout' => 0.1, 'quiet' => true }, [d, file])
      fb = Factbase.new
      fb.import(File.binread(file))
      xml = Nokogiri::XML.parse(Factbase::ToXML.new(fb).xml)
      assert_empty(xml.xpath('/fb/f'), xml)
    end
  end

  def test_extend_existing_factbase
    Dir.mktmpdir do |d|
      file = File.join(d, 'base.fb')
      fb = Factbase.new
      fb.insert.foo_bar = 42
      File.binwrite(file, fb.export)
      save_it(File.join(d, 'foo/foo.rb'), '$fb.insert.tt = 4')
      Judges::Update.new(Loog::NULL).run({ 'max-cycles' => 1 }, [d, file])
      fb = Factbase.new
      fb.import(File.binread(file))
      xml = Nokogiri::XML.parse(Factbase::ToXML.new(fb).xml)
      refute_empty(xml.xpath('/fb/f[tt="4"]'), xml)
      refute_empty(xml.xpath('/fb/f[foo_bar="42"]'), xml)
    end
  end

  def test_update_with_error
    Dir.mktmpdir do |d|
      save_it(File.join(d, 'foo/foo.rb'), 'this$is$a$broken$Ruby$script')
      file = File.join(d, 'base.fb')
      Judges::Update.new(Loog::NULL).run({ 'quiet' => true, 'max-cycles' => 2 }, [d, file])
    end
  end

  def test_update_with_options_in_file
    Dir.mktmpdir do |d|
      save_it(File.join(d, 'foo/foo.rb'), '$fb.insert.foo = $options.bar')
      file = File.join(d, 'base.fb')
      opts = File.join(d, 'opts.txt')
      save_it(opts, "   bar = helloo  \n  bar =   444\n\n")
      Judges::Update.new(Loog::NULL).run({ 'quiet' => true, 'max-cycles' => 1, 'options-file' => opts }, [d, file])
      fb = Factbase.new
      fb.import(File.binread(file))
      xml = Nokogiri::XML.parse(Factbase::ToXML.new(fb).xml)
      refute_empty(xml.xpath('/fb/f[foo="444"]'), xml)
    end
  end

  def test_update_with_error_no_quiet
    assert_raises(StandardError) do
      Dir.mktmpdir do |d|
        save_it(File.join(d, 'foo/foo.rb'), 'a < 1')
        file = File.join(d, 'base.fb')
        Judges::Update.new(Loog::NULL).run({ 'quiet' => false }, [d, file])
      end
    end
  end

  def test_update_with_error_and_summary
    Dir.mktmpdir do |d|
      save_it(File.join(d, 'foo/foo.rb'), 'this$is$a$broken$Ruby$script')
      file = File.join(d, 'base.fb')
      2.times do
        Judges::Update.new(Loog::NULL).run(
          { 'quiet' => true, 'summary' => true, 'max-cycles' => 2 },
          [d, file]
        )
      end
      fb = Factbase.new
      fb.import(File.binread(file))
      sums = fb.query('(eq what "judges-summary")').each.to_a
      assert_equal(1, sums.size)
      sum = sums.first
      assert_includes(sum.error, 'unexpected global variable', sum.error)
      refute_nil(sum.seconds)
    end
  end

  def test_appends_to_existing_summary
    Dir.mktmpdir do |d|
      save_it(File.join(d, 'foo/foo.rb'), 'mistake here')
      file = File.join(d, 'base.fb')
      fb = Factbase.new
      fb.insert.then do |f|
        f.what = 'judges-summary'
        f.error = 'first'
        f.error = 'second'
      end
      File.binwrite(file, fb.export)
      Judges::Update.new(Loog::NULL).run(
        { 'quiet' => true, 'summary' => true, 'max-cycles' => 2 },
        [d, file]
      )
      fb = Factbase.new
      fb.import(File.binread(file))
      sums = fb.query('(eq what "judges-summary")').each.to_a
      assert_equal(1, sums.size)
      sum = sums.first
      assert_equal(3, sum['error'].size)
    end
  end

  def test_fail_fast_stops_cycle
    Dir.mktmpdir do |d|
      save_it(File.join(d, 'error/error.rb'), 'invalid$ruby$syntax')
      save_it(File.join(d, 'valid/valid.rb'), '$fb.insert')
      file = File.join(d, 'base.fb')
      Judges::Update.new(Loog::NULL).run(
        { 'fail-fast' => true, 'quiet' => true, 'max-cycles' => 3, 'boost' => 'error' },
        [d, file]
      )
      fb = Factbase.new
      fb.import(File.binread(file))
      assert_equal(0, fb.size)
    end
  end

  def test_fails_when_no_judges_used
    assert_raises(StandardError) do
      Dir.mktmpdir do |d|
        save_it(File.join(d, 'foo/foo.rb'), '$fb.insert')
        file = File.join(d, 'base.fb')
        Judges::Update.new(Loog::NULL).run({ 'judge' => ['nonexistent'], 'expect-judges' => true }, [d, file])
      end
    end
  end

  def test_fails_when_empty_directory
    assert_raises(StandardError) do
      Dir.mktmpdir do |d|
        file = File.join(d, 'base.fb')
        Judges::Update.new(Loog::NULL).run({ 'expect-judges' => true }, [d, file])
      end
    end
  end

  def test_no_failure_when_expect_judges_false
    Dir.mktmpdir do |d|
      file = File.join(d, 'base.fb')
      Judges::Update.new(Loog::NULL).run({ 'expect-judges' => false }, [d, file])
      assert_path_exists(file)
    end
  end

  def test_no_failure_with_nonexistent_judge_when_expect_judges_false
    Dir.mktmpdir do |d|
      save_it(File.join(d, 'foo/foo.rb'), '$fb.insert')
      file = File.join(d, 'base.fb')
      Judges::Update.new(Loog::NULL).run({ 'judge' => ['nonexistent'], 'expect-judges' => false }, [d, file])
      assert_path_exists(file)
    end
  end
end
