# frozen_string_literal: true

require "spec_helper"

RSpec.describe GoldMiner::TerminalDistributor do
  it_behaves_like "distributor"

  describe "#distribute" do
    it "prints the blog post to STDOUT" do
      blog_post = double("blog_post", to_s: "A blog post")

      expect { subject.distribute(blog_post) }.to output("A blog post\n").to_stdout
    end
  end
end
