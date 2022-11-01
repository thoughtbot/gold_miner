# frozen_string_literal: true

require "spec_helper"

RSpec.describe GoldMiner::Helpers do
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
