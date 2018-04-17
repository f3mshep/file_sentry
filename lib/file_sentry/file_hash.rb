class FileHash

  attr_accessor :hash, :op_file

  def initialize(op_file)
    self.op_file = op_file
  end

  def md5_hash
  end

  def sha1_hash
  end

  def sha256_hash
  end

end