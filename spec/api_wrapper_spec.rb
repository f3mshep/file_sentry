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

  describe "#post_file" do
    it "makes a POST request to the correct URL" do
      @api_wrapper.post_file
    end
    it "has a file in the body payload" do
    end
  end
end