# frozen_string_literal: true

WebMock.allow_net_connect!

RSpec.describe OPFile do
  describe '#process_file' do
    it 'updates the scan_results attribute with OPSWAT\'s scan results' do
      op_file = described_class.new filepath: File.expand_path('../test_file.txt', __FILE__)
      op_file.process_file('md5')
      expect(op_file.scan_results).to have_key('scan_details')
    end

    it 'correctly reports if file is infected' do
      op_file = described_class.new filepath: File.expand_path('../fake_infected_file.mean', __FILE__)
      op_file.process_file('md5')
      expect(op_file.scan_results['scan_all_result_a']).to match(/\bInfected\b/i)
    end
  end
end
