# frozen_string_literal: true

require "dry/monads"
require "slack-ruby-client"

module GoldMiner
  class BlogPost
    def initialize(slack_channel:, messages:, since:)
      @slack_channel = slack_channel
      @messages = messages
      @since = since
    end

    def to_s
      <<~MARKDOWN
        ---
        title: "#{title}"
        tags: #{tags}
        teaser: >
          Highlights of what happened in our ##{@slack_channel} channel on Slack this week.
        author: Matheus Richard
        ---

        #{highlights}

        ## Thanks

        This edition was brought to you by: #{authors}. Thanks to all contributors! 🎉
      MARKDOWN
    end

    def title
      "This week in ##{@slack_channel} #{time_period}"
    end

    def tags
      [
        "this-week-in-#{@slack_channel}",
        *topics
      ].join(", ")
    end

    def highlights
      @messages.map { |message| highlight_from(message) }.join("\n").chomp("")
    end

    def highlight_from(message)
      <<~MARKDOWN
        ## #{message[:permalink]}

        #{message[:text]}
      MARKDOWN
    end

    def time_period
      start_date = @since
      end_date = Helpers::Time.as_yyyy_mm_dd(Date.today)

      "(#{start_date} - #{end_date})"
    end

    def topics
      @messages.map { |message| message[:topic] }.uniq
    end

    def authors
      @messages
        .map { |message| "@#{message[:author_username]}" }
        .uniq
        .sort
        .then { |author_usernames| Helpers::Sentence.from(author_usernames) }
    end
  end
end
