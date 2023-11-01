# frozen_string_literal: true

require "yaml"

class GoldMiner
  class AuthorConfig
    DEFAULT_AUTHOR_LINK = "#to-do"
    DEFAULT_CONFIG_PATH = "lib/config/author_config.yml"

    def self.default
      YAML
        .load_file(DEFAULT_CONFIG_PATH)
        .then { |links| new(links) }
    end

    def initialize(author_config = {})
      @author_config = author_config
    end

    def link_for(slack_username)
      @author_config.dig(slack_username, "link") || DEFAULT_AUTHOR_LINK
    end
  end
end
