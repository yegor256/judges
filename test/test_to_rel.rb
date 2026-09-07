# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require 'minitest/mock'
require 'pathname'
require_relative '../lib/judges'
require_relative '../lib/judges/to_rel'
require_relative 'test__helper'

# Test.
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2024-2026 Yegor Bugayenko
# License:: MIT
class TestToRel < Minitest::Test
  def test_simple_mapping
    assert_equal('lib/commands/update.rb', File.absolute_path(File.join('.', 'lib/../lib/commands/update.rb')).to_rel)
  end

  def test_maps_dir_name
    assert_equal('lib/judges/commands/', File.absolute_path(File.join('.', 'lib/../lib/judges/commands')).to_rel)
  end

  def test_survives_a_path_with_no_relative_form
    fake =
      Class.new do
        define_method(:relative_path_from) { |_other| raise(ArgumentError, 'different prefix: "C:/" and "D:/work"') }
      end.new
    file = File.absolute_path(File.join('.', 'lib/judges/to_rel.rb'))
    Pathname.stub(:new, fake) do
      assert_equal(file, file.to_rel)
    end
  end
end
