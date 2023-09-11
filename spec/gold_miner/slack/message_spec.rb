# frozen_string_literal: true

require "spec_helper"

RSpec.describe GoldMiner::Slack::Message do
  describe "#[]" do
    it "returns the message attribute" do
      user = TestFactories.create_slack_user
      message = described_class.new(
        id: "message-1",
        text: "TIL",
        user: user,
        permalink: "https:///message-1-permalink.com"
      )

      expect(message[:text]).to eq "TIL"
      expect(message[:user]).to eq user
      expect(message[:permalink]).to eq "https:///message-1-permalink.com"
    end
  end
end
