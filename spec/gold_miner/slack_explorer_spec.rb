# frozen_string_literal: true

require "spec_helper"

RSpec.describe GoldMiner::SlackExplorer do
  describe "#explore" do
    it "returns uniq interesting Slack messages sent on dev channel since last friday" do
      travel_to "2022-10-07" do
        user1 = TestFactories.create_slack_user(id: "user-id-1", name: "User 1", username: "username-1")
        author1 = TestFactories.create_author(name: user1.name, id: user1.username)
        user2 = TestFactories.create_slack_user(id: "user-id-2", name: "User 2", username: "username-2")
        author2 = TestFactories.create_author(name: user2.name, id: user2.username)
        user3 = TestFactories.create_slack_user(id: "user-id-3", name: "User 3", username: "username-3")
        author3 = TestFactories.create_author(name: user3.name, id: user3.username)

        author_config = GoldMiner::AuthorConfig.new({
          user1.username => {"link" => author1.link},
          user2.username => {"link" => author2.link},
          user3.username => {"link" => author3.link}
        })
        slack_client = instance_double(GoldMiner::Slack::Client)
        date = "2022-09-30"
        msg1 = TestFactories.create_slack_message(
          "text" => "TIL",
          "user" => user1,
          "permalink" => "https:///message-1-permalink.com"
        )
        msg2 = TestFactories.create_slack_message(
          "text" => "Ruby tip/TIL: Array#sample...",
          "user" => user2,
          "permalink" => "https:///message-2-permalink.com"
        )
        msg3 = TestFactories.create_slack_message(
          "text" => "Ruby tip: have fun!",
          "user" => user2,
          "permalink" => "https:///message-3-permalink.com"
        )
        msg4 = TestFactories.create_slack_message(
          "text" => "CSS clamp() is so cool!",
          "user" => user3,
          "permalink" => "https:///message-4-permalink.com"
        )
        stub_slack_message_search_requests(slack_client, {
          "TIL in:dev after:#{date}" => [msg1, msg2],
          "tip in:dev after:#{date}" => [msg2, msg3],
          "in:dev after:#{date} has::rupee-gold:" => [msg2, msg4]
        })

        explorer = described_class.new(slack_client, author_config)
        messages = explorer.explore("dev", start_on: date)

        expect(messages).to match_array [
          TestFactories.create_gold_nugget(content: msg1.text, author: author1, source: msg1.permalink),
          TestFactories.create_gold_nugget(content: msg2.text, author: author2, source: msg2.permalink),
          TestFactories.create_gold_nugget(content: msg3.text, author: author2, source: msg3.permalink),
          TestFactories.create_gold_nugget(content: msg4.text, author: author3, source: msg4.permalink)
        ]
      end
    end

    it "searches Slack messages asynchronously" do
      seconds_of_sleep = 0.5
      mock_client = double("Sleepy Slack Client")
      allow(mock_client).to receive(:auth_test).and_return(status: 200)
      allow(mock_client).to receive(:search_messages) {
        sleep seconds_of_sleep

        []
      }
      slack_explorer = described_class.new(mock_client, GoldMiner::AuthorConfig.new({}))

      t0 = Process.clock_gettime(Process::CLOCK_MONOTONIC)
      slack_explorer.explore("dev", start_on: Date.parse("2022-09-30"))
      elapsed_time = Process.clock_gettime(Process::CLOCK_MONOTONIC) - t0

      overhead = 0.1
      expect(elapsed_time).to be_within(overhead).of(seconds_of_sleep)
      expect(mock_client).to have_received(:search_messages).thrice
    end

    private

    def stub_slack_message_search_requests(client, requests)
      requests.map do |query, response|
        allow(client).to receive(:search_messages).with(query).and_return(response)
      end
    end
  end
end
