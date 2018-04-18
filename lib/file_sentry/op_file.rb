class OPFile

  attr_accessor :filepath, :hash, :data_id, :scan_results, :file_hash, :api_wrapper

  def initialize(attributes)
    attributes.each {|attribute, value| self.send("#{attribute}=", value)}
    self.file_hash ||= FileHash.new({op_file: self})
    self.api_wrapper ||= APIWrapper.new({op_file: self})
  end

  def process_file(encrypt)
    check_file
    file_hash.hash_file(encrypt)
    api_wrapper.scan_file
  end

  def print_result
    #move to command line class
    raise "Scan not completed" if self.scan_results.nil?
    status = scan_results["scan_all_result_a"]
    status == "No threat detected" ? status = status.colorize(:green) : status = status.colorize(:red)
    puts "\n" * 10
    puts "Filename: #{File.basename(filepath)}"
    puts "Overall Status: " + status
    puts "\n"
    scan_results["scan_details"].each do |engine_arr|
      engine = engine_arr[1]
      threats_found = engine["threat_found"].colorize(:red)
      puts "Engine: #{engine_arr[0]}"
      puts "Threats Found: #{threats_found.empty? ? "Clean".colorize(:green) : threats_found}"
      puts "Scan Result: #{engine["scan_result_i"]}"
      puts "Time: #{engine["def_time"]}"
      puts "\n"
    end
  end

  private

  def check_file
    raise "Invalid file" if !File.file?(filepath)
  end

end