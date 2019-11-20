# frozen_string_literal: true

BAD_HASH = 'IAmNotReal'

RSpec.describe FileSentry::ApiWrapper do
  let!(:op_file) { FileSentry::OpFile.new }
  let!(:api_wrapper) { op_file.api_wrapper }

  describe '#report_by_hash' do
    it 'raises error when requesting without hash' do
      expect { api_wrapper.send(:report_by_hash) }.to raise_error(RuntimeError, /^No hash set\b/i)
    end

    it 'makes a GET request with non-existing hash' do
      stub_api_hash_report op_file.hash = BAD_HASH, not_found: true

      response = api_wrapper.send(:report_by_hash)
      expect([response['data_id'], response.fetch('error', {})['code']]).to eq [nil, 404_001]
    end

    it 'raises error while requesting without existing hash' do
      op_file.hash = BAD_HASH
      stub_api_hash_report BAD_HASH, not_found: true

      expect { api_wrapper.send(:report_by_hash, [200]) }.to raise_error(/\bWas not found$/i)
    end
  end
end
