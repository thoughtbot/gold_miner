# frozen_string_literal: true

require "dry/monads"
require "slack-ruby-client"

module GoldMiner
  class SlackClient
    GOLD_EMOJI = "rupee-gold"

    extend Dry::Monads[:result]

    def self.build(api_token:, slack_client: ::Slack::Web::Client)
      client = new(api_token, slack_client)

      begin
        client.auth_test

        Success(client)
      rescue Slack::Web::Api::Errors::SlackError
        Failure("Slack authentication failed. Please check your API token.")
      rescue Slack::Web::Api::Errors::HttpRequestError => e
        Failure("Slack authentication failed. An HTTP error occurred: #{e.message}.")
      end
    end

    def initialize(api_token, slack_client)
      @slack = slack_client.new(token: api_token)
    end

    def auth_test
      @slack.auth_test
    end

    def search_interesting_messages_in(channel)
      interesting_messages = interesting_messages_query(channel)
      til_messages = extract_messages_from_result(
        @slack.search_messages(query: interesting_messages.with_topic("TIL"))
      )
      tip_messages = extract_messages_from_result(
        @slack.search_messages(query: interesting_messages.with_topic("tip"))
      )
      golden_messages = extract_messages_from_result(
        @slack.search_messages(query: interesting_messages.with_reaction(GOLD_EMOJI))
      )

      (til_messages + tip_messages + golden_messages).uniq { |message| message[:permalink] }
    end

    private_class_method :new

    private

    def interesting_messages_query(channel)
      MessagesQuery
        .new
        .on_channel(channel)
        .sent_after_last_friday
    end

    def extract_messages_from_result(result)
      warn_on_multiple_pages(result)

      result.messages.matches.map do |match|
        {
          text: match.text,
          author_username: match.username,
          permalink: match.permalink,
        }
      end
    end

    # For simplicity, I'm not handling API pagination yet
    def warn_on_multiple_pages(result)
      if result.messages.paging.pages > 1
        warn "[WARNING] Found more than one page of results, only the first page will be processed"
      end
    end
  end
end
