# frozen_string_literal: true

module FileSentry
  BAD_API_KEY = 'BadApiKey'
  BAD_HASH = 'IAmNotReal'

  MOCK_HASH = '3A93D4CCEF8CFDE41DF8F543852B4A43'
  MOCK_DATA_ID = 'dDE4MDQxN0JKdHNNbTNRaHpCSnFzTVgyUTN6'

  API_HEADERS = { apikey: ENV['OPSWAT_KEY'] }.freeze
  JSON_HEADERS = { content_type: 'application/json' }.freeze

  # API output
  JSON_SCAN_REPORTS = File.read File.expand_path('../data/test_file_scan_reports.json', __FILE__)

  RSpec.describe ApiWrapper do # rubocop:disable Metrics/BlockLength
    BASE_URL = described_class.base_uri

    before :each do
      @op_file = OpFile.new filepath: File.expand_path('../data/test_file.txt', __FILE__)
      @op_file.file_hash.hash_file('md5')
      @api_wrapper = @op_file.api_wrapper

      # API Stub responses
      # GET hash stub (hash exists)
      stub_request(:get, "#{BASE_URL}/hash/#{MOCK_HASH}")
        .with(headers: API_HEADERS)
        .to_return(status: [200, 'OK'], body: JSON_SCAN_REPORTS, headers: JSON_HEADERS)

      # GET hash stub (hash does not exist)
      stub_request(:get, "#{BASE_URL}/hash/#{BAD_HASH}")
        .with(headers: API_HEADERS)
        .to_return(
          status: [404, 'Not Found'],
          body: '{"error":{"code":404003,"messages":["The hash was not found"]}}',
          headers: JSON_HEADERS
        )

      # Invalid API
      stub_request(:get, "#{BASE_URL}/hash/#{MOCK_HASH}")
        .with(headers: { apikey: BAD_API_KEY })
        .to_return(status: [401, 'Invalid Apikey'], body: '{}', headers: JSON_HEADERS)

      # GET data_id
      stub_request(:get, "#{BASE_URL}/file/#{MOCK_DATA_ID}")
        .with(headers: API_HEADERS)
        .to_return(status: [200, 'OK'], body: JSON_SCAN_REPORTS, headers: JSON_HEADERS)

      # POST file
      stub_request(:post, "#{BASE_URL}/file/")
        .with(
          headers: API_HEADERS.merge('content-type' => 'application/octet-stream'),
          body: File.read(@op_file.filepath, mode: 'rb')
        )
        .to_return(status: [200, 'OK'], body: '{"data_id":"' + MOCK_DATA_ID + '"}', headers: JSON_HEADERS)
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
        @op_file.data_id = MOCK_DATA_ID
        @api_wrapper.send(:report_by_data_id)
        expect(WebMock).to have_requested(:get, "#{BASE_URL}/file/#{MOCK_DATA_ID}").with(headers: API_HEADERS)
      end

      it 'returns a hash containing the response body' do
        @op_file.data_id = MOCK_DATA_ID
        response = @api_wrapper.send(:report_by_data_id)
        expect(response['data_id']).to eq(MOCK_DATA_ID)
      end
    end

    describe '#report_by_hash' do
      it 'makes a GET request with an existing hash' do
        @api_wrapper.send(:report_by_hash)
        expect(WebMock).to have_requested(:get, "#{BASE_URL}/hash/#{MOCK_HASH}")
      end

      it 'makes a GET request without existing hash' do
        @op_file.hash = BAD_HASH
        response = @api_wrapper.send(:report_by_hash)
        expect(response.dig('error', 'code')).to eq(404_003)
      end

      it 'returns a hash containing the response body' do
        response = @api_wrapper.send(:report_by_hash)
        expect(response['data_id']).to eq(MOCK_DATA_ID)
      end
    end

    describe '#upload_file' do
      it 'makes a POST request with a file to the appropriate OPSWAT endpoint' do
        @api_wrapper.send(:upload_file)
        expect(WebMock).to have_requested(:post, "#{BASE_URL}/file/").with(headers: API_HEADERS)
      end

      it 'returns a hash containing the response body' do
        response = @api_wrapper.send(:upload_file)
        expect(response['data_id']).to eq(MOCK_DATA_ID)
      end
    end

    describe '#scan_file' do
      it 'scans file with OPSWAT' do
        @api_wrapper.scan_file
      end

      it 'raises error if API raises error' do
        FileSentry.configure do |config|
          config.access_key = BAD_API_KEY
          described_class.configure config
        end

        expect { @api_wrapper.scan_file }.to raise_error(/^Error: Invalid Apikey\b/i)
      end
    end
  end
end
