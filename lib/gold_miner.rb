# frozen_string_literal: true

require "dry/monads"
require "zeitwerk"

Zeitwerk::Loader.for_gem.setup

class GoldMiner
  include Dry::Monads[:result]

  def initialize(explorer:, smith:, distributor:, env_file: ".env")
    @explorer = explorer
    @smith = smith
    @distributor = distributor
    @env_file = env_file
  end

  def mine(location, start_on:)
    explore(location, start_on:)
      .bind { |gold_container| smith(gold_container) }
      .bind { |blog_post| distribute(blog_post) }
  end

  private

  def explore(location, start_on:)
    Success(@explorer.explore(location, start_on:))
  end

  def smith(gold_container)
    Success(@smith.smith(gold_container))
  end

  def distribute(blog_post)
    Success(@distributor.distribute(blog_post))
  end
end
