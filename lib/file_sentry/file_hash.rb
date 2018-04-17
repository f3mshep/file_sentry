require 'digest'

class FileHash

  attr_accessor :op_file

  def initialize(attributes)
    attributes.each {|attribute, value| self.send("#{attribute}=", value)}
  end

  def md5_hash
    digest = Digest::MD5.hexdigest(File.read(op_file.filepath))
    op_file.hash = digest.upcase
  end

  def sha1_hash
    digest = Digest::SHA1.hexdigest(File.read(op_file.filepath))
    op_file.hash = digest.upcase
  end

  def sha256_hash
    digest = Digest::SHA256.hexdigest(File.read(op_file.filepath))
    op_file.hash = digest.upcase
  end

end