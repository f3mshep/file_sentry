# frozen_string_literal: true

require 'rainbow/ext/string'

module FileSentry
  # @attr [String] filepath
  # @attr [String] encryption
  # @attr [OpFile] op_file
  class CommandLine
    attr_accessor :filepath, :encryption, :op_file

    # @param [String] filepath
    # @param [String] encryption
    # @param [OpFile] op_file
    def initialize(filepath: nil, encryption: nil, op_file: nil)
      self.filepath = filepath
      self.encryption = encryption
      self.op_file = op_file || OpFile.new(filepath: filepath)
    end

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

    # @raise [ArgumentError] If scanning is not completed
    def print_result
      scan_results = op_file.scan_results
      raise ArgumentError, 'Scan not completed.' unless scan_results

      3.times { puts }
      puts "Filename: #{File.basename(op_file.filepath)}"
      puts 'Overall Status: ' + get_scan_status(scan_results)

      print_scan_results scan_results['scan_details']
    end

    # @param [Hash] scan_results
    # @return [String]
    def get_scan_status(scan_results)
      status = scan_results['scan_all_result_i'].to_i
      scan_results['scan_all_result_a'].to_s.color(status.zero? ? :green : :red)
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

    def analyze_file
      # TODO: $stdout.sync = true
      print 'Analyzing File...  '

      encrypt = encryption || 'md5'
      show_wait_spinner do
        op_file.process_file(encrypt)
      end

      print_result
    end

    def show_config
      puts 'press "y" to change API Key, or any other key to exit'
      input = gets.chomp # $stdin
      input_api_key if input.downcase == 'y'
    end

    def show_usage
      puts 'Usage: file_sentry filepath encryption'
      puts 'encryption is an optional argument'
      puts
    end

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

      File.read config_file
    rescue StandardError
      input_api_key
    end

    # @return [String]
    def input_api_key
      puts 'Please enter OPSWAT MetaDefender API Key:'
      key = gets.chomp # TODO: $stdin

      save_key(key)
      key
    end

    # @param [String] api_key
    def save_key(api_key)
      File.write config_file, api_key
      puts 'API Key saved'
    rescue StandardError
      warn 'Could not save API configuration file'.color(:yellow)
    end

    # https://stackoverflow.com/questions/10262235/printing-an-ascii-spinning-cursor-in-the-console
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

    def spin_chars(idx = 0)
      @spin_chars ||= %w[┤ ┘ ┴ └ ├ ┌ ┬ ┐].map { |s| s.color(:cyan) }.freeze
      @spin_chars[idx % @spin_chars.length]
    end
  end
end
