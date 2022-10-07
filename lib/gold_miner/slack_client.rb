# frozen_string_literal: true

require "dry/monads"
require "slack-ruby-client"

module GoldMiner
  class SlackClient
    extend Dry::Monads[:result]

    def self.build(api_token:)
      client = new(api_token)

      begin
        client.auth_test

        Success(client)
      rescue => e
        Failure(e)
      end
    end

    def initialize(api_token)
      @slack = Slack::Web::Client.new(token: api_token)
    end

    def auth_test
      @slack.auth_test
    end

    def search_interesting_messages_in(channel)
      til_message_results = @slack.search_messages(query: interesting_messages_query(channel).til_messages)
      tip_message_results = @slack.search_messages(query: interesting_messages_query(channel).tip_messages)
      messages = (til_message_results.messages.matches + tip_message_results.messages.matches).uniq { |msg| msg.iid }
      warn_on_multiple_pages(til_message_results, tip_message_results)

      # TODO: messages might have a `files[0].preview` with code snippets
      messages.map { |match|
        {
          text: match.text,
          author_username: match.username,
          permalink: match.permalink
        }
      }
    end

    private_class_method :new

    private

    def interesting_messages_query(channel)
      MessagesQuery
        .new
        .on_channel(channel)
        .sent_since_last_friday
    end

    # For simplicity, I'm not handling API pagination yet
    def warn_on_multiple_pages(*results)
      results.each do |result|
        if result.messages.paging.pages > 1
          warn "[WARNING] Found more than one page of results, only the first page will be processed"
        end
      end
    end
  end
end
