# frozen_string_literal: true

BAD_KEY = 'BadKey'

RSpec.describe FileSentry::CommandLine do
  before(:each) { @encrypt = %w[md5 sha1 sha256].sample }

  describe '#start_utility' do
    it 'raises error when scanning with an invalid API key' do
      stub_api_hash_report mock_hash(encrypt: @encrypt), bad_key: BAD_KEY

      # @type [FileSentry::CommandLine]
      cmd = described_class.new(['-e', @encrypt, '-k', BAD_KEY, '-d', '--no-gzip'], filepath: test_file_path)
      expect(cmd.op_file.filepath).to be_truthy

      allow(File).to receive(:write).with(/\S+/, BAD_KEY)

      expect { cmd.start_utility }.to raise_error(/^Error: Invalid API key\b/i)
      expect(FileSentry.configuration.is_debug).to eq(!FileSentry.configuration.enable_gzip)
    end

    it 'scan and clean with OPSWAT successfully' do
      FileSentry.reset
      stub_api_hash_report mock_hash(encrypt: @encrypt, infected: true), infected: true

      # @type [FileSentry::CommandLine]
      cmd = described_class.new(['-e', @encrypt, test_file_path(true), '-s'])
      expect(cfg_file = cmd.send(:config_file)).to be_truthy

      allow(File).to receive(:size?).with(cfg_file).and_return(nil)
      allow($stdin).to receive(:gets).and_return(api_key = opswat_key)
      allow(File).to receive(:write).with(cfg_file, api_key)

      expected = /\bFilename: \S+.*\bOverall Status: [^\n]*?Infected\b.*\bSanitized filepath: \S+/m
      expect { cmd.start_utility }.to output(expected).to_stdout
      expect(FileSentry.configuration.is_debug).to be_nil
      expect(FileSentry.configuration.enable_gzip).to eq(true)
    end
  end
end
