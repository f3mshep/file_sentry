# frozen_string_literal: true

module FileSentry
  HASHED_FILE = {
    MD5: '3A93D4CCEF8CFDE41DF8F543852B4A43',
    Sha1: '0511263E3518679BF8297C93D551AAB7F2B93196',
    sha256: 'EF748125CF8B36714F7D99ED170B664E27D545AAFE3C54EC85371EA48AAA35BA'
  }.freeze

  RSpec.describe FileHash do
    before :each do
      @op_file = OpFile.new filepath: File.expand_path('../data/test_file.txt', __FILE__)
      @file_hash = @op_file.file_hash
    end

    describe '#hash_file' do
      HASHED_FILE.each do |encrypt, hashed|
        it "can generate a #{encrypt} hash" do
          @file_hash.hash_file(encrypt)
          expect(@op_file.hash).to eq(hashed)
        end
      end

      it 'raise error for unsupported encryption' do
        expect(@file_hash).to be_kind_of(described_class)

        expect { @file_hash.hash_file('SHA') }.to raise_error(NameError, /\bUnsupported\b/i)
      end
    end
  end
end
