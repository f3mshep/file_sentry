# frozen_string_literal: true

require 'rainbow/ext/string'

class CommandLine
  attr_accessor :filepath, :encryption, :op_file

  def initialize(attributes)
    attributes.each {|attribute, value| self.send("#{attribute}=", value) }
    self.op_file = OPFile.new({filepath: filepath})
  end

  def start_utility
    key = load_api_key
    config_app(key)
    op_file.filepath = filepath
    if filepath
      analyze_file
    else
      show_usage
      show_config
    end
  end

  private

  def print_result
    raise 'Scan not completed.' unless op_file.scan_results

    status = op_file.scan_results['scan_all_result_a']
    puts "\n" * 10

    puts 'Filename: ' + File.basename(op_file.filepath)
    puts 'Overall Status: ' + (status =~ /\bNo\s*Threats?\b/i ? status.green : status.red)
    puts

    op_file.scan_results['scan_details'].each do |engine, result|
      threats_found = result['threat_found'].to_s

      puts "Engine: #{engine}"
      puts 'Threats Found: ' + (threats_found.empty? ? 'Clean'.green : threats_found.red)
      puts "Scan Result: #{result['scan_result_i']}"
      puts "Time: #{result['def_time']}"
      puts
    end
  end

  def analyze_file
    encrypt = encryption || 'md5'
    print 'Analyzing File... '
    show_wait_spinner { op_file.process_file(encrypt) }
    print_result
  end

  def show_config
    puts "press 'y' to change API Key, or any other key to exit"
    input = STDIN.gets.chomp
    get_key_from_user if input.downcase == 'y'
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

  def load_api_key
    key = FileSentry.configuration.access_key
    if key.nil?
      begin
        key = File.read("#{Dir.home}/.file_sentry")
      rescue
        key = get_key_from_user
      end
    end
    key
  end

  def get_key_from_user
    puts 'Please enter OPSWAT MetaDefender API Key: '
    key = STDIN.gets.chomp
    save_key(key)
    key
  end

  def save_key(key)
    begin
      File.write("#{Dir.home}/.file_sentry", key)
      puts 'API Key saved'
    rescue
      warn 'Could not save API configuration file'.yellow
    end
    key
  end

  # https://stackoverflow.com/questions/10262235/printing-an-ascii-spinning-cursor-in-the-console
  def show_wait_spinner(fps = 10)
    chars = %w[⣾ ⣷ ⣯ ⣟ ⡿ ⢿ ⣻ ⣽].map(&:lightblue).freeze
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
