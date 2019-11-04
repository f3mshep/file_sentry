# frozen_string_literal: true

RSpec.describe FileSentry::ApiWrapper do
  let! :fixture_data do
    op_file = FileSentry::OpFile.new(test_file_path(infected = rand_boolean))
    op_file.file_hash.hash_file(encrypt = rand_encrypt)
    [infected, encrypt, op_file.api_wrapper]
  end

  describe '#report_by_hash' do
    it 'makes a GET request with an existing hash' do
      infected, encrypt, api_wrapper = fixture_data
      stub_api_hash_report hash = mock_hash(infected, encrypt), infected: infected

      api_wrapper.send(:report_by_hash)
      expect(WebMock).to have_requested(:get, "#{base_url}/hash/#{hash}")
    end

    it 'returns a hash containing the response body' do
      infected, encrypt, api_wrapper = fixture_data
      stub_api_hash_report mock_hash(infected, encrypt), infected: infected

      response = api_wrapper.send(:report_by_hash)
      expect(response['data_id']).to eq(mock_data_id(infected))
    end
  end
end
