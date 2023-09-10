module TestFactories
  extend self

  def create_slack_user(overriden_attributes = {})
    default_attributes = {
      id: "U123",
      name: "John Doe",
      username: "john.doe"
    }
    GoldMiner::Slack::User.new(**default_attributes.merge(overriden_attributes))
  end

  def create_slack_message(overriden_attributes = {})
    default_attributes = {
      id: "msg-id",
      text: "Hello world",
      user: create_slack_user,
      permalink: "https://example.com/slack/messages/123"
    }
    GoldMiner::Slack::Message.new(**default_attributes.merge(overriden_attributes))
  end
end
