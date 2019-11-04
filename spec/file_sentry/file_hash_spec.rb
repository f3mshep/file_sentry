# frozen_string_literal: true

RSpec.describe FileSentry::FileHash do
  describe '.new' do
    it 'must be an instance of FileHash' do
      op_file = FileSentry::OpFile.new
      expect(op_file.file_hash).to be_kind_of(described_class)
    end
  end

  describe '#hash_file' do
    it 'raises error for unsupported encryption' do
      file_hash = described_class.new(FileSentry::OpFile.new)
      expect { file_hash.hash_file('SHA') }.to raise_error(NameError, /\bUnsupported\b/i)
    end

    %w[MD5 Sha1 sha256].each do |encrypt|
      it "can generate a #{encrypt} hash" do
        op_file = FileSentry::OpFile.new(test_file_path(infected = rand_boolean))
        op_file.file_hash.hash_file(encrypt)

        expect(op_file.hash).to eq(mock_hash(infected, encrypt.downcase))
      end
    end
  end
end
