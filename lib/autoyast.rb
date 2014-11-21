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

class Autoyast
  def initialize(description)
    @system_description = description
  end

  def write(output_dir)
    File.write(File.join(output_dir, "autoinst.xml"), profile)
  end

  def profile
    builder = Nokogiri::XML::Builder.new do |xml|
      xml.doc.create_internal_subset("profile", nil, nil)
      xml.profile(
        "xmlns" => "http://www.suse.com/1.0/yast2ns",
        "xmlns:config" => "http://www.suse.com/1.0/configns"
      ) do
        apply_repositories(xml)
        xml.software do
          apply_packages(xml)
          apply_patterns(xml)
        end
        apply_users(xml)
        apply_groups(xml)
      end
    end

    builder.to_xml
  end

  private

  def apply_repositories(xml)
    return if !@system_description.repositories

    xml.send("add-on") do
      xml.add_on_products("config:type" => "list") do
        @system_description.repositories.each do |repository|
          xml.listentry do
            xml.media_url repository.url
            xml.name repository.alias
          end
        end
      end
    end
  end

  def apply_packages(xml)
    return if !@system_description.packages

    xml.packages("config:type" => "list") do
      @system_description.packages.each do |package|
        xml.package package.name
      end
    end
  end

  def apply_patterns(xml)
    return if !@system_description.patterns

    xml.patterns("config:type" => "list") do
      @system_description.patterns.each do |pattern|
        xml.pattern pattern.name
      end
    end
  end

  def apply_users(xml)
    return if !@system_description.users

    xml.users("config:type" => "list") do
      @system_description.users.each do |user|
        xml.user do
          xml.username user.name
          xml.user_password user.encrypted_password
          xml.encrypted "true", "config:type" => "boolean"
          xml.uid user.uid
          xml.gid user.gid
          xml.home user.home
          xml.shell user.shell
          xml.fullname user.comment
          xml.password_settings do
            xml.min user.min_days
            xml.max user.max_days
            xml.warn user.warn_days
            xml.inact user.disable_days
            xml.expire user.disabled_date
          end
        end
      end
    end
  end

  def apply_groups(xml)
    return if !@system_description.groups

    xml.groups("config:type" => "list") do
      @system_description.groups.each do |group|
        xml.group do
          xml.encrypted "true", "config:type" => "boolean"
          xml.gid group.gid
          xml.groupname group.name
          xml.group_password group.password
          xml.userlist group.users.join(",")
        end
      end
    end
  end
end
