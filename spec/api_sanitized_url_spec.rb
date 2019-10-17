# frozen_string_literal: true

BAD_SANITIZED_DATA_ID = 'NonExists'

RSpec.describe FileSentry::ApiWrapper do
  before :each do
    @op_file = FileSentry::OpFile.new
    @api_wrapper = @op_file.api_wrapper
  end

  describe '.new' do
    it 'initializes with a op_file instance' do
      expect(@api_wrapper).to be_kind_of(described_class)
      expect(@api_wrapper.op_file).to eq(@op_file)
    end
  end

  describe '#get_sanitized_url' do
    it 'raises error if empty argument' do
      expect { @api_wrapper.get_sanitized_url('') }.to raise_error(RuntimeError, /^No sanitized data_id set\b/i)
    end

    it 'makes a request with non-existing data_id' do
      stub_api_sanitized_url BAD_SANITIZED_DATA_ID
      expect { @api_wrapper.get_sanitized_url(BAD_SANITIZED_DATA_ID) }.to raise_error(/\bWas not found$/i)
    end

    it 'returns a valid sanitized URL' do
      stub_api_sanitized_url data_id = mock_sanitized(true)

      response = @api_wrapper.get_sanitized_url data_id
      expect(response).to eq(mock_sanitized)
    end
  end
end
