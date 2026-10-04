# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

# A marker for durables that have been placed but not yet saved.
module Judges::DurablePlaceholder
  CONTENT = "\x00JUDGES_DURABLE_UPLOAD_INCOMPLETE\x00".b.freeze

  # Write an incomplete marker to a local file.
  # @param [String] path The local file path
  def self.write(path)
    File.binwrite(path, CONTENT)
  end

  # Is this local file an incomplete durable marker?
  # @param [String] path The local file path
  # @return [Boolean] TRUE if it is
  def self.incomplete?(path)
    File.size(path) == CONTENT.bytesize && File.binread(path) == CONTENT
  end
end
