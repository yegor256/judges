# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2025 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require 'loog'
require 'tmpdir'
require_relative '../lib/judges'
require_relative '../lib/judges/judges'
require_relative 'test__helper'

# Test.
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2024-2025 Yegor Bugayenko
# License:: MIT
class TestJudges < Minitest::Test
  def test_basic
    Dir.mktmpdir do |d|
      dir = File.join(d, 'foo')
      save_it(File.join(dir, 'foo.rb'), 'hey')
      save_it(File.join(dir, 'something.yml'), "---\nfoo: 42")
      found = 0
      Judges::Judges.new(d, nil, Loog::NULL).each do |p|
        assert_equal('foo.rb', p.script)
        found += 1
        assert_equal('something.yml', File.basename(p.tests.first))
      end
      assert_equal(1, found)
    end
  end

  def test_get_one
    Dir.mktmpdir do |d|
      save_it(File.join(d, 'boo/boo.rb'), 'hey')
      j = Judges::Judges.new(d, nil, Loog::NULL).get('boo')
      assert_equal('boo.rb', j.script)
    end
  end

  def test_list_only_direct_subdirs
    Dir.mktmpdir do |d|
      save_it(File.join(d, 'first/first.rb'), '')
      save_it(File.join(d, 'second/second.rb'), '')
      save_it(File.join(d, 'second/just-file.rb'), '')
      save_it(File.join(d, 'wrong.rb'), '')
      save_it(File.join(d, 'another/wrong/wrong.rb'), '')
      save_it(File.join(d, 'bad/hello.rb'), '')
      list = Judges::Judges.new(d, nil, Loog::NULL).each.to_a
      assert_equal(2, list.size)
    end
  end

  def test_list_with_empty_dir
    Dir.mktmpdir do |d|
      save_it(File.join(d, 'wrong.rb'), '')
      save_it(File.join(d, 'another/wrong/wrong.rb'), '')
      save_it(File.join(d, 'bad/hello.rb'), '')
      list = Judges::Judges.new(d, nil, Loog::NULL).each.to_a
      assert_empty(list)
    end
  end
end
