# frozen_string_literal: true

module FileSentry
  WebMock.allow_net_connect!

  RSpec.describe OpFile do
    describe '#process_file' do
      it 'updates the scan_results attribute with OPSWAT scan results' do
        op_file = described_class.new filepath: File.expand_path('../data/test_file.txt', __FILE__)
        op_file.process_file('md5')
        expect(op_file.scan_results).to have_key('scan_details')
      end

      it 'correctly reports if file is infected' do
        op_file = described_class.new filepath: File.expand_path('../data/fake_infected_file.mean', __FILE__)
        op_file.process_file('md5')
        expect(op_file.scan_results['scan_all_result_a']).to match(/\bInfected\b/i)
      end
    end
  end
end
