# frozen_string_literal: true

require "stringio"

RSpec.describe Elelem::OpenAI::KeyCommand do
  let(:messages) { [{ role: "user", content: "hi" }] }

  let(:issuer) do
    Class.new do
      attr_reader :commands

      def initialize(keys)
        @keys = keys
        @commands = []
      end

      def call(command)
        @commands << command
        @keys.shift
      end
    end
  end

  let(:server) do
    Class.new do
      attr_reader :seen

      def initialize(accepted)
        @accepted = accepted
        @seen = []
      end

      def post(_uri, headers: {}, **, &)
        @seen << headers["authorization"]
        raise "HTTP 401: token expired" unless headers["authorization"] == "Bearer #{@accepted}"

        reply("data: {\"choices\":[{\"delta\":{\"content\":\"hi\"}}]}\n\ndata: [DONE]\n", &)
      end

      private

      def reply(events)
        io = Net::BufferedIO.new(StringIO.new("HTTP/1.1 200 OK\r\ncontent-length: #{events.bytesize}\r\n\r\n#{events}"))
        response = Net::HTTPResponse.read_new(io)
        response.reading_body(io, true) { yield response }
      end
    end
  end

  def said(provider) = [].tap { |seen| provider.fetch(messages, []) { seen << it[:text] } }

  it "strips the key that the command prints" do
    expect(described_class.new("mint", run: ->(_) { " sk-printed\n" }).call).to eq("sk-printed")
  end

  it "names the variable and the command when nothing is printed" do
    [nil, "", " \n"].each do |output|
      expect { described_class.new("mint", run: ->(_) { output }).call }
        .to raise_error(KeyError, "OPENAI_API_KEY_COMMAND printed no key: mint")
    end
  end

  it "runs when the provider starts" do
    mint = issuer.new(%w[sk-first])
    http = server.new("sk-first")
    provider = Elelem::OpenAI::Provider.new(model: "m", key_command: described_class.new("mint", run: mint), http:)

    expect(mint.commands).to eq(%w[mint])
    expect(said(provider)).to eq(%w[hi])
    expect(http.seen).to eq(["Bearer sk-first"])
  end

  it "runs again on a 401, and the request is retried with the new key" do
    mint = issuer.new(%w[sk-expired sk-fresh])
    http = server.new("sk-fresh")
    provider = Elelem::OpenAI::Provider.new(model: "m", key_command: described_class.new("mint", run: mint), http:)

    expect(said(provider)).to eq(%w[hi])
    expect(http.seen).to eq(["Bearer sk-expired", "Bearer sk-fresh"])
    expect(said(provider)).to eq(%w[hi])
    expect(mint.commands.size).to eq(2)
  end

  it "retries once only" do
    mint = issuer.new(%w[sk-one sk-two sk-three])
    http = server.new("sk-never")
    provider = Elelem::OpenAI::Provider.new(model: "m", key_command: described_class.new("mint", run: mint), http:)

    expect { said(provider) }.to raise_error("HTTP 401: token expired")
    expect(http.seen).to eq(["Bearer sk-one", "Bearer sk-two"])
  end

  it "leaves a 401 alone when the key is fixed" do
    http = server.new("sk-other")
    provider = Elelem::OpenAI::Provider.new(model: "m", api_key: "sk-test", http:)

    expect { said(provider) }.to raise_error("HTTP 401: token expired")
    expect(http.seen).to eq(["Bearer sk-test"])
  end

  it "fails the request when the command prints nothing on the retry" do
    mint = issuer.new(["sk-expired", ""])
    provider = Elelem::OpenAI::Provider.new(model: "m", key_command: described_class.new("mint", run: mint),
                                            http: server.new("sk-fresh"))

    expect { said(provider) }.to raise_error(KeyError, /OPENAI_API_KEY_COMMAND/)
  end
end
