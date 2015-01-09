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
end

def with_c_locale(&block)
  with_env "LC_ALL" => "C", &block
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
