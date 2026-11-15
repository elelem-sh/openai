# frozen_string_literal: true

# A fake Chat Completions server that rejects a history in the wrong shape,
# the way the API does with a 400.
RSpec.describe "a tool call round trip through Elelem::Agent" do
  let(:server) do
    Class.new do
      attr_reader :requests

      def initialize
        @requests = []
      end

      def post(_uri, body:, **)
        @requests << body
        problem = invalid(body[:messages])
        events = @requests.size == 1 ? tool_call : reply
        yield(problem ? bad_request(problem) : ok(events))
      end

      private

      def invalid(messages)
        messages.flat_map { |m| m[:tool_calls] || [] }.find do |call|
          call[:type] != "function" || !call.dig(:function, :arguments).is_a?(String)
        end
      end

      def tool_call
        call = { "index" => 0, "id" => "c1", "function" => { "name" => "now", "arguments" => "{}" } }
        [{ "choices" => [{ "delta" => { "tool_calls" => [call] } }] }]
      end

      def reply = [{ "choices" => [{ "delta" => { "content" => "It is noon." } }] }]

      def ok(events)
        Net::HTTPOK.new("1.1", "200", "OK").tap do |res|
          data = events.map { |e| "data: #{JSON.generate(e)}\n" }.join << "data: [DONE]\n"
          res.define_singleton_method(:read_body) { |&block| block.call(data) }
        end
      end

      def bad_request(problem)
        Net::HTTPBadRequest.new("1.1", "400", "Bad Request").tap do |res|
          res.define_singleton_method(:body) { "invalid tool call: #{problem}" }
        end
      end
    end.new
  end

  it "calls the tool, sends its result back, and gets the reply" do
    toolbox = Elelem::Toolbox.new
    toolbox.add("now", description: "Time", params: {}) { { time: "noon" } }
    provider = Elelem::OpenAI::Provider.new(model: "gpt-4o", api_key: "sk-test", http: server)

    reply = Elelem::Agent.new(provider, toolbox: toolbox, output: Elelem::NullOutput.new).turn("What time is it?")

    expect(reply).to eq("It is noon.")
    expect(server.requests.size).to eq(2)
  end
end
