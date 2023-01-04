# frozen_string_literal: true

require "spec_helper"
require "ostruct"

RSpec.describe GoldMiner::Slack::Message do
  describe "#[]" do
    it "returns the message attribute" do
      message = described_class.new(
        text: "TIL",
        author: "@JohnDoe",
        permalink: "https:///message-1-permalink.com"
      )

      expect(message[:text]).to eq "TIL"
      expect(message[:author]).to eq "@JohnDoe"
      expect(message[:permalink]).to eq "https:///message-1-permalink.com"
    end
  end

  describe "#==" do
    it "returns true if the messages have the same attributes" do
      message1 = described_class.new(
        text: "TIL",
        author: "@JohnDoe",
        permalink: "https:///message-1-permalink.com"
      )
      message2 = described_class.new(
        text: "TIL",
        author: "@JohnDoe",
        permalink: "https:///message-1-permalink.com"
      )

      result = message1 == message2

      expect(result).to be true
    end

    it "returns false if any of the attributes are different" do
      message1 = described_class.new(
        text: "TIL",
        author: "@JohnDoe",
        permalink: "https:///message-1-permalink.com"
      )
      message2 = described_class.new(
        text: "TIL2",
        author: "@JohnDoe",
        permalink: "https:///message-1-permalink.com"
      )
      message3 = described_class.new(
        text: "TIL",
        author: "@JohnDoe2",
        permalink: "https:///message-1-permalink.com"
      )
      message4 = described_class.new(
        text: "TIL",
        author: "@JohnDoe",
        permalink: "https:///message-2-permalink.com"
      )

      expect(message1 == message2).to be false
      expect(message1 == message3).to be false
      expect(message1 == message4).to be false
      expect(message2 == message3).to be false
      expect(message2 == message4).to be false
      expect(message3 == message4).to be false
    end
  end
end
