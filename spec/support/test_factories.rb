module TestFactories
  extend self

  def create_author(overriden_attributes = {})
    default_attributes = {
      id: "author-id",
      name: "John Doe",
      link: "https://example.com/users/john.doe"
    }
    GoldMiner::Author.new(**default_attributes.merge(overriden_attributes))
  end

  def create_gold_container(overriden_attributes = {})
    default_attributes = {
      gold_nuggets: [],
      origin: "some-channel",
      packing_date: Date.today
    }
    GoldMiner::GoldContainer.new(**default_attributes.merge(overriden_attributes))
  end

  def create_gold_nugget(overriden_attributes = {})
    default_attributes = {
      content: "TIL about the difference betweeen .size and .count in Rails",
      source: "https://example.com/messages/1",
      author: create_author
    }
    GoldMiner::GoldNugget.new(**default_attributes.merge(overriden_attributes))
  end

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
