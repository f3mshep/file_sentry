require 'spec_helper'

describe CommandLine do
  describe "#print_result" do
    it "prints a formatted version of the scan results" do
      @op_file.process_file("md5")
      expect{@op_file.print_result}.to output(
        /Filename: test_file.txt/
      ).to_stdout
    end
  end
end