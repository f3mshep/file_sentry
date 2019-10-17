# frozen_string_literal: true

BAD_DATA_ID = 'IAmNotReal'

RSpec.describe FileSentry::ApiWrapper do
  before :each do
    @op_file = FileSentry::OpFile.new
    @api_wrapper = @op_file.api_wrapper
  end

  describe '#report_by_data_id' do
    it 'raises error when requesting without hash' do
      expect { @api_wrapper.send(:report_by_data_id) }.to raise_error(RuntimeError, /^No data_id set\b/i)
    end

    it 'makes a GET request to the appropriate OPSWAT endpoint' do
      @op_file.data_id = data_id = mock_data_id
      stub_api_data_id_report data_id

      @api_wrapper.send(:report_by_data_id)
      expect(WebMock).to have_requested(:get, "#{base_url}/file/#{data_id}").with(headers: request_headers)
    end

    it 'returns a hash containing the response body' do
      @op_file.data_id = data_id = mock_data_id(infected: true)
      stub_api_data_id_report data_id, infected: true

      response = @api_wrapper.send(:report_by_data_id)
      expect(response['data_id']).to eq(data_id)
    end

    it 'raises error while requesting with invalid data_id' do
      stub_api_data_id_report @op_file.data_id = BAD_DATA_ID, not_found: true

      expect { @api_wrapper.send(:report_by_data_id) }.to raise_error(/\bWas not found$/i)
    end
  end
end
