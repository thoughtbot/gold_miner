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

      writer = described_class.new(topic_extractor: topic_extractor)
      extracted_topics = writer.extract_topics_from("message text")

      expect(extracted_topics).to eq(topics)
      expect(topic_extractor).to have_received(:call).with("message text")
    end

    it "has a default topic extractor" do
      message = "message text"
      writer = described_class.new

      extracted_topics = writer.extract_topics_from(message)

      expect(extracted_topics).to be_a Array
    end
  end

  describe "#give_title_to" do
    it "returns the message permalink" do
      message = {permalink: "https://permalink.com", text: "message text"}
      writer = described_class.new

      title = writer.give_title_to(message)

      expect(title).to eq("https://permalink.com")
    end
  end

  describe "#summarize" do
    it "returns the given text" do
      message = "message text"
      writer = described_class.new

      summary = writer.summarize(message)

      expect(summary).to eq(message)
    end
  end
end
