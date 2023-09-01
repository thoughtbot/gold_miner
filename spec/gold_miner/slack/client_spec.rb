# frozen_string_literal: true

RSpec.describe GoldMiner::Slack::Client do
  describe ".build" do
    it "returns a success monad if api_token is valid" do
      token = "valid-token"
      stub_slack_auth_test_request(status: 200, token: token)

      result = GoldMiner::Slack::Client.build(api_token: token)

      expect(result).to be_success
      expect(result.value!).to be_a GoldMiner::Slack::Client
    end

    it "returns a failure monad if api_token is nil" do
      token = nil
      stub_slack_auth_test_request(token: token, body: {"ok" => false, "error" => "not_authed"})

      result = GoldMiner::Slack::Client.build(api_token: token)
      error_message = result.failure

      expect(error_message).to eq "Slack authentication failed. Please check your API token."
    end

    it "returns a failure monad if api_token is invalid" do
      token = "invalid-token"
      stub_slack_auth_test_request(token: token, body: {"ok" => false, "error" => "invalid_auth"})

      result = GoldMiner::Slack::Client.build(api_token: token)
      error_message = result.failure

      expect(error_message).to eq "Slack authentication failed. Please check your API token."
    end

    it "returns a failure monad if a http request fails" do
      mock_client_instance = instance_double(Slack::Web::Client)
      allow(mock_client_instance).to receive(:auth_test).and_raise(Slack::Web::Api::Errors::TimeoutError, "timeout_error")
      mock_client_class = class_double(Slack::Web::Client, new: mock_client_instance)
      token = "valid-token"

      result = GoldMiner::Slack::Client.build(api_token: token, slack_client: mock_client_class)
      error_message = result.failure

      expect(error_message).to eq "Slack authentication failed. An HTTP error occurred: timeout_error."
    end
  end

  describe "#search_interesting_messages_in" do
    it "returns uniq interesting messages sent on dev channel since last friday" do
      travel_to "2022-10-07" do
        token = "valid-token"
        user1 = TestFactories.create_slack_user(id: "user-id-1", name: "User 1", username: "username-1")
        user2 = TestFactories.create_slack_user(id: "user-id-2", name: "User 2", username: "username-2")
        user3 = TestFactories.create_slack_user(id: "user-id-3", name: "User 3", username: "username-3")

        stub_slack_auth_test_request(status: 200, token: token)
        stub_slack_message_search_request(
          query: "TIL in:dev after:2022-09-30",
          body: {
            "ok" => true,
            "messages" => {
              "matches" => [
                {"text" => "TIL", "user" => user1.id, "username" => user1.username, "permalink" => "https:///message-1-permalink.com"},
                {"text" => "Ruby tip/TIL: Array#sample...", "user" => user2.id, "username" => user2.username, "permalink" => "https:///message-2-permalink.com"}
              ],
              "paging" => {"pages" => 1}
            }
          }
        )
        stub_slack_message_search_request(
          query: "tip in:dev after:2022-09-30",
          body: {
            "ok" => true,
            "messages" => {
              "matches" => [
                {"text" => "Ruby tip/TIL: Array#sample...", "user" => user2.id, "username" => user2.username, "permalink" => "https:///message-2-permalink.com"},
                {"text" => "Ruby tip: have fun!", "user" => user2.id, "username" => user2.username, "permalink" => "https:///message-3-permalink.com"}
              ],
              "paging" => {"pages" => 1}
            }
          }
        )
        stub_slack_message_search_request(
          query: "in:dev after:2022-09-30 has::rupee-gold:",
          body: {
            "ok" => true,
            "messages" => {
              "matches" => [
                {"text" => "Ruby tip/TIL: Array#sample...", "user" => user2.id, "username" => user2.username, "permalink" => "https:///message-2-permalink.com"},
                {"text" => "CSS clamp() is so cool!", "user" => user3.id, "username" => user3.username, "permalink" => "https:///message-4-permalink.com"}
              ],
              "paging" => {"pages" => 1}
            }
          }
        )
        stub_slack_users_info_request(
          token: token,
          user_id: user1.id,
          body: {"ok" => true, "user" => {"profile" => {"real_name" => user1.name}}}
        )
        stub_slack_users_info_request(
          token: token,
          user_id: user2.id,
          body: {"ok" => true, "user" => {"profile" => {"real_name" => user2.name}}}
        )
        stub_slack_users_info_request(
          token: token,
          user_id: user3.id,
          body: {"ok" => true, "user" => {"profile" => {"real_name" => user3.name}}}
        )
        stub_slack_users_info_request(
          token: token,
          user_id: "user4-id",
          body: {"ok" => true, "user" => {"profile" => {"real_name" => "User 4"}}}
        )
        author_config = GoldMiner::AuthorConfig.new({
          user1.username => {"link" => user1.link},
          user2.username => {"link" => user2.link},
          user3.username => {"link" => user3.link}
        })
        slack = GoldMiner::Slack::Client.build(api_token: token, author_config:).value!

        messages = slack.search_interesting_messages_in("dev")

        expect(messages).to match_array [
          GoldMiner::Slack::Message.new(text: "TIL", author: user1, permalink: "https:///message-1-permalink.com"),
          GoldMiner::Slack::Message.new(text: "Ruby tip/TIL: Array#sample...", author: user2, permalink: "https:///message-2-permalink.com"),
          GoldMiner::Slack::Message.new(text: "Ruby tip: have fun!", author: user2, permalink: "https:///message-3-permalink.com"),
          GoldMiner::Slack::Message.new(text: "CSS clamp() is so cool!", author: user3, permalink: "https:///message-4-permalink.com")
        ]
      end
    end

    it "warns when results have multiple pages" do
      travel_to "2022-10-07" do
        token = "valid-token"
        user1 = TestFactories.create_slack_user(id: "user-id-1", name: "User 1", username: "username-1")
        user2 = TestFactories.create_slack_user(id: "user-id-2", name: "User 2", username: "username-2")
        stub_slack_auth_test_request(status: 200, token: token)
        stub_slack_message_search_request(
          query: "TIL in:dev after:2022-09-30",
          body: {
            "ok" => true,
            "messages" => {
              "matches" => [
                {"text" => "TIL", "user" => user1.id, "username" => user1.username, "permalink" => "https:///message-1-permalink.com"},
                {"text" => "Ruby tip/TIL: Array#sample...", "user" => user2.id, "username" => user2.username, "permalink" => "https:///message-2-permalink.com"}
              ],
              "paging" => {"pages" => 2}
            }
          }
        )
        stub_slack_message_search_request(
          query: "tip in:dev after:2022-09-30",
          body: {
            "ok" => true,
            "messages" => {
              "matches" => [],
              "paging" => {"pages" => 1}
            }
          }
        )
        stub_slack_message_search_request(
          query: "in:dev after:2022-09-30 has::rupee-gold:",
          body: {
            "ok" => true,
            "messages" => {
              "matches" => [],
              "paging" => {"pages" => 1}
            }
          }
        )
        stub_slack_users_info_request(
          token: token,
          user_id: user1.id,
          body: {"ok" => true, "user" => {"profile" => {"real_name" => user1.name}}}
        )
        stub_slack_users_info_request(
          token: token,
          user_id: user2.id,
          body: {"ok" => true, "user" => {"profile" => {"real_name" => user2.name}}}
        )
        author_config = GoldMiner::AuthorConfig.new({
          user1.username => {"link" => user1.link}
        })
        slack = GoldMiner::Slack::Client.build(api_token: token, author_config: author_config).value!

        expect {
          slack.search_interesting_messages_in("dev")
        }.to output("[WARNING] Found more than one page of results, only the first page will be processed\n").to_stderr
      end
    end
  end

  private

  def stub_slack_auth_test_request(token:, status: 200, body: {"ok" => true})
    headers = {
      "Accept" => "application/json; charset=utf-8",
      "Accept-Encoding" => "gzip;q=1.0,deflate;q=0.6,identity;q=0.3",
      "Content-Length" => "0"
    }
    headers["Authorization"] = "Bearer #{token}" if token

    stub_request(:post, "https://slack.com/api/auth.test")
      .with(headers: headers)
      .to_return(status: status, body: body.to_json, headers: {})
  end

  def stub_slack_message_search_request(query:, body:)
    stub_request(:post, "https://slack.com/api/search.messages")
      .with(
        body: {"query" => query},
        headers: {
          "Accept" => "application/json; charset=utf-8",
          "Accept-Encoding" => "gzip;q=1.0,deflate;q=0.6,identity;q=0.3",
          "Content-Type" => "application/x-www-form-urlencoded"
        }
      )
      .to_return(status: 200, body: body.to_json, headers: {})
  end

  def stub_slack_users_info_request(token:, user_id:, body:)
    stub_request(:post, "https://slack.com/api/users.info")
      .with(
        body: {"user" => user_id},
        headers: {
          "Accept" => "application/json; charset=utf-8",
          "Accept-Encoding" => "gzip;q=1.0,deflate;q=0.6,identity;q=0.3",
          "Authorization" => "Bearer #{token}",
          "Content-Type" => "application/x-www-form-urlencoded"
        }
      )
      .to_return(status: 200, body: body.to_json, headers: {})
  end
end
