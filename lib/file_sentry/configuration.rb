module FileSentry
  class Configuration

    attr_accessor :access_key

    def initialize
      self.access_key = nil
    end

  end
end