# frozen_string_literal: true

require "spec_helper"

RSpec.describe GoldMiner::BlogPost::Writer do
  describe ".from_env" do
    context "when OPEN_AI_API_TOKEN env var is set" do
      it "returns an OpenAI writer" do
        with_env("OPEN_AI_API_TOKEN" => "test-token") do
          writer = described_class.from_env

          expect(writer).to be_a GoldMiner::BlogPost::OpenAiWriter
        end
      end
    end
    context "when OPEN_AI_API_TOKEN env var is not set" do
      it "returns a Simple writer" do
        with_env("OPEN_AI_API_TOKEN" => nil) do
          writer = described_class.from_env

          expect(writer).to be_a GoldMiner::BlogPost::SimpleWriter
        end
      end
    end
  end
end
