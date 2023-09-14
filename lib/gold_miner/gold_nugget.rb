# frozen_string_literal: true

module GoldMiner
  GoldNugget = Data.define(:content, :author, :source) do
    def as_conversation
      <<~MARKDOWN
        #{author.name_with_link_reference} says: #{content}

        #{author.reference_link}
      MARKDOWN
    end
  end
end
