# Copyright (c) 2013-2016 SUSE LLC
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
  module Scope
    def self.included(mod)
      mod.extend(ClassMethods)

      @scopes ||= []
      @scopes.push(mod)
    end

    def self.all_scopes
      @scopes
    end

    def self.visible_scopes
      all_scopes.reject(&:hidden?)
    end

    def self.for(scope_name, json, scope_file_store)
      all_scopes.each do |scope|
        if scope.new.scope_name == scope_name
          scope = scope.from_json(json)
          scope.scope_file_store = scope_file_store

          scope.scope = scope

          return scope
        end
      end
      nil
    end

    def self.extract_changed_elements(a, b, primary_key)
      changed_keys = a.map(&primary_key) & b.map(&primary_key)
      changed = []

      changed_keys.each do |key|
        changed << [
          a.find { |e| e.send(primary_key) == key },
          b.find { |e| e.send(primary_key) == key },
        ]
        a.reject! { |e| e.send(primary_key) == key }
        b.reject! { |e| e.send(primary_key) == key }
      end

      changed
    end

    module ClassMethods
      def hidden?
        @hidden || false
      end

      def hidden_scope
        @hidden = true
      end

      def scope_name
        scope = name.match(/^Machinery::(.*)Scope$/)[1]
        scope.gsub(/([^A-Z])([A-Z])/, "\\1_\\2").downcase
      end
    end

    attr_accessor :meta
    attr_accessor :scope_file_store

    def set_metadata(timestring, host)
      self.meta = Machinery::Object.new(
        modified: timestring,
        hostname: host
      )
    end

    def scope_name
      self.class.scope_name
    end

    def is_extractable?
      Machinery::SystemDescription::EXTRACTABLE_SCOPES.include?(scope_name)
    end
  end
end
