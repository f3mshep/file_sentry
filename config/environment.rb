#Uses a block to recursively require every file in a directory
require 'file_sentry/configuration'
Dir[File.expand_path(File.join(File.dirname(File.absolute_path(__FILE__)), "../lib")) + "/**/*.rb"].each {|file| require file}
require 'digest'
require 'colorize'
require 'httparty'
require 'dotenv'
Dotenv.load('../config/.env')