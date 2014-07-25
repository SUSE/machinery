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
  class Scope < SimpleDelegator
    class << self
      attr_reader :payload_class

      def contains(klass)
        @payload_class = klass
      end

      def from_json(*args)
        payload = @payload_class.from_json(*args)
        self.new(payload)
      end
    end

    attr_reader :payload
    attr_accessor :meta

    def initialize(*args)
      if args.first.is_a?(self.class.payload_class)
        @payload = args.first
      else
        @payload = self.class.payload_class.new(*args)
      end

      super(@payload)
    end

    def set_metadata(timestring, host)
      self.meta = Machinery::Object.new(
        modified: timestring,
        hostname: host
      )
    end

    def compare_with(other)
      self.payload == other.payload ? [nil, nil, self] : [self, other, nil]
    end

    def ==(other)
      self.class == other.class && @payload == other.payload
    end
    alias eql? ==

    # we need to explicitly delegate Enumerable#select to the payload object
    # because otherwise the select calls to the delegator object are confused
    # with Kernel#select
    def select(&block)
      @payload.select(&block)
    end
  end
end
