# frozen_string_literal: true

require "spec_helper"

RSpec.describe GoldMiner::AuthorConfig do
  describe ".default" do
    it "loads the author links from the config file" do
      author_config = described_class.default

      link = author_config.link_for("matheus")

      expect(link).to eq "https://thoughtbot.com/blog/authors/matheus-richard"
    end
  end

  describe "#link_for" do
    it "returns the preferred link for the given author username" do
      matz = "matz"
      matz_link = "https://example.com/matz"
      author_config = described_class.new({matz => {"link" => matz_link}})

      link = author_config.link_for(matz)

      expect(link).to eq(matz_link)
    end

    context "when author has not a preferred link" do
      it "returns a todo link" do
        author_config = described_class.new({})

        link = author_config.link_for("some-author")

        expect(link).to eq("#to-do")
      end
    end
  end
end
