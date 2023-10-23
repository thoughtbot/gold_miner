# frozen_string_literal: true

require "dry/monads"
require "dotenv"

RSpec.describe GoldMiner do
  include Dry::Monads[:result]

  describe "#mine" do
    it "explores, smiths and distributes gold from the given location and date" do
      location = "dev"
      start_date = Date.parse("2023-10-20")
      gold_container = TestFactories.create_gold_container
      explorer = spy("Explorer", explore: gold_container)
      blog_post = TestFactories.create_blog_post
      smith = spy("Smith", smith: blog_post)
      distributor = spy("Distributor", distribute: nil)

      gold_miner = GoldMiner.new(explorer: explorer, smith: smith, distributor: distributor)
      result = gold_miner.mine(location, start_on: start_date)

      expect(explorer).to have_received(:explore).with(location, start_on: start_date)
      expect(smith).to have_received(:smith).with(gold_container)
      expect(distributor).to have_received(:distribute).with(blog_post)
      expect(result).to be_success
    end
  end

  it "keeps env files in sync" do
    fixture_env = Dotenv.parse("./spec/fixtures/.env.test")
    example_env = Dotenv.parse(".env.example")

    expect(example_env.keys).to match_array(fixture_env.keys)
  end

  it "has a version number" do
    expect(GoldMiner::VERSION).not_to be nil
  end
end
