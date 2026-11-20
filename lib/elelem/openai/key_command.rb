# frozen_string_literal: true

module Elelem
  module OpenAI
    class KeyCommand
      VARIABLE = "OPENAI_API_KEY_COMMAND"
      COMPLAINT_LIMIT = 500
      SHELL = lambda do |command|
        Tempfile.create("elelem-openai") do |complaint|
          output = IO.popen(command, err: complaint, &:read)
          [output, complaint.tap(&:rewind).read(COMPLAINT_LIMIT), Process.last_status.exitstatus]
        end
      end

      def initialize(command, run: SHELL)
        @command = command
        @run = run
      end

      def call
        output, complaint, status = @run.call(@command)
        raise KeyError, failure(status, complaint) unless status&.zero?

        printed(output)
      rescue SystemCallError => e
        raise KeyError, "#{VARIABLE} could not run: #{e.message}"
      end

      private

      def failure(status, complaint)
        said = complaint.to_s.strip
        "#{VARIABLE} failed with status #{status.inspect}: #{@command}#{": #{said}" unless said.empty?}"
      end

      def printed(output)
        key = output.to_s.strip
        raise KeyError, "#{VARIABLE} printed no key: #{@command}" if key.empty?

        key
      end
    end
  end
end
