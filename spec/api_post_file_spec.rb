# frozen_string_literal: true

RSpec.describe FileSentry::ApiWrapper do
  before :each do
    @op_file = FileSentry::OpFile.new(filepath: test_file_path(@infected = rand(2).zero?))
    @api_wrapper = @op_file.api_wrapper
  end

  describe '#upload_file' do
    it 'makes a POST request with a file to the appropriate OPSWAT endpoint' do
      stub_api_post_file infected: @infected
      @api_wrapper.send(:upload_file, true)

      req_headers = request_headers extra: { 'content-type' => 'application/octet-stream', rule: 'sanitize,unarchive' }
      expect(WebMock).to have_requested(:post, "#{base_url}/file/").with(headers: req_headers)
    end

    it 'returns a hash containing the response body' do
      stub_api_post_file infected: @infected

      response = @api_wrapper.send(:upload_file)
      expect(response['data_id']).to eq(mock_data_id(infected: @infected))
    end
  end
end
