# frozen_string_literal: true

BAD_API_KEY = 'BadApiKey'
BAD_HASH    = 'IAmNotReal'

RSpec.describe FileSentry::ApiWrapper do # rubocop:disable Metrics/BlockLength
  before :each do
    @op_file = FileSentry::OpFile.new(filepath: test_file_path)
    @op_file.file_hash.hash_file('md5')
    @api_wrapper = @op_file.api_wrapper
  end

  describe '.new' do
    it 'initializes with a op_file instance' do
      expect(@api_wrapper).to be_kind_of(described_class)

      expect(@api_wrapper.op_file).to eq(@op_file)
    end
  end

  # generally I treat private methods as black boxes,
  # but these API calls make or break the application,
  # and I do not expect them to change too much.

  describe '#report_by_data_id' do
    it 'makes a GET request to the appropriate OPSWAT endpoint' do
      @op_file.data_id = data_id = mock_data_id
      stub_api_data_id_report data_id

      @api_wrapper.send(:report_by_data_id)
      expect(WebMock).to have_requested(:get, "#{base_url}/file/#{data_id}").with(headers: request_headers)
    end

    it 'returns a hash containing the response body' do
      @op_file.data_id = data_id = mock_data_id
      stub_api_data_id_report data_id

      response = @api_wrapper.send(:report_by_data_id)
      expect(response['data_id']).to eq(data_id)
    end

    it 'raise error while requesting with invalid data_id' do
      @op_file.data_id = BAD_HASH
      stub_api_data_id_report BAD_HASH, not_found: true

      expect { @api_wrapper.send(:report_by_data_id) }.to raise_error(/\bWas not found$/i)
    end
  end

  describe '#report_by_hash' do
    it 'makes a GET request with an existing hash' do
      stub_api_hash_report hash = mock_hash

      @api_wrapper.send(:report_by_hash)
      expect(WebMock).to have_requested(:get, "#{base_url}/hash/#{hash}")
    end

    it 'makes a GET request with non-existing hash' do
      @op_file.hash = BAD_HASH
      stub_api_hash_report BAD_HASH, not_found: true

      response = @api_wrapper.send(:report_by_hash)
      expect(response['data_id']).to be_nil
      expect(response.dig('error', 'code')).to eq(404_001)
    end

    it 'raise error while requesting without existing hash' do
      @op_file.hash = BAD_HASH
      stub_api_hash_report BAD_HASH, not_found: true

      expect { @api_wrapper.send(:report_by_hash, [200]) }.to raise_error(/\bWas not found$/i)
    end

    it 'returns a hash containing the response body' do
      stub_api_hash_report mock_hash

      response = @api_wrapper.send(:report_by_hash)
      expect(response['data_id']).to eq(mock_data_id)
    end
  end

  describe '#upload_file' do
    it 'makes a POST request with a file to the appropriate OPSWAT endpoint' do
      stub_api_post_file
      @api_wrapper.send(:upload_file, true)

      req_headers = request_headers extra: { 'content-type' => 'application/octet-stream', rule: 'sanitize,unarchive' }
      expect(WebMock).to have_requested(:post, "#{base_url}/file/").with(headers: req_headers)
    end

    it 'returns a hash containing the response body' do
      stub_api_post_file

      response = @api_wrapper.send(:upload_file)
      expect(response['data_id']).to eq(mock_data_id)
    end
  end

  describe '#scan_file' do
    it 'scans file with OPSWAT' do
      stub_api_hash_report mock_hash, not_found: true
      stub_api_post_file
      stub_api_data_id_report mock_data_id

      response = @api_wrapper.scan_file
      expect(response).to have_key('scan_details')
    end

    it 'raises error if API raises error' do
      FileSentry.configure do |config|
        config.access_key = BAD_API_KEY
        described_class.configure config
      end

      stub_api_hash_report mock_hash, bad_key: BAD_API_KEY
      expect { @api_wrapper.scan_file }.to raise_error(/^Error: Invalid API key\b/i)
    end
  end
end
