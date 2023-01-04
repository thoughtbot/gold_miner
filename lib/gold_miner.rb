# frozen_string_literal: true

require "dotenv"
require "zeitwerk"
require "ruby/openai"

Zeitwerk::Loader.for_gem.setup

module GoldMiner
  extend self

  def mine_in(slack_channel, slack_client: GoldMiner::Slack::Client, env_file: ".env")
    Dotenv.load!(env_file)

    slack_client
      .build(api_token: ENV["SLACK_API_TOKEN"])
      .fmap { |client| client.search_interesting_messages_in(slack_channel) }
  end

  def convert_messages_to_blogpost(channel, messages, blog_post_builder: GoldMiner::BlogPost)
    blog_post_builder.new(
      slack_channel: channel,
      messages: messages,
      since: Helpers::Time.last_friday,
      writer: blog_post_writer
    )
  end

  private

  def blog_post_writer
    if ENV["OPEN_AI_API_TOKEN"]
      GoldMiner::BlogPost::OpenAiWriter.new(
        open_ai_api_token: ENV["OPEN_AI_API_TOKEN"],
        fallback_writer: GoldMiner::BlogPost::SimpleWriter.new
      )
    else
      GoldMiner::BlogPost::SimpleWriter.new
    end
  end
end
