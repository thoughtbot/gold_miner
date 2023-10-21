# frozen_string_literal: true

class GoldMiner
  module Slack
    Message = Data.define(:id, :text, :user, :permalink) do
      alias_method :[], :public_send
    end
  end
end
