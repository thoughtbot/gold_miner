# frozen_string_literal: true

RSpec.describe GoldMiner::SlackClient do
  describe ".build" do
    it "returns a success monad if api_token is valid" do
      token = "valid-token"
      stub_slack_auth_test_request(status: 200, token: token)

      result = GoldMiner::SlackClient.build(api_token: token)

      expect(result).to be_success
      expect(result.value!).to be_a GoldMiner::SlackClient
    end

    it "returns a failure monad if api_token is invalid" do
      token = "invalid-token"
      stub_slack_auth_test_request(token: token, body: {"ok" => false, "error" => "invalid_auth"})

      result = GoldMiner::SlackClient.build(api_token: token)
      error_message = result.failure.message

      expect(error_message).to eq "invalid_auth"
    end
  end

  describe "#search_interesting_messages_in" do
    it "returns uniq til and tip messages sent on dev channel since last friday" do
      travel_to "2022-10-07" do
        token = "valid-token"
        stub_slack_auth_test_request(status: 200, token: token)
        stub_slack_message_search_request(
          query: "TIL in:dev after:2022-09-30",
          body: {
            "ok" => true,
            "messages" => {
              "matches" => [
                {"iid" => "1", "text" => "TIL", "username" => "user", "permalink" => "https:///message-1-permalink.com"},
                {"iid" => "2", "text" => "Ruby tip/TIL: Array#sample...", "username" => "user2", "permalink" => "https:///message-2-permalink.com"},
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
                {"iid" => "2", "text" => "Ruby tip/TIL: Array#sample...", "username" => "user2", "permalink" => "https:///message-2-permalink.com"},
                {"iid" => "3", "text" => "Ruby tip: have fun!", "username" => "user2", "permalink" => "https:///message-3-permalink.com"},
              ],
              "paging" => {"pages" => 1}
            }
          }
        )
        slack = GoldMiner::SlackClient.build(api_token: token).value!

        messages = slack.search_interesting_messages_in("dev")

        expect(messages).to match_array [
          {text: "TIL", author_username: "user", permalink: "https:///message-1-permalink.com"},
          {text: "Ruby tip/TIL: Array#sample...", author_username: "user2", permalink: "https:///message-2-permalink.com"},
          {text: "Ruby tip: have fun!", author_username: "user2", permalink: "https:///message-3-permalink.com"},
        ]
      end
    end

    it "warns when results have multiple pages" do
      travel_to "2022-10-07" do
        token = "valid-token"
        stub_slack_auth_test_request(status: 200, token: token)
        stub_slack_message_search_request(
          query: "TIL in:dev after:2022-09-30",
          body: {
            "ok" => true,
            "messages" => {
              "matches" => [
                {"iid" => "1", "text" => "TIL", "username" => "user", "permalink" => "https:///message-1-permalink.com"},
                {"iid" => "2", "text" => "Ruby tip/TIL: Array#sample...", "username" => "user2", "permalink" => "https:///message-2-permalink.com"}
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
        slack = GoldMiner::SlackClient.build(api_token: token).value!

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
      "Authorization" => "Bearer #{token}",
      "Content-Length" => "0",
      "User-Agent" => "Slack Ruby Client/1.1.0"
    }

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
          "Content-Type" => "application/x-www-form-urlencoded",
          "User-Agent" => "Slack Ruby Client/1.1.0"
        }
      )
      .to_return(status: 200, body: body.to_json, headers: {})
  end
end
