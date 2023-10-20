RSpec.shared_examples "distributor" do
  it { is_expected.to respond_to(:distribute) }
end
