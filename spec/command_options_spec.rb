# frozen_string_literal: true

RSpec.describe FileSentry::CommandLine do
  before :each do
    @encrypt = %w[md5 sha1 sha256].sample
  end

  describe '#start_utility' do
    it 'parse command options with invalid arguments' do
      # @type [FileSentry::CommandLine]
      cmd = described_class.new(['--foo'])
      expect do
        expect { expect { cmd.start_utility }.to raise_error(SystemExit) }.to output(/--help\b/).to_stdout
      end.to output(/--foo\b/).to_stderr
    end

    it 'prints command line usage with -h switch' do
      # @type [FileSentry::CommandLine]
      cmd = described_class.new(['-h'])
      expect { expect { cmd.start_utility }.to raise_error(SystemExit) }.to output(/--help\b/).to_stdout
    end

    it 'prints usage when perform without required argument' do
      # @type [FileSentry::CommandLine]
      cmd = described_class.new(['-k', api_key = opswat_key])
      allow(File).to receive(:write).with(/\S+/, api_key)

      expect { cmd.start_utility }.to output(/--help\b/).to_stdout
    end
  end
end
