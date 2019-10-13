# frozen_string_literal: true

require 'httparty'

class APIWrapper
  include HTTParty
  base_uri 'https://api.metadefender.com/v4'

  # @return [OpFile]
  attr_accessor :op_file

  # @param [OpFile] op_file
  def initialize(op_file:)
    self.op_file = op_file

    # default request headers
    self.class.headers 'apikey' => FileSentry.configuration.access_key

    if FileSentry.configuration.is_debug
      self.class.debug_output
    else
      self.class.debug_output nil
    end
  end

  # @return [Hash] Scan results
  def scan_file
    response = report_by_hash
    response = post_file unless does_hash_exist?(response, op_file.hash)
    save_data_id response

    monitor_scan
  end

  private

  # @return [Hash] Scan results
  # @raise [ThreadError] If scanning timeout
  def monitor_scan
    (FileSentry.configuration.scan_timeout || 3600).times do
      sleep(1)
      response = report_by_data_id

      return op_file.scan_results = response['scan_results'] if scan_complete?(response)
    end

    raise ThreadError, 'Error: API timeout.'
  end

  def post_file
    response = self.class.post('/file/', body: { filename: File.open(op_file.filepath, 'rb') })
    error_check(response)
  end

  # @raise [ArgumentError] If file hash was not set
  def report_by_hash
    raise ArgumentError, 'No hash set.' unless op_file.hash

    response = self.class.get('/hash/' + op_file.hash)
    error_check(response)
  end

  # @raise [ArgumentError] If data_id was not set
  def report_by_data_id
    raise ArgumentError, 'No data_id set.' unless op_file.data_id

    response = self.class.get('/file/' + op_file.data_id)
    error_check(response)
  end

  # @param [Hash] response
  # @return [String] Data ID
  def save_data_id(response)
    op_file.data_id = response['data_id']
  end

  # @param [Hash] response
  # @param [String] hash
  def does_hash_exist?(response, hash)
    !response[hash]
    # response.any? do |_, val|
    #   (val.is_a?(String) && hash.casecmp(val).zero?) || (val.is_a?(Hash) && does_hash_exist?(val, hash))
    # end
  end

  # @param [HTTParty::Response] response
  # @return [Hash] Parsed response
  # @raise [TypeError] If response is invalid
  # @raise [RuntimeError] If response status is not OK
  def error_check(response)
    raise TypeError, 'Error: No response.' unless response

    data = response.parsed_response
    if response.code != 200
      err = data.is_a?(Hash) ? find_error(data) : response.body
      raise "Error: #{(err && !err.empty? ? err : response.message)}"
    end

    data
  end

  # @param [Hash] data
  # @return [Object]
  def find_error(data)
    data['err'] || data.dig('error', 'messages')&.first
  end

  # @param [Hash] response
  # @return [Boolean]
  def scan_complete?(response)
    find_progress(response) >= 100
  end

  # @param [Hash] response
  # @return [Integer]
  def find_progress(response)
    begin
      progress = response['scan_results']['progress_percentage']
    rescue StandardError
      progress = response['scan_results']['scan_details']['progress_percentage']
    end

    progress || 0
  end
end
