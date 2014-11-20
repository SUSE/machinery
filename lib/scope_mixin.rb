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

module Machinery
  module ScopeMixin
    def self.included(mod)
      @scopes ||= []
      @scopes.push(mod)
    end

    def self.all_scopes
      @scopes
    end

    def self.class_for(scope_name)
      all_scopes.each do |scope|
        if scope.new.scope_name == scope_name
          return scope
        end
      end
      nil
    end

    attr_accessor :meta

    def set_metadata(timestring, host)
      self.meta = Machinery::Object.new(
        modified: timestring,
        hostname: host
      )
    end

    def scope_name
      scope = self.class.name.match(/^(.*)Scope$/)[1]
      scope.gsub(/([^A-Z])([A-Z])/, "\\1_\\2").downcase
    end

    def is_extractable?
      SystemDescription::EXTRACTABLE_SCOPES.include?(self.scope_name)
    end
  end
end
