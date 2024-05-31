# Judges

[![DevOps By Rultor.com](http://www.rultor.com/b/yegor256/judges)](http://www.rultor.com/p/yegor256/judges)
[![We recommend RubyMine](https://www.elegantobjects.org/rubymine.svg)](https://www.jetbrains.com/ruby/)

[![rake](https://github.com/yegor256/judges/actions/workflows/rake.yml/badge.svg)](https://github.com/yegor256/judges/actions/workflows/rake.yml)
[![PDD status](http://www.0pdd.com/svg?name=yegor256/judges)](http://www.0pdd.com/p?name=yegor256/judges)
[![Gem Version](https://badge.fury.io/rb/judges.svg)](http://badge.fury.io/rb/judges)
[![Test Coverage](https://img.shields.io/codecov/c/github/yegor256/judges.svg)](https://codecov.io/github/yegor256/judges?branch=master)
[![Yard Docs](http://img.shields.io/badge/yard-docs-blue.svg)](http://rubydoc.info/github/yegor256/judges/master/frames)
[![Hits-of-Code](https://hitsofcode.com/github/yegor256/judges)](https://hitsofcode.com/view/github/yegor256/judges)
[![License](https://img.shields.io/badge/license-MIT-green.svg)](https://github.com/yegor256/judges/blob/master/LICENSE.txt)

A command line tool and a Ruby gem for running judges agains a
[factbase](https://github.com/yegor256/factbase).

Every "judge" is a directory with a single `.rb` file and a number
of `.yml` files. A script in the Ruby file is executed with the following
global variables available to it:

* `$fb` — an instance
  of [`Factbase`](https://www.rubydoc.info/gems/factbase/0.0.22/Factbase),
  where facts may be added/updated;
* `$loog` — an instance
  of [`Loog`](https://www.rubydoc.info/gems/loog/0.5.1/Loog),
  where `.info` and `.debug` logs are welcome;
* `$options` — a holder of options coming from `.yml` files;
* `$local` — a hash map that is cleaned up when the execution of
  a judge is finished;
* `$global` — a hash map that is never cleaned up;
* `$judge` — the name of the directory, where the `.rb` script is located.

Every `.yml` file must be formatted as such:

```yaml
input:
  -
    foo: 42
    bar: Hello, world!
options:
  max: 100
expected:
  - /fb[count(f)=1]
```

Here, the `input` is an array of facts to be placed into the Factbase before
the test starts; the `options` is a hash map of options to be passed
via command line `--option` of the `update` command; and `expected` is
an array of XPath expressions that must be present in the XML of the Factbase
when the test is finished.

## How to contribute

Read
[these guidelines](https://www.yegor256.com/2014/04/15/github-guidelines.html).
Make sure you build is green before you contribute
your pull request. You will need to have
[Ruby](https://www.ruby-lang.org/en/) 2.3+ and
[Bundler](https://bundler.io/) installed. Then:

```bash
bundle update
bundle exec rake
```

If it's clean and you don't see any error messages, submit your pull request.
