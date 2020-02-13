# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

Gem::Specification.new do |spec|
  spec.name          = "fluent-plugin-sentry-rubrik"
  spec.version       = "0.0.16"
  spec.authors       = ["Kentaro Yoshida", "François-Xavier Bourlet"]
  spec.email         = ["y.ken.studio@gmail.com", "fx.bourlet@rubrik.com"]
  spec.summary       = %q{Fluentd output plugin that sends aggregated errors/exception events to Sentry. Sentry is a event logging and aggregation platform.}
  spec.homepage      = "https://github.com/rubrikinc/fluent-plugin-sentry"
  spec.license       = "Apache-2.0"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.16"
  spec.add_development_dependency "rake", "~> 12.3"
  spec.add_development_dependency "webmock", "~> 3.3"
  spec.add_development_dependency "test-unit", "~> 3.2"
  spec.add_development_dependency "appraisal", "~> 2.2"

  # Since Fluentd v0.14 requires ruby 2.1 or later.
  if defined?(RUBY_VERSION) && RUBY_VERSION < "2.1"
    spec.add_runtime_dependency "fluentd", "< 0.14"
  else
    spec.add_runtime_dependency "fluentd", "~> 1.1"
  end
  spec.add_runtime_dependency "sentry-raven", "~> 2.7"
end
