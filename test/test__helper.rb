# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2025 Yegor Bugayenko
# SPDX-License-Identifier: MIT

$stdout.sync = true

require 'simplecov'
SimpleCov.start

require 'simplecov-cobertura'
SimpleCov.formatter = SimpleCov::Formatter::CoberturaFormatter

require 'minitest/autorun'

require 'minitest/reporters'
Minitest::Reporters.use! [Minitest::Reporters::SpecReporter.new]

# To make tests retry on failure:
if ENV['RACK_RUN']
  require 'minitest/retry'
  Minitest::Retry.use!
end

class Minitest::Test
  def save_it(file, content)
    require 'fileutils'
    FileUtils.mkdir_p(File.dirname(file))
    File.binwrite(file, content)
  end
end
