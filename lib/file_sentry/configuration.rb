# frozen_string_literal: true

module FileSentry
  # @attr [String] access_key
  # @attr [Boolean] enable_gzip  Enable HTTP compression?
  # @attr [Integer] max_file_size File size limit in MB
  # @attr [Integer] scan_timeout  Scanning timeout in seconds
  # @attr [Boolean] is_debug      Debug mode is enabled or not?
  class Configuration
    attr_accessor :access_key, :enable_gzip, :max_file_size, :scan_timeout, :is_debug

    def initialize
      self.access_key = nil
      self.enable_gzip = true

      self.max_file_size = 140
      self.scan_timeout = 120

      self.is_debug = false
    end
  end
end
