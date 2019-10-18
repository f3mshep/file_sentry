# frozen_string_literal: true

require 'tmpdir'

RSpec.describe FileSentry::OpFile do
  before :each do
    @encrypt = %w[md5 sha1 sha256].sample
  end

  describe '#download_sanitized' do
    it 'prints error if no sanitized results' do
      # @type [FileSentry::OpFile]
      op_file = described_class.new
      expect { expect(op_file.download_sanitized).to eq(false) }.to output(/\bNo sanitized results\b/i).to_stderr
    end

    it 'download sanitized file correctly' do
      stub_api_hash_report mock_hash(infected: true, encrypt: @encrypt), infected: true
      stub_api_download_file url = mock_sanitized, sanitized_file = test_file_path

      # @type [FileSentry::OpFile]
      op_file = described_class.new(filepath: test_file_path(true))
      op_file.process_file(@encrypt)

      expect(op_file.sanitized_url).to eq(url)

      Dir::Tmpname.create(['', '.sanitized']) do |path|
        expect(op_file.download_sanitized(path)).to eq(true)
        expect(File.size(path)).to eq(File.size(sanitized_file))
      end
    end
  end
end
