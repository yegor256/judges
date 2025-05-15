# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2025 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require 'factbase'
require 'fileutils'
require 'elapsed'
require_relative '../judges'
require_relative '../judges/to_rel'

# Import/Export of factbases.
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2024-2025 Yegor Bugayenko
# License:: MIT
class Judges::Impex
  # Initialize.
  # @param [Loog] loog Logging facility
  # @param [String] file File path for import/export operations
  def initialize(loog, file)
    @loog = loog
    @file = file
  end

  # Import factbase from file.
  # @param [Boolean] strict Whether to raise error if file doesn't exist
  # @return [Factbase] The imported factbase
  def import(strict: true)
    fb = Factbase.new
    if File.exist?(@file)
      elapsed(@loog, level: Logger::INFO) do
        fb.import(File.binread(@file))
        throw :"The factbase imported from #{@file.to_rel} (#{File.size(@file)} bytes, #{fb.size} facts)"
      end
    else
      raise "The factbase is absent at #{@file.to_rel}" if strict
      @loog.info("Nothing to import from #{@file.to_rel} (file not found)")
    end
    fb
  end

  # Import factbase from file into existing factbase.
  # @param [Factbase] fb The factbase to import into
  # @raise [RuntimeError] If file doesn't exist
  def import_to(fb)
    raise "The factbase is absent at #{@file.to_rel}" unless File.exist?(@file)
    elapsed(@loog, level: Logger::INFO) do
      fb.import(File.binread(@file))
      throw :"The factbase loaded from #{@file.to_rel} (#{File.size(@file)} bytes, #{fb.size} facts)"
    end
  end

  # Export factbase to file.
  # @param [Factbase] fb The factbase to export
  def export(fb)
    elapsed(@loog, level: Logger::INFO) do
      FileUtils.mkdir_p(File.dirname(@file))
      File.binwrite(@file, fb.export)
      throw :"Factbase exported to #{@file.to_rel} (#{File.size(@file)} bytes, #{fb.size} facts)"
    end
  end
end
