# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require 'delegate'
require 'ellipsized'
require_relative '../judges'

# Decorates the exception to show an ellipsized message.
class Judges::PrettyException < SimpleDelegator
  undef_method :class
  undef_method :instance_of?
  undef_method :is_a?
  undef_method :kind_of?

  def message
    __getobj__.message.ellipsized(100, :right)
  end

  # The exception to raise, of the original class, with the shortened message.
  #
  # @param [String] msg The message to use, or nil to use the shortened one
  # @return [Exception] The exception
  def exception(msg = nil)
    __getobj__.exception(msg || message)
  end
end
