# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2025 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require 'tmpdir'
require 'English'
require 'securerandom'

Before do
  @cwd = Dir.pwd
end

After do
  unless @tmp.nil?
    Dir.chdir(@cwd)
    FileUtils.rm_rf(@tmp)
  end
end

Given(/^We are online$/) do
  TCPSocket.new('google.com', 80)
rescue SocketError
  pending
end

Given(/^I make a temp directory$/) do
  @tmp = Dir.mktmpdir('test')
  FileUtils.mkdir_p(@tmp)
  Dir.chdir(@tmp)
end

Given(/^I have a "([^"]*)" file with content:$/) do |file, text|
  FileUtils.mkdir_p(File.dirname(file)) unless File.exist?(file)
  File.write(file, text.gsub('\\xFF', 0xFF.chr))
end

When(%r{^I run bin/judges with "([^"]*)"$}) do |arg|
  home = File.join(File.dirname(__FILE__), '../..')
  arg.gsub!('{FAKE-NAME}') { "fake#{SecureRandom.hex(8)}" }
  cmd = "ruby -I#{home}/lib #{home}/bin/judges #{arg}"
  cmd = "GLI_DEBUG=true #{cmd}" unless Gem.win_platform?
  @stdout = `#{cmd} 2>&1`
  @exitstatus = $CHILD_STATUS.exitstatus
end

When(/^I run bash with "([^"]*)"$/) do |text|
  FileUtils.copy_entry(@cwd, File.join(@tmp, 'judges'))
  @stdout = `#{text}`
  @exitstatus = $CHILD_STATUS.exitstatus
end

When(/^I run bash with:$/) do |text|
  FileUtils.copy_entry(@cwd, File.join(@tmp, 'judges'))
  @stdout = `#{text}`
  @exitstatus = $CHILD_STATUS.exitstatus
end

Then(/^Stdout contains "([^"]*)"$/) do |txt|
  raise "STDOUT doesn't contain '#{txt}':\n#{@stdout}" unless @stdout.include?(txt)
end

Then(/^Stdout is empty$/) do
  raise "STDOUT is not empty:\n#{@stdout}" unless @stdout == ''
end

Then(/^Exit code is zero$/) do
  raise "Non-zero exit #{@exitstatus}:\n#{@stdout}" unless @exitstatus.zero?
end

Then(/^Exit code is not zero$/) do
  raise 'Zero exit code' if @exitstatus.zero?
end
