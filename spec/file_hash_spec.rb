# frozen_string_literal: true

RSpec.describe FileSentry::FileHash do
  before :all do
    @op_file = FileSentry::OpFile.new(filepath: test_file_path)
    @file_hash = @op_file.file_hash
  end

  describe '#hash_file' do
    it 'raise error for unsupported encryption' do
      expect(@file_hash).to be_kind_of(described_class)

      expect { @file_hash.hash_file('SHA') }.to raise_error(NameError, /\bUnsupported\b/i)
    end

    %w[MD5 Sha1 sha256].each do |encrypt|
      it "can generate a #{encrypt} hash" do
        @file_hash.hash_file(encrypt)
        expect(@op_file.hash).to eq(mock_hash(encrypt: encrypt.downcase))
      end
    end
  end
end
