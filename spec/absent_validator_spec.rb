require 'spec_helper'
require 'faraday'

require 'support/validator_shared_examples'

describe ApiValidator::Absent do
  let(:env) { HashWrapper.new(:status => 200, :response_headers => {}, :body => '') }
  let(:response) { Faraday::Response.new(env) }
  let(:validator) { stub(:everything) }
  let(:instance) { described_class.new(*expected_paths) }
  let(:expectation_key) { :response_body }

  let(:res) { instance.validate(response) }

  describe "#validate" do
    let(:expected_paths) { %w( /wind/water/fire/pits /wind/water/fire/pots ) }

    let(:expected_assertions) do
      [
        { :op => "test", :path => "/wind/water/fire/pits", :type => 'absent' },
        { :op => "test", :path => "/wind/water/fire/pots", :type => 'absent' },
      ]
    end

    context "when expectation fails" do
      context "when property exists" do
        before do
          env.body = {
            "wind" => {
              "water" => {
                "fire" => {
                  "pots" => [1,2,3]
                }
              }
            }
          }
        end

        let(:expected_failed_assertions) do
          [
            { :op => "test", :path => "/wind/water/fire/pots", :type => 'absent' },
          ]
        end

        let(:expected_diff) do
          [
            { :op => "remove", :path => "/wind/water/fire/pots", :current_value => [1,2,3] },
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
                "dishes" => "all of them"
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
