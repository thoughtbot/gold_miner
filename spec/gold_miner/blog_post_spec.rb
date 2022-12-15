# frozen_string_literal: true

require "spec_helper"

RSpec.describe GoldMiner::BlogPost do
  describe "#to_s" do
    it "creates a blogpost from a list of messages" do
      travel_to "2022-10-07" do
        messages = [
          {text: "TIL 1", author_username: "user2", permalink: "http://permalink-1.com", topic: :til},
          {text: "TIL 2", author_username: "user1", permalink: "http://permalink-2.com", topic: :til},
          {text: "Tip 1", author_username: "user2", permalink: "http://permalink-3.com", topic: :tip}
        ]
        blogpost = GoldMiner::BlogPost.new(slack_channel: "design", messages: messages, since: "2022-09-30")

        result = blogpost.to_s

        expect(result).to eq <<~MARKDOWN
          ---
          title: "This week in #design (2022-09-30 - 2022-10-07)"
          tags: this-week-in-design, til, tip
          teaser: >
            Highlights of what happened in our #design channel on Slack this week.
          author: Matheus Richard
          ---

          ## http://permalink-1.com

          TIL 1

          ## http://permalink-2.com

          TIL 2

          ## http://permalink-3.com

          Tip 1

          ## Thanks

          This edition was brought to you by: @user1 and @user2. Thanks to all contributors! 🎉
        MARKDOWN
      end
    end
  end
end
