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

  private

  def check_file
    raise "Invalid file" if !File.file?(filepath)
    raise "File size too large" if get_file_size > 140
  end

  def get_file_size
    ('%.2f' % (File.size(filepath).to_f / 2**20)).to_i
  end

end