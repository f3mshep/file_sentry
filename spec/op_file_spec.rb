require 'spec_helper'

describe APIWrapper do
  before :each do
    @op_file = OPFile.new({filepath: "spec/test_file.txt"})
  end

  describe "#process_file" do
    it "Updates the scan_results attribute with OPSWAT's scan results" do
      @op_file.process_file
      expect(true).to eq(false)
    end
  end

  describe "#print_result" do
    it "prints a formatted version of the scan results" do
      @op_file.process_file
      @op_file.print_result
      expect(true).to eq(false)
    end
  end
end