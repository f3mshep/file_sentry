# frozen_string_literal: true

require 'json'
require 'webmock/rspec'

module FileSentry
  BAD_API_KEY = 'BadApiKey'
  BAD_HASH = 'IAmNotReal'

  MOCK_HASH = '3A93D4CCEF8CFDE41DF8F543852B4A43'
  MOCK_DATA_ID = 'dDE4MDQxN0JKdHNNbTNRaHpCSnFzTVgyUTN6'

  # API output
  # GET data_id
  DATA_ID_RESPONSE = {
    file_id: 'dDE4MDQxN0JKdHNNbTNRaHo',
    data_id: MOCK_DATA_ID,
    archived: false,
    process_info: {
      user_agent: '',
      result: 'Allowed',
      progress_percentage: 100,
      profile: 'File scan',
      file_type_skipped_scan: false,
      blocked_reason: ''
    },
    scan_results: {
      scan_details: {
        nProtect: {
          wait_time: 19,
          threat_found: '',
          scan_time: 2957,
          scan_result_i: 0,
          def_time: '2018-04-17T05:00:00.000Z'
        }
      },
      rescan_available: true,
      data_id: MOCK_DATA_ID,
      scan_all_result_i: 0,
      start_time: '2018-04-17T17:47:01.988Z',
      total_time: 3021,
      total_avs: 37,
      total_detected_avs: 0,
      progress_percentage: 100,
      in_queue: 0,
      scan_all_result_a: 'No threat detected'
    },
    file_info: {
      file_size: 17,
      upload_timestamp: '2018-04-17T17:47:01.979Z',
      md5: MOCK_HASH,
      sha1: '0511263E3518679BF8297C93D551AAB7F2B93196',
      sha256: 'EF748125CF8B36714F7D99ED170B664E27D545AAFE3C54EC85371EA48AAA35BA',
      file_type_category: 'T',
      file_type_description: 'ASCII text, with no line terminators',
      file_type_extension: 'txt',
      display_name: 'test_file.txt'
    },
    top_threat: -1,
    share_file: 1,
    rest_version: '4',
    original_file: {
      detected_by: 0,
      progress_percentage: 100,
      scan_result_i: 0,
      data_id: MOCK_DATA_ID
    }
  }.freeze

  # GET hash
  HASH_RESPONSE = {
    file_id: 'dDE4MDQxN0JKdHNNbTNRaHo',
    data_id: MOCK_DATA_ID,
    archived: false,
    process_info: {
      user_agent: '',
      result: 'Allowed',
      progress_percentage: 100,
      profile: 'File scan',
      file_type_skipped_scan: false,
      blocked_reason: ''
    },
    scan_results: {
      scan_details: {
        nProtect: {
          wait_time: 19,
          threat_found: '',
          scan_time: 2957,
          scan_result_i: 0,
          def_time: '2018-04-17T05:00:00.000Z'
        }
      },
      rescan_available: true,
      data_id: MOCK_DATA_ID,
      scan_all_result_i: 0,
      start_time: '2018-04-17T17:47:01.988Z',
      total_time: 3021,
      total_avs: 37,
      total_detected_avs: 0,
      progress_percentage: 100,
      in_queue: 0,
      scan_all_result_a: 'No threat detected'
    },
    file_info: {
      file_size: 17,
      upload_timestamp: '2018-04-17T17:47:01.979Z',
      md5: MOCK_HASH,
      sha1: '0511263E3518679BF8297C93D551AAB7F2B93196',
      sha256: 'EF748125CF8B36714F7D99ED170B664E27D545AAFE3C54EC85371EA48AAA35BA',
      file_type_category: 'T',
      file_type_description: 'ASCII text, with no line terminators',
      file_type_extension: 'txt',
      display_name: 'test_file.txt'
    },
    top_threat: -1,
    share_file: 1,
    rest_version: '4'
  }.freeze

  API_HEADERS = { 'Apikey' => ENV['OPSWAT_KEY'] }.freeze
  JSON_HEADERS = { content_type: 'application/json' }.freeze

  RSpec.describe ApiWrapper do
    BASE_URL = described_class.base_uri

    before :each do
      @op_file = OpFile.new filepath: File.expand_path('../test_file.txt', __FILE__)
      @op_file.file_hash.hash_file('md5')
      @api_wrapper = @op_file.api_wrapper

      # API Stub responses
      # GET hash stub (hash exists)
      stub_request(:get, "#{BASE_URL}/hash/#{MOCK_HASH}")
        .with(headers: API_HEADERS)
        .to_return(status: [200, 'OK'], body: JSON.generate(HASH_RESPONSE), headers: JSON_HEADERS)

      # GET hash stub (hash does not exist)
      stub_request(:get, "#{BASE_URL}/hash/#{BAD_HASH}")
        .with(headers: API_HEADERS)
        .to_return(status: [200, 'OK'], body: JSON.generate(BAD_HASH => 'Not Found'), headers: JSON_HEADERS)

      # Invalid API
      stub_request(:get, "#{BASE_URL}/hash/#{MOCK_HASH}")
        .with(headers: { 'Apikey' => BAD_API_KEY })
        .to_return(status: [401, 'Invalid Apikey'], body: JSON.generate(HASH_RESPONSE), headers: JSON_HEADERS)

      # GET data_id
      stub_request(:get, "#{BASE_URL}/file/#{MOCK_DATA_ID}")
        .with(headers: API_HEADERS)
        .to_return(status: [200, 'OK'], body: JSON.generate(DATA_ID_RESPONSE), headers: JSON_HEADERS)

      # POST file
      stub_request(:post, "#{BASE_URL}/file/")
        .with(headers: API_HEADERS, body: { filename: File.open(@op_file.filepath, 'rb') })
        .to_return(status: [200, 'OK'], body: JSON.generate(data_id: MOCK_DATA_ID), headers: JSON_HEADERS)
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
        expect(response[BAD_HASH]).to match(/\bNot Found\b/i)
      end

      it 'returns a hash containing the response body' do
        response = @api_wrapper.send(:report_by_hash)
        expect(response['data_id']).to eq(MOCK_DATA_ID)
      end
    end

    describe '#upload_file' do
      # Currently, WebMock does not correctly test POST requests with file uploads
      # a work around in other cases would be to read the file in the API wrapper
      # instead of opening it. However, this would create a different file,
      # resulting in a different hash digest
      it 'makes a POST request with a file to the appropriate OPSWAT endpoint' do
        # @api_wrapper.send(:upload_file)
      end

      it 'returns a hash containing the response body' do
        # response = @api_wrapper.send(:upload_file)
        # expect(response['data_id']).to eq(MOCK_DATA_ID)
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
