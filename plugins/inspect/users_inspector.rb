# Copyright (c) 2013-2014 SUSE LLC
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

class UsersInspector < Inspector
  def inspect(system, description, options = {})
    passwd = system.cat_file("/etc/passwd")
    shadow = system.cat_file("/etc/shadow")

    users = passwd ? parse_users(passwd, shadow) : []

    description.users = UsersScope.new(users.sort_by(&:name))
    "Found #{users.size} users."
  end

  private

  def parse_users(passwd, shadow)
    users = passwd.lines.map { |l| l.split(":").first }

    users.map do |user|
      attributes = passwd_attributes(passwd, user)
      attributes.merge!(shadow_attributes(shadow, user)) if shadow

      User.new(attributes)
    end
  end

  def passwd_attributes(passwd, user)
    line = passwd.lines.find { |l| l.start_with?("#{user}:") }
    user, passwd, uid, gid, comment, home, shell = line.split(":").map(&:chomp)

    {
        name: user,
        password: passwd,
        uid: uid.to_i,
        gid: gid.to_i,
        comment: comment,
        home: home,
        shell: shell
    }
  end

  def shadow_attributes(shadow, user)
    line = shadow.lines.find { |l| l.start_with?("#{user}:") }
    if line
      user, passwd, changed, min, max, warn, inactive, expire = line.split(":").map(&:chomp)

      result = {
        encrypted_password: passwd
      }
      result[:last_changed_date] = changed.to_i if !changed.empty?
      result[:min_days] = min.to_i if !min.empty?
      result[:max_days] = max.to_i if !max.empty?
      result[:warn_days] = warn.to_i if !warn.empty?
      result[:disable_days] = inactive.to_i if !inactive.empty?
      result[:disabled_date] = expire.to_i if !expire.empty?

      result
    else
      {}
    end
  end
end
