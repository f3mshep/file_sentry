# frozen_string_literal: true

RSpec.describe FileSentry::ApiWrapper do
  let!(:infected) { rand_boolean }
  let!(:op_file) { FileSentry::OpFile.new(test_file_path(infected)) }

  describe '#upload_file' do
    it 'makes a POST request with a file to the appropriate OPSWAT endpoint' do
      stub_api_post_file infected: infected
      op_file.api_wrapper.send(:upload_file, true)

      expected = request_headers nil, 'content-type' => 'application/octet-stream', rule: 'sanitize,unarchive'
      expect(WebMock).to have_requested(:post, "#{base_url}/file/").with(headers: expected)
    end

    it 'returns a hash containing the response body' do
      stub_api_post_file infected: infected

      response = op_file.api_wrapper.send(:upload_file)
      expect(response['data_id']).to eq(mock_data_id(infected))
    end
  end
end
