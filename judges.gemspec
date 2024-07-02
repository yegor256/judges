# frozen_string_literal: true

# Copyright (c) 2024 Yegor Bugayenko
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the 'Software'), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED 'AS IS', WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

require 'English'

Gem::Specification.new do |s|
  s.required_rubygems_version = Gem::Requirement.new('>= 0') if s.respond_to? :required_rubygems_version=
  s.required_ruby_version = '>=3.2'
  s.name = 'judges'
  s.version = '0.14.0'
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
  s.homepage = 'http://github.com/yegor256/judges'
  s.files = `git ls-files`.split($RS)
  s.executables = s.files.grep(%r{^bin/}) { |f| File.basename(f) }
  s.rdoc_options = ['--charset=UTF-8']
  s.extra_rdoc_files = ['README.md', 'LICENSE.txt']
  s.add_runtime_dependency 'backtrace', '~>0.3'
  s.add_runtime_dependency 'concurrent-ruby', '~>1.2'
  s.add_runtime_dependency 'factbase', '~>0.0'
  s.add_runtime_dependency 'gli', '~>2.21'
  s.add_runtime_dependency 'iri', '~>0.8'
  s.add_runtime_dependency 'loog', '~>0.2'
  s.add_runtime_dependency 'moments', '~>0.3'
  s.add_runtime_dependency 'nokogiri', '~>1.10'
  s.add_runtime_dependency 'others', '~>0.0'
  s.add_runtime_dependency 'retries', '~>0.0'
  s.add_runtime_dependency 'tago', '~>0.0'
  s.add_runtime_dependency 'typhoeus', '~>1.3'
  s.metadata['rubygems_mfa_required'] = 'true'
end
