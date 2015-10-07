# Copyright (c) 2013-2015 SUSE LLC
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of version 3 of the GNU General Public License as
# published by the Free Software Foundation.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.   See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, contact SUSE LLC.
#
# To contact SUSE about this file by physical or electronic mail,
# you may find current contact information at www.suse.com

module Machinery
  def self.is_int?(string)
    (string =~ /^\d+$/) != nil
  end

  def self.file_is_binary?(path)
    # Code by https://github.com/djberg96/ptools
    # Modified by SUSE Linux GmbH
    # License: Artistic 2.0
    bytes = File.stat(path).blksize
    bytes = 4096 if bytes > 4096
    s = (File.read(path, bytes) || "")
    s = s.encode("US-ASCII", undef: :replace).split(//)
    ((s.size - s.grep(" ".."~").size) / s.size.to_f) > 0.30
  end

  # Implementation of String#scrub for Ruby < 2.1. Assumes the string is in
  # UTF-8.
  def self.scrub(s)
    # We have a string in UTF-8 with possible invalid byte sequences. It turns
    # out that String#encode can remove these sequences when given appropriate
    # options, but just converting into UTF-8 would be a no-op. So let's convert
    # into UTF-16 (which has the same character set as UTF-8) and back.
    #
    # See also: http://stackoverflow.com/a/21315619
    s.dup.force_encoding("UTF-8").encode("UTF-16", invalid: :replace).encode("UTF-8")
  end

  def self.pluralize(count, singular, plural = nil)
    val = if count > 1 || count == 0
      if !plural
        singular + "s"
      else
        plural
      end
    else
      singular
    end

    val.gsub("%d", count.to_s)
  end
end

def with_c_locale(&block)
  with_env "LC_ALL" => "C", &block
end

def with_utf8_locale(&block)
  with_env "LC_ALL" => "en_US.UTF-8", &block
end

def with_env(env)
  # ENV isn't a Hash, but a weird Hash-like object. Calling #to_hash on it
  # will copy its items into a newly created Hash instance. This approach
  # ensures that any modifications of ENV won't affect the stored value.
  saved_env = ENV.to_hash
  begin
    ENV.replace(saved_env.merge(env))
    yield
  ensure
    ENV.replace(saved_env)
  end
end
