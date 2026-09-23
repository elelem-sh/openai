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
      attr_reader :body

      def initialize(response)
        @response = response
      end

      def post(_uri, body:, **)
        @body = body
        yield @response
      end
    end.new(response)
  end

  def sse(events)
    events.map { |event| "data: #{JSON.generate(event)}\n" }.join << "data: [DONE]\n"
  end

  describe "#fetch" do
    it "always sends tools and tool_choice" do
      provider.fetch(messages, [])

      expect(body).to eq(model: "gpt-4o", messages:, stream: true, tools: [], tool_choice: "auto")
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

      it "raises instead of defaulting to an empty hash" do
        expect { provider.fetch(messages, []) {} }.to raise_error(JSON::ParserError)
      end
    end
  end
end
