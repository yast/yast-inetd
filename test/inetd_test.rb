#! /usr/bin/env rspec

require_relative "./test_helper"

Yast.import "Inetd"
Yast.import "Service"

describe Yast::Inetd do
  describe "#adjust_xinetd_service" do
    context "while service was already running" do
      before(:each) do
        expect(Yast::Service).to receive(:active?).and_return(true)
      end

      context "service should be started" do
        it "reloads and enables the service" do
          expect(Yast::Service).to receive(:reload).and_return(true)
          expect(Yast::Service).to receive(:Enable).and_return(true)
          Yast::Inetd.netd_status = true
          Yast::Inetd.adjust_xinetd_service
        end
      end

      context "service should be stopped" do
        it "stops and disables the service" do
          expect(Yast::Service).to receive(:Stop).and_return(true)
          expect(Yast::Service).to receive(:Disable).and_return(true)
          Yast::Inetd.netd_status = false
          Yast::Inetd.adjust_xinetd_service
        end
      end
    end

    context "while service was not running" do
      before(:each) do
        expect(Yast::Service).to receive(:active?).and_return(false)
      end

      context "service should be started" do
        it "starts and enables the service" do
          expect(Yast::Service).to receive(:Start).and_return(true)
          expect(Yast::Service).to receive(:Enable).and_return(true)
          Yast::Inetd.netd_status = true
          Yast::Inetd.adjust_xinetd_service
        end
      end

      context "service should be stopped" do
        it "disables the service" do
          expect(Yast::Service).not_to receive(:Stop)
          expect(Yast::Service).to receive(:Disable).and_return(true)
          Yast::Inetd.netd_status = false
          Yast::Inetd.adjust_xinetd_service
        end
      end
    end

    context "GetServerBasename: return basename of the real server" do

      context "server binary is tcpd" do
        let(:tcpd_name) { "/usr/sbin/tcpd" }

        context "server name is defined in server_args" do
          it "returns server name from server_args" do
            expect(Yast::Inetd.GetServerBasename(tcpd_name, "/usr/sbin/in.rlogin")).to eq("in.rlogin")
            expect(Yast::Inetd.GetServerBasename(tcpd_name, "/usr/sbin/in.rlogin arg")).to eq("in.rlogin")
          end
        end

        context "server name is not defined in server_args" do
          it "returns nil" do
            expect(Yast::Inetd.GetServerBasename(tcpd_name, "")).to be_nil
            expect(Yast::Inetd.GetServerBasename(tcpd_name, nil)).to be_nil
          end
        end
      end

      context "server binary is not tcpd" do
        let(:texecd_name) { "/usr/sbin/in.texecd" }
        it "returns given server name" do
          expect(Yast::Inetd.GetServerBasename(texecd_name, nil)).to eq("in.texecd")
          expect(Yast::Inetd.GetServerBasename(texecd_name, "not interested")).to eq("in.texecd")
        end
      end

      context "server binary is nil" do
        it "returns nil" do
          expect(Yast::Inetd.GetServerBasename(nil, nil)).to be_nil
          expect(Yast::Inetd.GetServerBasename(nil, "not interested")).to be_nil
        end
      end
    end

    context "MergeAyProfile: Merges AY profile items into a target list (defaults or system)" do
      it "Merging profiles" do
        target = [
          { "enabled"=>false,
            "iid"=>"1:/etc/xinetd.d/time",
            "protocol"=>"tcp",
            "script"=>"time",
            "service"=>"time"
          }
        ]
        changes = [
          { "enabled"=>false,
            "iid"=>"1:/etc/xinetd.d/services",
            "protocol"=>"tcp",
            "script"=>"services",
            "service"=>"services" },
          { "enabled"=>false,
            "iid"=>"1:/etc/xinetd.d/vnc",
            "protocol"=>"tcp",
            "script"=>"vnc",
            "server"=>"/usr/bin/Xvnc",
            "server_args"=>"-noreset -inetd -once -query localhost",
            "service"=>"vnc1" },
          { "enabled"=>true,
            "iid"=>"1:/etc/xinetd.d/time",
            "protocol"=>"tcp",
            "script"=>"time",
            "service"=>"time"
          }
        ]
        ret = [
          { "enabled"=>true,
            "iid"=>"1:/etc/xinetd.d/time",
            "protocol"=>"tcp",
            "script"=>"time",
            "service"=>"time",
            "changed"=>true },
          { "enabled"=>false,
            "iid"=>"1:/etc/xinetd.d/services",
            "protocol"=>"tcp",
            "script"=>"services",
            "service"=>"services" },
          { "enabled"=>false,
            "iid"=>"1:/etc/xinetd.d/vnc",
            "protocol"=>"tcp",
            "script"=>"vnc",
            "server"=>"/usr/bin/Xvnc",
            "server_args"=>"-noreset -inetd -once -query localhost",
            "service"=>"vnc1" }
        ]
        expect(Yast::Inetd.MergeAyProfile(target, changes)).to eq(ret)
      end
    end

  end
end
