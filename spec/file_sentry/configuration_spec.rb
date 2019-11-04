# frozen_string_literal: true

RSpec.describe FileSentry::Configuration do
  it 'has a version number' do
    expect(FileSentry::VERSION).to match(/^\d+(\.\d+)+$/)
  end

  it 'verify default configuration' do
    old_config = FileSentry.configuration
    config = FileSentry.reset
    FileSentry.configuration = old_config

    attributes = { access_key: nil, enable_gzip: true, max_file_size: 140, scan_timeout: 120, is_debug: false }
    expect(config).to have_attributes(attributes)
  end

  it 'testing configuration must enable debugging' do
    attributes = {
      access_key: opswat_key, enable_gzip: false,
      max_file_size: 140, scan_timeout: 120, is_debug: true
    }
    expect(FileSentry.configuration).to be_kind_of(described_class).and have_attributes(attributes)
  end

  it 'testing configuration must have API Key' do
    expect(FileSentry.configuration.access_key).to be_truthy
  end
end
