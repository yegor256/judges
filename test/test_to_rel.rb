# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative '../lib/judges'
require_relative '../lib/judges/to_rel'
require_relative 'test__helper'

# Test.
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2024-2026 Yegor Bugayenko
# License:: MIT
class TestToRel < Minitest::Test
  def test_simple_mapping
    n = File.absolute_path(File.join('.', 'lib/../lib/commands/update.rb'))
    assert_equal('lib/commands/update.rb', n.to_rel)
  end

  def test_maps_dir_name
    n = File.absolute_path(File.join('.', 'lib/../lib/judges/commands'))
    assert_equal('lib/judges/commands/', n.to_rel)
  end
end
