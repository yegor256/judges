# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require 'os'
require 'qbash'
require 'rake'
require 'rake/clean'
require 'rubygems'
require 'shellwords'

def name
  @name ||= File.basename(Dir['*.gemspec'].first, '.*')
end

def version
  Gem::Specification.load(Dir['*.gemspec'].first).version
end

ENV['RACK_ENV'] = 'test'

task default: %i[clean test features picks rubocop yard]

desc 'Delete the coverage report of the previous run'
task :uncover do
  Rake::Cleaner.cleanup_files(['coverage'])
end

require 'rake/testtask'
desc 'Run all unit tests'
Rake::TestTask.new(test: :uncover) do |test|
  test.libs << 'lib' << 'test'
  test.pattern = 'test/**/test_*.rb'
  test.warning = true
  test.verbose = false
end

desc 'Run them via Ruby, one by one'
task :picks do
  next if OS.windows?
  %w[test lib].each do |d|
    Dir["#{d}/**/*.rb"].each do |f|
      qbash("bundle exec ruby #{Shellwords.escape(f)}", stdout: $stdout, env: { 'PICKS' => 'yes' })
    end
  end
end

require 'cucumber/rake/task'
Cucumber::Rake::Task.new(features: :uncover) do |t|
  t.cucumber_opts = %w[--no-color --retry=2 --fail-fast --backtrace --order=random]
end
Cucumber::Rake::Task.new(:'features:html') do |t|
  t.profile = 'html_report'
end

require 'yard'
desc 'Build Yard documentation'
YARD::Rake::YardocTask.new do |t|
  t.files = ['lib/**/*.rb']
  t.options = ['--fail-on-warning']
end

require 'rubocop/rake_task'
desc 'Run RuboCop on all directories'
RuboCop::RakeTask.new(:rubocop) do |task|
  task.fail_on_error = true
end
