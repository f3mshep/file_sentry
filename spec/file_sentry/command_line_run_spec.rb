# frozen_string_literal: true

BAD_KEY = 'BadKey'
EXPECTED_INFECTED_OUT = '\bFilename: \S+.*\bOverall Status: [^\n]*?Infected\b.*\bSanitized filepath: \S+'

RSpec.describe FileSentry::CommandLine do
  before { mock_save_api_key }

  describe '#start_utility' do
    it 'configure with parsed arguments correctly' do
      # @type [FileSentry::CommandLine]
      cmd = described_class.new(%w[-k key -d --no-gzip], filepath: '/source')

      allow(cmd).to receive(:analyze_file)
      cmd.start_utility

      expect(FileSentry.configuration).to have_attributes(is_debug: true, enable_gzip: false)
    end

    it 'raises error when scanning with an invalid API key' do
      stub_api_hash_report mock_hash(false, encrypt = rand_encrypt), bad_key: BAD_KEY

      # @type [FileSentry::CommandLine]
      cmd = described_class.new(['-e', encrypt, '-k', BAD_KEY], filepath: test_file_path)

      expect { cmd.start_utility }.to raise_error(/^Error: Invalid API key\b/i)
    end

    it 'scan and clean with OPSWAT successfully' do
      stub_api_hash_report mock_hash(true, encrypt = rand_encrypt), infected: true

      # @type [FileSentry::CommandLine]
      cmd = described_class.new(['-e', encrypt, test_file_path(true), '-s'])

      allow(File).to receive(:size?).with(/\.file_sentry$/).and_return(nil)
      allow($stdin).to receive(:gets).and_return(opswat_key)

      expect { cmd.start_utility }.to output(/#{EXPECTED_INFECTED_OUT}/m).to_stdout
    end
  end
end
