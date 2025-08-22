# frozen_string_literal: true

class GoldMiner
  class BlogPost
    class SimpleWriter
      def initialize(topic_extractor: TopicExtractor)
        @topic_extractor = topic_extractor
      end

      def extract_topics_from(gold_nugget)
        @topic_extractor.call(gold_nugget.content)
      end

      def give_title_to(gold_nugget)
        gold_nugget.source
      end

      def summarize(gold_nugget)
        gold_nugget.as_conversation
      end
    end
  end
end
