# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2025 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require 'factbase'
require 'fileutils'
require 'elapsed'
require_relative '../judges'
require_relative '../judges/to_rel'

# Import/Export of factbases.
#
# This class provides functionality for importing and exporting Factbase
# objects to and from binary files. It handles file I/O operations with
# proper logging and error handling.
#
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2024-2025 Yegor Bugayenko
# License:: MIT
class Judges::Impex
  # Initialize a new Impex instance.
  #
  # @param [Loog] loog Logging facility for recording import/export operations
  # @param [String] file File path for import/export operations
  # @example Create an Impex instance
  #   impex = Judges::Impex.new(logger, '/path/to/factbase.fb')
  def initialize(loog, file)
    @loog = loog
    @file = file
  end

  # Import factbase from file.
  #
  # Creates a new Factbase instance and imports data from the file specified
  # during initialization. The operation is timed and logged. If the file
  # doesn't exist, behavior depends on the strict parameter.
  #
  # @param [Boolean] strict Whether to raise error if file doesn't exist.
  #   When true (default), raises an error if file is missing.
  #   When false, logs a message and returns an empty factbase.
  # @return [Factbase] The imported factbase, or empty factbase if file
  #   doesn't exist and strict is false
  # @raise [RuntimeError] If file doesn't exist and strict is true
  # @example Import with strict mode (default)
  #   fb = impex.import # Raises error if file missing
  # @example Import with non-strict mode
  #   fb = impex.import(strict: false) # Returns empty factbase if file missing
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
  #
  # Imports data from the file into an existing Factbase instance rather
  # than creating a new one. This is useful when you need to merge data
  # into an already populated factbase. The operation is timed and logged.
  #
  # @param [Factbase] fb The factbase to import into. The imported data
  #   will be added to this existing factbase.
  # @raise [RuntimeError] If file doesn't exist
  # @example Import into existing factbase
  #   fb = Factbase.new
  #   # ... populate fb with some data ...
  #   impex.import_to(fb) # Adds data from file to existing facts
  def import_to(fb)
    raise "The factbase is absent at #{@file.to_rel}" unless File.exist?(@file)
    elapsed(@loog, level: Logger::INFO) do
      fb.import(File.binread(@file))
      throw :"The factbase loaded from #{@file.to_rel} (#{File.size(@file)} bytes, #{fb.size} facts)"
    end
  end

  # Export factbase to file.
  #
  # Exports the given Factbase instance to the file specified during
  # initialization. Creates any necessary parent directories automatically.
  # The operation is timed and logged with file size and fact count information.
  #
  # @param [Factbase] fb The factbase to export. All facts in this factbase
  #   will be serialized to the binary file format.
  # @example Export a factbase
  #   fb = Factbase.new
  #   # ... add facts to fb ...
  #   impex.export(fb) # Saves to file specified in constructor
  def export(fb)
    elapsed(@loog, level: Logger::INFO) do
      FileUtils.mkdir_p(File.dirname(@file))
      File.binwrite(@file, fb.export)
      throw :"Factbase exported to #{@file.to_rel} (#{File.size(@file)} bytes, #{fb.size} facts)"
    end
  end
end
