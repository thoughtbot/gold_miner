# frozen_string_literal: true

require "spec_helper"

RSpec.describe GoldMiner::GoldNugget do
  describe "#as_conversation" do
    it "returns the gold nugget content with the author name and link" do
      author = TestFactories.create_author(name: "Matz", id: "the-ruby-matz", link: "https://example.com/matz")
      gold_nugget = described_class.new(
        content: "TIL",
        author: author,
        source: "https:///message-1-permalink.com"
      )

      conversation = gold_nugget.as_conversation

      expect(conversation).to eq <<~MARKDOWN
        [Matz][the-ruby-matz] says: TIL

        [the-ruby-matz]: https://example.com/matz
      MARKDOWN
    end
  end
end
