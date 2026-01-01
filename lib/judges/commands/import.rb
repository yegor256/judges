# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require 'elapsed'
require 'time'
require_relative '../../judges'
require_relative '../../judges/impex'
require_relative '../../judges/to_rel'

# The +import+ command.
#
# This class is instantiated by the +bin/judge+ command line interface. You
# are not supposed to instantiate it yourself.
#
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2024-2026 Yegor Bugayenko
# License:: MIT
class Judges::Import
  # Initialize.
  # @param [Loog] loog Logging facility
  def initialize(loog)
    @loog = loog
  end

  # Run the import command (called by the +bin/judges+ script).
  # @param [Hash] opts Command line options (start with '--')
  # @param [Array] args List of command line arguments
  # @raise [RuntimeError] If not exactly two arguments provided or file not found
  def run(opts, args)
    raise 'Exactly two arguments required' unless args.size == 2
    raise "File not found #{args[0].to_rel}" unless File.exist?(args[0])
    elapsed(@loog, level: Logger::INFO) do
      yaml = YAML.load_file(args[0], permitted_classes: [Time])
      @loog.info("YAML loaded from #{args[0].to_rel} (#{yaml.size} facts)")
      impex = Judges::Impex.new(@loog, args[1])
      fb = impex.import(strict: false)
      if opts['log']
        require 'factbase/logged'
        fb = Factbase::Logged.new(fb, @loog)
      end
      yaml.each do |i|
        f = fb.insert
        i.each do |p, v|
          f.send(:"#{p}=", v)
        end
      end
      impex.export(fb)
      throw :"👍 Import of #{yaml.size} facts completed"
    end
  end
end
