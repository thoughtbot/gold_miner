# frozen_string_literal: true

require "spec_helper"

RSpec.describe GoldMiner::BlogPost do
  describe "#to_s" do
    it "creates a blogpost from a list of messages" do
      travel_to "2022-10-07" do
        author1 = TestFactories.create_slack_user(id: "U123", name: "John Doe", username: "john.doe", link: "https://example.com/john.doe")
        author2 = TestFactories.create_slack_user(id: "U456", name: "Jane Smith", username: "jane.smith", link: "https://example.com/jane.smith")
        messages = [
          GoldMiner::Slack::Message.new(text: "TIL 1", author: author1, permalink: "http://permalink-1.com"),
          GoldMiner::Slack::Message.new(text: "TIL 2", author: author2, permalink: "http://permalink-2.com"),
          GoldMiner::Slack::Message.new(text: "Tip 1", author: author1, permalink: "http://permalink-3.com")
        ]
        blogpost = GoldMiner::BlogPost.new(slack_channel: "design", messages: messages, since: "2022-09-30")

        result = blogpost.to_s

        expect(result).to eq <<~MARKDOWN
          ---
          title: "This week in #design (Sep 30, 2022)"
          tags: this-week-in-design, til, tip
          teaser: >
            Highlights of what happened in our #design channel on Slack this week.
          author: Matheus Richard
          auto_social_share: true
          ---

          Welcome to another edition of [This Week in #dev](https://thoughtbot.com/blog/tags/this-week-in-dev),
          a series of posts where we bring some of our most interesting Slack
          conversations to the public.

          ## http://permalink-1.com

          TIL 1

          ## http://permalink-2.com

          TIL 2

          ## http://permalink-3.com

          Tip 1

          ## Thanks

          This edition was brought to you by [Jane Smith][jane.smith] and [John Doe][john.doe]. Thanks to all contributors! 🎉
        MARKDOWN
      end
    end

    it "creates a blog post asynchronously" do
      sleep_writer = Class.new do
        def initialize(seconds_of_sleep:)
          @seconds_of_sleep = seconds_of_sleep
        end

        def extract_topics_from(message)
          sleep @seconds_of_sleep

          ["test", "test2"]
        end

        def give_title_to(message)
          sleep @seconds_of_sleep

          "test"
        end

        def summarize(message)
          sleep @seconds_of_sleep

          "test"
        end
      end
      author1 = TestFactories.create_slack_user(id: "U123", name: "John Doe", username: "john.doe", link: "https://example.com/john.doe")
      author2 = TestFactories.create_slack_user(id: "U456", name: "Jane Smith", username: "jane.smith", link: "https://example.com/jane.smith")
      messages = [
        GoldMiner::Slack::Message.new(text: "TIL 1", author: author1, permalink: "http://permalink-1.com"),
        GoldMiner::Slack::Message.new(text: "TIL 2", author: author2, permalink: "http://permalink-2.com")
      ]
      seconds_of_sleep = 0.5
      blogpost = GoldMiner::BlogPost.new(
        slack_channel: "design",
        messages: messages,
        since: "2022-09-30",
        writer: sleep_writer.new(seconds_of_sleep: seconds_of_sleep)
      )

      t0 = Process.clock_gettime(Process::CLOCK_MONOTONIC)
      result = blogpost.to_s
      elapsed_time = Process.clock_gettime(Process::CLOCK_MONOTONIC) - t0

      overhead = 0.1
      expect(elapsed_time).to be_between(seconds_of_sleep, seconds_of_sleep + overhead)
      expect(result).to eq <<~MARKDOWN
        ---
        title: "This week in #design (Sep 30, 2022)"
        tags: this-week-in-design, test, test2
        teaser: >
          Highlights of what happened in our #design channel on Slack this week.
        author: Matheus Richard
        auto_social_share: true
        ---

        Welcome to another edition of [This Week in #dev](https://thoughtbot.com/blog/tags/this-week-in-dev),
        a series of posts where we bring some of our most interesting Slack
        conversations to the public.

        ## test

        test

        ## test

        test

        ## Thanks

        This edition was brought to you by [Jane Smith][jane.smith] and [John Doe][john.doe]. Thanks to all contributors! 🎉
      MARKDOWN
    end
  end
end
