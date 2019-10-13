# frozen_string_literal: true

require 'digest'

module FileSentry
  class FileHash
    # @return [OpFile]
    attr_accessor :op_file

    # @param [OpFile] op_file
    def initialize(op_file:)
      self.op_file = op_file
    end

    # @param [Object] encryption
    # @return [String] The file hashed as a hex-string
    # @raise [NotImplementedError] If encryption is not supported
    def hash_file(encryption)
      digest = get_digest(encryption).file op_file.filepath
      op_file.hash = digest.hexdigest.upcase
    end

    private

    # @param [Object] encryption
    # @return [Digest::Instance]
    # @raise [NotImplementedError] If encryption is not supported
    def get_digest(encryption)
      case encryption.to_s.strip.upcase
      when 'MD5'
        Digest::MD5
      when 'SHA1'
        Digest::SHA1
      when 'SHA256'
        # noinspection RubyResolve
        Digest::SHA256
      else
        # No encryption found for: encryption
        raise NotImplementedError, "Unsupported encryption: #{encryption}"
      end
    end
  end
end
