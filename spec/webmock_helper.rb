# frozen_string_literal: true

require 'json'

module WebMockHelper
  RESPONSE_HEADERS = { content_type: 'application/json; charset=utf-8' }.freeze

  # @param [Boolean] infected
  # @param [String] encrypt
  # @return [String]
  def mock_hash(infected = false, encrypt = 'md5')
    (infected ? infected_scan_reports : test_scan_reports).fetch('file_info', {})[encrypt]
  end

  # @param [Boolean] infected
  # @return [String]
  def mock_data_id(infected = false)
    (infected ? infected_scan_reports : test_scan_reports)['data_id']
  end

  # @param [Boolean] data_id
  # @return [String]
  def mock_sanitized(data_id = false)
    infected_scan_reports.fetch('sanitized', {})[data_id ? 'data_id' : 'file_path']
  end

  # @param [Boolean] infected
  # @return [String]
  def test_file_path(infected = false)
    File.expand_path '../data/' + (infected ? 'fake_infected_file.mean' : 'test_file.txt'), __FILE__
  end

  # @return [String]
  def base_url
    @base_url ||= FileSentry::ApiWrapper.base_uri
  end

  # @param [String] key
  # @return [String]
  def opswat_key(key = false)
    return ENV['OPSWAT_KEY'] if key.is_a?(FalseClass)

    ENV['OPSWAT_KEY'] = key
  end

  # @return [Hash]
  def request_headers(bad_key = nil, extra = {})
    key = bad_key ? bad_key.to_s : opswat_key
    extra['apikey'] = key if key
    extra['accept-encoding'] = /\bGZip\b/i if FileSentry.configuration.enable_gzip
    extra
  end

  def stub_api_hash_report(hash, opts = {})
    stub_request(:get, "#{base_url}/hash/#{hash}")
      .with(headers: request_headers(opts[:bad_key]))
      .to_return(status: response_status(opts), body: response_body(opts).to_json, headers: RESPONSE_HEADERS)
  end

  def stub_api_data_id_report(data_id, opts = {})
    stub_request(:get, "#{base_url}/file/#{data_id}")
      .with(headers: request_headers(opts[:bad_key]))
      .to_return(status: response_status(opts), body: response_body(opts).to_json, headers: RESPONSE_HEADERS)
  end

  def stub_api_post_file(opts = {})
    stub_request(:post, "#{base_url}/file/")
      .with(
        headers: request_headers(opts[:bad_key], 'content-type' => 'application/octet-stream'),
        body: File.read(test_file_path(opts[:infected]), mode: 'rb')
      )
      .to_return(
        status: response_status(opts),
        body: response_body(bad_key: opts[:bad_key], data: { data_id: mock_data_id(opts[:infected]) }).to_json,
        headers: RESPONSE_HEADERS
      )
  end

  def stub_api_sanitized_url(data_id, opts = {})
    not_found = data_id != mock_sanitized(true)
    response_data = { sanitizedFilePath: mock_sanitized }

    stub_request(:get, "#{base_url}/file/converted/#{data_id}")
      .with(headers: request_headers(opts[:bad_key]))
      .to_return(
        status: response_status(bad_key: opts[:bad_key], not_found: not_found),
        body: response_body(bad_key: opts[:bad_key], not_found: not_found, data: response_data).to_json,
        headers: RESPONSE_HEADERS
      )
  end

  def stub_api_download_file(url, response_file = nil)
    not_found = !response_file || response_file.empty?
    filename = not_found ? 'Unknown' : File.basename(response_file)

    stub_request(:get, url)
      .to_return(
        status: response_status(not_found: not_found),
        body: not_found ? nil : File.read(response_file, mode: 'rb'),
        headers: { content_type: 'application/octet-stream', content_disposition: "attachment; filename=#{filename}" }
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

  # @param [Hash] opts
  # @option opts [Boolean] :bad_key
  # @option opts [Boolean] :not_found
  # @return [Array]
  def response_status(opts = {})
    return [401, 'Unauthorized'] if opts[:bad_key] || !opswat_key

    opts[:not_found] ? [404, 'Not Found'] : [200, 'OK']
  end

  # @param [Hash] opts
  # @option opts [Boolean] :infected
  # @option opts [Boolean] :bad_key
  # @option opts [Boolean] :not_found
  # @option opts [Hash] :data
  # @return [Hash]
  def response_body(opts = {})
    return { error: { code: 401_006, messages: ['Invalid API key'] } } if opts[:bad_key]
    return { error: { code: 401_001, messages: ['Authentication strategy is invalid'] } } unless opswat_key
    return { error: { code: 404_001, messages: ['The item was not found'] } } if opts[:not_found]
    return opts[:data] if opts[:data]

    opts[:infected] ? infected_scan_reports : test_scan_reports
  end
end
