# frozen_string_literal: true

module GoldMiner
  class BlogPost
    class SimpleWriter
      def initialize(topic_extractor: TopicExtractor)
        @topic_extractor = topic_extractor
      end

      def extract_topics_from(message)
        @topic_extractor.call(message[:text])
      end

      def give_title_to(message)
        message[:permalink]
      end

      def summarize(message)
        message[:text]
      end
    end
  end
end
