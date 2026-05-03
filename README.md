# Judges over a Factbase Executor

[![DevOps By Rultor.com](https://www.rultor.com/b/yegor256/judges)](https://www.rultor.com/p/yegor256/judges)
[![We recommend RubyMine](https://www.elegantobjects.org/rubymine.svg)](https://www.jetbrains.com/ruby/)

[![rake](https://github.com/yegor256/judges/actions/workflows/rake.yml/badge.svg)](https://github.com/yegor256/judges/actions/workflows/rake.yml)
[![PDD status](https://www.0pdd.com/svg?name=yegor256/judges)](https://www.0pdd.com/p?name=yegor256/judges)
[![Gem Version](https://badge.fury.io/rb/judges.svg)](https://badge.fury.io/rb/judges)
[![Test Coverage](https://img.shields.io/codecov/c/github/yegor256/judges.svg)](https://codecov.io/github/yegor256/judges?branch=master)
[![Yard Docs](https://img.shields.io/badge/yard-docs-blue.svg)](https://rubydoc.info/github/yegor256/judges/master/frames)
[![Hits-of-Code](https://hitsofcode.com/github/yegor256/judges)](https://hitsofcode.com/view/github/yegor256/judges)
[![License](https://img.shields.io/badge/license-MIT-green.svg)](https://github.com/yegor256/judges/blob/master/LICENSE.txt)
[![FOSSA Status](https://app.fossa.com/api/projects/git%2Bgithub.com%2Fyegor256%2Fjudges.svg?type=shield&issueType=license)](https://app.fossa.com/projects/git%2Bgithub.com%2Fyegor256%2Fjudges?ref=badge_shield&issueType=license)

A command line tool and a Ruby gem for running so-called judges against a
[factbase](https://github.com/yegor256/factbase).

Every "judge" is a directory with a single `.rb` file and a number
of `.yml` files. A script in the Ruby file is executed with the following
global variables available to it:

* `$fb` — an instance
  of [Factbase](https://www.rubydoc.info/gems/factbase/0.0.22/Factbase),
  where facts may be added/updated;
* `$loog` — an instance
  of [Loog](https://www.rubydoc.info/gems/loog/0.5.1/Loog),
  where `.info` and `.debug` logs are welcome;
* `$options` — a holder of options coming from either the `--option` command
  line flag or the `.yml` file during testing;
* `$local` — a hash map that is cleaned up when the execution of
  a judge is finished;
* `$global` — a hash map that is never cleaned up;
* `$judge` — the basename of the directory, where the `.rb` script is located;
* `$epoch` — the time moment when the plugin was started;
* `$kickoff` — the time moment when a judge was started.

Every `.yml` file must be formatted as such:

```yaml
before:
  - abc
category: slow
runs: 1
skip: false
repeat: 20
input:
  -
    foo: 42
    bar: Hello, world!
    many: [1, 2, -10]
options:
  max: 100
expected:
  - /fb[count(f)=1]
expected_failure:
  - 'file not found'
after:
  - first.rb
  - second.rb
```

Here, the `input` is an array of facts to be placed into the Factbase before
the test starts; the `options` is a hash map of options as if they are passed
via the command line `--option` flag of the `update` command; and `expected` is
an array of XPath expressions that must be present in the XML of the Factbase
when the test is finished.

The `category` (default: `[]`) may have one category or an array of categories,
which then may be turned on via the `--category` command line flag.

The `repeat` (default: `1`) makes the `input` to be repeated multiple times
(mostly useful for speed measuring on big data inputs).

The `runs` (default: `1`) is the number of times the `.rb` script should
be executed. After each execution, all expected XPath expressions are validated.

The `before` (default: `[]`) is a list of judges that must be executed before
the current one.

The `after` (default: `[]`) is a list of relative file names
of Ruby scripts that are executed after the judge
(`$fb` and `$loog` are passed into them).

The `expected_failure` (default: `[]`) is a list of strings that must
be present in the message of the exception being raised.

## Architecture

The core data structure is a
  [Factbase](https://github.com/yegor256/factbase) — a flat, schemaless,
  binary-serialized collection of facts (records with named attributes)
  held in memory during a run. Facts are queried via
  [XPath](https://www.w3.org/TR/xpath/) expressions rather than SQL.
  There is no schema to migrate, no ORM layer, and no database process
  to manage. The factbase binary file is read at the start of each
  `update` run and written back on exit, making state portable and
  inspectable via `judges print`. This differs from tools such as
  [Sidekiq](https://sidekiq.org/) or
  [ActiveJob](https://guides.rubyonrails.org/active_job_basics.html),
  which depend on an external database or message broker.

Each judge is a single `.rb` Ruby file in its own directory. It is
  not a class, a module, or a Rake task — it is a plain script loaded
  with Ruby's `load(file, true)`, which wraps it in an anonymous module
  and prevents constants in one judge from leaking into another. All
  context is injected as Ruby global variables: `$fb` (the factbase),
  `$loog` (logging), `$options` (configuration), `$global` (shared
  across all judges in a run), and `$local` (reset after each judge).
  A new judge author needs to know only those variables; there is no
  base class to inherit and no interface contract to satisfy.

The `update` command runs all judges in repeated cycles until the
  factbase stops changing (zero churn) or until the `--max-cycles` or
  `--lifetime` limit is reached. This fixed-point convergence model is
  analogous to [Datalog](https://en.wikipedia.org/wiki/Datalog): a
  judge that inserts a fact in one cycle may trigger a different judge
  in the next cycle, without any explicit dependency declaration.
  Pipeline tools such as
  [Apache Airflow](https://airflow.apache.org/) or
  [GitHub Actions](https://docs.github.com/en/actions) require a
  directed acyclic graph defined upfront; judges require none.

Every judge directory contains `.yml` test files alongside its `.rb`
  script. A YAML file declares the initial facts (`input`), the count
  of judge executions (`runs`), prerequisite judges (`before`),
  post-condition scripts (`after`), and
  [XPath](https://www.w3.org/TR/xpath/) assertions the factbase must
  satisfy when the judge finishes (`expected`). Running `judges test`
  creates a fresh, in-memory factbase per test case. Co-locating tests
  with the script keeps each judge directory self-contained: one
  directory holds both the deliverable and its verification.

The `push` and `pull` commands exchange the binary factbase with a
  remote [Baza](https://github.com/yegor256/baza.rb) server via a
  named-lock protocol. `pull` acquires the lock and downloads the
  file; `push` uploads the modified file and releases the lock. This
  lets distributed CI pipelines share a single evolving factbase
  across multiple jobs without running a database: each job pulls,
  runs `update` locally, and pushes back.

## How to contribute

Read
[these guidelines](https://www.yegor256.com/2014/04/15/github-guidelines.html).
Make sure your build is green before you contribute
your pull request. You will need to have
[Ruby](https://www.ruby-lang.org/en/) 3.0+,
[Bundler](https://bundler.io/), and
[Tidy](https://www.html-tidy.org/) installed. Then:

```bash
bundle update
bundle exec rake
```

If it's clean and you don't see any error messages, submit your pull request.
