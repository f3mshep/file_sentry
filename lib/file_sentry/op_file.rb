class OPFile

  attr_accessor :filepath, :hash, :data_id, :scan_results, :file_hash

  def initialize(attributes)
    attributes.each {|attribute, value| self.send("#{attribute}=", value)}
    self.file_hash ||= FileHash.new(filepath)
    self.api_wrapper ||= APIWrapper.new(self)
  end

  def process_file(encrypt)
    file_hash.hash_file(encrypt)
    api_wrapper.scan_file
    binding.pry
  end

  def print_result
  end

end