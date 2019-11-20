# frozen_string_literal: true

lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'file_sentry/version'

Gem::Specification.new do |spec|
  spec.name          = 'file_sentry'
  spec.version       = FileSentry::VERSION
  spec.authors       = ['Alexandra Wright']
  spec.email         = ['superbiscuit@gmail.com']

  spec.summary       = 'A command line utility to scan files for malware risks. Uses the OPSWAT Defender Cloud API.'
  spec.homepage      = 'https://github.com/f3mshep/file_sentry'
  spec.license       = 'MIT'

  # Specify which files should be added to the gem when it is released.
  spec.files         = Dir.chdir(File.expand_path('..', __FILE__)) do
    %w[README.md LICENSE.txt CODE_OF_CONDUCT.md] + Dir['{bin,lib}/**/*'].reject { |f| File.directory? f }
  end

  spec.bindir        = 'bin'
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']
  spec.required_ruby_version = '>= 1.9.3'

  spec.add_runtime_dependency 'httparty', '~> 0.14'
  spec.add_runtime_dependency 'rainbow'

  spec.add_development_dependency 'bundler', '>= 1.14'
  spec.add_development_dependency 'rake', '>= 10.0'
  spec.add_development_dependency 'rspec', '~> 3.0'
  spec.add_development_dependency 'rubocop'
  spec.add_development_dependency 'rubocop-rspec'
  spec.add_development_dependency 'webmock'
end
