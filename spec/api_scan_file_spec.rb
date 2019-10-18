# frozen_string_literal: true

BAD_API_KEY = 'BadApiKey'

RSpec.describe FileSentry::ApiWrapper do
  before :each do
    @op_file = FileSentry::OpFile.new(filepath: test_file_path(@infected = rand(2).zero?))
    @op_file.file_hash.hash_file(@encrypt = %w[md5 sha1 sha256].sample)
    @api_wrapper = @op_file.api_wrapper
  end

  describe '#scan_file' do
    it 'scans file with OPSWAT' do
      stub_api_hash_report mock_hash(infected: @infected, encrypt: @encrypt), infected: @infected, not_found: true
      stub_api_post_file infected: @infected
      stub_api_data_id_report mock_data_id(infected: @infected), infected: @infected

      response = @api_wrapper.scan_file(@infected)
      expect(response).to have_key('scan_details')
    end

    it 'raises error when processing with invalid API key' do
      FileSentry.configure do |config|
        config.access_key = BAD_API_KEY
        config.is_debug = false
        described_class.configure config
      end

      stub_api_hash_report hash = mock_hash(infected: @infected, encrypt: @encrypt), bad_key: BAD_API_KEY
      expect { @api_wrapper.scan_file }.to raise_error(/^Error: Invalid API key\b/i)

      req_headers = { 'accept-encoding' => /\bGZip\b/i }
      expect(WebMock).to have_requested(:get, "#{base_url}/hash/#{hash}").with(headers: req_headers)
    end
  end
end
