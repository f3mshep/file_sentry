# frozen_string_literal: true

require 'file_sentry/command_line'

module FileSentry
  RSpec.describe CommandLine do
    before :each do
      @cmd = described_class.new filepath: File.expand_path('../test_file.txt', __FILE__)
    end

    # properly printing the result is mission critical
    describe '#print_result' do
      it 'prints a formatted version of the scan results' do
        @cmd.op_file.process_file('md5')
        expect { @cmd.send(:print_result) }.to output(/\bFilename: test_file.txt\b/).to_stdout
      end
    end
  end
end
