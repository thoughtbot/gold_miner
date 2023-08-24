# frozen_string_literal: true

require "spec_helper"
require "ostruct"

RSpec.describe GoldMiner::Slack::Message do
  describe "#[]" do
    it "returns the message attribute" do
      author = TestFactories.create_slack_user
      message = described_class.new(
        text: "TIL",
        author: author,
        permalink: "https:///message-1-permalink.com"
      )

      expect(message[:text]).to eq "TIL"
      expect(message[:author]).to eq author
      expect(message[:permalink]).to eq "https:///message-1-permalink.com"
    end
  end

  describe "#as_conversation" do
    it "returns the message content with the author name and link" do
      author = TestFactories.create_slack_user(name: "Matz", username: "the-ruby-matz", link: "https://example.com/matz")
      message = described_class.new(
        text: "TIL",
        author: author,
        permalink: "https:///message-1-permalink.com"
      )

      conversation = message.as_conversation

      expect(conversation).to eq <<~MARKDOWN
        [Matz][the-ruby-matz] says: TIL

        [the-ruby-matz]: https://example.com/matz
      MARKDOWN
    end
  end
end
