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

  describe "#search_messages" do
    it "returns a list of messages matching the query, including their respective author names" do
      token = "valid-token"
      stub_slack_auth_test_request(status: 200, token: token)
      search_query = "tip in:dev"
      user1 = TestFactories.create_slack_user(id: "user-id-1", name: "User 1", username: "username-1")
      user2 = TestFactories.create_slack_user(id: "user-id-2", name: "User 2", username: "username-2")
      msg1 = {"id" => "msg1", "text" => "TIL", "user" => user1.id, "username" => user1.username, "permalink" => "https:///message-1-permalink.com"}
      msg2 = {"id" => "msg2", "text" => "Ruby tip/TIL: Array#sample...", "user" => user2.id, "username" => user2.username, "permalink" => "https:///message-2-permalink.com"}
      stub_slack_message_search_request(
        query: search_query,
        body: {
          "ok" => true,
          "messages" => {
            "matches" => [msg1, msg2],
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
      slack = described_class.build(api_token: token).value!

      messages = slack.search_messages(search_query).messages.matches

      expect(messages).to match_array [
        msg1.merge("author_real_name" => user1.name),
        msg2.merge("author_real_name" => user2.name)
      ]
    end

    it "searches author names only once per user" do
      token = "valid-token"
      stub_slack_auth_test_request(status: 200, token: token)
      search_query = "tip in:dev"
      user1 = TestFactories.create_slack_user(id: "user-id-1", name: "User 1", username: "username-1")
      msg1 = {"id" => "msg1", "text" => "TIL", "user" => user1.id, "username" => user1.username, "permalink" => "https:///message-1-permalink.com"}
      msg2 = {"id" => "msg2", "text" => "Ruby tip/TIL: Array#sample...", "user" => user1.id, "username" => user1.username, "permalink" => "https:///message-2-permalink.com"}
      stub_slack_message_search_request(
        query: search_query,
        body: {
          "ok" => true,
          "messages" => {
            "matches" => [msg1, msg2],
            "paging" => {"pages" => 1}
          }
        }
      )
      stub_slack_users_info_request(
        token: token,
        user_id: user1.id,
        body: {"ok" => true, "user" => {"profile" => {"real_name" => user1.name}}}
      )
      slack = described_class.build(api_token: token).value!

      slack.search_messages(search_query).messages.matches

      expect(WebMock).to have_requested(:post, "https://slack.com/api/users.info").once
    end

    it "searches author names asynchronously" do
      search_query_time = 0.5
      sleepy_slack_client = instance_double(Slack::Web::Client, auth_test: true)
      sleepy_slack_class = class_double(Slack::Web::Client, new: sleepy_slack_client)

      search_query = "tip in:dev"
      user1 = TestFactories.create_slack_user(id: "user-id-1", name: "User 1", username: "username-1")
      user2 = TestFactories.create_slack_user(id: "user-id-2", name: "User 2", username: "username-2")
      msg1 = {"id" => "msg1", "text" => "TIL", "user" => user1.id, "username" => user1.username, "permalink" => "https:///message-1-permalink.com"}
      msg2 = {"id" => "msg2", "text" => "Ruby tip/TIL: Array#sample...", "user" => user2.id, "username" => user2.username, "permalink" => "https:///message-2-permalink.com"}
      allow(sleepy_slack_client).to receive(:search_messages).with({query: search_query}) {
        sleep(search_query_time)

        deep_open_struct(
          {"ok" => true,
           "messages" => {
             "matches" => [msg1, msg2],
             "paging" => {"pages" => 1}
           }}
        )
      }

      user_info_query_time = 1
      allow(sleepy_slack_client).to receive(:users_info).with({user: user1.id}) {
        sleep(user_info_query_time)
        deep_open_struct({"ok" => true, "user" => {"profile" => {"real_name" => user1.name}}})
      }
      allow(sleepy_slack_client).to receive(:users_info).with({user: user2.id}) {
        sleep(user_info_query_time)
        deep_open_struct({"ok" => true, "user" => {"profile" => {"real_name" => user2.name}}})
      }

      slack = described_class.build(api_token: "valid-token", slack_client: sleepy_slack_class).value!

      t0 = Process.clock_gettime(Process::CLOCK_MONOTONIC)
      slack.search_messages(search_query)
      total_elapsed_time = Process.clock_gettime(Process::CLOCK_MONOTONIC) - t0

      # We have to sum the search and user info query times because they run
      # sequentially. Both user info queries run in parallel, so we don't have
      # to sum them twice.
      overhead = 0.1
      expect(total_elapsed_time).to be_within(overhead).of(search_query_time + user_info_query_time)
      expect(sleepy_slack_client).to have_received(:search_messages).with({query: search_query}).once
      expect(sleepy_slack_client).to have_received(:users_info).with({user: user1.id}).once
      expect(sleepy_slack_client).to have_received(:users_info).with({user: user2.id}).once
    end

    it "warns when results have multiple pages" do
      travel_to "2022-10-07" do
        token = "valid-token"
        stub_slack_auth_test_request(status: 200, token: token)
        search_query = "tip in:dev"
        user1 = TestFactories.create_slack_user(id: "user-id-1", name: "User 1", username: "username-1")
        user2 = TestFactories.create_slack_user(id: "user-id-2", name: "User 2", username: "username-2")
        msg1 = {"id" => "msg1", "text" => "TIL", "user" => user1.id, "username" => user1.username, "permalink" => "https:///message-1-permalink.com"}
        msg2 = {"id" => "msg2", "text" => "Ruby tip/TIL: Array#sample...", "user" => user2.id, "username" => user2.username, "permalink" => "https:///message-2-permalink.com"}
        stub_slack_message_search_request(
          query: search_query,
          body: {
            "ok" => true,
            "messages" => {
              "matches" => [msg1, msg2],
              "paging" => {"pages" => 2}
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
        slack = described_class.build(api_token: token).value!

        expect {
          slack.search_messages(search_query)
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
