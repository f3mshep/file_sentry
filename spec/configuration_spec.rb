# frozen_string_literal: true

RSpec.describe FileSentry::Configuration do
  it 'has a version number' do
    expect(FileSentry::VERSION).to match(/^\d+(\.\d+)+$/)
  end

  it 'verify default configuration' do
    old_config = FileSentry.configuration
    config = FileSentry.reset
    FileSentry.configuration = old_config

    expect(config.access_key).to be_nil
    expect(config.enable_gzip).to eq(true)

    expect(config.max_file_size).to eq(140)
    expect(config.scan_timeout).to eq(120)
    expect(config.is_debug).to eq(false)
  end

  it 'testing configuration must have API Key' do
    config = FileSentry.configuration
    expect(config).to be_kind_of(described_class)

    expect(config.access_key).to be_truthy
    expect(config.access_key).to eq(opswat_key)

    expect(config.max_file_size).to eq(140)
    expect(config.scan_timeout).to eq(120)
    expect(config.is_debug).to eq(true)
  end
end
