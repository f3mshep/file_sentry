require 'spec_helper'
require 'dotenv'
Dotenv.load('.env')
describe CommandLine do
  before :each do
    @cmd = CommandLine.new({filepath: "spec/test_file.txt"})
  end

  # properly printing the result is mission critiscal
  describe "#print_result" do
    it "prints a formatted version of the scan results" do
      @cmd.op_file.process_file("md5")
      expect{ @cmd.send(:print_result) }.to output(
        /Filename: test_file.txt/
      ).to_stdout
    end
  end
end