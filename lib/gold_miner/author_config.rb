# frozen_string_literal: true

module GoldMiner
  class AuthorConfig
    DEFAULT_AUTHOR_LINK = "#to-do"
    DEFAULT_CONFIG_PATH = "lib/config/author_config.yml"

    def self.default
      YAML
        .load_file(DEFAULT_CONFIG_PATH)
        .transform_values { |author| author["link"] }
        .then { |links| new(links) }
    end

    def initialize(author_config = {})
      @author_config = author_config
    end

    def link_for(slack_username)
      @author_config.fetch(slack_username, DEFAULT_AUTHOR_LINK)
    end
  end
end
