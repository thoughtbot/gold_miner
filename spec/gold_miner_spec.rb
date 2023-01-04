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
      messages = {text: "text", author_username: "user1", permalink: "http://permalink-1.com"}
      slack_client = instance_double(GoldMiner::Slack::Client, search_interesting_messages_in: messages)
      slack_client_builder = double(GoldMiner::Slack::Client, build: Success(slack_client))

      result = GoldMiner.mine_in("dev", slack_client: slack_client_builder, env_file: "./spec/fixtures/.env.test")

      expect(result.value!).to eq messages
    end
  end

  describe ".convert_messages_to_blogpost" do
    it "converts slack messages to a blogpost and writes it to a file" do
      travel_to "2022-10-07" do
        with_env("OPEN_AI_API_TOKEN" => nil) do
          channel = "dev"
          messages = [
            {text: "text", author_username: "user1", permalink: "http://permalink-1.com"},
            {text: "text2", author_username: "user2", permalink: "http://permalink-2.com"}
          ]
          blog_post_builder = spy("BlogPost builder")

          GoldMiner.convert_messages_to_blogpost(channel, messages, blog_post_builder: blog_post_builder)

          expect(blog_post_builder).to have_received(:new).with(
            slack_channel: channel,
            messages: messages,
            since: "2022-09-30",
            writer: instance_of(GoldMiner::BlogPost::SimpleWriter)
          )
        end
      end
    end

    context "when the OPEN_AI_API_TOKEN is set" do
      it "uses the OpenAiWriter" do
        travel_to "2022-10-07" do
          with_env("OPEN_AI_API_TOKEN" => "test-token") do
            channel = "dev"
            messages = []
            blog_post_builder = spy("BlogPost builder")

            GoldMiner.convert_messages_to_blogpost(channel, messages, blog_post_builder: blog_post_builder)

            expect(blog_post_builder).to have_received(:new).with(
              slack_channel: channel,
              messages: messages,
              since: "2022-09-30",
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

  private

  def with_env(env)
    original_env = ENV.to_hash
    ENV.update(env)

    yield
  ensure
    ENV.replace(original_env)
  end
end
