# frozen_string_literal: true

require "dry/monads"
require "slack-ruby-client"

module GoldMiner
  class SlackClient
    GOLD_EMOJI = "rupee-gold"

    extend Dry::Monads[:result]

    def self.build(api_token:)
      client = new(api_token)

      begin
        client.auth_test

        Success(client)
      rescue Slack::Web::Api::Errors::InvalidAuth, Slack::Web::Api::Errors::NotAuthed
        Failure("Authentication failed. Please check your API token.")
      end
    end

    def initialize(api_token)
      @slack = Slack::Web::Client.new(token: api_token)
    end

    def auth_test
      @slack.auth_test
    end

    def search_interesting_messages_in(channel)
      til_messages = extract_messages_from_result(
        @slack.search_messages(query: interesting_messages_query(channel).with_topic("TIL")),
        topic: :til
      )
      tip_messages = extract_messages_from_result(
        @slack.search_messages(query: interesting_messages_query(channel).with_topic("tip")),
        topic: :tip
      )
      golden_messages = extract_messages_from_result(
        @slack.search_messages(query: interesting_messages_query(channel).with_reaction(GOLD_EMOJI)),
        topic: nil
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

    def extract_messages_from_result(result, topic:)
      warn_on_multiple_pages(result)

      result.messages.matches.map do |match|
        {
          text: match.text,
          author_username: match.username,
          permalink: match.permalink,
          topic: topic
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
