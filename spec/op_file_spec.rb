# frozen_string_literal: true

RSpec.describe FileSentry::OpFile do
  describe '#process_file' do
    it 'updates the scan_results attribute with OPSWAT scan results' do
      stub_api_hash_report mock_hash(encrypt: 'sha1')

      # @type [FileSentry::OpFile]
      op_file = described_class.new(filepath: test_file_path)
      op_file.process_file('sha1')

      expect(op_file.scan_results).to have_key('scan_details')
    end

    it 'correctly reports if file is infected' do
      stub_api_hash_report mock_hash(infected: true), infected: true, not_found: true
      stub_api_post_file infected: true
      stub_api_data_id_report mock_data_id(infected: true), infected: true

      # @type [FileSentry::OpFile]
      op_file = described_class.new(filepath: test_file_path(true))
      op_file.process_file('md5')

      expect(op_file.scan_results['scan_all_result_a']).to match(/\bInfected\b/i)
    end
  end
end
