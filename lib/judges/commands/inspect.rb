# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2025 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative '../../judges'
require_relative '../../judges/impex'

# The +inspect+ command.
#
# This class is instantiated by the +bin/judge+ command line interface. You
# are not supposed to instantiate it yourself.
#
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2024-2025 Yegor Bugayenko
# License:: MIT
class Judges::Inspect
  def initialize(loog)
    @loog = loog
  end

  def run(_opts, args)
    raise 'At lease one argument required' if args.empty?
    fb = Judges::Impex.new(@loog, args[0]).import
    @loog.info("Facts: #{fb.size}")
  end
end
