# frozen_string_literal: true

require "spec_helper"

RSpec.describe GoldMiner::BlogPost::SimpleWriter::TopicExtractor do
  describe "#call" do
    it "extracts topics from a message text" do
      message = <<~MARKDOWN
        TIL: a message about ruby and elixir, javascript, typescript, sql
        refactoring, testing, functional programming, oop, and tips
      MARKDOWN

      topics = described_class.call(message)

      expect(topics).to eq([
        "Ruby",
        "Elixir",
        "JavaScript",
        "TypeScript",
        "SQL",
        "Refactoring",
        "Testing",
        "Functional Programming",
        "OOP",
        "TIL",
        "Tip"
      ])
    end

    it "finds topics for abbreviated words" do
      message = "I actually like js and ts"

      topics = described_class.call(message)

      expect(topics).to eq(%w[JavaScript TypeScript])
    end

    it "does not add duplicates" do
      message = "I actually like js and javascript"

      topics = described_class.call(message)

      expect(topics).to eq(%w[JavaScript])
    end

    it "is case insensitive" do
      message = "I actually like JS and TyPeScrIpt"

      topics = described_class.call(message)

      expect(topics).to eq(%w[JavaScript TypeScript])
    end

    it "finds topics split in multiple lines" do
      message = <<~MARKDOWN
        I am a message about functional
        programming
      MARKDOWN

      topics = described_class.call(message)

      expect(topics).to eq(["Functional Programming"])
    end

    it "doesn't add topics for substrings" do
      message = "I like rubyon rails"

      topics = described_class.call(message)

      expect(topics).to be_empty
    end

    it "adds topics for hashtags" do
      message = "I like #ruby"

      topics = described_class.call(message)

      expect(topics).to eq(%w[Ruby])
    end
  end
end
