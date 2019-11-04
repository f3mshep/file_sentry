# encoding: UTF-8
# frozen_string_literal: true

require 'optparse'
require 'rainbow/ext/string'

module FileSentry
  class CommandOptions
    class << self
      # @param [Array] args
      def parse(args)
        into = {}
        rest = []
        parser.send(:parse_in_order, args, proc { |name, val| into[name.to_sym] = val }, &rest.method(:<<)) if args

        into[:file] = rest.first unless rest.empty?
        into
      rescue RuntimeError => e
        warn e # to_s.color(:white)
        puts parser
        exit
      end

      # @return [OptionParser]
      def parser
        @parser ||= OptionParser.new do |opts|
          opts.banner = 'Usage: file_sentry [options] filepath'
          opts.separator '  Scan a file for malware with OPSWAT MetaDefender Cloud API'
          opts.separator 'Options:'

          init_parser_params opts

          opts.separator nil
          init_parser_options opts
        end
      end

      private

      # @param [OptionParser] opts
      def init_parser_params(opts)
        opts.on('--file filepath', 'Relative path to file for scanning')
        opts.on('-e', '--encryption [MD5]', 'Hash digest for the file (md5 sha1 sha256)')

        opts.on('-s', '--[no-]sanitize', 'Clean malicious after scanning')
        opts.on('-a', '--[no-]archive', 'Support scanning archive contents (Enabled)')
        opts.on('-p', '--password [ARCHIVE_PWD]', 'For password-protected archive')
      end

      # @param [OptionParser] opts
      def init_parser_options(opts)
        opts.on('-k', '--key [API_KEY]', 'API key')
        opts.on('-z', '--[no-]gzip', 'Support HTTP compression (Enabled)')
        opts.on('-l', '--limit [140]', Integer, 'File size limit in MB')
        opts.on('-t', '--timeout [120]', Integer, 'Scanning timeout in seconds')

        opts.separator nil
        opts.on('-d', '--[no-]debug', 'Run verbosely')
        opts.on('-h', '--help', 'Prints this help') do
          puts opts
          exit
        end
      end
    end
  end

  # @attr [String] filepath
  # @attr [Hash] options
  # @attr [OpFile] op_file
  class CommandLine
    attr_accessor :filepath, :options, :op_file

    # @param [Array] args
    # @param [Hash] opts
    # @option opts [String] :filepath
    # @option opts [Hash] :options
    # @option opts [OpFile] :op_file
    # @option options [String] :encryption
    # @option options [Boolean] :sanitize Clean malicious after scanning?
    # @option options [Boolean] :archive  Support scanning archive contents
    # @option options [String] :password  For password-protected archive
    # @option options [String] :key       API key
    # @option options [Boolean] :gzip     Support HTTP compression?
    # @option options [Integer] :limit    File size limit in MB
    # @option options [Integer] :timeout  Scanning timeout in seconds
    # @option options [Boolean] :debug
    def initialize(args = nil, opts = {})
      @args = args
      self.filepath = opts[:filepath]
      self.options = opts[:options]
      self.op_file = opts[:op_file] || OpFile.new(opts[:filepath])
    end

    # @raise [ArgumentError] If the file not found or it's size is reached the maximum limit
    # @raise [NameError] If digest encryption is not supported
    # @raise [RuntimeError] If scanning timeout or not completed or no hash/data_id set during runtime
    # @raise [TypeError] If invalid API response
    # @raise [HTTParty::ResponseError] If API response status is not OK
    def start_utility
      self.options ||= CommandOptions.parse(@args)
      self.filepath ||= options.delete(:file)

      load_api_key
      config_app options

      if op_file.filepath ||= filepath
        analyze_file
      else
        # show usage
        puts CommandOptions.parser
      end
    end

    private

    # @raise [RuntimeError] If scanning is not completed
    # @raise [TypeError] If invalid API response
    # @raise [HTTParty::ResponseError] If API response status is not OK
    def print_result
      results = op_file.scan_results
      raise 'Scan not completed.' unless results

      print_scan_results results['scan_details']

      print_overall_status results
      print_sanitized_file if options[:sanitize] && results.key?('sanitized')
    end

    # @param [Hash] scan_results
    def print_overall_status(scan_results)
      puts
      puts
      puts "Filename: #{File.basename(op_file.filepath)}"
      puts 'Overall Status: ' + scan_results['scan_all_result_a'].to_s.color(op_file.infected? ? :red : :green)
    end

    # @raise [TypeError] If invalid API response
    # @raise [HTTParty::ResponseError] If API response status is not OK
    def print_sanitized_file
      puts "Sanitized filepath: #{op_file.sanitized_url}"
    rescue RuntimeError => e
      warn e
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

      WaitSpinner.show do
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
    def process_file(opts = options)
      op_file.process_file(
        opts[:encryption] || 'md5',
        sanitize: opts[:sanitize],
        unarchive: !opts.key?(:archive) || opts[:archive],
        archive_pwd: opts[:password]
      )
    end

    # @param [Hash] opts
    # @option opts [String] :key      API key
    # @option opts [Boolean] :gzip    Support HTTP compression?
    # @option opts [Integer] :limit   File size limit in MB
    # @option opts [Integer] :timeout Scanning timeout in seconds
    # @option opts [Boolean] :debug
    def config_app(opts = options)
      FileSentry.configure do |config|
        config.access_key = opts[:key]
        config.enable_gzip = !opts.key?(:gzip) || opts[:gzip]

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

    def load_api_key
      key = options[:key]
      if key
        save_key key
      else
        key = File.read(config_file) if File.size?(config_file)

        key = input_api_key if !key || key.empty?
        options[:key] = key
      end
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
  end

  # https://stackoverflow.com/questions/10262235/printing-an-ascii-spinning-cursor-in-the-console
  class WaitSpinner
    class << self
      # @param [Float] delay
      # @param [Integer] loop
      def show(delay = 0.1, loop = 0)
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

      private

      # @param [Integer] index
      # @return [String]
      def spin_chars(index)
        @spin_chars ||= %w[┤ ┘ ┴ └ ├ ┌ ┬ ┐].map { |s| s.color(:cyan) }.freeze
        @spin_chars[index % @spin_chars.length]
      end
    end
  end
end
