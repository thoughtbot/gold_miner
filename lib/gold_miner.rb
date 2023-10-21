# frozen_string_literal: true

require "dotenv"
require "zeitwerk"
require "openai"

Zeitwerk::Loader.for_gem.setup

class GoldMiner
  class << self
    def mine_in(slack_channel, slack_client: GoldMiner::Slack::Client, env_file: ".env")
      Dotenv.load!(env_file)

      prepare(slack_client)
        .fmap { |client| explore(slack_channel, client) }
    end

    def smith_blog_post(gold_container, ...)
      BlogPostSmith.new(...).smith(gold_container)
    end

    def distribute(blog_post)
      TerminalDistributor.new.distribute(blog_post)
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
end
