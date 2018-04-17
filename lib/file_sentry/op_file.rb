class OPFile

  attr_accessor :filepath, :hash, :data_id, :scan_results, :file_hash

  def initialize(attributes)
    attributes.each {|attribute, value| self.send("#{attribute}=", value)}
    self.file_hash ||= FileHash.new(filepath)
    self.api_wrapper ||= APIWrapper.new(self)
  end

  def process_file
    #change this to send :md5_hash or whatever
    file_hash.md5_hash
    if api_wrapper.get_hash
      api_wrapper.get_data_id
    end

  end

end