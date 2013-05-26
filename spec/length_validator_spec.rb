require 'spec_helper'
require 'faraday'

require 'support/validator_shared_examples'

describe ApiValidator::Length do
  let(:env) { HashWrapper.new(:status => 200, :response_headers => {}, :body => '') }
  let(:response) { Faraday::Response.new(env) }
  let(:validator) { stub(:everything) }
  let(:instance) { described_class.new(expected_path, expected_length) }
  let(:expectation_key) { :response_body }

  let(:res) { instance.validate(response) }

  describe "#validate" do
    let(:expected_path) { "/wind/water/fire/pits" }
    let(:expected_length) { 12 }

    let(:expected_assertions) do
      [
        { :op => "test", :path => "/wind/water/fire/pits", :type => 'length', :value => 12 },
      ]
    end

    context "when expectation fails" do
      context "when property exists" do
        before do
          env.body = {
            "wind" => {
              "water" => {
                "fire" => {
                  "pits" => [1,2,3]
                }
              }
            }
          }
        end

        let(:expected_failed_assertions) do
          [
            { :op => "test", :path => "/wind/water/fire/pits", :type => 'length', :value => 12 },
          ]
        end

        let(:expected_diff) do
          [
            { :op => "replace", :path => "/wind/water/fire/pits", :type => 'length', :value => 12, :current_value => 3 },
          ]
        end

        it_behaves_like "a validator #validate method"
      end

      context "when property does not exist" do
        before do
          env.body = {}
        end

        let(:expected_failed_assertions) do
          [
            { :op => "test", :path => "/wind/water/fire/pits", :type => 'length', :value => 12 },
          ]
        end

        let(:expected_diff) do
          [
            { :op => "add", :path => "/wind/water/fire/pits", :type => 'length', :value => 12 },
          ]
        end

        it_behaves_like "a validator #validate method"
      end
    end

    context "when expectation passes" do
      it_behaves_like "a validator #validate method"

      before do
        env.body = {
          "wind" => {
            "water" => {
              "fire" => {
                "pits" => (1..12).to_a
              }
            }
          }
        }
      end

      let(:expected_failed_assertions) { [] }
      let(:expected_diff) { [] }
    end
  end
end
