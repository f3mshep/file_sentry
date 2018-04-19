require 'spec_helper'
require 'webmock/rspec'
WebMock.disable_net_connect!(allow_localhost: true)

describe APIWrapper do
  before :each do
    @op_file = OPFile.new({filepath: "spec/test_file.txt"})
    @file_hash = FileHash.new({op_file: @op_file})
    @api_wrapper = APIWrapper.new({op_file: @op_file})
  end

  describe ".new" do
    it "initializes with a op_file instance" do
      expect(@api_wrapper.op_file).to eq(@op_file)
    end
  end

  # generally I treat private methods as black boxes,
  # but these API calls make or break the application,
  # and I do not expect them to change too much.

  describe "#get_data_id" do
    it "makes a GET request to the appropriate OPSWAT endpoint" do
    end
    it "returns a hash containing the response body" do
    end
  end

  describe "#get_hash" do
    it "makes a GET request with a hash to the appropriate OPSWAT endpoint" do
    end
    it "returns a hash containing the response body" do
    end
  end

  describe "#post_file" do
    it "makes a POST request with a file to the appropriate OPSWAT endpoint" do
    end
    it "returns a hash containing the response body" do
    end
  end

  describe "#scan_file" do
    it "scans file with OPSWAT" do
      @file_hash.hash_file("md5")
      @api_wrapper.scan_file
    end
    it "raises error if API raises error" do
      FileSentry.configure { |config| config.access_key = "BAD API KEY" }
      @file_hash.hash_file("md5")
      expect{@api_wrapper.scan_file}.to raise_error("Error: Invalid Apikey")
    end
  end
end