# frozen_string_literal: true

require 'json'
require 'webmock/rspec'

module WebMockHelper
  RESPONSE_HEADERS = { content_type: 'application/json; charset=utf-8' }.freeze

  # @return [String]
  def mock_hash(infected: false, encrypt: 'md5')
    (infected ? infected_scan_reports : test_scan_reports).dig('file_info', encrypt)
  end

  # @return [String]
  def mock_data_id(infected: false)
    (infected ? infected_scan_reports : test_scan_reports).dig('data_id')
  end

  # @return [String]
  def test_file_path(infected = false)
    File.expand_path '../data/' + (infected ? 'fake_infected_file.mean' : 'test_file.txt'), __FILE__
  end

  # @return [String]
  def base_url
    @base_url ||= FileSentry::ApiWrapper.base_uri
  end

  # @return [String]
  def opswat_key
    ENV['OPSWAT_KEY']
  end

  # @return [Hash]
  def request_headers(bad_key = false, extra: {})
    extra.merge(apikey: bad_key ? bad_key.to_s : opswat_key)
  end

  def stub_api_hash_report(hash, infected: false, bad_key: false, not_found: false)
    stub_request(:get, "#{base_url}/hash/#{hash}")
      .with(headers: request_headers(bad_key))
      .to_return(
        status: response_status(bad_key: bad_key, not_found: not_found),
        body: response_body(infected: infected, bad_key: bad_key, not_found: not_found).to_json,
        headers: RESPONSE_HEADERS
      )
  end

  def stub_api_data_id_report(data_id, infected: false, bad_key: false, not_found: false)
    stub_request(:get, "#{base_url}/file/#{data_id}")
      .with(headers: request_headers(bad_key))
      .to_return(
        status: response_status(bad_key: bad_key, not_found: not_found),
        body: response_body(infected: infected, bad_key: bad_key, not_found: not_found).to_json,
        headers: RESPONSE_HEADERS
      )
  end

  def stub_api_post_file(infected: false, bad_key: false)
    stub_request(:post, "#{base_url}/file/")
      .with(
        headers: request_headers(bad_key, extra: { 'content-type' => 'application/octet-stream' }),
        body: File.read(test_file_path(infected), mode: 'rb')
      )
      .to_return(
        status: response_status(bad_key: bad_key),
        body: response_body(infected: infected, bad_key: bad_key).select { |k, _| k[/^data_id|error$/] }.to_json,
        headers: RESPONSE_HEADERS
      )
  end

  private

  # @return [Hash]
  def test_scan_reports
    @test_scan_reports ||= JSON.parse File.read(File.expand_path('../data/test_file_scan_reports.json', __FILE__))
  end

  # @return [Hash]
  def infected_scan_reports
    @infected_scan_reports ||= JSON.parse File.read(File.expand_path('../data/infected_scan_reports.json', __FILE__))
  end

  # @return [Array]
  def response_status(bad_key: false, not_found: false)
    if bad_key || !opswat_key
      [401, 'Unauthorized']
    elsif not_found
      [404, 'Not Found']
    else
      [200, 'OK']
    end
  end

  # @return [Hash]
  def response_body(infected: false, bad_key: false, not_found: false)
    if bad_key
      { error: { code: 401_006, messages: ['Invalid API key'] } }
    elsif !opswat_key
      { error: { code: 401_001, messages: ['Authentication strategy is invalid'] } }
    elsif not_found
      { error: { code: 404_001, messages: ['The item was not found'] } }
    else
      infected ? infected_scan_reports : test_scan_reports
    end
  end
end
