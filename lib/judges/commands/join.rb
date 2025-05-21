# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2025 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require 'elapsed'
require_relative '../../judges'
require_relative '../../judges/impex'

# The +join+ command.
#
# This class is instantiated by the +bin/judge+ command line interface. You
# are not supposed to instantiate it yourself.
#
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2024-2025 Yegor Bugayenko
# License:: MIT
class Judges::Join
  # Initialize.
  # @param [Loog] loog Logging facility
  def initialize(loog)
    @loog = loog
  end

  # Run the join command (called by the +bin/judges+ script).
  # @param [Hash] _opts Command line options (not used)
  # @param [Array] args List of command line arguments
  # @raise [RuntimeError] If not exactly two arguments provided
  def run(_opts, args)
    raise 'Exactly two arguments required' unless args.size == 2
    master = Judges::Impex.new(@loog, args[0])
    slave = Judges::Impex.new(@loog, args[1])
    elapsed(@loog, level: Logger::INFO) do
      fb = master.import
      slave.import_to(fb)
      master.export(fb)
      throw :'👍 Two factbases joined successfully'
    end
  end
end
