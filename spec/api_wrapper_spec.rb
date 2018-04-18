require 'spec_helper'

describe APIWrapper do
  before :each do
    @op_file = OPFile.new({filepath: "spec/test_file.txt"})
    @api_wrapper = APIWrapper.new({op_file: @op_file})
  end

  describe ".new" do
    it "initializes with a op_file instance" do
      expect(@api_wrapper.op_file).to eq(@op_file)
    end
  end

  describe "#scan_file" do
    it "scans file with OPSWAT" do
      @api_wrapper.scan_file
    end
  end
end