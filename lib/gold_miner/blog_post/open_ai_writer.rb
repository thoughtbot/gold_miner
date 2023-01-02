# frozen_string_literal: true

require "json"

module GoldMiner
  class BlogPost
    class OpenAiWriter
      def initialize(open_ai_api_token:, fallback_writer:)
        @openai_client = OpenAI::Client.new(access_token: open_ai_api_token)
        @fallback_writer = fallback_writer
      end

      def extract_topics_from(message)
        topics_json = ask_openai("Extract the 3 most relevant topics, if possible in one word, from this text as a single parseable JSON array: #{message[:text]}")

        if (topics = try_parse_json(topics_json))
          topics
        else
          fallback_topics_for(message)
        end
      end

      def give_title_to(message)
        title = ask_openai("Give a small title to this text: #{message[:text]}")
        title = title&.delete_prefix('"')&.delete_suffix('"')

        title || fallback_title_for(message)
      end

      def summarize(message)
        summary = ask_openai("Summarize this text: #{message[:text]}")

        if summary
          "#{summary}\n\nSource: #{message[:permalink]}"
        else
          fallback_summary_for(message)
        end
      end

      private

      def ask_openai(prompt)
        response = @openai_client.completions(
          parameters: {
            model: "text-davinci-003",
            prompt: prompt,
            max_tokens: 1000,
            temperature: 0
          }
        )

        if !response.success?
          warn "[WARNING] OpenAI error: #{response["error"]["message"]}"
          return
        end

        response["choices"].first["text"].strip
      end

      def fallback_title_for(message)
        @fallback_writer.give_title_to(message)
      end

      def fallback_summary_for(message)
        @fallback_writer.summarize(message)
      end

      def fallback_topics_for(message)
        @fallback_writer.extract_topics_from(message)
      end

      def try_parse_json(json)
        JSON.parse(json.to_s)
      rescue JSON::ParserError
        nil
      end
    end
  end
end
