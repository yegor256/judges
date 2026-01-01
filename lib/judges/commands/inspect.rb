# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require 'factbase/fact_as_yaml'
require_relative '../../judges'
require_relative '../../judges/impex'

# The +inspect+ command.
#
# This class is instantiated by the +bin/judge+ command line interface. You
# are not supposed to instantiate it yourself.
#
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2024-2026 Yegor Bugayenko
# License:: MIT
class Judges::Inspect
  # Initialize.
  # @param [Loog] loog Logging facility
  def initialize(loog)
    @loog = loog
  end

  # Run the inspect command (called by the +bin/judges+ script).
  # @param [Hash] _opts Command line options (not used)
  # @param [Array] args List of command line arguments
  # @raise [RuntimeError] If no arguments provided
  def run(_opts, args)
    raise 'At least one argument required' if args.empty?
    fb = Judges::Impex.new(@loog, args[0]).import
    @loog.info("Facts: #{fb.size}")
    sum = fb.query('(eq what "judges-summary")').each.to_a
    if sum.empty?
      @loog.info('Summary fact not found')
    else
      @loog.info("Summary fact found:\n\t#{Factbase::FactAsYaml.new(sum.first).to_s.gsub("\n", "\n\t")}")
    end
  end
end
