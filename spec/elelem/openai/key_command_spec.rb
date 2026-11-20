# frozen_string_literal: true

require "socket"
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
        [@keys.shift, "", 0]
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
    expect(described_class.new("mint", run: ->(_) { [" sk-printed\n", "", 0] }).call).to eq("sk-printed")
  end

  it "names the variable and the command when nothing is printed" do
    [nil, "", " \n"].each do |output|
      expect { described_class.new("mint", run: ->(_) { [output, "", 0] }).call }
        .to raise_error(KeyError, "OPENAI_API_KEY_COMMAND printed no key: mint")
    end
  end

  it "fails with the status and stderr of a command that fails, whatever it printed" do
    [1, 78, nil].each do |status|
      expect { described_class.new("mint", run: ->(_) { ["sk-half", "not signed in\n", status] }).call }
        .to raise_error(KeyError, "OPENAI_API_KEY_COMMAND failed with status #{status.inspect}: mint: not signed in")
    end
  end

  it "runs at the first request, once, and not when the provider is built" do
    mint = issuer.new(%w[sk-first])
    http = server.new("sk-first")
    provider = Elelem::OpenAI::Provider.new(model: "m", key_command: described_class.new("mint", run: mint), http:)

    expect(mint.commands).to be_empty
    expect(said(provider) + said(provider)).to eq(%w[hi hi])
    expect(mint.commands).to eq(%w[mint])
    expect(http.seen).to eq(["Bearer sk-first"] * 2)
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

  context "with elelem's own HTTP client and a server that answers 401" do
    let(:listener) { TCPServer.new("127.0.0.1", 0) }
    let(:seen) { [] }

    around do |example|
      serving = Thread.new { 2.times { refuse(listener.accept) } }
      example.run
    ensure
      serving.kill
      listener.close
    end

    def refuse(client)
      head = client.readpartial(64 << 10)
      seen << head[/^authorization: (.*)\r$/i, 1]
      client.write("HTTP/1.1 401 Unauthorized\r\ncontent-length: 7\r\nconnection: close\r\n\r\nexpired")
      client.close
    end

    it "sees the 401 in the wording that the retry looks for" do
      mint = issuer.new(%w[sk-one sk-two])
      provider = Elelem::OpenAI::Provider.new(model: "m", key_command: described_class.new("mint", run: mint),
                                              base_url: "http://127.0.0.1:#{listener.addr[1]}/v1")

      expect { said(provider) }.to raise_error(RuntimeError, "HTTP 401: expired")
      expect(seen).to eq(["Bearer sk-one", "Bearer sk-two"])
    end
  end
end
