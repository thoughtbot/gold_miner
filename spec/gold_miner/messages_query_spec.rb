# frozen_string_literal: true

require "spec_helper"

RSpec.describe GoldMiner::Slack::MessagesQuery do
  describe "#on_channel" do
    it "sets the channel to search messages in" do
      query = described_class.new

      result = query.on_channel("dev")

      expect(result.channel).to eq("dev")
    end
  end

  describe "#sent_after" do
    it "sets the start date to search messages" do
      query = described_class.new

      result = query.sent_after("2018-01-01")

      expect(result.start_date).to eq("2018-01-01")
    end
  end

  describe "#with_reaction" do
    it "sets the query reaction to search messages" do
      query = described_class.new

      result = query.with_reaction("thumbsup")

      expect(result.reaction).to eq("thumbsup")
    end
  end

  describe "#with_topic" do
    it "sets the query topic to TIL messages" do
      query = described_class.new

      result = query.with_topic("TIL")

      expect(result.topic).to eq("TIL")
    end
  end

  describe "#to_s" do
    it "returns the string representation of the query" do
      query = described_class.new

      result = query
        .with_topic("TIL")
        .sent_after("2022-10-07")
        .on_channel("dev")
        .with_reaction("thumbsup")
        .to_s

      expect(result).to eq("TIL in:dev after:2022-10-07 has::thumbsup:")
    end

    it "does not include unset options" do
      query = described_class.new

      result = query.to_s

      expect(result).to eq("")
    end
  end
end
