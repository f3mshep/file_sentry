# frozen_string_literal: true

module FileSentry
  # @attr [String] filepath
  # @attr [FileHash] file_hash
  # @attr [ApiWrapper] api_wrapper
  # @attr [String] hash
  # @attr [String] data_id
  # @attr [Hash] scan_results
  class OpFile
    attr_accessor :filepath, :file_hash, :api_wrapper, :hash, :data_id, :scan_results

    # @param [String] filepath
    # @param [Hash] opts
    # @option opts [FileHash] :file_hash
    # @option opts [ApiWrapper] :api_wrapper
    def initialize(filepath = nil, opts = {})
      self.filepath = filepath
      self.file_hash = opts[:file_hash] || FileHash.new(self)
      self.api_wrapper = opts[:api_wrapper] || ApiWrapper.new(self)
    end

    # @param [String] encrypt   Digest encryption
    # @param [Hash] opts
    # @option opts [Boolean] :sanitize  Clean malicious after scanning?
    # @option opts [Boolean] :unarchive
    # @option opts [String] :archive_pwd For password-protected archive
    # @return [Hash] Scan results
    # @raise [ArgumentError] If the file not found or it's size is reached the maximum limit
    # @raise [NameError] If digest encryption is not supported
    # @raise [RuntimeError] If scanning timeout or no hash/data_id set during runtime
    # @raise [TypeError] If invalid API response
    # @raise [HTTParty::ResponseError] If API response status is not OK
    def process_file(encrypt, opts = {})
      check_file
      file_hash.hash_file encrypt
      api_wrapper.scan_file opts[:sanitize], opts.fetch(:unarchive, true), opts[:archive_pwd]
    end

    # @return [Boolean] Scanned file is infected?
    def infected?
      scan_results ? scan_results['scan_all_result_i'].to_i.nonzero? : nil
    end

    # @return [String] Download URL for sanitized file
    # @raise [RuntimeError] If no sanitized results found or sanitized data_id was not set
    # @raise [TypeError] If invalid API response
    # @raise [HTTParty::ResponseError] If API response status is not OK
    def sanitized_url
      results = scan_results ? scan_results['sanitized'] : nil
      raise 'No sanitized results found.' unless results

      results['file_path'] || api_wrapper.get_sanitized_url(results['data_id'])
    end

    # @param [String] save_to   File path to save to
    # @param [Hash] opts
    # @option opts [Boolean] :use_api Use API key for requesting
    # @return [Boolean] Success?
    # @raise [TypeError] If invalid API response
    # @raise [HTTParty::ResponseError] If API response status is not OK
    def download_sanitized(save_to = nil, opts = {})
      url = sanitized_url
      return false unless url

      save_to ||= filepath + '.sanitized'
      api_wrapper.download_file url, save_to, opts

    # Returns FALSE if no sanitized results found or sanitized data_id was not set
    rescue RuntimeError => e
      warn e if FileSentry.configuration.is_debug
      false
    end

    private

    # @raise [ArgumentError] If the file not found or it's size is reached the maximum limit
    def check_file
      raise ArgumentError, 'Invalid file.' unless File.file?(filepath)
      raise ArgumentError, 'File size is too large.' if file_size_limit > 0.0 && file_size_mb > file_size_limit
    end

    # @return [Float]
    def file_size_mb
      File.size(filepath).to_f / 1_048_576
    end

    # @return [Float]
    def file_size_limit
      @file_size_limit ||= FileSentry.configuration.max_file_size.to_f
    end
  end
end
