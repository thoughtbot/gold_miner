# frozen_string_literal: true

module GoldMiner
  module Slack
    User = Data.define(:id, :name, :username, :link) do
      alias_method :to_s, :name

      def name_with_link_reference
        "[#{name}][#{username}]"
      end

      def reference_link
        "[#{username}]: #{link}"
      end
    end
  end
end
