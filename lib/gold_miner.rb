# frozen_string_literal: true

require "dotenv"
require "zeitwerk"

Zeitwerk::Loader.for_gem.setup

module GoldMiner
  extend self

  def mine_in(slack_channel, slack_client: GoldMiner::SlackClient, env_file: ".env")
    Dotenv.load(env_file)

    slack_client
      .build(api_token: ENV["SLACK_API_TOKEN"])
      .fmap { |client| client.search_interesting_messages_in(slack_channel) }
  end

  def convert_messages_to_blogpost(channel, messages, blog_post_builder: GoldMiner::BlogPost)
    blog_post_builder.new(slack_channel: channel, messages: messages, since: Helpers::Time.last_friday)
  end
end
