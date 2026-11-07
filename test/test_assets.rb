# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative 'test__helper'

# Tests that the stylesheet keeps its pale labels readable on the white page.
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
