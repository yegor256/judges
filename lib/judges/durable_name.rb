# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative '../judges'

# Name of a durable, taken from the local file name.
#
# The server accepts only lower case letters, digits and dashes, with
# one extension, and refuses everything else.
#
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2024-2026 Yegor Bugayenko
# License:: MIT
class Judges::DurableName
  # Initialize.
  # @param [String] path Path of the local file
  def initialize(path)
    @path = path
  end

  # Make the name, or fail if the server would not accept it.
  # @return [String] The name of the durable
  # @raise [StandardError] If the name is not valid
  def to_s
    name = File.basename(@path)
    unless name.match?(/\A@?[a-z\-0-9]+\.[a-z]+\z/)
      raise(
        StandardError,
        "The durable name '#{name}' is not valid, it must be lower case letters, digits and dashes, with one extension"
      )
    end
    name
  end
end
