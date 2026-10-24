# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require 'securerandom'
require 'socket'
require_relative '../judges'

# Owner of a lock on the server.
#
# If the owner is not provided explicitly, a new one is made for
# every instance, so that two runs never share a lock by accident.
#
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2024-2026 Yegor Bugayenko
# License:: MIT
class Judges::Owner
  # Initialize.
  # @param [String] given The owner provided by the user, or nil
  def initialize(given)
    @given = given
  end

  # Make the owner.
  # @return [String] The owner to lock and unlock with
  def to_s
    @given || "#{Socket.gethostname}-#{Process.pid}-#{SecureRandom.hex(4)}"
  end
end
