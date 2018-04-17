class OPFile

  attr_accessor :filepath, :hash, :data_id, :scan_results, :file_hash, :api_wrapper

  def initialize(attributes)
    attributes.each {|attribute, value| self.send("#{attribute}=", value)}
    self.file_hash ||= FileHash.new({op_file: self})
    self.api_wrapper ||= APIWrapper.new({op_file: self})
  end

  def process_file(encrypt = "md5")
    file_hash.hash_file(encrypt)
    api_wrapper.scan_file
    binding.pry
  end

  def print_result
    raise "Scan not completed" if self.scan_results.nil?
    puts "Filename: #{File.basename(filepath)}"
    puts "Overall Status: #{scan_results["scan_all_result_a"]}"
    puts "\n"
    scan_results["scan_details"].each do |engine_arr|
      engine = engine_arr[1]
      threats_found = engine["threat_found"]
      puts "Engine: #{engine_arr[0]}"
      puts "Threats Found: #{threats_found.empty? ? "Clean" : threats_found}"
      puts "Scan Result: #{engine["scan_result_i"]}"
      puts "Time: #{engine["def_time"]}"
      puts "\n"
    end
  end

end