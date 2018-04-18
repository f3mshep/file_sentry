class FileHash

  attr_accessor :op_file

  def initialize(attributes)
    attributes.each {|attribute, value| self.send("#{attribute}=", value)}
  end

  def hash_file(encryption)
    begin
      self.send("digest_#{encryption.downcase}")
    rescue
      raise "No encryption found for: #{encryption}"
    end
  end

  private

  def digest_md5
    digest = Digest::MD5.file op_file.filepath
    op_file.hash = digest.hexdigest.upcase
  end

  def digest_sha1
    digest = Digest::SHA1.file op_file.filepath
    op_file.hash = digest.hexdigest.upcase
  end

  def digest_sha256
    digest = Digest::SHA256.file op_file.filepath
    op_file.hash = digest.hexdigest.upcase
  end

end