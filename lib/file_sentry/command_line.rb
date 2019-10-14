# frozen_string_literal: true

require 'optparse'
require 'rainbow/ext/string'

module FileSentry
  # @attr [String] filepath
  # @attr [Hash] options
  # @attr [OpFile] op_file
  class CommandLine # rubocop:disable Metrics/ClassLength
    attr_accessor :filepath, :options, :op_file

    # @param [Array] args
    # @param [String] filepath
    # @param [Hash] options
    # @option options [String] :encryption
    # @option options [Boolean] :sanitize Clean malicious after scanning?
    # @option options [Boolean] :archive  Support scanning archive contents
    # @option options [String] :password  For password-protected archive
    # @option options [String] :key       API key
    # @option options [Integer] :limit    File size limit in MB
    # @option options [Integer] :timeout  Scanning timeout in seconds
    # @option options [Boolean] :debug
    # @param [OpFile] op_file
    def initialize(args = nil, filepath: nil, options: nil, op_file: nil)
      @args = args
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
      parse_arguments @args

      options[:key] = load_api_key
      config_app options

      op_file.filepath ||= filepath
      if op_file.filepath
        analyze_file
      else
        # show usage
        puts opt_parser
      end
    end

    private

    # @raise [RuntimeError] If scanning is not completed
    def print_result
      results = op_file.scan_results
      raise 'Scan not completed.' unless results

      print_scan_results results['scan_details']

      puts
      puts
      puts "Filename: #{File.basename(op_file.filepath)}"
      print_scan_status results

      # print_sanitized_file(results['sanitized']) if options[:sanitize] && op_file.infected?
    end

    # @param [Hash] results Scan results
    def print_scan_status(results)
      puts 'Overall Status: ' + results['scan_all_result_a'].to_s.color(op_file.infected? ? :red : :green)
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

    # @return [OptionParser]
    def opt_parser
      @opt_parser ||= OptionParser.new do |opts|
        opts.banner = 'Usage: file_sentry [options] filepath'
        opts.separator '  Scan a file for malware with OPSWAT MetaDefender Cloud API'
        opts.separator 'Options:'

        init_parser_params opts

        opts.separator nil
        init_parser_options opts
      end
    end

    # @param [OptionParser] opts
    def init_parser_params(opts)
      opts.on('--file filepath', 'Relative path to file for scanning')
      opts.on('-e', '--encryption [MD5]', 'Hash digest for the file (md5 sha1 sha256)')

      opts.on('-s', '--[no-]sanitize', 'Clean malicious after scanning')
      opts.on('-a', '--[no-]archive', 'Support scanning archive contents')
      opts.on('-p', '--password [ARCHIVE_PWD]', 'For password-protected archive')
    end

    # @param [OptionParser] opts
    def init_parser_options(opts)
      opts.on('-k', '--key [API_KEY]', 'API key')
      opts.on('-l', '--limit [140]', Integer, 'File size limit in MB')
      opts.on('-t', '--timeout [120]', Integer, 'Scanning timeout in seconds')

      opts.separator nil
      opts.on('-d', '--[no-]debug', 'Run verbosely')
      opts.on('-h', '--help', 'Prints this help') do
        puts opts
        exit
      end
    end

    # @param [Array] args
    def parse_arguments(args)
      opts = {}
      rest = args ? opt_parser.parse!(args, into: opts) : nil
      opts[:file] = rest.first if rest && !rest.empty?

      self.options ||= opts
      self.filepath ||= options.delete :file
    rescue RuntimeError => e
      warn e # .to_s.color(:white)
      puts opt_parser
      exit
    end

    # @param [Hash] opts
    # @option opts [String] :key      API key
    # @option opts [Integer] :limit   File size limit in MB
    # @option opts [Integer] :timeout Scanning timeout in seconds
    # @option opts [Boolean] :debug
    def config_app(opts)
      FileSentry.configure do |config|
        config.access_key = opts[:key]
        config.max_file_size = opts[:limit] if opts.key?(:limit)
        config.scan_timeout = opts[:timeout] if opts.key?(:timeout)

        config.is_debug = opts[:debug]
        ApiWrapper.configure config
      end
    end

    # @return [String]
    def config_file
      @config_file ||= File.join(Dir.home, '.file_sentry')
    end

    # @return [String]
    def load_api_key
      key = options[:key]

      if key
        save_key key
      else
        key = File.read(config_file) if File.size?(config_file)
        key = input_api_key if !key || key.empty?
      end

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
        # noinspection RubyUnusedLocalVariable
        loop = false
        spinner.join
      end
    end

    # @param [Integer] index
    # @return [String]
    def spin_chars(index = nil)
      @spin_chars ||= %w[┤ ┘ ┴ └ ├ ┌ ┬ ┐].map { |s| s.color(:cyan) }.freeze
      index ? @spin_chars[index % @spin_chars.length] : @spin_chars
    end
  end
end
