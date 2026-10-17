# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative '../lib/judges/masked_args'
require_relative 'test__helper'

# Test.
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2024-2026 Yegor Bugayenko
# License:: MIT
class TestMaskedArgs < Minitest::Test
  def test_hides_a_token_glued_to_the_option
    line = Judges::MaskedArgs.new(%w[push --token=SUPERSECRET123 zzz]).to_s
    refute_includes(line, 'SUPERSECRET123', line)
    assert_equal('push --token\=SUPE\*\*\*\*\*\*T123 zzz', line)
  end

  def test_hides_a_token_that_follows_the_option
    line = Judges::MaskedArgs.new(['push', '--token', 'SUPERSECRET123', 'zzz']).to_s
    refute_includes(line, 'SUPERSECRET123', line)
    assert_equal('push --token SUPE\*\*\*\*\*\*T123 zzz', line)
  end

  def test_hides_a_short_token_entirely
    assert_equal('--token \*\*\*\*\*\*', Judges::MaskedArgs.new(['--token', 'abcdef']).to_s)
  end

  def test_hides_a_token_inside_an_option
    line = Judges::MaskedArgs.new(%w[update --option=github_token=ghp_SUPERSECRET123]).to_s
    refute_includes(line, 'ghp_SUPERSECRET123', line)
    assert_equal('update --option\=github_token\=ghp_\*\*\*\*\*\*\*\*\*\*T123', line)
  end

  def test_hides_a_token_inside_an_option_that_follows
    line = Judges::MaskedArgs.new(['update', '--option', 'zerocracy_token=ZRCY-SUPERSECRET']).to_s
    refute_includes(line, 'ZRCY-SUPERSECRET', line)
    assert_equal('update --option zerocracy_token\=ZRCY\*\*\*\*\*\*\*\*CRET', line)
  end

  def test_hides_a_token_after_the_short_option
    line = Judges::MaskedArgs.new(['update', '-o', 'github_token=ghp_SUPERSECRET123']).to_s
    refute_includes(line, 'ghp_SUPERSECRET123', line)
  end

  def test_hides_secrets_by_other_names
    %w[secret password key].each do |name|
      line = Judges::MaskedArgs.new(["--option=my_#{name}=SUPERSECRET123"]).to_s
      refute_includes(line, 'SUPERSECRET123', line)
    end
  end

  def test_keeps_an_option_that_is_not_a_secret
    assert_equal(
      'update --option\=repositories\=zerocracy/fbe',
      Judges::MaskedArgs.new(%w[update --option=repositories=zerocracy/fbe]).to_s
    )
  end

  def test_keeps_everything_else
    assert_equal('update --quiet a b', Judges::MaskedArgs.new(%w[update --quiet a b]).to_s)
  end

  def test_refuses_nil_args
    assert_includes(assert_raises(ArgumentError) { Judges::MaskedArgs.new(nil) }.message, 'The args are nil')
  end

  def test_escapes_arguments_with_spaces
    assert_equal('eval my\ file.fb', Judges::MaskedArgs.new(['eval', 'my file.fb']).to_s)
  end

  def test_escapes_arguments_with_dollar_signs
    assert_equal('eval \$foo', Judges::MaskedArgs.new(['eval', '$foo']).to_s)
  end

  def test_escapes_arguments_with_parentheses
    assert_equal('print \(eq\ a\ 1\)', Judges::MaskedArgs.new(['print', '(eq a 1)']).to_s)
  end

  def test_escapes_arguments_with_double_quotes
    assert_equal(
      'print --query \(eq\ what\ \"x\"\)',
      Judges::MaskedArgs.new(['print', '--query', '(eq what "x")']).to_s
    )
  end

  def test_escapes_arguments_with_single_quotes
    assert_equal("eval foo\\'bar", Judges::MaskedArgs.new(['eval', "foo'bar"]).to_s)
  end

  def test_escapes_empty_argument
    assert_equal("run ''", Judges::MaskedArgs.new(['run', '']).to_s)
  end

  def test_escapes_complex_arguments_from_issue
    assert_equal(
      'eval my\ file.fb \$fb.insert.a\ \=\ \%q\(x\ y\)',
      Judges::MaskedArgs.new(['eval', 'my file.fb', '$fb.insert.a = %q(x y)']).to_s
    )
  end

  def test_escapes_option_values_with_spaces
    assert_equal('-o message\=hello\ world', Judges::MaskedArgs.new(['-o', 'message=hello world']).to_s)
  end

  def test_escapes_and_masks_token_with_spaces
    line = Judges::MaskedArgs.new(['--token', 'secret with spaces!']).to_s
    refute_includes(line, 'with', line)
    assert_equal('--token secr\*\*\*\*\*\*\*\*\*\*\*ces\!', line)
  end
end
