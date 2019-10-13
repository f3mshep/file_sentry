# frozen_string_literal: true

require 'rainbow/ext/string'

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
    self.op_file = op_file || OPFile.new(filepath: filepath)
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

  # @raise [TypeError] If scanning is not completed
  def print_result
    raise TypeError, 'Scan not completed.' unless op_file.scan_results

    status = op_file.scan_results['scan_all_result_a'].to_s
    puts "\n" * 10

    puts 'Filename: ' + File.basename(op_file.filepath)
    puts 'Overall Status: ' + status.color(status =~ /\bNo\s*Threats?\b/i ? :green : :red)
    puts

    print_scan_results op_file.scan_results['scan_details']
  end

  # @param [Hash] scan_details
  def print_scan_results(scan_details)
    scan_details.each do |engine, result|
      threats_found = result['threat_found'].to_s

      puts "Engine: #{engine}"
      puts 'Threats Found: ' + (threats_found.empty? ? 'Clean'.color(:green) : threats_found.color(:red))
      puts "Scan Result: #{result['scan_result_i']}"
      puts "Time: #{result['def_time']}"
      puts
    end
  end

  def analyze_file
    # TODO: $stdout.sync = true
    print 'Analyzing File... '

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
    end
  end

  # @return [String]
  def config_file
    @config_file ||= File.join(Dir.home, '.file_sentry')
  end

  def load_api_key
    key = FileSentry.configuration.access_key
    unless key
      begin
        key = File.read config_file
      rescue IOError
        key = input_api_key
      end
    end
    key
  end

  # @return [String]
  def input_api_key
    puts 'Please enter OPSWAT MetaDefender API Key: '
    key = gets.chomp # TODO: $stdin
    save_key(key)
    key
  end

  # @param [String] api_key
  def save_key(api_key)
    File.write config_file, api_key
    puts 'API Key saved'
  rescue IOError
    warn 'Could not save API configuration file'.color(:yellow)
  end

  # https://stackoverflow.com/questions/10262235/printing-an-ascii-spinning-cursor-in-the-console
  def show_wait_spinner(fps = 10)
    chars = %w[⣾ ⣷ ⣯ ⣟ ⡿ ⢿ ⣻ ⣽].map { |s| s.color(:lightblue) }
    delay = 1.0 / fps
    iter = 0

    spinner = Thread.new do
      # Keep spinning until told otherwise
      while iter
        print chars[(iter += 1) % chars.length]
        sleep delay
        print "\b"
      end
    end

    # After yielding to the block, save the return value
    # Tell the thread to exit, cleaning up after itself and wait for it to do so.
    # Use the block's return value as the method's
    yield.tap do
      iter = false
      spinner.join
    end
  end
end
