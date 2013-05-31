require 'spec_helper'
require 'faraday'

require 'support/validator_shared_examples'

describe ApiValidator::Present do
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
        { :op => "test", :path => "/wind/water/fire/pits", :type => 'present' },
        { :op => "test", :path => "/wind/water/fire/pots", :type => 'present' },
      ]
    end

    context "when expectation fails" do
      context "when property missing" do
        before do
          env.body = {
            "wind" => {
              "water" => {
                "fire" => {
                  "pits" => "very deep and full of mud"
                }
              }
            }
          }
        end

        let(:expected_failed_assertions) do
          [
            { :op => "test", :path => "/wind/water/fire/pots", :type => 'present' },
          ]
        end

        let(:expected_diff) do
          [
            { :op => "add", :path => "/wind/water/fire/pots" },
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
                "pits" => "very deep and full of mud",
                "pots" => "yum!"
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
