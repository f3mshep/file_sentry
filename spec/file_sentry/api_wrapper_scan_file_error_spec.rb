# frozen_string_literal: true

RSpec.describe FileSentry::ApiWrapper do
  let! :fixture_data do
    op_file = FileSentry::OpFile.new(test_file_path(infected = rand_boolean))
    op_file.file_hash.hash_file(encrypt = rand_encrypt)
    [infected, encrypt, op_file.api_wrapper]
  end

  describe '#scan_file' do
    it 'raises error if OPSWAT_KEY is not set' do
      infected, encrypt, api = fixture_data

      last_key = delete_opswat_key
      stub_api_hash_report mock_hash(infected, encrypt), infected: infected
      configure_api_key(nil, true, true)

      expect { scan_and_restore_key(api, last_key) }.to raise_error(/^Error: Authentication strategy is invalid\b/i)
    end
  end

  def delete_opswat_key
    old = opswat_key
    opswat_key nil
    old
  end

  def scan_and_restore_key(api_wrapper, last_key)
    api_wrapper.scan_file
  ensure
    opswat_key last_key
  end
end
