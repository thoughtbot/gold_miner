# frozen_string_literal: true

module GoldMiner
  class BlogPost
    def initialize(slack_channel:, messages:, since:, writer: SimpleWriter.new)
      @slack_channel = slack_channel
      @messages = messages
      @since = since
      @writer = writer
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

        Welcome to another edition of This Week in #dev, a series of posts where we
        bring some of the most interesting Slack conversations to the public.
        Today we're talking about: #{topics_sentence}.

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
        *topic_tags
      ].join(", ")
    end

    def highlights
      @messages.map { |message| highlight_from(message) }.join("\n").chomp("")
    end

    def highlight_from(message)
      <<~MARKDOWN
        ## #{@writer.give_title_to(message)}

        #{@writer.summarize(message)}
      MARKDOWN
    end

    def time_period
      start_date = Helpers::Time.pretty_date(Date.parse(@since))

      "(#{start_date})"
    end

    def topics_sentence
      Helpers::Sentence.from(topics)
    end

    def topic_tags
      topics.map(&:downcase)
    end

    def topics
      @topics ||= @messages.flat_map { |message| topics_from(message) }.uniq
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
