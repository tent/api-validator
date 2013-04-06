require 'spec_helper'
require 'faraday'

require 'support/validator_shared_examples'

describe ApiValidator::Status do
  let(:env) { HashWrapper.new(:status => 200, :response_headers => {}, :body => '') }
  let(:response) { Faraday::Response.new(env) }
  let(:validator) { stub(:everything) }
  let(:instance) { described_class.new(expected_status) }
  let(:expectation_key) { :response_status }

  let(:res) { instance.validate(response) }

  describe "#validate" do
    let(:expected_status) { 304 }

    let(:expected_assertions) do
      [
        { :op => "test", :path => "", :value => 304 }
      ]
    end

    context "when expectation fails" do
      it_behaves_like "a validator #validate method"

      before do
        env.status = 400
      end

      let(:expected_diff) { [{ :op => "replace", :path => "", :value => 304, :current_value => 400 }] }
      let(:expected_failed_assertions) { [expected_assertions.first] }
    end

    context "when expectation passes" do
      it_behaves_like "a validator #validate method"

      before do
        env.status = 304
      end

      let(:expected_diff) { [] }
      let(:expected_failed_assertions) { [] }
    end
  end
end
