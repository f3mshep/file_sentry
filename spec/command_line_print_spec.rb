# frozen_string_literal: true

RSpec.describe FileSentry::CommandLine do
  before :each do
    @encrypt = %w[md5 sha1 sha256].sample
  end

  # properly printing the result is mission critical
  describe '#print_result' do
    it 'prints a formatted version of the scan results' do
      stub_api_hash_report mock_hash(encrypt: @encrypt, infected: true), infected: true

      # @type [FileSentry::CommandLine]
      cmd = described_class.new(filepath: test_file_path(true), options: { sanitize: true })
      cmd.op_file.process_file(@encrypt)

      filename = File.basename(cmd.op_file.filepath)
      expect { cmd.send(:print_result) }.to output(/\bFilename: #{filename}\b.*\bSanitized filepath: \S+/m).to_stdout
    end
  end

  describe '#print_sanitized_file' do
    it 'prints warning message if no sanitized results' do
      cmd = described_class.new([test_file_path])

      expect(cmd.op_file.filepath).to be_nil
      expect { cmd.send(:print_sanitized_file) }.to output(/\bNo sanitized results\b/i).to_stderr
    end
  end
end
