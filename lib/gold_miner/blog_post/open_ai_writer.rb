# frozen_string_literal: true

require "openai"
require "json"

class GoldMiner
  class BlogPost
    class OpenAiWriter
      def initialize(open_ai_api_token:, fallback_writer:, open_ai_client: OpenAI::Client)
        @openai_client = open_ai_client.new(access_token: open_ai_api_token)
        @fallback_writer = fallback_writer
      end

      def extract_topics_from(gold_nugget)
        topics_json = ask_openai("Extract the 3 most relevant topics, if possible in one word, from this text as a single parseable JSON array: #{gold_nugget.content}")

        if (topics = try_parse_json(topics_json))
          topics
        else
          fallback_topics_for(gold_nugget)
        end
      end

      def give_title_to(gold_nugget)
        title = ask_openai("Give a small title to this text: #{gold_nugget.content}")
        title = title&.delete_prefix('"')&.delete_suffix('"')

        title || fallback_title_for(gold_nugget)
      end

      def summarize(gold_nugget)
        summary = ask_openai <<~PROMPT
          Summarize the following markdown message without removing the author's blog link. Return the summary as markdown.

          Message:
          #{gold_nugget.as_conversation}
        PROMPT

        if summary
          "#{summary}\n\nSource: #{gold_nugget.source}"
        else
          fallback_summary_for(gold_nugget)
        end
      end

      private

      def ask_openai(prompt)
        response = @openai_client.chat(
          parameters: {
            model: "gpt-3.5-turbo",
            messages: [{role: "user", content: prompt.strip}],
            temperature: 0
          }
        )

        if !response["error"].nil?
          warn "[WARNING] OpenAI error: #{response["error"]["message"]}"
          return
        end

        response.dig("choices", 0, "message", "content").strip
      rescue SocketError
        nil
      end

      def fallback_title_for(gold_nugget)
        @fallback_writer.give_title_to(gold_nugget)
      end

      def fallback_summary_for(gold_nugget)
        @fallback_writer.summarize(gold_nugget)
      end

      def fallback_topics_for(gold_nugget)
        @fallback_writer.extract_topics_from(gold_nugget)
      end

      def try_parse_json(json)
        sanitized_json = json.to_s.delete_prefix("`").delete_suffix("`")

        JSON.parse(sanitized_json)
      rescue JSON::ParserError
        nil
      end
    end
  end
end
