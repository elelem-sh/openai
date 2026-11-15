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
    base_url = ENV.fetch("OPENAI_BASE_URL", "https://api.openai.com/v1")
    Elelem::OpenAI::Provider.new(
      model: model || ENV.fetch("OPENAI_MODEL", "gpt-4o"),
      api_key: ENV.key?("OPENAI_BASE_URL") ? ENV.fetch("OPENAI_API_KEY", "") : ENV.fetch("OPENAI_API_KEY"),
      base_url: base_url
    )
  end
end
