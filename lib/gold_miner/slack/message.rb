# frozen_string_literal: true

module GoldMiner
  class Slack::Message
    def initialize(text:, author:, permalink:)
      @text = text
      @author = author
      @permalink = permalink
    end

    def [](attribute)
      instance_variable_get("@#{attribute}")
    end

    def ==(other)
      self[:text] == other[:text] &&
        self[:author] == other[:author] &&
        self[:permalink] == other[:permalink]
    end
  end
end
