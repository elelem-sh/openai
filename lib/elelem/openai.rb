# frozen_string_literal: true

require "elelem"
require "json"
require "net/http"
require "uri"

require_relative "openai/version"
require_relative "openai/provider"

Elelem.configure do |config|
  # OPENAI_BASE_URL points at any Chat Completions server, such as a local
  # one that needs no key.
  config.provider(:openai) do |model: nil, **|
    custom = ENV["OPENAI_BASE_URL"].to_s
    Elelem::OpenAI::Provider.new(
      model: model || ENV.fetch("OPENAI_MODEL", "gpt-4o"),
      api_key: custom.empty? ? ENV.fetch("OPENAI_API_KEY") : ENV.fetch("OPENAI_API_KEY", ""),
      base_url: custom.empty? ? "https://api.openai.com/v1" : custom
    )
  end
end
