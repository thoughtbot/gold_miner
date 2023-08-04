# frozen_string_literal: true

module GoldMiner
  module Slack
    Message = Data.define(:text, :author, :permalink) do
      alias_method :[], :public_send

      def as_conversation
        "#{author} says: #{text}"
      end
    end
  end
end
