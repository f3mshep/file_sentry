# frozen_string_literal: true

RSpec.describe FileSentry::ApiWrapper do
  before :each do
    @op_file = FileSentry::OpFile.new(filepath: test_file_path(@infected = rand(2).zero?))
    @op_file.file_hash.hash_file(@encrypt = %w[md5 sha1 sha256].sample)
    @api_wrapper = @op_file.api_wrapper
  end

  describe '#report_by_hash' do
    it 'makes a GET request with an existing hash' do
      stub_api_hash_report hash = mock_hash(encrypt: @encrypt, infected: @infected), infected: @infected

      @api_wrapper.send(:report_by_hash)
      expect(WebMock).to have_requested(:get, "#{base_url}/hash/#{hash}")
    end

    it 'returns a hash containing the response body' do
      stub_api_hash_report mock_hash(encrypt: @encrypt, infected: @infected), infected: @infected

      response = @api_wrapper.send(:report_by_hash)
      expect(response['data_id']).to eq(mock_data_id(infected: @infected))
    end
  end
end
