require 'spec_helper'

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

  describe "#scan_file" do
    it "scans file with OPSWAT" do
      @file_hash.hash_file("md5")
      @api_wrapper.scan_file
    end
    it "raises an error with a bad API key" do
      FileSentry.configure { |config| config.access_key = "BAD API KEY" }
      @file_hash.hash_file("md5")
      expect{@api_wrapper.scan_file}.to raise_error("Error: Invalid Apikey")
    end
  end
end