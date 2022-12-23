RSpec.shared_examples "a blog post writer" do |parameter|
  describe "#extract_topics_from" do
    it "extracts an array of topics from a message text" do
      message_text = "I'm learning about Ruby on Rails today"

      topics = described_class.new.extract_topics_from(message_text)

      expect(topics).to be_a Array
    end
  end

  describe "#give_title_to" do
    it "creates a title from a message text" do
      message = {
        text: "I'm learning about Ruby on Rails today",
        permalink: "https://permalink.com"
      }

      topics = described_class.new.give_title_to(message)

      expect(topics).to be_a String
    end
  end

  describe "#summarize" do
    it "summarizes a message text" do
      message_text = "I'm learning about Ruby on Rails today"

      topics = described_class.new.summarize(message_text)

      expect(topics).to be_a String
    end
  end
end
