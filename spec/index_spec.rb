require 'spec_helper'

describe RspecApiDocumentation::Index do
  let(:index) { RspecApiDocumentation::Index.new }

  subject { index }

  describe "#examples" do
    let(:examples) { [double, double] }

    before do
      index.examples.push(*examples)
    end

    it "should contain all added examples" do
      index.examples.should eq(examples)
    end
  end
end
