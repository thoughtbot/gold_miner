# frozen_string_literal: true

module GoldMiner
  module Slack
    User = Data.define(:id, :name, :username) do
      alias_method :to_s, :name
    end
  end
end
