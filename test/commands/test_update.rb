# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2025 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require 'loog'
require 'loog/tee'
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

  def test_cancels_slow_execution
    Dir.mktmpdir do |d|
      100.times do |i|
        save_it(File.join(d, "foo-#{i}/foo-#{i}.rb"), '$fb.insert.foo = 0.05; sleep 2;')
      end
      file = File.join(d, 'base.fb')
      Judges::Update.new(Loog::NULL).run({ 'lifetime' => 0.12, 'timeout' => 0.1, 'quiet' => true }, [d, file])
      fb = Factbase.new
      fb.import(File.binread(file))
      xml = Nokogiri::XML.parse(Factbase::ToXML.new(fb).xml)
      refute_empty(xml.xpath('/fb/f[foo]'), xml)
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

  def test_accepts_changes_from_slow_judge
    Dir.mktmpdir do |d|
      save_it(File.join(d, 'foo/foo.rb'), '$fb.insert.foo = 1; sleep 10')
      file = File.join(d, 'base.fb')
      Judges::Update.new(Loog::NULL).run(
        { 'timeout' => 0.1, 'quiet' => true, 'fail-fast' => true },
        [d, file]
      )
      fb = Factbase.new
      fb.import(File.binread(file))
      xml = Nokogiri::XML.parse(Factbase::ToXML.new(fb).xml)
      refute_empty(xml.xpath('/fb/f[foo]'), xml)
    end
  end

  def test_reports_changes_from_slow_judge
    Dir.mktmpdir do |d|
      save_it(File.join(d, 'foo/foo.rb'), '$fb.insert.foo = 1; sleep 10')
      file = File.join(d, 'base.fb')
      log = Loog::Buffer.new
      Judges::Update.new(Loog::Tee.new(log, Loog::NULL)).run(
        { 'timeout' => 0.1, 'quiet' => true, 'fail-fast' => true },
        [d, file]
      )
      assert_includes(log.to_s, 'did 1i/0d/1a')
      assert_includes(log.to_s, 'Update completed in 1 cycle(s), did 1i/0d/1a')
      fb = Factbase.new
      fb.import(File.binread(file))
      xml = Nokogiri::XML.parse(Factbase::ToXML.new(fb).xml)
      refute_empty(xml.xpath('/fb/f[foo]'), xml)
    end
  end

  def test_exports_fb_only_once
    Dir.mktmpdir do |d|
      save_it(File.join(d, 'foo/foo.rb'), '$fb.insert.foo = 1;')
      file = File.join(d, 'base.fb')
      log = Loog::Buffer.new
      Judges::Update.new(Loog::Tee.new(log, Loog::NULL)).run(
        { 'quiet' => true, 'max-cycles' => 2 },
        [d, file]
      )
      assert_equal(1, log.to_s.scan('Factbase exported to').count)
    end
  end

  def test_exports_fb_despite_judge_syntax_error
    Dir.mktmpdir do |d|
      save_it(File.join(d, 'foo/foo.rb'), '$fb.insert.foo = 1')
      save_it(File.join(d, 'bar/bar.rb'), 'this$is$a$broken$Ruby$script')
      file = File.join(d, 'base.fb')
      assert_raises(StandardError) do
        Judges::Update.new(Loog::NULL).run(
          { 'quiet' => false, 'max-cycles' => 1 },
          [d, file]
        )
      end
      fb = Factbase.new
      fb.import(File.binread(file))
      xml = Nokogiri::XML.parse(Factbase::ToXML.new(fb).xml)
      refute_empty(xml.xpath('/fb/f[foo]'), xml)
    end
  end

  # @todo #341:30min This test is flaky on macOS in GitHub Actions.
  #  If the 'lifetime' is less than 15 seconds, the second cycle doesn't start due to insufficient time.
  #  If it's more than 15 seconds, the bar judge gets skipped in the second cycle (no time left).
  #  To enable this test for macOS, we need to devise a different way to trigger an exception during judge processing.
  def test_exports_all_judges_despite_lifetime_timeout
    skip 'Flaky on macOS in GitHub Actions' if RUBY_PLATFORM.include?('darwin')
    Dir.mktmpdir do |d|
      save_it(File.join(d, 'foo/foo.rb'), '$fb.insert.foo = 1')
      save_it(File.join(d, 'bar/bar.rb'), '$fb.insert.bar = 2; sleep 1')
      file = File.join(d, 'base.fb')
      assert_raises(StandardError) do
        Judges::Update.new(Loog::NULL).run(
          { 'quiet' => false, 'max-cycles' => 2, 'lifetime' => 2 },
          [d, file]
        )
      end
      fb = Factbase.new
      fb.import(File.binread(file))
      xml = Nokogiri::XML.parse(Factbase::ToXML.new(fb).xml)
      assert_equal(2, xml.xpath('/fb/f[foo]').size)
      assert_equal(2, xml.xpath('/fb/f[bar]').size)
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

  def test_terminates_on_lifetime
    Dir.mktmpdir do |d|
      save_it(File.join(d, 'foo/foo.rb'), 'sleep 999')
      file = File.join(d, 'base.fb')
      log = Loog::Buffer.new
      assert_raises(StandardError) do
        Judges::Update.new(Loog::Tee.new(log, Loog::NULL)).run({ 'lifetime' => 0.1 }, [d, file])
      end
      assert_includes(log.to_s, 'execution expired')
    end
  end

  def test_passes_timeout_and_lifetime_through
    %w[lifetime timeout].each do |o|
      Dir.mktmpdir do |d|
        save_it(File.join(d, 'foo/foo.rb'), "$loog.info '#{o}=' + $options.#{o}.to_s")
        file = File.join(d, 'base.fb')
        log = Loog::Buffer.new
        Judges::Update.new(Loog::Tee.new(log, Loog::NULL)).run({ o => 666 }, [d, file])
        assert_includes(log.to_s, "#{o}=666")
      end
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
          { 'quiet' => true, 'summary' => 'add', 'max-cycles' => 2 },
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
        { 'quiet' => true, 'summary' => 'append', 'max-cycles' => 2 },
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

  def test_isolates_churns
    Dir.mktmpdir do |d|
      save_it(File.join(d, 'first/first.rb'), '$global[:fb] ||= $fb; 2 + 2')
      save_it(File.join(d, 'second/second.rb'), '$global[:fb] ||= $fb; $global[:fb].insert')
      file = File.join(d, 'base.fb')
      Judges::Update.new(Loog::NULL).run(
        { 'max-cycles' => 3, 'boost' => 'first' },
        [d, file]
      )
      fb = Factbase.new
      fb.import(File.binread(file))
      assert_equal(3, fb.size)
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

  def test_seed_parameter_is_passed_through
    Dir.mktmpdir do |d|
      save_it(File.join(d, 'foo/foo.rb'), '$fb.insert')
      file = File.join(d, 'base.fb')
      Judges::Update.new(Loog::NULL).run({ 'seed' => 42, 'max-cycles' => 1, 'timeout' => 1 }, [d, file])
      assert_path_exists(file)
    end
  end
end
