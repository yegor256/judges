# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require 'pathname'

# Adding method +to_rel+ to all Ruby objects.
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2024-2026 Yegor Bugayenko
# License:: MIT
class Object
  # Generates a relative name of a file (to the current dir).
  # @return [String] Relative path to the file with optional quotes if it contains spaces
  def to_rel
    s = File.absolute_path(to_s)
    t =
      begin
        Pathname.new(s).relative_path_from(Dir.getwd).to_s
      rescue ArgumentError
        s
      end
    t = s if t.length > s.length
    t = "\"#{t}\"" if t.include?(' ')
    File.directory?(s) ? "#{t}/" : t
  end
end
