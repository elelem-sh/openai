# frozen_string_literal: true

require "elelem"
require "json"
require "net/http"
require "uri"

require_relative "openai/version"
require_relative "openai/client"

Elelem.configure do |config|
  config.provider(:openai) do
    Elelem::OpenAI::Client.new(
      model: ENV.fetch("OPENAI_MODEL", "gpt-4o"),
      api_key: ENV.fetch("OPENAI_API_KEY")
    )
  end
end
