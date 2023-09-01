# frozen_string_literal: true

module GoldMiner
  module Slack
    Message = Data.define(:text, :author, :permalink) do
      alias_method :[], :public_send

      def as_conversation
        <<~MARKDOWN
          #{author.name_with_link_reference} says: #{text}

          #{author.reference_link}
        MARKDOWN
      end
    end
  end
end
