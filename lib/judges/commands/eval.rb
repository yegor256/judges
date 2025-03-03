# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2025 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require 'elapsed'
require_relative '../../judges'
require_relative '../../judges/impex'

# The +eval+ command.
#
# This class is instantiated by the +bin/judge+ command line interface. You
# are not supposed to instantiate it yourself.
#
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2024-2025 Yegor Bugayenko
# License:: MIT
class Judges::Eval
  def initialize(loog)
    @loog = loog
  end

  def run(opts, args)
    raise 'Exactly two arguments required' unless args.size == 2
    impex = Judges::Impex.new(@loog, args[0])
    elapsed(@loog, level: Logger::INFO) do
      $fb = impex.import(strict: false)
      if opts['log']
        require 'factbase/logged'
        $fb = Factbase::Logged.new($fb, @loog)
      end
      expr = args[1]
      # rubocop:disable Security/Eval
      eval(expr)
      # rubocop:enable Security/Eval
      impex.export($fb)
      throw :'Evaluated successfully'
    end
  end
end
