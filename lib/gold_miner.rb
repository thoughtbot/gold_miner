# frozen_string_literal: true

require "dotenv"
require "zeitwerk"
require "openai"

Zeitwerk::Loader.for_gem.setup

module GoldMiner
  extend self

  def mine_in(slack_channel, slack_client: GoldMiner::Slack::Client, env_file: ".env")
    Dotenv.load!(env_file)

    prepare(slack_client)
      .fmap { |client| explore(slack_channel, client) }
  end

  def convert_messages_to_blogpost(channel, gold_nuggets, blog_post_builder: GoldMiner::BlogPost)
    blog_post_builder.new(
      slack_channel: channel,
      gold_nuggets: gold_nuggets,
      since: Helpers::Time.last_friday,
      writer: BlogPost::Writer.from_env
    )
  end

  private

  def prepare(slack_client)
    slack_client.build(api_token: ENV["SLACK_API_TOKEN"])
  end

  def explore(slack_channel, slack_client)
    SlackExplorer
      .new(slack_client, AuthorConfig.default)
      .explore(slack_channel, start_on: Helpers::Time.last_friday)
  end
end
