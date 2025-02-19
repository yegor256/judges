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
  def initialize(loog, file)
    @loog = loog
    @file = file
  end

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

  def import_to(fb)
    raise "The factbase is absent at #{@file.to_rel}" unless File.exist?(@file)
    elapsed(@loog, level: Logger::INFO) do
      fb.import(File.binread(@file))
      throw :"The factbase loaded from #{@file.to_rel} (#{File.size(@file)} bytes, #{fb.size} facts)"
    end
  end

  def export(fb)
    elapsed(@loog, level: Logger::INFO) do
      FileUtils.mkdir_p(File.dirname(@file))
      File.binwrite(@file, fb.export)
      throw :"Factbase exported to #{@file.to_rel} (#{File.size(@file)} bytes, #{fb.size} facts)"
    end
  end
end
