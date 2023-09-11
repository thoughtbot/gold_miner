# frozen_string_literal: true

require "dry/monads"
require "slack-ruby-client"

module GoldMiner
  class Slack::Client
    extend Dry::Monads[:result]

    def self.build(api_token:, slack_client: ::Slack::Web::Client)
      client = new(api_token, slack_client)

      begin
        client.auth_test

        Success(client)
      rescue ::Slack::Web::Api::Errors::SlackError
        Failure("Slack authentication failed. Please check your API token.")
      rescue ::Slack::Web::Api::Errors::HttpRequestError => e
        Failure("Slack authentication failed. An HTTP error occurred: #{e.message}.")
      end
    end

    def initialize(api_token, slack_client)
      @slack = slack_client.new(token: api_token)
      @user_name_cache = {}
    end

    def auth_test
      @slack.auth_test
    end

    def search_messages(query)
      @slack
        .search_messages(query:)
        .then { |response|
          warn_on_multiple_pages(response)
          fetch_author_names(response)

          response.messages.matches.map { |message|
            Slack::Message.new(
              id: message.id,
              text: message.text,
              user: Slack::User.new(
                id: message.user,
                name: message.author_real_name,
                username: message.username
              ),
              permalink: message.permalink
            )
          }
        }
    end

    private_class_method :new

    private

    # For simplicity, I'm not handling API pagination yet
    def warn_on_multiple_pages(result)
      if result.messages.paging.pages > 1
        warn "[WARNING] Found more than one page of results, only the first page will be processed"
      end
    end

    # Unfortunately, the Slack API doesn't return the real name of the
    # author of a message, so we need to make an additional API call for
    # each message.
    def fetch_author_names(response)
      Sync do
        author_names = response.messages.matches.map { |message|
          Async { [message.id, real_name_for(message.user)] }
        }.map(&:wait).to_h

        response.messages.matches.each { |message|
          message.author_real_name = author_names[message.id]
        }
      end
    end

    def real_name_for(user_id)
      @user_name_cache[user_id] ||=
        user_info(user_id)
          .user
          .profile
          .real_name
    end

    def user_info(user_id)
      @slack.users_info(user: user_id)
    end
  end
end
