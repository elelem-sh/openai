# frozen_string_literal: true

RSpec.describe Elelem::OpenAI::Provider do
  subject(:provider) do
    described_class.new(model: "gpt-4o", api_key: "sk-test", http:, **params)
  end

  let(:params) { {} }
  let(:messages) { [{ role: "user", content: "hi" }] }
  let(:body) { http.body }

  let(:response) do
    Net::HTTPOK.new("1.1", "200", "OK").tap do |res|
      allow(res).to receive(:read_body).and_yield(sse(events))
    end
  end

  let(:events) { [] }

  let(:http) do
    Class.new do
      attr_reader :body, :headers

      def initialize(response)
        @response = response
      end

      def post(_uri, body:, headers: {})
        @body = body
        @headers = headers
        yield @response
      end
    end.new(response)
  end

  def sse(events)
    events.map { |event| "data: #{JSON.generate(event)}\n" }.join << "data: [DONE]\n"
  end

  describe "#fetch" do
    it "leaves out tools and tool_choice when there are no tools" do
      provider.fetch(messages, [])

      expect(body).to eq(model: "gpt-4o", messages:, stream: true)
    end

    it "sends the key as a bearer token" do
      provider.fetch(messages, [])

      expect(http.headers).to eq("authorization" => "Bearer sk-test")
    end

    context "without a key, as for a local server" do
      let(:params) { { api_key: "" } }

      it "sends no authorization header" do
        provider.fetch(messages, [])

        expect(http.headers).to eq({})
      end
    end

    it "reads events split by CRLF" do
      allow(response).to receive(:read_body)
        .and_yield(%(data: {"choices":[{"delta":{"content":"hi"}}]}\r\n\r\ndata: [DONE]\r\n))
      seen = []

      provider.fetch(messages, []) { |event| seen << event }

      expect(seen).to eq([{ type: "saying", text: "hi" }])
    end

    context "with a tool call cut off at the output limit" do
      let(:events) do
        [{ "choices" => [{ "delta" => { "tool_calls" => [{ "index" => 0, "id" => "1",
                                                           "function" => { "name" => "write",
                                                                           "arguments" => '{"path":"a' } }] } }] },
         { "choices" => [{ "delta" => {}, "finish_reason" => "length" }] }]
      end

      it "says so instead of failing to parse half the arguments" do
        expect { provider.fetch(messages, []) {} }.to raise_error(/output limit before it ended/)
      end
    end

    context "with a filtered reply" do
      let(:events) { [{ "choices" => [{ "delta" => {}, "finish_reason" => "content_filter" }] }] }

      it "raises" do
        expect { provider.fetch(messages, []) {} }.to raise_error(/stopped by a content filter/)
      end
    end

    it "sends tools with tool_choice auto" do
      tools = [{ type: "function", function: { name: "read" } }]
      provider.fetch(messages, tools)

      expect(body).to include(tools:, tool_choice: "auto")
    end

    it "sends earlier tool calls in the Chat Completions shape" do
      history = messages + [
        { role: "assistant", content: "", tool_calls: [{ id: "1", name: "read", arguments: { "path" => "a.rb" } }] },
        { role: "tool", tool_call_id: "1", content: "{}" }
      ]
      provider.fetch(history, [])

      expect(body[:messages][1][:tool_calls]).to eq(
        [{ id: "1", type: "function", function: { name: "read", arguments: '{"path":"a.rb"}' } }]
      )
      expect(body[:messages][2]).to eq(history[2])
    end

    context "with a text delta" do
      let(:events) { [{ "choices" => [{ "delta" => { "content" => "hi" } }] }] }

      it "yields a saying block" do
        seen = []

        provider.fetch(messages, []) { |event| seen << event }

        expect(seen).to eq([{ type: "saying", text: "hi" }])
      end
    end

    context "with a streamed tool call split across chunks" do
      let(:first_chunk) do
        { "index" => 0, "id" => "1", "function" => { "name" => "read", "arguments" => '{"path":' } }
      end
      let(:second_chunk) { { "index" => 0, "function" => { "arguments" => '"a.rb"}' } } }

      let(:events) do
        [
          { "choices" => [{ "delta" => { "tool_calls" => [first_chunk] } }] },
          { "choices" => [{ "delta" => { "tool_calls" => [second_chunk] } }] }
        ]
      end

      it "accumulates arguments across chunks into parsed json" do
        result = provider.fetch(messages, []) {}

        expect(result).to eq([{ id: "1", name: "read", arguments: { "path" => "a.rb" } }])
      end
    end

    context "with a tool call that has no arguments" do
      let(:events) do
        [{ "choices" => [{ "delta" => { "tool_calls" => [{ "index" => 0, "id" => "1",
                                                           "function" => { "name" => "read" } }] } }] }]
      end

      it "takes them as an empty hash" do
        expect(provider.fetch(messages, []) {}).to eq([{ id: "1", name: "read", arguments: {} }])
      end
    end
  end
end
