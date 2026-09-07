# frozen_string_literal: true

require "elelem"
require "json"
require "net/http"
require "uri"

require_relative "openai/version"
require_relative "openai/provider"

Elelem.configure do |config|
  config.provider(:openai) do
    Elelem::OpenAI::Provider.new(
      model: ENV.fetch("OPENAI_MODEL", "gpt-4o"),
      api_key: ENV.fetch("OPENAI_API_KEY")
    )
  end
end
