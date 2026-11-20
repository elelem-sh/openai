# frozen_string_literal: true

require "elelem"
require "elelem/http"
require "json"
require "tempfile"
require "uri"

require_relative "openai/version"
require_relative "openai/key_command"
require_relative "openai/provider"

Elelem.configure do |config|
  # OPENAI_BASE_URL points at any Chat Completions server, such as a local
  # one that needs no key.
  config.provider(:openai) do |model: nil, http: nil, **|
    # A variable that is set but empty counts as unset.
    env = ->(name) { ENV[name].to_s.strip.then { |v| v.empty? ? nil : v } }
    custom = env.call("OPENAI_BASE_URL")
    key = env.call("OPENAI_API_KEY")
    command = env.call(Elelem::OpenAI::KeyCommand::VARIABLE) unless key
    raise KeyError, "set OPENAI_API_KEY or OPENAI_API_KEY_COMMAND" unless key || command || custom

    Elelem::OpenAI::Provider.new(
      model: model || env.call("OPENAI_MODEL") || "gpt-4o",
      api_key: key.to_s,
      key_command: command && Elelem::OpenAI::KeyCommand.new(command),
      http:,
      base_url: custom || "https://api.openai.com/v1"
    )
  end
end
