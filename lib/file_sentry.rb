# frozen_string_literal: true

require 'file_sentry/version'
require 'file_sentry/configuration'
require 'file_sentry/op_file'
require 'file_sentry/file_hash'
require 'file_sentry/api_wrapper'

module FileSentry
  # All methods in this block are static
  class << self
    attr_writer :configuration

    # @return [Configuration]
    def configuration
      @configuration ||= Configuration.new
    end

    # @return [Configuration]
    def reset
      @configuration = Configuration.new
    end

    # @yieldreturn [Configuration]
    def configure
      yield(configuration)
    end
  end
end
