# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2025 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require 'qbash'
require 'rubygems'
require 'rake'
require 'rdoc'
require 'rake/clean'
require 'shellwords'

def name
  @name ||= File.basename(Dir['*.gemspec'].first, '.*')
end

def version
  Gem::Specification.load(Dir['*.gemspec'].first).version
end

ENV['RACK_ENV'] = 'test'

task default: %i[clean test features picks reqs rubocop yard]

require 'rake/testtask'
desc 'Run all unit tests'
Rake::TestTask.new(:test) do |test|
  Rake::Cleaner.cleanup_files(['coverage'])
  test.libs << 'lib' << 'test'
  test.pattern = 'test/**/test_*.rb'
  test.warning = true
  test.verbose = false
end

desc 'Run them via Ruby, one by one'
task :picks do
  Dir['test/**/*.rb'].each do |f|
    qbash("bundle exec ruby #{Shellwords.escape(f)}", log: $stdout)
  end
end

desc 'Require them via Ruby, one by one'
task :reqs do
  Dir['lib/**/*.rb'].each do |f|
    qbash("bundle exec ruby #{Shellwords.escape(f)}", log: $stdout)
  end
end

require 'cucumber/rake/task'
Cucumber::Rake::Task.new(:features) do |t|
  Rake::Cleaner.cleanup_files(['coverage'])
  t.cucumber_opts = %w[--no-color --retry=2 --fail-fast --backtrace --order=random]
end
Cucumber::Rake::Task.new(:'features:html') do |t|
  t.profile = 'html_report'
end

require 'yard'
desc 'Build Yard documentation'
YARD::Rake::YardocTask.new do |t|
  t.files = ['lib/**/*.rb']
end

require 'rubocop/rake_task'
desc 'Run RuboCop on all directories'
RuboCop::RakeTask.new(:rubocop) do |task|
  task.fail_on_error = true
end
