
lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "file_sentry/version"

Gem::Specification.new do |spec|
  spec.name          = "file_sentry"
  spec.version       = FileSentry::VERSION
  spec.authors       = ["Alexandra Wright"]
  spec.email         = ["superbiscuit@gmail.com"]
  spec.summary       = %q{A command line utility to scan files for malware risks. Uses the OPSWAT Defender Cloud API.}
  spec.homepage      = "https://github.com/f3mshep/file_sentry"
  spec.license       = "MIT"

  # Prevent pushing this gem to RubyGems.org. To allow pushes either set the 'allowed_push_host'
  # to allow pushing to a single host or delete this section to allow pushing to any host.
  if spec.respond_to?(:metadata)
    spec.metadata["allowed_push_host"] = "https://rubygems.org"
  else
    raise "RubyGems 2.0 or newer is required to protect against " \
      "public gem pushes."
  end

  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  # spec.bindir        = "file_sentry"
  spec.executables   = spec.files.grep(%r{^bin/}) { |f|  File.basename(f) }
  spec.require_paths = ["lib", "config"]


  spec.add_runtime_dependency "dotenv"
  spec.add_runtime_dependency "httparty"
  spec.add_runtime_dependency "colorize"

  spec.add_development_dependency "bundler", "~> 1.16"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec", "~> 3.0"
  spec.add_development_dependency "pry"
  spec.add_development_dependency "webmock"

end
