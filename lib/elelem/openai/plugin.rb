# frozen_string_literal: true

require "elelem"
require_relative "../openai"

Elelem::Providers.register(:openai) do
  Elelem::OpenAI::Client.new(
    model: ENV.fetch("OPENAI_MODEL", "gpt-4o"),
    api_key: ENV.fetch("OPENAI_API_KEY")
  )
end
