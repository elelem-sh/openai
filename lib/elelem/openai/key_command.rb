# frozen_string_literal: true

module Elelem
  module OpenAI
    class KeyCommand
      VARIABLE = "OPENAI_API_KEY_COMMAND"
      SHELL = ->(command) { IO.popen(command, &:read) }

      def initialize(command, run: SHELL)
        @command = command
        @run = run
      end

      def call
        key = @run.call(@command).to_s.strip
        raise KeyError, "#{VARIABLE} printed no key: #{@command}" if key.empty?

        key
      end
    end
  end
end
