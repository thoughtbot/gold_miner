# frozen_string_literal: true

module GoldMiner
  class BlogPost
    module Writer
      def self.from_env
        if ENV["OPEN_AI_API_TOKEN"]
          GoldMiner::BlogPost::OpenAiWriter.new(
            open_ai_api_token: ENV["OPEN_AI_API_TOKEN"],
            fallback_writer: GoldMiner::BlogPost::SimpleWriter.new
          )
        else
          GoldMiner::BlogPost::SimpleWriter.new
        end
      end
    end
  end
end
