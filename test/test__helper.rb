# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2025 Yegor Bugayenko
# SPDX-License-Identifier: MIT

$stdout.sync = true

require 'simplecov'
require 'simplecov-cobertura'
unless SimpleCov.running
  # Custom formatter
  class MyFormatter
    def format(result)
      puts 'Coverage:'
      result.files.sort_by(&:filename).each do |file|
        per = file.covered_percent
        # rubocop:disable Style/FormatStringToken
        puts Kernel.format(
          '%40s %7.2f%% %s',
          File.basename(file.filename),
          per, (' (!)' if per < 80)
        )
        # rubocop:enable Style/FormatStringToken
      end
    end
  end
  SimpleCov.command_name('test')
  SimpleCov.formatter = SimpleCov::Formatter::MultiFormatter.new(
    [
      SimpleCov::Formatter::HTMLFormatter,
      SimpleCov::Formatter::CoberturaFormatter,
      MyFormatter
    ]
  )
  SimpleCov.minimum_coverage 90
  SimpleCov.minimum_coverage_by_file 80
  SimpleCov.start do
    add_filter 'test/'
    add_filter 'vendor/'
    add_filter 'target/'
    track_files 'lib/**/*.rb'
    track_files '*.rb'
  end
end

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
