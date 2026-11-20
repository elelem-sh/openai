# frozen_string_literal: true

RSpec.describe "the openai provider" do
  around do |example|
    saved = ENV.to_h.slice(*variables)
    variables.each { ENV.delete(it) }
    example.run
  ensure
    variables.each { ENV.delete(it) }
    ENV.update(saved)
  end

  def variables = %w[OPENAI_API_KEY OPENAI_API_KEY_COMMAND OPENAI_BASE_URL OPENAI_MODEL]

  def key = Elelem::Config.build_provider("openai").instance_variable_get(:@api_key)

  def uri = Elelem::Config.build_provider("openai").instance_variable_get(:@uri).to_s

  it "talks to OpenAI by default" do
    ENV["OPENAI_API_KEY"] = "sk-test"
    ENV.delete("OPENAI_BASE_URL")

    expect(uri).to eq("https://api.openai.com/v1/chat/completions")
  end

  it "uses OPENAI_BASE_URL, with no key needed" do
    ENV.delete("OPENAI_API_KEY")
    ENV["OPENAI_BASE_URL"] = "http://127.0.0.1:8080/v1"

    expect(uri).to eq("http://127.0.0.1:8080/v1/chat/completions")
  end

  it "takes a base URL with a trailing slash, and treats an empty one as unset" do
    ENV["OPENAI_API_KEY"] = "sk-test"
    ENV["OPENAI_BASE_URL"] = "http://127.0.0.1:8080/v1/"
    expect(uri).to eq("http://127.0.0.1:8080/v1/chat/completions")

    ENV["OPENAI_BASE_URL"] = ""
    expect(uri).to eq("https://api.openai.com/v1/chat/completions")
  end

  it "treats an empty model as unset, and an empty key as missing for OpenAI" do
    ENV.delete("OPENAI_BASE_URL")
    ENV["OPENAI_MODEL"] = ""
    ENV["OPENAI_API_KEY"] = "sk-test"
    expect(Elelem::Config.build_provider("openai").instance_variable_get(:@model)).to eq("gpt-4o")

    ENV["OPENAI_API_KEY"] = ""
    expect { Elelem::Config.build_provider("openai") }.to raise_error(KeyError, /OPENAI_API_KEY/)
  end

  it "takes the key that OPENAI_API_KEY_COMMAND prints" do
    ENV["OPENAI_API_KEY_COMMAND"] = "echo sk-printed"

    expect(key).to eq("sk-printed")
  end

  it "prefers OPENAI_API_KEY to the command, without running it" do
    ENV["OPENAI_API_KEY"] = "sk-test"
    ENV["OPENAI_API_KEY_COMMAND"] = "false"

    expect(key).to eq("sk-test")
  end

  it "names OPENAI_API_KEY_COMMAND when it prints nothing" do
    ENV["OPENAI_API_KEY_COMMAND"] = "true"

    expect { key }.to raise_error(KeyError, /OPENAI_API_KEY_COMMAND printed no key: true/)
  end
end
