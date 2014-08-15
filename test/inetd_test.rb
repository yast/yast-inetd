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
  end
end
