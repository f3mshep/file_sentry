# frozen_string_literal: true

RSpec.describe FileSentry::CommandLine do
  before :all do
    # @type [FileSentry::CommandLine]
    @cmd = described_class.new(filepath: test_file_path)
  end

  # properly printing the result is mission critical
  describe '#print_result' do
    it 'prints a formatted version of the scan results' do
      stub_api_hash_report mock_hash(encrypt: 'sha256')

      @cmd.op_file.process_file('sha256')

      expect { @cmd.send(:print_result) }.to output(/\bFilename: test_file.txt\b/).to_stdout
    end
  end
end
