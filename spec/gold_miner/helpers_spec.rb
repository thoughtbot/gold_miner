# frozen_string_literal: true

require "spec_helper"

RSpec.describe GoldMiner::Helpers do
  describe GoldMiner::Helpers::Time do
    describe ".last_friday" do
      it "returns the last Friday when today is Saturday" do
        travel_to Date.new(2024, 7, 13) do
          result = described_class.last_friday

          expect(result).to eq("2024-07-12")
        end
      end

      it "returns the last Friday when today is Friday" do
        travel_to Date.new(2024, 7, 12) do
          result = described_class.last_friday

          expect(result).to eq("2024-07-05")
        end
      end

      it "returns the last Friday when today is Thursday" do
        travel_to Date.new(2024, 7, 11) do
          result = described_class.last_friday

          expect(result).to eq("2024-07-05")
        end
      end
    end
  end

  describe GoldMiner::Helpers::Sentence do
    describe ".from" do
      it "returns a sentence from a list of words" do
        expect(GoldMiner::Helpers::Sentence.from([])).to eq("")
        expect(GoldMiner::Helpers::Sentence.from(%w[foo])).to eq("foo")
        expect(GoldMiner::Helpers::Sentence.from(%w[foo bar])).to eq("foo and bar")
        expect(GoldMiner::Helpers::Sentence.from(%w[foo bar baz])).to eq("foo, bar, and baz")
      end
    end
  end
end
