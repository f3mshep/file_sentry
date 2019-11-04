# frozen_string_literal: true

BAD_API_KEY = 'BadApiKey'

RSpec.describe FileSentry::ApiWrapper do
  let! :fixture_data do
    op_file = FileSentry::OpFile.new(test_file_path(infected = rand_boolean))
    op_file.file_hash.hash_file(encrypt = rand_encrypt)
    [infected, encrypt, op_file.api_wrapper]
  end

  describe '#scan_file' do
    it 'scans file with OPSWAT' do
      infected, encrypt, api_wrapper = fixture_data

      stub_api_hash_report mock_hash(infected, encrypt), infected: infected, not_found: true
      stub_api_post_file infected: infected
      stub_api_data_id_report mock_data_id(infected), infected: infected

      expect(api_wrapper.scan_file(infected)).to have_key('scan_details')
    end

    it 'raises error when processing with invalid API key' do
      infected, encrypt, api_wrapper = fixture_data

      configure_api_key(BAD_API_KEY, false, true)
      stub_api_hash_report hash = mock_hash(infected, encrypt), bad_key: BAD_API_KEY

      expect { scan_and_ensure_request(api_wrapper, hash) }.to raise_error(/^Error: Invalid API key\b/i)
    end
  end

  def scan_and_ensure_request(api_wrapper, hash, expected = { 'accept-encoding' => /\bGZip\b/i })
    api_wrapper.scan_file
  ensure
    expect(WebMock).to have_requested(:get, "#{base_url}/hash/#{hash}").with(headers: expected)
  end
end
