# frozen_string_literal: true

require "async"

module GoldMiner
  class BlogPost
    def initialize(slack_channel:, messages:, since:, writer: SimpleWriter.new)
      @slack_channel = slack_channel
      @messages = messages
      @since = since
      @writer = writer
    end

    def to_s
      Sync do
        tags_task = Async { tags }
        highlights_task = Async { highlights }

        <<~MARKDOWN
          ---
          title: "#{title}"
          tags: #{tags_task.wait}
          teaser: >
            Highlights of what happened in our ##{@slack_channel} channel on Slack this week.
          author: Matheus Richard
          auto_social_share: true
          ---

          Welcome to another edition of [This Week in #dev](https://thoughtbot.com/blog/tags/this-week-in-dev),
          a series of posts where we bring some of the most interesting Slack
          conversations to the public.

          #{highlights_task.wait}

          ## Thanks

          This edition was brought to you by #{authors}. Thanks to all contributors! 🎉
        MARKDOWN
      end
    end

    def title
      "This week in ##{@slack_channel} #{time_period}"
    end

    def tags
      [
        "this-week-in-#{@slack_channel}",
        *topic_tags
      ].join(", ")
    end

    def highlights
      @messages
        .map { |message| Async { highlight_from(message) } }
        .map(&:wait)
        .join("\n")
        .chomp("")
    end

    def highlight_from(message)
      title_task = Async { @writer.give_title_to(message) }
      summary_task = Async { @writer.summarize(message) }

      <<~MARKDOWN
        ## #{title_task.wait}

        #{summary_task.wait}
      MARKDOWN
    end

    def time_period
      start_date = Helpers::Time.pretty_date(Date.parse(@since))

      "(#{start_date})"
    end

    def topic_tags
      topics.map(&:downcase)
    end

    def topics
      @topics ||= @messages
        .map { |message| Async { topics_from(message) } }
        .flat_map(&:wait)
        .uniq
    end

    def topics_from(message)
      @writer.extract_topics_from(message)
    end

    def authors
      @messages
        .map { |message| message[:author] }
        .uniq
        .sort
        .then { |authors| Helpers::Sentence.from(authors) }
    end
  end
end
