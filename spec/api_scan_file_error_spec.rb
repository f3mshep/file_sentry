# frozen_string_literal: true

RSpec.describe FileSentry::ApiWrapper do
  before :each do
    @op_file = FileSentry::OpFile.new(filepath: test_file_path(@infected = rand(2).zero?))
    @op_file.file_hash.hash_file(@encrypt = %w[md5 sha1 sha256].sample)
    @api_wrapper = @op_file.api_wrapper
  end

  describe '#scan_file' do
    it 'raises error if OPSWAT_KEY is not set' do
      last_key = opswat_key
      opswat_key nil
      stub_api_hash_report mock_hash(encrypt: @encrypt, infected: @infected), infected: @infected

      FileSentry.configure do |config|
        config.access_key = nil
        described_class.configure config
      end

      expect { scan_and_restore_key(last_key) }.to raise_error(/^Error: Authentication strategy is invalid\b/i)
    end
  end

  def scan_and_restore_key(last_key)
    @api_wrapper.scan_file
  ensure
    opswat_key last_key
  end
end
