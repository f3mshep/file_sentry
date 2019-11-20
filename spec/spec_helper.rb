# frozen_string_literal: true

require 'bundler/setup'
require 'file_sentry'
require 'file_sentry/command_line'

require 'webmock/rspec'
require_relative 'webmock_helper'

module Helpers
  # @return [String]
  def rand_encrypt
    %w[md5 sha1 sha256].sample
  end

  # @return [Boolean]
  def rand_boolean
    rand(2).zero?
  end

  def configure_api_key(key, debug = false, immediately = false)
    FileSentry.configure do |config|
      config.access_key = key
      config.enable_gzip = !(config.is_debug = debug)

      FileSentry::ApiWrapper.configure(config) if immediately
    end
  end

  def mock_save_api_key(key = /\S+/, path = /\.file_sentry$/)
    allow(File).to receive(:write).with(path, key)
  end
end

RSpec.configure do |config|
  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  config.include Helpers
  config.include WebMockHelper

  config.before :all do
    configure_api_key(opswat_key, true)
  end
end
