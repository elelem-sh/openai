# frozen_string_literal: true

require_relative "lib/elelem/openai/version"

Gem::Specification.new do |spec|
  spec.name = "elelem-openai"
  spec.version = Elelem::OpenAI::VERSION
  spec.authors = ["mo khan"]
  spec.email = ["mo@mokhan.ca"]

  spec.summary = "An OpenAI provider plugin for elelem."
  spec.description = "An OpenAI provider plugin for elelem."
  spec.homepage = "https://src.mokhan.ca/xlgmokha/elelem"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 4.0.0"
  spec.required_rubygems_version = ">= 4.0.0"
  spec.metadata["allowed_push_host"] = "https://rubygems.org"
  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://git.mokhan.ca/xlgmokha/elelem.git"

  spec.files = ["LICENSE.txt", "lib/elelem/openai.rb", "exe/elelem-openai"] +
    Dir["lib/elelem/openai/**/*.{rb}"]
  spec.bindir = "exe"
  spec.executables = ["elelem-openai"]
  spec.require_paths = ["lib"]

  spec.add_dependency "elelem-plugins", "~> 0.1"
  spec.add_dependency "elelem-cli", "~> 0.1"
  spec.add_dependency "json", "~> 2.21"
  spec.add_dependency "net-http", "~> 0.9"
  spec.add_dependency "uri", "~> 1.1"
end
