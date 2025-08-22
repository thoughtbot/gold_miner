# frozen_string_literal: true

class GoldMiner
  GoldNugget = Data.define(:content, :author, :source) do
    def as_conversation = "#{author.name} says: #{content}"
  end
end
