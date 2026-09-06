# frozen_string_literal: true

require_relative "lib/elelem/openai/version"

Gem::Specification.new do |spec|
  spec.name = "elelem-openai"
  spec.version = Elelem::OpenAI::VERSION
  spec.authors = ["mo khan"]
  spec.email = ["mo@mokhan.ca"]

  spec.summary = "An OpenAI provider plugin for elelem."
  spec.description = "An OpenAI provider plugin for elelem."
  spec.homepage = "https://src.mokhan.ca/elelem/openai"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 4.0.0"
  spec.metadata["allowed_push_host"] = "https://rubygems.org"
  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage

  gemspec = File.basename(__FILE__)
  spec.files = IO.popen(%w[git ls-files -z], chdir: __dir__, err: IO::NULL) do |ls|
    ls.readlines("\x0", chomp: true).reject do |f|
      (f == gemspec) || f.start_with?(*%w[bin/ Gemfile .gitignore])
    end
  end
  spec.bindir = "exe"
  spec.executables = ["elelem-openai"]
  spec.require_paths = ["lib"]

  spec.add_dependency "elelem", "~> 0.10"
  spec.add_dependency "json", "~> 2.21"
  spec.add_dependency "net-http", "~> 0.9"
  spec.add_dependency "uri", "~> 1.1"
end
