require "bundler/setup"
require "file_sentry"
require "pry"
require 'dotenv'
Dotenv.load('.env')
require_relative "../config/environment.rb"

RSpec.configure do |config|
  # Use color in STDOUT
  config.color = true

  # Use color not only in STDOUT but also in pagers and files
  config.tty = true

  # Use the specified formatter
  config.formatter = :documentation # :progress, :html,
                                    # :json, CustomFormatterClass
  config.before(:all) do
    FileSentry.configure do |config|
      config.access_key = ENV["OPSWAT_KEY"]
    end
  end

end
