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

  let(:wire) do
    Class.new do
      attr_reader :uri, :body, :headers

      def post(uri, body:, headers: {})
        @uri = uri
        @body = body
        @headers = headers
      end
    end.new
  end

  def sent
    Elelem::Config.build_provider("openai", http: wire).fetch([{ role: "user", content: "hi" }], [])
    wire
  end

  def authorization = sent.headers["authorization"]

  def uri = sent.uri.to_s

  it "talks to OpenAI by default" do
    ENV["OPENAI_API_KEY"] = "sk-test"
    ENV.delete("OPENAI_BASE_URL")

    expect(uri).to eq("https://api.openai.com/v1/chat/completions")
  end

  it "uses OPENAI_BASE_URL, with no key needed" do
    ENV.delete("OPENAI_API_KEY")
    ENV["OPENAI_BASE_URL"] = "http://127.0.0.1:8080/v1"

    expect(uri).to eq("http://127.0.0.1:8080/v1/chat/completions")
    expect(authorization).to be_nil
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
    expect(sent.body[:model]).to eq("gpt-4o")

    ENV["OPENAI_API_KEY"] = ""
    expect { Elelem::Config.build_provider("openai") }
      .to raise_error(KeyError, "set OPENAI_API_KEY or OPENAI_API_KEY_COMMAND")
  end

  it "sends OPENAI_API_KEY as a bearer token" do
    ENV["OPENAI_API_KEY"] = "sk-test"

    expect(authorization).to eq("Bearer sk-test")
  end

  it "sends the key that OPENAI_API_KEY_COMMAND prints" do
    ENV["OPENAI_API_KEY_COMMAND"] = "echo sk-printed"

    expect(authorization).to eq("Bearer sk-printed")
  end

  it "prefers OPENAI_API_KEY to the command, without running it" do
    ENV["OPENAI_API_KEY"] = "sk-test"
    ENV["OPENAI_API_KEY_COMMAND"] = "false"

    expect(authorization).to eq("Bearer sk-test")
  end

  it "runs the command at the first request, not when the provider is built" do
    ENV["OPENAI_API_KEY_COMMAND"] = "false"

    expect { Elelem::Config.build_provider("openai", http: wire) }.not_to raise_error
    expect { authorization }.to raise_error(KeyError, "OPENAI_API_KEY_COMMAND failed with status 1: false")
  end

  it "names OPENAI_API_KEY_COMMAND when it prints nothing" do
    ENV["OPENAI_API_KEY_COMMAND"] = "true"

    expect { authorization }.to raise_error(KeyError, "OPENAI_API_KEY_COMMAND printed no key: true")
  end

  it "keeps what a failed command wrote to stderr in the error and drops its stdout" do
    ENV["OPENAI_API_KEY_COMMAND"] = "sh -c 'echo sk-half; echo run elelem-gateway login >&2; exit 3'"

    expect { authorization }.to raise_error(KeyError, /failed with status 3: .*: run elelem-gateway login\z/)
  end

  it "names OPENAI_API_KEY_COMMAND when the command does not exist" do
    ENV["OPENAI_API_KEY_COMMAND"] = "elelem-no-such-command"

    expect { authorization }.to raise_error(KeyError, /OPENAI_API_KEY_COMMAND could not run: .*elelem-no-such-command/)
  end
end
