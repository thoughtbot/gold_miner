# frozen_string_literal: true

require "openai"
require "json"
require "top_secret"

class GoldMiner
  class BlogPost
    class OpenAiWriter
      def initialize(open_ai_api_token:, fallback_writer:, open_ai_client: OpenAI::Client)
        @openai_client = open_ai_client.new(access_token: open_ai_api_token)
        @fallback_writer = fallback_writer
      end

      def extract_topics_from(gold_nugget)
        topics_json = ask_llm("Extract the 3 most relevant topics, if possible in one word, from this text as a single parseable JSON array: #{gold_nugget.content}")

        if (topics = try_parse_json(topics_json))
          topics
        else
          fallback_topics_for(gold_nugget)
        end
      end

      def give_title_to(gold_nugget)
        title = ask_llm("Give a small title to this text: #{gold_nugget.content}")
        title = title&.delete_prefix('"')&.delete_suffix('"')

        title || fallback_title_for(gold_nugget)
      end

      def summarize(gold_nugget)
        summary = ask_llm <<~PROMPT
          Summarize the following markdown message. Keep code examples and links, if any. Return the summary as markdown.

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

      def ask_llm(prompt)
        filtered_prompt = filter_sensitive_information(prompt.strip)
        response = ask_openai(filtered_prompt.output)

        restore_information(response, mapping: filtered_prompt.mapping)
      rescue Faraday::Error => e
        warn "[WARNING] OpenAI error: #{e.response.dig(:body, "error", "message")}"
      rescue SocketError
        nil
      end

      def filter_sensitive_information(message) = TopSecret::Text.filter(message)
      def restore_information(...) = TopSecret::FilteredText.restore(...).output

      DEVELOPER_PROMPT = <<-TEXT
        I'm going to send filtered information to you in the form of free text.
        If you need to refer to the filtered information in a response, just reference it by the filter.
      TEXT
      def ask_openai(prompt)
        response = @openai_client.chat(
          parameters: {
            model: "gpt-4o",
            messages: [
              {role: "developer", content: DEVELOPER_PROMPT},
              {role: "user", content: prompt}
            ],
            temperature: 0
          }
        )

        response.dig("choices", 0, "message", "content").strip
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
