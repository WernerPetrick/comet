require_relative "../lib/comet"

RSpec.describe Comet do
  it "has a version number" do
    expect(Comet::VERSION).not_to be nil
  end
end
