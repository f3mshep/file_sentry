# frozen_string_literal: true

# @attr [String] filepath
# @attr [FileHash] file_hash
# @attr [ApiWrapper] api_wrapper
# @attr [String] hash
# @attr [String] data_id
# @attr [Hash] scan_results
class OPFile
  attr_accessor :filepath, :file_hash, :api_wrapper, :hash, :data_id, :scan_results

  # @param [String] filepath
  # @param [FileHash] file_hash
  # @param [ApiWrapper] api_wrapper
  def initialize(filepath: nil, file_hash: nil, api_wrapper: nil)
    self.filepath = filepath
    self.file_hash = file_hash || FileHash.new(op_file: self)
    self.api_wrapper = api_wrapper || APIWrapper.new(op_file: self)
  end

  # @param [String] encrypt
  # @return [Hash] Scan results
  def process_file(encrypt)
    check_file
    file_hash.hash_file encrypt
    api_wrapper.scan_file
  end

  private

  # @raise [IOError] If the filepath is invalid
  # @raise [RangeError] If the file-size is reached the maximum limit
  def check_file
    raise IOError, 'Invalid file.' unless File.file?(filepath)
    raise RangeError, 'File size is too large.' if file_size_limit > 0.0 && file_size_mb > file_size_limit
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
