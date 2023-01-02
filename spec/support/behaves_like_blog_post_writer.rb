RSpec.shared_examples "a blog post writer" do
  it { expect(writer_instance).to respond_to(:extract_topics_from).with(1).argument }
  it { expect(writer_instance).to respond_to(:give_title_to).with(1).argument }
  it { expect(writer_instance).to respond_to(:summarize).with(1).argument }
end
