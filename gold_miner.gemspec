# frozen_string_literal: true

require_relative "lib/gold_miner/version"

Gem::Specification.new do |spec|
  spec.name = "gold_miner"
  spec.version = GoldMiner::VERSION
  spec.authors = ["Matheus Richard"]
  spec.email = ["matheusrichardt@gmail.com"]

  spec.summary = "Searches for interesting things in a Slack channel."
  spec.description = "This gem searches for TILs and tips in a Slack channel and turns them into a blog post."
  spec.homepage = "https://github.com/thoughtbot/gold_miner"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.2.0"

  # spec.metadata["allowed_push_host"] = "TODO: Set to your gem server 'https://example.com'"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["changelog_uri"] = "#{spec.homepage}/blob/main/CHANGELOG.md"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(__dir__) do
    `git ls-files -z`.split("\x0").reject do |f|
      (f == __FILE__) || f.match(%r{\A(?:(?:bin|test|spec|features)/|\.(?:git|travis|circleci)|appveyor)})
    end
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "async"
  spec.add_dependency "dotenv", "~> 2.8.0"
  spec.add_dependency "dry-monads", ">= 1.3", "< 1.7"
  spec.add_dependency "ruby-openai", "~> 3.0.0"
  spec.add_dependency "slack-ruby-client", "~> 1.1.0"
  spec.add_dependency "zeitwerk", "~> 2.6.6"

  # For more information and examples about making a new gem, check out our
  # guide at: https://bundler.io/guides/creating_gem.html
end
