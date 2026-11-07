# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative 'test__helper'

# Tests that the stylesheet keeps its pale labels readable on the white page
# and its table headers visible below the 1024px breakpoint.
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2024-2026 Yegor Bugayenko
# License:: MIT
class TestAssets < Minitest::Test
  CSS = File.expand_path('../assets/index.css', __dir__).freeze

  NAMED = { 'lightgray' => '#D3D3D3' }.freeze

  def test_hidden_is_readable_on_white
    assert_operator(contrast(color('.hidden')), :>=, 4.5, 'the .hidden label is too pale on white')
  end

  def test_empty_marker_is_readable_on_white
    assert_operator(contrast(color('.empty')), :>=, 4.5, 'the .empty marker is too pale on white')
  end

  def test_header_stays_visible
    css = File.read(File.join(__dir__, '../assets/index.css')).gsub(%r{/\*.*?\*/}m, '')
    rule = css[/table\s+thead\s*\{[^}]*\}/]
    refute_nil(rule, 'the "table thead" rule is missing')
    assert_match(/display:\s*table-header-group/, rule)
    refute_match(/!important/, rule)
    before = css[0...css.index(rule)]
    assert_equal(0, before.count('{') - before.count('}'), 'the rule must not sit inside a media query')
  end

  # Tacit hides thead, so our stylesheet has to win the cascade by loading after it.
  def test_css_loads_after_tacit
    xsl = File.read(File.join(__dir__, '../assets/index.xsl'))
    tacit = xsl.index('tacit-css')
    local = xsl.index('yegor256.github.io/judges/assets/index.css')
    refute_nil(tacit, 'Tacit is not linked')
    refute_nil(local, 'the local stylesheet is not linked')
    assert_operator(tacit, :<, local, 'index.css must load after Tacit')
  end

  private

  def color(selector)
    blocks = File.read(CSS).scan(/#{Regexp.escape(selector)}\s*\{([^}]*)\}/).flatten
    raise(StandardError, "#{selector} has no rule in #{CSS}") if blocks.empty?
    found = blocks.filter_map { |b| b[/(?:\A|;)\s*color:\s*([^;]+);/, 1] }.last
    raise(StandardError, "#{selector} has no color in #{CSS}") if found.nil?
    hex = NAMED.fetch(found.strip.downcase, found.strip)
    unless hex.match?(/\A#[0-9A-Fa-f]{6}\z/)
      raise(StandardError, "#{selector} has an unparsable color: #{found.strip}")
    end
    hex
  end

  def contrast(hex)
    fg = luminance(hex)
    bg = luminance('#FFFFFF')
    ([fg, bg].max + 0.05) / ([fg, bg].min + 0.05)
  end

  def luminance(hex)
    rgb = hex[1..].scan(/../).map { |c| c.to_i(16) / 255.0 }
    rgb.zip([0.2126, 0.7152, 0.0722]).sum do |c, k|
      k * (c <= 0.03928 ? c / 12.92 : ((c + 0.055) / 1.055)**2.4)
    end
  end
end
