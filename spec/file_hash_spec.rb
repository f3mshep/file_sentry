require 'spec_helper'
hashed_file ={
  md5: "3A93D4CCEF8CFDE41DF8F543852B4A43",
  sha1: "0511263E3518679BF8297C93D551AAB7F2B93196",
  sha256: "EF748125CF8B36714F7D99ED170B664E27D545AAFE3C54EC85371EA48AAA35BA",
}

describe FileHash do

  before :each do
    @op_file = OPFile.new({filepath: "spec/test_file.txt"})
    @file_hash = FileHash.new({op_file: @op_file})
  end

  describe ".new" do
    it "initializes with a op_file instance" do
      expect(@file_hash.op_file).to eq(@op_file)
    end
  end

  describe "#md5_hash" do
    it "generates and sets an MD5 hash" do
      @file_hash.md5_hash
      expect(@op_file.hash).to eq(hashed_file[:md5])
    end
  end

  describe "sha1_hash" do
    it "generates and sets a SHA1 hash" do
      @file_hash.sha1_hash
      expect(@op_file.hash).to eq(hashed_file[:sha1])
    end
  end

  describe "sha256_hash" do
    it "generates and sets a SHA256 hash" do
      @file_hash.sha256_hash
      expect(@op_file.hash).to eq(hashed_file[:sha256])
    end
  end

end