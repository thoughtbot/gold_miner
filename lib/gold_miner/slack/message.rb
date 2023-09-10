# frozen_string_literal: true

module GoldMiner
  module Slack
    Message = Data.define(:id, :text, :user, :permalink) do
      alias_method :[], :public_send
    end
  end
end
