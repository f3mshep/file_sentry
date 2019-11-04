# frozen_string_literal: true

RSpec.describe FileSentry::OpFile do
  describe '#sanitized_url' do
    it 'raises error if no sanitized results' do
      # @type [FileSentry::OpFile]
      op_file = described_class.new

      expect { op_file.sanitized_url }.to raise_error(RuntimeError, /^No sanitized results\b/i)
    end
  end

  describe '#process_file' do
    it 'updates the scan_results attribute with OPSWAT scan results' do
      stub_api_hash_report mock_hash(false, encrypt = rand_encrypt)

      # @type [FileSentry::OpFile]
      (op_file = described_class.new(test_file_path)).process_file(encrypt)

      expect(op_file.scan_results).to have_key('scan_details')
    end

    it 'returns correctly reports for infected file' do
      stub_api_hash_report mock_hash(true, encrypt = rand_encrypt), infected: true, not_found: true
      stub_api_post_file infected: true
      stub_api_data_id_report mock_data_id(true), infected: true

      # @type [FileSentry::OpFile]
      (op_file = described_class.new(test_file_path(true))).process_file(encrypt)

      expect(op_file.scan_results['scan_all_result_a']).to match(/\bInfected\b/i)
    end
  end
end
