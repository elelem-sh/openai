# frozen_string_literal: true

require "json"
require "net/http"
require "uri"

module Elelem
  module OpenAI
    class Client
      def initialize(model:, api_key:, base_url: "https://api.openai.com/v1", read_timeout: 3600, open_timeout: 10)
        @uri = URI.join("#{base_url}/", "chat/completions")
        @model = model
        @api_key = api_key
        @read_timeout = read_timeout
        @open_timeout = open_timeout
      end

      def fetch(messages, tools = [], &block)
        tool_calls = {}
        body = build_request_body(messages, tools)

        stream(body) do |event|
          handle_event(event, tool_calls, &block)
        end

        finalize_tool_calls(tool_calls, &block)
      end

      private

      def build_request_body(messages, tools)
        { model: @model, messages:, stream: true, tools:, tool_choice: "auto" }
      end

      def handle_event(event, tool_calls, &block)
        delta = event.dig("choices", 0, "delta") || {}

        block.call(type: "saying", text: delta["content"]) if delta["content"]

        accumulate_tool_calls(delta["tool_calls"], tool_calls) if delta["tool_calls"]
      end

      def accumulate_tool_calls(incoming_tool_calls, tool_calls)
        incoming_tool_calls.each do |tool_call|
          index = tool_call["index"]
          tool_calls[index] ||= { id: nil, name: nil, args: String.new }
          tool_calls[index][:id] ||= tool_call["id"]
          tool_calls[index][:name] ||= tool_call.dig("function", "name")
          tool_calls[index][:args] << tool_call.dig("function", "arguments").to_s
        end
      end

      def stream(body)
        request = Net::HTTP::Post.new(@uri)
        request["content-type"] = "application/json"
        request["authorization"] = "Bearer #{@api_key}"
        request.body = JSON.generate(body)

        http = Net::HTTP.new(@uri.host, @uri.port)
        http.use_ssl = @uri.scheme == "https"
        http.read_timeout = @read_timeout
        http.open_timeout = @open_timeout

        http.start do |conn|
          conn.request(request) do |response|
            raise "HTTP #{response.code}: #{response.body}" unless response.is_a?(Net::HTTPSuccess)

            read_sse_stream(response) { |event| yield event }
          end
        end
      end

      def read_sse_stream(response)
        buffer = String.new

        response.read_body do |chunk|
          buffer << chunk

          while (index = buffer.index("\n"))
            line = buffer.slice!(0, index + 1).strip
            next unless line.start_with?("data: ") && line != "data: [DONE]"

            yield JSON.parse(line.delete_prefix("data: "))
          end
        end
      end

      def finalize_tool_calls(tool_calls, &block)
        tool_calls.values.map do |tool_call|
          {
            id: tool_call[:id],
            name: tool_call[:name],
            arguments: JSON.parse(tool_call[:args])
          }.tap { |result| block.call(result.merge(type: "doing")) }
        end
      end
    end
  end
end
