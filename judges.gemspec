# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2025 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require 'English'

Gem::Specification.new do |s|
  s.required_rubygems_version = Gem::Requirement.new('>= 0') if s.respond_to? :required_rubygems_version=
  s.required_ruby_version = '>=3.2'
  s.name = 'judges'
  s.version = '0.53.0'
  s.license = 'MIT'
  s.summary = 'Command-Line Tool for a Factbase'
  s.description =
    'A command-line tool that runs a collection of \"judges\" ' \
    'against a \"factbase,\" modifying ' \
    'it and updating. Also, helps printing a factbase, merge with ' \
    'another one, inspect, and so on. Also, helps run automated tests ' \
    'for a set of judges.'
  s.authors = ['Yegor Bugayenko']
  s.email = 'yegor256@gmail.com'
  s.homepage = 'https://github.com/yegor256/judges'
  s.files = `git ls-files`.split($RS)
  s.executables = s.files.grep(%r{^bin/}) { |f| File.basename(f) }
  s.rdoc_options = ['--charset=UTF-8']
  s.extra_rdoc_files = ['README.md', 'LICENSE.txt']
  s.add_dependency 'backtrace', '~>0.4'
  s.add_dependency 'baza.rb', '~>0.5'
  s.add_dependency 'concurrent-ruby', '~>1.2'
  s.add_dependency 'elapsed', '~>0.0'
  s.add_dependency 'factbase', '~>0.11'
  s.add_dependency 'gli', '~>2.21'
  s.add_dependency 'iri', '~>0.11'
  s.add_dependency 'loog', '~>0.6'
  s.add_dependency 'moments', '~>0.3'
  s.add_dependency 'nokogiri', '~>1.10'
  s.add_dependency 'others', '~>0.0'
  s.add_dependency 'retries', '~>0.0'
  s.add_dependency 'tago', '~>0.1'
  s.add_dependency 'timeout', '~>0.4'
  s.add_dependency 'total', '~>0.4'
  s.add_dependency 'typhoeus', '~>1.3'
  s.metadata['rubygems_mfa_required'] = 'true'
end
