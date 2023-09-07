# frozen_string_literal: true

require "spec_helper"

RSpec.describe GoldMiner::SlackExplorer do
  describe "#explore" do
    it "returns uniq interesting Slack messages sent on dev channel since last friday" do
      travel_to "2022-10-07" do
        user1 = TestFactories.create_slack_user(id: "user-id-1", name: "User 1", username: "username-1")
        user2 = TestFactories.create_slack_user(id: "user-id-2", name: "User 2", username: "username-2")
        user3 = TestFactories.create_slack_user(id: "user-id-3", name: "User 3", username: "username-3")

        author_config = GoldMiner::AuthorConfig.new({
          user1.username => {"link" => user1.link},
          user2.username => {"link" => user2.link},
          user3.username => {"link" => user3.link}
        })
        slack_client = instance_double(GoldMiner::Slack::Client)
        date = "2022-09-30"
        stub_slack_message_search_requests(slack_client, {
          "TIL in:dev after:#{date}" => {
            "ok" => true,
            "messages" => {
              "matches" => [
                {"text" => "TIL",
                 "user" => user1.id,
                 "username" => user1.username,
                 "author_real_name" => user1.name,
                 "permalink" => "https:///message-1-permalink.com"},
                {"text" => "Ruby tip/TIL: Array#sample...",
                 "user" => user2.id,
                 "username" => user2.username,
                 "author_real_name" => user2.name,
                 "permalink" => "https:///message-2-permalink.com"}
              ],
              "paging" => {"pages" => 1}
            }
          },
          "tip in:dev after:#{date}" => {
            "ok" => true,
            "messages" => {
              "matches" => [
                {"text" => "Ruby tip/TIL: Array#sample...",
                 "user" => user2.id,
                 "username" => user2.username,
                 "author_real_name" => user2.name,
                 "permalink" => "https:///message-2-permalink.com"},
                {"text" => "Ruby tip: have fun!",
                 "user" => user2.id,
                 "username" => user2.username,
                 "author_real_name" => user2.name,
                 "permalink" => "https:///message-3-permalink.com"}
              ],
              "paging" => {"pages" => 1}
            }
          },
          "in:dev after:#{date} has::rupee-gold:" => {
            "messages" => {
              "matches" => [
                {"text" => "Ruby tip/TIL: Array#sample...",
                 "user" => user2.id,
                 "username" => user2.username,
                 "author_real_name" => user2.name,
                 "permalink" => "https:///message-2-permalink.com"},
                {"text" => "CSS clamp() is so cool!",
                 "user" => user3.id,
                 "username" => user3.username,
                 "author_real_name" => user3.name,
                 "permalink" => "https:///message-4-permalink.com"}
              ],
              "paging" => {"pages" => 1}
            }
          }
        })

        explorer = described_class.new(slack_client, author_config)
        messages = explorer.explore("dev", start_on: date)

        expect(messages).to match_array [
          GoldMiner::Slack::Message.new(text: "TIL", author: user1, permalink: "https:///message-1-permalink.com"),
          GoldMiner::Slack::Message.new(text: "Ruby tip/TIL: Array#sample...", author: user2, permalink: "https:///message-2-permalink.com"),
          GoldMiner::Slack::Message.new(text: "Ruby tip: have fun!", author: user2, permalink: "https:///message-3-permalink.com"),
          GoldMiner::Slack::Message.new(text: "CSS clamp() is so cool!", author: user3, permalink: "https:///message-4-permalink.com")
        ]
      end
    end

    it "searches Slack messages asynchronously" do
      seconds_of_sleep = 0.5
      mock_client = double("Sleepy Slack Client")
      allow(mock_client).to receive(:auth_test).and_return(status: 200)
      allow(mock_client).to receive(:search_messages) {
        sleep seconds_of_sleep

        double("Search result", messages: double("Slack messages", matches: [], paging: double("Slack paging", pages: 1)))
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
        allow(client).to receive(:search_messages).with(query).and_return(deep_open_struct(response))
      end
    end
  end
end
