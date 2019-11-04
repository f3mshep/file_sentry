# frozen_string_literal: true

require 'tmpdir'

RSpec.describe FileSentry::OpFile do
  describe '#download_sanitized' do
    it 'returns FALSE if no sanitized results' do
      # @type [FileSentry::OpFile]
      op_file = described_class.new

      expect(op_file.download_sanitized).to eq(false)
    end

    it 'prints error if no sanitized results' do
      # @type [FileSentry::OpFile]
      op_file = described_class.new

      expect { op_file.download_sanitized }.to output(/\bNo sanitized results\b/i).to_stderr
    end

    it 'download sanitized file correctly' do
      stub_api_hash_report mock_hash(true, encrypt = rand_encrypt), infected: true
      stub_api_download_file url = mock_sanitized, sanitized_file = test_file_path

      # @type [FileSentry::OpFile]
      (op_file = described_class.new(test_file_path(true))).process_file(encrypt)

      expect(download_and_get_results(op_file)).to eq [url, true, File.size(sanitized_file)]
    end
  end

  def download_and_get_results(op_file)
    Dir::Tmpname.create(['', '.sanitized']) do |path|
      return [op_file.sanitized_url, op_file.download_sanitized(path), File.size?(path)]
    end
  end
end
