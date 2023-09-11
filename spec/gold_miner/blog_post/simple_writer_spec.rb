# frozen_string_literal: true

require "spec_helper"

RSpec.describe GoldMiner::BlogPost::SimpleWriter do
  it_behaves_like "a blog post writer" do
    let(:writer_instance) { described_class.new }
  end

  describe "#extract_topics_from" do
    it "delegates to the topic extractor" do
      topics = ["topic-#{rand}"]
      topic_extractor = double(:topic_extractor, call: topics)
      gold_nugget = TestFactories.create_gold_nugget(content: "message text")

      writer = described_class.new(topic_extractor: topic_extractor)
      extracted_topics = writer.extract_topics_from(gold_nugget)

      expect(extracted_topics).to eq(topics)
      expect(topic_extractor).to have_received(:call).with(gold_nugget.content)
    end

    it "has a default topic extractor" do
      gold_nugget = TestFactories.create_gold_nugget(content: "message text")
      writer = described_class.new

      extracted_topics = writer.extract_topics_from(gold_nugget)

      expect(extracted_topics).to be_a Array
    end
  end

  describe "#give_title_to" do
    it "returns the message permalink" do
      gold_nugget = TestFactories.create_gold_nugget(source: "https://permalink.com", content: "message text")
      writer = described_class.new

      title = writer.give_title_to(gold_nugget)

      expect(title).to eq("https://permalink.com")
    end
  end

  describe "#summarize" do
    it "returns the given text" do
      gold_nugget = TestFactories.create_gold_nugget(content: "message text")
      writer = described_class.new

      summary = writer.summarize(gold_nugget)

      expect(summary).to eq(gold_nugget.content)
    end
  end
end
