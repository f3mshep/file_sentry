require 'spec_helper'
require 'webmock/rspec'

BAD_API_KEY = "BAD API KEY"
BAD_HASH = "IAMNOTREAL"

describe APIWrapper do
  before :each do
    @op_file = OPFile.new({filepath: "spec/test_file.txt"})
    @file_hash = FileHash.new({op_file: @op_file})
    @api_wrapper = APIWrapper.new({op_file: @op_file})
    @file_hash.hash_file("md5")

    # API output
    #GET data_id
    data_id_response = {"file_id"=>"dDE4MDQxN0JKdHNNbTNRaHo",
    "data_id"=>"dDE4MDQxN0JKdHNNbTNRaHpCSnFzTVgyUTN6",
    "archived"=>false,
    "process_info"=>
      {"user_agent"=>"",
      "result"=>"Allowed",
      "progress_percentage"=>100,
      "profile"=>"File scan",
      "file_type_skipped_scan"=>false,
      "blocked_reason"=>""},
    "scan_results"=>
      {"scan_details"=>
        {"nProtect"=>
          {"wait_time"=>19,
          "threat_found"=>"",
          "scan_time"=>2957,
          "scan_result_i"=>0,
          "def_time"=>"2018-04-17T05:00:00.000Z"},
        },
      "rescan_available"=>true,
      "data_id"=>"dDE4MDQxN0JKdHNNbTNRaHpCSnFzTVgyUTN6",
      "scan_all_result_i"=>0,
      "start_time"=>"2018-04-17T17:47:01.988Z",
      "total_time"=>3021,
      "total_avs"=>37,
      "total_detected_avs"=>0,
      "progress_percentage"=>100,
      "in_queue"=>0,
      "scan_all_result_a"=>"No threat detected"},
    "file_info"=>
      {"file_size"=>17,
      "upload_timestamp"=>"2018-04-17T17:47:01.979Z",
      "md5"=>"3A93D4CCEF8CFDE41DF8F543852B4A43",
      "sha1"=>"0511263E3518679BF8297C93D551AAB7F2B93196",
      "sha256"=>
        "EF748125CF8B36714F7D99ED170B664E27D545AAFE3C54EC85371EA48AAA35BA",
      "file_type_category"=>"T",
      "file_type_description"=>"ASCII text, with no line terminators",
      "file_type_extension"=>"txt",
      "display_name"=>"test_file.txt"},
    "top_threat"=>-1,
    "share_file"=>1,
    "rest_version"=>"4",
    "original_file"=>
      {"detected_by"=>0,
      "progress_percentage"=>100,
      "scan_result_i"=>0,
      "data_id"=>"dDE4MDQxN0JKdHNNbTNRaHpCSnFzTVgyUTN6"}}

    #GET hash
    hash_response = {"file_id"=>"dDE4MDQxN0JKdHNNbTNRaHo",
    "data_id"=>"dDE4MDQxN0JKdHNNbTNRaHpCSnFzTVgyUTN6",
    "archived"=>false,
    "process_info"=>
      {"user_agent"=>"",
      "result"=>"Allowed",
      "progress_percentage"=>100,
      "profile"=>"File scan",
      "file_type_skipped_scan"=>false,
      "blocked_reason"=>""},
    "scan_results"=>
      {"scan_details"=>
        {"nProtect"=>
          {"wait_time"=>19,
          "threat_found"=>"",
          "scan_time"=>2957,
          "scan_result_i"=>0,
          "def_time"=>"2018-04-17T05:00:00.000Z"},
        },
      "rescan_available"=>true,
      "data_id"=>"dDE4MDQxN0JKdHNNbTNRaHpCSnFzTVgyUTN6",
      "scan_all_result_i"=>0,
      "start_time"=>"2018-04-17T17:47:01.988Z",
      "total_time"=>3021,
      "total_avs"=>37,
      "total_detected_avs"=>0,
      "progress_percentage"=>100,
      "in_queue"=>0,
      "scan_all_result_a"=>"No threat detected"},
    "file_info"=>
      {"file_size"=>17,
      "upload_timestamp"=>"2018-04-17T17:47:01.979Z",
      "md5"=>"3A93D4CCEF8CFDE41DF8F543852B4A43",
      "sha1"=>"0511263E3518679BF8297C93D551AAB7F2B93196",
      "sha256"=>
        "EF748125CF8B36714F7D99ED170B664E27D545AAFE3C54EC85371EA48AAA35BA",
      "file_type_category"=>"T",
      "file_type_description"=>"ASCII text, with no line terminators",
      "file_type_extension"=>"txt",
      "display_name"=>"test_file.txt"},
    "top_threat"=>-1,
    "share_file"=>1,
    "rest_version"=>"4"}

    # API Stub responses
    # GET hash stub (hash exists)
    stub_request(:get, "https://api.metadefender.com/v2/hash/3A93D4CCEF8CFDE41DF8F543852B4A43").
      with(  headers: {
      'Apikey'=>'9c2b11386f6d45999252d497855a3b0b'
      }).
      to_return(
        status: [200, "OK"],
        body: JSON.generate(hash_response),
        headers: {content_type: 'application/json'})
    # GET hash stub (hash does not exist)
    stub_request(:get, "https://api.metadefender.com/v2/hash/#{BAD_HASH}").
      with(  headers: {
      'Apikey'=>'9c2b11386f6d45999252d497855a3b0b'
      }).
      to_return(
        status: [200, "OK"],
        body: JSON.generate({BAD_HASH => "Not Found"}),
        headers: {content_type: 'application/json'})
    # Invalid API
    stub_request(:get, "https://api.metadefender.com/v2/hash/3A93D4CCEF8CFDE41DF8F543852B4A43").
      with(  headers: {
      'Apikey'=> BAD_API_KEY
      }).
      to_return(
        status: [401, "Invalid Apikey"],
        body: JSON.generate(hash_response),
        headers: {content_type: 'application/json'})
    # GET data_id
    stub_request(:get, "https://api.metadefender.com/v2/file/dDE4MDQxN0JKdHNNbTNRaHpCSnFzTVgyUTN6").
      with(  headers: {
      'Apikey'=>'9c2b11386f6d45999252d497855a3b0b'
      }).
      to_return(status: [200, "OK"], body: JSON.generate(data_id_response), headers: {content_type: 'application/json'})
    # POST file
    stub_request(:post, "https://api.metadefender.com/v2/file/").
      with(  headers: {
      'Apikey'=>'9c2b11386f6d45999252d497855a3b0b'
      },
      body: {"filename" => File.open(@op_file.filepath)}
      ).
      to_return(status: [200, "OK"], body: JSON.generate({"data_id"=> 'dDE4MDQxN0JKdHNNbTNRaHpCSnFzTVgyUTN6'}), headers: {content_type: 'application/json'})
  end

  describe ".new" do
    it "initializes with a op_file instance" do
      expect(@api_wrapper.op_file).to eq(@op_file)
    end
  end

  # generally I treat private methods as black boxes,
  # but these API calls make or break the application,
  # and I do not expect them to change too much.

  describe "#get_data_id" do
    it "makes a GET request to the appropriate OPSWAT endpoint" do
      @op_file.data_id= "dDE4MDQxN0JKdHNNbTNRaHpCSnFzTVgyUTN6"
      @api_wrapper.send(:get_data_id)
      expect(WebMock).to have_requested(
        :get,
        "https://api.metadefender.com/v2/file/dDE4MDQxN0JKdHNNbTNRaHpCSnFzTVgyUTN6"
      ).
      with(
        headers: {
          'Apikey'=>'9c2b11386f6d45999252d497855a3b0b'
        })
    end
    it "returns a hash containing the response body" do
      @op_file.data_id= "dDE4MDQxN0JKdHNNbTNRaHpCSnFzTVgyUTN6"
      response = @api_wrapper.send(:get_data_id)
      expect(response["data_id"]).to eq("dDE4MDQxN0JKdHNNbTNRaHpCSnFzTVgyUTN6")
    end
  end

  describe "#get_hash" do
    it "makes a GET request with an existing hash" do
      @api_wrapper.send(:get_hash)
      expect(WebMock).to have_requested(
        :get,
        "https://api.metadefender.com/v2/hash/3A93D4CCEF8CFDE41DF8F543852B4A43"
      )
    end
    it "makes a GET request without existing hash" do
      @op_file.hash = BAD_HASH
      response = @api_wrapper.send(:get_hash)
      expect(response[BAD_HASH]).to eq("Not Found")
    end
    it "returns a hash containing the response body" do
      response = @api_wrapper.send(:get_hash)
      expect(response["data_id"]).to eq("dDE4MDQxN0JKdHNNbTNRaHpCSnFzTVgyUTN6")
    end
  end

  describe "#post_file" do
    # Currently, WebMock does not correctly test POST requests with file uploads
    # a work around in other cases would be to read the file in the API wrapper
    # instead of opening it. However, this would create a different file,
    # resulting in a different hash digest
    it "makes a POST request with a file to the appropriate OPSWAT endpoint" do
      # @api_wrapper.send(:post_file)
    end
    it "returns a hash containing the response body" do
      # response = @api_wrapper.send(:post_file)
      # expect(response["data_id"]).to eq("dDE4MDQxN0JKdHNNbTNRaHpCSnFzTVgyUTN6")
    end
  end

  describe "#scan_file" do
    it "scans file with OPSWAT" do
      @api_wrapper.scan_file
    end
    it "raises error if API raises error" do
      FileSentry.configure { |config| config.access_key = BAD_API_KEY }
      expect{@api_wrapper.scan_file}.to raise_error("Error: Invalid Apikey")
    end
  end
end


