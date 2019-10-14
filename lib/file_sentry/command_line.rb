# frozen_string_literal: true

require 'optparse'
require 'rainbow/ext/string'

module FileSentry
  # @attr [String] filepath
  # @attr [Hash] options
  # @attr [OpFile] op_file
  class CommandLine
    attr_accessor :filepath, :options, :op_file

    # @param [String] filepath
    # @param [Hash] options
    # @option options [String] :encryption
    # @option options [Boolean] :sanitize Clean malicious after scanning?
    # @option options [Boolean] :archive  Support scanning archive contents
    # @option options [String] :password  For password-protected archive
    # @param [OpFile] op_file
    def initialize(filepath: nil, options: nil, op_file: nil)
      self.filepath = filepath
      self.options = options
      self.op_file = op_file || OpFile.new(filepath: filepath)
    end

    # @raise [ArgumentError] If the file not found or it's size is reached the maximum limit
    # @raise [NameError] If digest encryption is not supported
    # @raise [RuntimeError] If scanning timeout or not completed or no hash/data_id set during runtime
    # @raise [TypeError] If invalid API response
    # @raise [HTTParty::ResponseError] If API response status is not OK
    def start_utility
      key = load_api_key
      config_app key

      op_file.filepath ||= filepath
      if op_file.filepath
        analyze_file
      else
        show_usage
        show_config
      end
    end

    private

    # @param [Hash] results Scan results
    # @raise [RuntimeError] If scanning is not completed
    def print_result(results = op_file.scan_results)
      raise 'Scan not completed.' unless results

      puts
      puts
      puts "Filename: #{File.basename(op_file.filepath)}"
      puts 'Overall Status: ' + get_scan_status(results)

      print_scan_results results['scan_details']
    end

    # @param [Hash] results Scan results
    # @return [String]
    def get_scan_status(results)
      status = results['scan_all_result_i'].to_i
      results['scan_all_result_a'].to_s.color(status.zero? ? :green : :red)
    end

    # @param [Hash] scan_details
    def print_scan_results(scan_details)
      scan_details.each do |engine, result|
        threats_found = result['threat_found'].to_s

        puts
        puts "Engine: #{engine}"
        puts 'Threats Found: ' + (threats_found.empty? ? 'Clean'.color(:green) : threats_found.color(:red))
        puts "Scan Result: #{result['scan_result_i']}"
        puts "Time: #{result['def_time']}"
      end
    end

    # @raise [ArgumentError] If the file not found or it's size is reached the maximum limit
    # @raise [NameError] If digest encryption is not supported
    # @raise [RuntimeError] If scanning timeout or not completed or no hash/data_id set during runtime
    # @raise [TypeError] If invalid API response
    # @raise [HTTParty::ResponseError] If API response status is not OK
    def analyze_file
      $stdout.sync = true
      print 'Analyzing File...  '

      show_wait_spinner do
        begin
          process_file options
        ensure
          puts
        end
      end

      print_result
    end

    # @param [Hash] opts
    # @option opts [String] :encryption
    # @option opts [Boolean] :sanitize  Clean malicious after scanning?
    # @option opts [Boolean] :archive   Support scanning archive contents
    # @option opts [String] :password   For password-protected archive
    # @return [Hash] Scan results
    # @raise [ArgumentError] If the file not found or it's size is reached the maximum limit
    # @raise [NameError] If digest encryption is not supported
    # @raise [RuntimeError] If scanning timeout or no hash/data_id set during runtime
    # @raise [TypeError] If invalid API response
    # @raise [HTTParty::ResponseError] If API response status is not OK
    def process_file(opts)
      op_file.process_file(
        opts[:encryption] || 'md5',
        sanitize: opts[:sanitize],
        unarchive: !opts.key?(:archive) || opts[:archive],
        archive_pwd: opts[:password]
      )
    end

    def show_config
      puts 'press "y" to change API Key, or any other key to exit'
      input = $stdin.gets.chomp
      input_api_key if input.downcase == 'y'
    end

    def show_usage
      puts 'Usage: file_sentry filepath encryption'
      puts 'encryption is an optional argument'
      puts
    end

    # @param [String] key
    def config_app(key)
      FileSentry.configure do |config|
        config.access_key = key

        ApiWrapper.configure config
      end
    end

    # @return [String]
    def config_file
      @config_file ||= File.join(Dir.home, '.file_sentry')
    end

    def load_api_key
      key = FileSentry.configuration.access_key
      return key if key

      has_config = File.size?(config_file)
      key = File.read(config_file) if has_config

      key = input_api_key if !key || key.empty?
      key
    end

    # @return [String]
    def input_api_key
      puts 'Please enter OPSWAT MetaDefender API Key:'
      key = $stdin.gets.chomp

      save_key key
      key
    end

    # @param [String] api_key
    def save_key(api_key)
      File.write config_file, api_key
    end

    # https://stackoverflow.com/questions/10262235/printing-an-ascii-spinning-cursor-in-the-console
    # @param [Float] delay
    # @param [Integer] loop
    def show_wait_spinner(delay = 0.1, loop = 0)
      spinner = Thread.new do
        # Keep spinning until told otherwise
        while loop
          print "\b#{spin_chars(loop += 1)}"
          sleep delay
        end
      end

      # After yielding to the block, save the return value
      # Tell the thread to exit, cleaning up after itself and wait for it to do so.
      # Use the block's return value as the method's
      yield.tap do
        loop = false
        spinner.join
      end
    end

    # @param [Integer] index
    # @return [String]
    def spin_chars(index = nil)
      @spin_chars ||= %w[┤ ┘ ┴ └ ├ ┌ ┬ ┐].map { |s| s.color(:cyan) }.freeze
      !index ? @spin_chars : @spin_chars[index % @spin_chars.length]
    end
  end
end
