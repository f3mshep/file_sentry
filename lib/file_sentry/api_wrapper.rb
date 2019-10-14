# frozen_string_literal: true

require 'httparty'

module FileSentry
  class ApiWrapper
    include HTTParty
    base_uri 'https://api.metadefender.com/v4'

    # @return [OpFile]
    attr_accessor :op_file

    # @param [OpFile] op_file
    def initialize(op_file:)
      self.op_file = op_file

      self.class.configure
    end

    def self.configure(config = nil)
      config ||= FileSentry.configuration

      # default request headers
      headers 'apikey' => config.access_key

      if config.is_debug
        debug_output
      else
        debug_output nil
      end
    end

    # @param [Boolean] sanitize Clean malicious after scanning?
    # @param [Boolean] unarchive
    # @param [String] archive_pwd For password-protected archive
    # @return [Hash] Scan results
    # @raise [RuntimeError] If scanning timeout or no hash/data_id set during runtime
    # @raise [TypeError] If invalid API response
    # @raise [HTTParty::ResponseError] If API response status is not OK
    def scan_file(sanitize = false, unarchive = true, archive_pwd = nil)
      response = report_by_hash
      response = upload_file(sanitize, unarchive, archive_pwd) unless does_hash_exist?(response, op_file.hash)
      save_data_id response

      monitor_scan
    end

    private

    # @return [Hash] Scan results
    # @raise [RuntimeError] If scanning timeout or no data_id set during runtime
    # @raise [TypeError] If invalid API response
    # @raise [HTTParty::ResponseError] If API response status is not OK
    def monitor_scan
      (FileSentry.configuration.scan_timeout || 3600).times do
        sleep(1)
        response = report_by_data_id

        return op_file.scan_results = response['scan_results'] if scan_complete?(response)
      end

      raise 'Error: API timeout.'
    end

    # @param [Boolean] sanitize Clean malicious after scanning?
    # @param [Boolean] unarchive
    # @param [String] archive_pwd For password-protected archive
    # @return [Hash] Uploading status
    # @raise [TypeError] If invalid API response
    # @raise [HTTParty::ResponseError] If API response status is not OK
    def upload_file(sanitize = false, unarchive = true, archive_pwd = nil)
      rules = []
      rules << 'sanitize' if sanitize
      rules << 'unarchive' if unarchive || archive_pwd

      api_headers = {}
      api_headers['rule'] = rules.join(',') unless rules.empty?
      api_headers['archivepwd'] = archive_pwd if archive_pwd

      response = self.class.post '/file/', headers: api_headers, body_stream: File.open(op_file.filepath, 'rb')
      error_check(response)
    end

    # @return [Hash] Scan reports
    # @raise [RuntimeError] If file hash was not set
    # @raise [TypeError] If invalid API response
    # @raise [HTTParty::ResponseError] If API response status is not OK
    def report_by_hash
      raise 'No hash set.' unless op_file.hash

      response = self.class.get '/hash/' + op_file.hash
      error_check(response, [200, 404])
    end

    # @return [Hash] Scan reports
    # @raise [RuntimeError] If data_id was not set
    # @raise [TypeError] If invalid API response
    # @raise [HTTParty::ResponseError] If API response status is not OK
    def report_by_data_id
      raise 'No data_id set.' unless op_file.data_id

      response = self.class.get '/file/' + op_file.data_id
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
      response.any? do |_, val|
        (val.is_a?(String) && hash.casecmp(val).zero?) || (val.is_a?(Hash) && does_hash_exist?(val, hash))
      end
    end

    # @param [HTTParty::Response] response
    # @param [Array<Integer>] ok_on
    # @return [Hash] Parsed response
    # @raise [TypeError] If invalid API response
    # @raise [HTTParty::ResponseError] If API response status is not OK
    def error_check(response, ok_on = nil)
      raise TypeError, 'Error: No response.' unless response

      ok_on = [200] if !ok_on || ok_on.empty?
      data = response.parsed_response

      unless ok_on.include?(response.code)
        raise HTTParty::ResponseError.new(response.response), "Error: #{find_err_message(response, data)}"
      end

      data
    end

    # @param [HTTParty::Response] response
    # @param [Hash] data
    # @return [Object]
    def find_err_message(response, data)
      err = data.is_a?(Hash) ? (data['err'] || data.dig('error', 'messages')&.first) : response.body
      err && !err.empty? ? err : response.message
    end

    # @param [Hash] response
    # @return [Boolean]
    def scan_complete?(response)
      find_progress(response) >= 100
    end

    # @param [Hash] response
    # @return [Integer]
    def find_progress(response)
      (response.dig('scan_results', 'progress_percentage') ||
        response.dig('scan_results', 'scan_details', 'progress_percentage')).to_i
    end
  end
end
