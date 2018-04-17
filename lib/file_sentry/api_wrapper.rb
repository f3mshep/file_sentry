require 'httparty'

class APIWrapper

  BASE_URL = 'https://api.metadefender.com/v2'
  API_KEY = "9c2b11386f6d45999252d497855a3b0b"

  attr_accessor :op_file

  def initialize(attributes)
    attributes.each {|attribute, value| self.send("#{attribute}=", value)}
  end

  def post_file
    response = HTTParty.post(
        "#{BASE_URL}/file/",
        headers: {"apikey"=> API_KEY},
        body: {"filename" => File.read(op_file.filepath)}
      )
    error_check(response)
    op_file.data_id = response["data_id"]
  end

  def get_hash
    raise "No hash set" if op_file.hash.nil?
    response = HTTParty.get(
      "#{BASE_URL}/hash/#{op_file.hash}",
      headers: {"apikey"=> API_KEY}
    )
    error_check(response)
    op_file.data_id = response["data_id"]
  end

  def get_data_id
    raise "No data_id set" if op_file.data_id.nil?
    response = HTTParty.get(
      "#{BASE_URL}/file/#{op_file.data_id}",
      headers: {"apikey"=> API_KEY}
    )
    error_check(response)
    print_response_status(response)
    op_file.scan_results = response["scan_results"] if is_scan_complete?(response)
  end

  private

  def print_response_status(response)
    progress = response["process_info"]["progress_percentage"]
    puts
  end

  def error_check(response)
    raise "Error: #{response.message}" if response.message != "OK"
  end

  def is_scan_complete?(response)
    response["process_info"]["progress_percentage"] == 100
  end

end
