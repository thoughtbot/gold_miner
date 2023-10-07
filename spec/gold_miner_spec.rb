# frozen_string_literal: true

require "dry-monads"

RSpec.describe GoldMiner do
  include Dry::Monads[:result]

  describe ".mine_in" do
    it "loads the API token from the given env file" do
      slack_client_builder = spy("Slack::Client builder")

      GoldMiner.mine_in("dev", slack_client: slack_client_builder, env_file: "./spec/fixtures/.env.test")

      expect(slack_client_builder).to have_received(:build).with(api_token: "test-token")
    end

    it "returns interesting messages from the given channel" do
      message_author = TestFactories.create_slack_user
      slack_message = TestFactories.create_slack_message(user: message_author)
      search_result = [slack_message]

      slack_client = instance_double(GoldMiner::Slack::Client, search_messages: search_result)
      slack_client_builder = double(GoldMiner::Slack::Client, build: Success(slack_client))

      result = GoldMiner.mine_in("dev", slack_client: slack_client_builder, env_file: "./spec/fixtures/.env.test")
      gold_nuggets = result.value!.gold_nuggets

      expect(gold_nuggets).to eq [
        TestFactories.create_gold_nugget(
          content: slack_message.text,
          author: TestFactories.create_author(
            id: message_author.username,
            name: message_author.name,
            link: "#to-do"
          ),
          source: slack_message.permalink
        )
      ]
    end
  end

  describe ".smith_blog_post" do
    it "creates a blog post from a gold container" do
      date = "2022-10-07"
      travel_to date do
        with_env("OPEN_AI_API_TOKEN" => nil) do
          channel = "dev"
          gold_nuggets = [
            TestFactories.create_gold_nugget,
            TestFactories.create_gold_nugget
          ]
          blog_post_class = spy("BlogPost class")
          container = TestFactories.create_gold_container(
            gold_nuggets: gold_nuggets,
            origin: channel,
            packing_date: Date.today
          )
          GoldMiner.smith_blog_post(container, blog_post_class:)

          expect(blog_post_class).to have_received(:new).with(
            slack_channel: channel,
            gold_nuggets: gold_nuggets,
            since: Date.parse(date),
            writer: instance_of(GoldMiner::BlogPost::SimpleWriter)
          )
        end
      end
    end

    context "when the OPEN_AI_API_TOKEN is set" do
      it "uses the OpenAiWriter" do
        date = "2022-10-07"
        token = "test-token"
        travel_to date do
          with_env("OPEN_AI_API_TOKEN" => token) do
            channel = "dev"
            gold_nuggets = [
              TestFactories.create_gold_nugget,
              TestFactories.create_gold_nugget
            ]
            blog_post_class = spy("BlogPost class")
            container = TestFactories.create_gold_container(
              gold_nuggets: gold_nuggets,
              origin: channel,
              packing_date: Date.today
            )
            GoldMiner.smith_blog_post(container, blog_post_class:)

            expect(blog_post_class).to have_received(:new).with(
              slack_channel: channel,
              gold_nuggets: gold_nuggets,
              since: Date.parse(date),
              writer: instance_of(GoldMiner::BlogPost::OpenAiWriter)
            )
          end
        end
      end
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
