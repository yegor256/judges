# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require 'pathname'

# Adding method +to_rel+ to all Ruby objects.
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2024-2026 Yegor Bugayenko
# License:: MIT
class Object
  # Generates a display name of a file: the shorter of its relative and
  # absolute spellings, with a trailing slash when it is an existing
  # directory and with double quotes when it has a space.
  # @return [String] Display path, not usable as-is with +File.+ calls
  def to_rel
    s = File.absolute_path(to_s)
    t =
      begin
        Pathname.new(s).relative_path_from(Dir.getwd).to_s
      rescue ArgumentError
        s
      end
    t = s if t.length > s.length
    t = "#{t}/" if File.directory?(s)
    t.include?(' ') ? "\"#{t}\"" : t
  end
end
