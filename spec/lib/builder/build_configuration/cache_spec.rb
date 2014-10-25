require 'spec_helper'

describe Vx::Builder::BuildConfiguration::Cache do
  let(:params) { { "directories" => ['/a', '/b'] } }
  let(:env)    { described_class.new params }
  subject { env }

  its(:attributes) { should eq("directories"=>["/a", "/b"], "enabled"=>true) }

  context "attributes" do
    context "when cache is valid hash" do
      let(:params) { {"directories" => ['/a']} }
      it { is_expected.to be_enabled }
      its(:directories) { should eq ['/a'] }
    end

    context "when cache is invalid hash" do
      let(:params) { {"key" => ['/a']} }
      it { is_expected.to be_enabled }
      its(:directories) { should eq [] }
    end

    context "when is nil" do
      let(:params) { nil }
      it { is_expected.to be_enabled }
      its(:directories) { should eq [] }
    end

    context "when is false value" do
      let(:params) { false }
      it { is_expected.not_to be_enabled }
      its(:directories){ should eq [] }
    end

    context "when disabled with normalized attributes" do
      let(:params) { {
        "directories" => [],
        "enabled" => false
      } }

      it { is_expected.not_to be_enabled }
      its(:directories) { should eq [] }
    end
  end
end
