# frozen_string_literal: true

module Elelem
  module OpenAI
    class Provider
      def initialize(model:, api_key: "", key_command: nil, base_url: "https://api.openai.com/v1", read_timeout: 3600,
                     open_timeout: 10, http: nil)
        @uri = URI.join("#{base_url.chomp("/")}/", "chat/completions")
        @model = model
        @key_command = key_command
        @api_key = key_command ? key_command.call : api_key
        @read_timeout = read_timeout
        @open_timeout = open_timeout
        @http = http
      end

      def fetch(messages, tools = [], &)
        tool_calls = {}
        body = build_request_body(messages, tools)

        stream(body) do |event|
          handle_event(event, tool_calls, &)
        end

        finalize_tool_calls(tool_calls, &)
      end

      private

      def build_request_body(messages, tools)
        body = { model: @model, messages: messages.map { |m| normalize(m) }, stream: true }
        tools.empty? ? body : body.merge(tools:, tool_choice: "auto")
      end

      # elelem keeps tool calls as {id, name, arguments: Hash}. Chat Completions
      # wants {id, type: "function", function: {name, arguments: "<json>"}}.
      def normalize(message)
        calls = message[:tool_calls]
        return message unless calls

        message.merge(tool_calls: calls.map { |call| to_openai(call) })
      end

      def to_openai(call)
        arguments = call[:arguments]
        arguments = JSON.generate(arguments || {}) unless arguments.is_a?(String)
        { id: call[:id], type: "function", function: { name: call[:name], arguments: } }
      end

      def handle_event(event, tool_calls, &block)
        stopped(event.dig("choices", 0, "finish_reason"))
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

      # Raises before a cut-off tool call is parsed.
      def stopped(reason)
        case reason
        when "length" then raise "the reply hit the model's output limit before it ended"
        when "content_filter" then raise "the reply was stopped by a content filter"
        end
      end

      def stream(body, &)
        post(body, &)
      rescue RuntimeError => e
        raise unless renewable?(e)

        @api_key = @key_command.call
        post(body, &)
      end

      def post(body)
        http.post(@uri, body:, headers:) do |response|
          Elelem::HTTP.events(response) { |data| yield JSON.parse(data) }
        end
      end

      def renewable?(error) = @key_command && error.message.start_with?("HTTP 401")

      # A local server may need no key.
      def headers
        @api_key.to_s.empty? ? {} : { "authorization" => "Bearer #{@api_key}" }
      end

      def http
        @http ||= Elelem::HTTP.new(read_timeout: @read_timeout, open_timeout: @open_timeout)
      end

      def finalize_tool_calls(tool_calls, &block)
        tool_calls.values.map do |tool_call|
          {
            id: tool_call[:id],
            name: tool_call[:name],
            arguments: tool_call[:args].strip.empty? ? {} : JSON.parse(tool_call[:args])
          }.tap { |result| block.call(result.merge(type: "doing")) }
        end
      end
    end
  end
end
