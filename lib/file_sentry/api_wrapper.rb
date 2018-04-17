require 'httparty'

class APIWrapper

  BASE_URL = 'https://api.metadefender.com/v2'
  API_KEY = "9c2b11386f6d45999252d497855a3b0b"

  attr_accessor :op_file

  def initialize(attributes)
    attributes.each {|attribute, value| self.send("#{attribute}=", value)}
  end

  def post_file
    response = HTTParty.post("#{BASE_URL}/file/", {apikey: API_KEY})
  end

  def get_hash
    response = HTTParty.get("#{BASE_URL}/hash/#{op_file.hash}", {apikey: API_KEY})
  end

  def get_data_id
    raise "No data_id set" if op_file.data_id.nil?
    response = HTTParty.get("#{BASE_URL}/file/#{op_file.data_id}", {apikey: API_KEY})
  end

end