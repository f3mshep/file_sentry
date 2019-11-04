# frozen_string_literal: true

RSpec.describe FileSentry::CommandLine do
  describe '.new' do
    it 'must have filepath parameter' do
      # @type [FileSentry::CommandLine]
      cmd = described_class.new(nil, filepath: '/source')
      expect(cmd.op_file.filepath).to be_truthy
    end

    it 'must not have filepath argument' do
      # @type [FileSentry::CommandLine]
      cmd = described_class.new(%w[-s /source])
      expect(cmd.op_file.filepath).to be_nil
    end
  end

  describe '#config_file' do
    it 'must have config_file' do
      expect(described_class.new.send(:config_file)).to be_truthy.and end_with('.file_sentry')
    end
  end

  describe '#start_utility' do
    before { FileSentry.reset }

    it 'parse options correctly' do
      # @type [FileSentry::CommandLine]
      cmd = described_class.new(%w[-e enc -k key /source -s])

      mock_save_api_key 'key'
      allow(cmd).to receive(:analyze_file)

      cmd.start_utility

      expect(FileSentry.configuration).to have_attributes(is_debug: nil, enable_gzip: true)
    end
  end
end
