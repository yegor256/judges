# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2025 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require 'time'
require 'elapsed'
require_relative '../../judges'
require_relative '../../judges/impex'

# The +trim+ command.
#
# This class is instantiated by the +bin/judge+ command line interface. You
# are not supposed to instantiate it yourself.
#
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2024-2025 Yegor Bugayenko
# License:: MIT
class Judges::Trim
  def initialize(loog)
    @loog = loog
  end

  # Run it (it is supposed to be called by the +bin/judges+ script.
  # @param [Hash] opts Command line options (start with '--')
  # @param [Array] args List of command line arguments
  def run(opts, args)
    raise 'Exactly one argument required' unless args.size == 1
    impex = Judges::Impex.new(@loog, args[0])
    fb = impex.import
    elapsed(@loog, level: Logger::INFO) do
      deleted = fb.query(opts['query']).delete!
      throw :'No facts deleted' if deleted.zero?
      impex.export(fb)
      throw :"🗑 #{deleted} fact(s) deleted"
    end
  end
end
