# frozen_string_literal: true

require "async"

class GoldMiner
  class BlogPost
    def initialize(slack_channel:, gold_nuggets:, since:, writer: SimpleWriter.new)
      @slack_channel = slack_channel
      @gold_nuggets = gold_nuggets
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
          author: thoughtbot
          editor_name: Your Name Here
          auto_social_share: true
          ---

          Welcome to another edition of [This Week in #dev](https://thoughtbot.com/blog/tags/this-week-in-dev),
          a series of posts where we bring some of our most interesting Slack
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
        "this week in #{@slack_channel}",
        *topic_tags
      ].join(", ")
    end

    def highlights
      @gold_nuggets
        .map { |gold_nugget| Async { highlight_from(gold_nugget) } }
        .map(&:wait)
        .join("\n")
        .chomp("")
    end

    def highlight_from(gold_nugget)
      title_task = Async { @writer.give_title_to(gold_nugget) }
      summary_task = Async { @writer.summarize(gold_nugget) }

      <<~MARKDOWN
        ## #{title_task.wait}

        #{summary_task.wait}
      MARKDOWN
    end

    def time_period
      start_date = Helpers::Time.pretty_date(Date.parse(@since.to_s))

      "(#{start_date})"
    end

    def topic_tags
      topics.map(&:downcase)
    end

    def topics
      @topics ||= @gold_nuggets
        .map { |gold_nugget| Async { topics_from(gold_nugget) } }
        .flat_map(&:wait)
        .uniq
    end

    def topics_from(gold_nugget)
      @writer.extract_topics_from(gold_nugget)
    end

    def authors
      @gold_nuggets
        .map { |gold_nugget| gold_nugget.author.name_with_link_reference }
        .uniq
        .sort
        .then { |authors| Helpers::Sentence.from(authors) }
    end
  end
end
