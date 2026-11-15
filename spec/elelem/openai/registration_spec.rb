# frozen_string_literal: true

RSpec.describe "the openai provider" do
  around do |example|
    saved = ENV.to_h.slice("OPENAI_API_KEY", "OPENAI_BASE_URL")
    example.run
  ensure
    %w[OPENAI_API_KEY OPENAI_BASE_URL].each { |k| ENV.delete(k) }
    ENV.update(saved)
  end

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
end
