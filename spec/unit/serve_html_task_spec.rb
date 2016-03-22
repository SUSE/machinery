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

require_relative "spec_helper"

describe ServeHtmlTask do
  describe "#assemble_url" do
    context "when option public is not specified" do
      let(:opts) { { port: 5000, public: false } }

      it "uses 127.0.0.1 as host in url" do
        url = subject.assemble_url(opts)
        expect(url).to eq("http://127.0.0.1:5000/")
      end
    end

    context "when option public is specified" do
      let(:opts) { { port: 5000, public: true } }
      before(:each) do
        allow(Socket).to receive(:gethostname).and_return("public")
      end

      context "when hostname is mapped in /etc/hosts" do
        before(:each) do
          allow(Socket).to receive(:gethostbyname).and_return(
            ["public.example.com", ["localhost", "public"], 2, "\x7F\x00\x00\x01"]
          )
        end

        it "sets the specified hostname as host" do
          url = subject.assemble_url(opts)
          expect(url).to eq("http://public.example.com:5000/")
        end
      end

      context "when hostname is not mapped in /etc/hosts" do
        before(:each) do
          allow(Socket).to receive(:gethostbyname).and_raise(SocketError)
        end

        it "sets the specified hostname as host" do
          url = subject.assemble_url(opts)
          expect(url).to eq("http://public:5000/")
        end
      end
    end
  end
end
