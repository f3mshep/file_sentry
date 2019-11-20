# frozen_string_literal: true

RSpec.describe FileSentry::CommandLine do
  describe '#start_utility' do
    it 'parse command options with invalid arguments' do
      # @type [FileSentry::CommandLine]
      cmd = described_class.new(['--foo'])

      expect do
        cmd.start_utility
      end.to raise_error(SystemExit).and output(/--help\b/).to_stdout.and output(/--foo\b/).to_stderr
    end

    it 'prints command line usage with -h switch' do
      # @type [FileSentry::CommandLine]
      cmd = described_class.new(['-h'])

      expect { cmd.start_utility }.to raise_error(SystemExit).and output(/--help\b/).to_stdout
    end

    it 'prints usage when perform without required argument' do
      # @type [FileSentry::CommandLine]
      cmd = described_class.new(['-k', api_key = opswat_key])

      mock_save_api_key api_key
      expect { cmd.start_utility }.to output(/--help\b/).to_stdout
    end
  end
end
