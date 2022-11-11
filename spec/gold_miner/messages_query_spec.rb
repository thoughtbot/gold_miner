# frozen_string_literal: true

require "spec_helper"

RSpec.describe GoldMiner::MessagesQuery do
  describe "#on_channel" do
    it "sets the channel to search messages in" do
      query = GoldMiner::MessagesQuery.new

      result = query.on_channel("dev")

      expect(query.channel).to eq("dev")
      expect(result).to eq(query)
    end
  end

  describe "#sent_after" do
    it "sets the start date to search messages" do
      query = GoldMiner::MessagesQuery.new

      result = query.sent_after("2018-01-01")

      expect(query.start_date).to eq("2018-01-01")
      expect(result).to eq(query)
    end
  end

  describe "#til_messages" do
    it "sets the query topic to TIL messages" do
      query = GoldMiner::MessagesQuery.new

      result = query.til_messages

      expect(query.topic).to eq("TIL")
      expect(result).to eq(query)
    end
  end

  describe "#tip_messages" do
    it "sets the query topic to tip messages" do
      query = GoldMiner::MessagesQuery.new

      result = query.tip_messages

      expect(query.topic).to eq("tip")
      expect(result).to eq(query)
    end
  end

  describe "#sent_after_last_friday" do
    it "sets the start date to the last Friday", :aggregate_failures do
      a_thursday = "2022-10-06"
      a_friday = "2022-10-07"
      a_saturday = "2022-10-08"

      travel_to a_thursday do
        query = GoldMiner::MessagesQuery.new

        result = query.sent_after_last_friday

        expect(query.start_date).to eq("2022-09-30")
        expect(result).to eq(query)
      end

      travel_to a_friday do
        query = GoldMiner::MessagesQuery.new

        result = query.sent_after_last_friday

        expect(query.start_date).to eq("2022-09-30") # a week before, not today
        expect(result).to eq(query)
      end

      travel_to a_saturday do
        query = GoldMiner::MessagesQuery.new

        result = query.sent_after_last_friday

        expect(query.start_date).to eq("2022-10-07") # the day before
        expect(result).to eq(query)
      end
    end
  end

  describe "#to_s" do
    it "returns the string representation of the query" do
      query = GoldMiner::MessagesQuery.new

      result = query
        .til_messages
        .sent_after("2022-10-07")
        .on_channel("dev")
        .to_s

      expect(result).to eq("TIL in:dev after:2022-10-07")
    end

    it "does not include unset options" do
      query = GoldMiner::MessagesQuery.new

      result = query.to_s

      expect(result).to eq("")
    end
  end
end
