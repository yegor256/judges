# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require 'pathname'

# Adding method +to_rel+ to all Ruby objects.
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2024-2026 Yegor Bugayenko
# License:: MIT
class Object
  # Generates a display name of a file: a path relative to the current
  # directory or its absolute spelling, whichever is shorter.
  # A path that exists as a directory on disk gets a trailing slash.
  # A path with a space is wrapped in double quotes; when it is an existing
  # directory, the slash ends up inside the quotes.
  # @return [String] Display path to the file, relative to the current
  #   directory or absolute when it is shorter or has no relative form,
  #   with a trailing slash for an existing directory and double quotes
  #   if it has a space; not usable as-is with +File.+ calls
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
