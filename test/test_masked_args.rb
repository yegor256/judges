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
    assert_equal('push --token=SUPE******T123 zzz', line)
  end

  def test_hides_a_token_that_follows_the_option
    line = Judges::MaskedArgs.new(['push', '--token', 'SUPERSECRET123', 'zzz']).to_s
    refute_includes(line, 'SUPERSECRET123', line)
    assert_equal('push --token SUPE******T123 zzz', line)
  end

  def test_hides_a_short_token_entirely
    assert_equal('--token ******', Judges::MaskedArgs.new(['--token', 'abcdef']).to_s)
  end

  def test_hides_a_token_inside_an_option
    line = Judges::MaskedArgs.new(%w[update --option=github_token=ghp_SUPERSECRET123]).to_s
    refute_includes(line, 'ghp_SUPERSECRET123', line)
    assert_equal('update --option=github_token=ghp_**********T123', line)
  end

  def test_hides_a_token_inside_an_option_that_follows
    line = Judges::MaskedArgs.new(['update', '--option', 'zerocracy_token=ZRCY-SUPERSECRET']).to_s
    refute_includes(line, 'ZRCY-SUPERSECRET', line)
    assert_equal('update --option zerocracy_token=ZRCY********CRET', line)
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

  def test_hides_an_upper_case_token_inside_an_option
    line = Judges::MaskedArgs.new(%w[update --option=GITHUB_TOKEN=ghp_abcdef1234567890]).to_s
    refute_includes(line, 'ghp_abcdef1234567890', line)
    assert_equal('update --option=GITHUB_TOKEN=ghp_************7890', line)
  end

  def test_hides_a_mixed_case_key_after_short_option
    line = Judges::MaskedArgs.new(['update', '-o', 'Api_Key=sk-0123456789abcdef']).to_s
    refute_includes(line, 'sk-0123456789abcdef', line)
    assert_equal('update -o Api_Key=sk-0***********cdef', line)
  end

  def test_hides_an_upper_case_following_secret
    line = Judges::MaskedArgs.new(['update', '--option', 'DB_PASSWORD=SUPERSECRET123']).to_s
    refute_includes(line, 'SUPERSECRET123', line)
  end

  def test_hides_a_capitalized_secret_inside_an_option
    line = Judges::MaskedArgs.new(%w[--option=My_Secret=SUPERSECRET123]).to_s
    refute_includes(line, 'SUPERSECRET123', line)
    assert_equal('--option=My_Secret=SUPE******T123', line)
  end

  def test_keeps_an_upper_case_plain_option
    assert_equal(
      'update --option=REPOSITORIES=zerocracy/fbe',
      Judges::MaskedArgs.new(%w[update --option=REPOSITORIES=zerocracy/fbe]).to_s
    )
  end

  def test_keeps_an_option_that_is_not_a_secret
    assert_equal(
      'update --option=repositories=zerocracy/fbe',
      Judges::MaskedArgs.new(%w[update --option=repositories=zerocracy/fbe]).to_s
    )
  end

  def test_keeps_everything_else
    assert_equal('update --quiet a b', Judges::MaskedArgs.new(%w[update --quiet a b]).to_s)
  end

  def test_refuses_nil_args
    assert_includes(assert_raises(ArgumentError) { Judges::MaskedArgs.new(nil) }.message, 'The args are nil')
  end
end
