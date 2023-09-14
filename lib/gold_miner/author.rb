# frozen_string_literal: true

module GoldMiner
  Author = Data.define(:id, :name, :link) do
    alias_method :to_s, :name

    def name_with_link_reference
      "[#{name}][#{id}]"
    end

    def reference_link
      "[#{id}]: #{link}"
    end
  end
end
