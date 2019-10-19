# frozen_string_literal: true

require 'simplecov'
SimpleCov.start

require 'bundler/setup'
require 'file_sentry'
require 'file_sentry/command_line'

require 'webmock/rspec'
require_relative 'webmock_helper'

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = '.rspec_status'

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  config.include WebMockHelper

  config.before :all do
    FileSentry.configure do |cfg|
      cfg.access_key = opswat_key
      cfg.is_debug = true
      cfg.enable_gzip = false
    end
  end
end
