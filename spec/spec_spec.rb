require 'spec_helper'
require 'support/shared_examples/validation_declaration'
require 'support/shared_examples/shared_example_declaration'
require 'support/shared_examples/shared_example_lookup'

describe ApiValidator::Spec do
  describe "class methods" do
    let(:instance) { described_class }

    describe ".describe" do
      it_behaves_like "a validation declaration" do
        let(:method_name) { :describe }
        let(:parent) { nil }
      end
    end

    describe ".context" do
      it_behaves_like "a validation declaration" do
        let(:method_name) { :describe }
        let(:parent) { nil }
      end
    end

    describe ".shared_example" do
      it_behaves_like "a shared example declaration"
    end
  end

  describe "instance methods" do
    let(:instance) { described_class.new("foo bar") }

    describe "#describe" do
      it_behaves_like "a validation declaration" do
        let(:method_name) { :describe }
        let(:parent) { instance }
      end
    end

    describe "#context" do
      it_behaves_like "a validation declaration" do
        let(:method_name) { :context }
        let(:parent) { instance }
      end
    end

    describe "#shared_example" do
      it_behaves_like "a shared example declaration"
    end

    describe "#find_shared_example" do
      let(:block) { lambda {} }
      let(:name) { :foo }

      context "when example in current instance" do
        before do
          instance.shared_examples[name] = block
        end

        it_behaves_like "shared example lookup"
      end

      context "when example in parent instance" do
        before do
          i = described_class.new("bar baz")
          instance.instance_eval { @parent = i }
          i.shared_examples[name] = block
        end

        it_behaves_like "shared example lookup"
      end

      context "when example in parent of parent instance" do
        before do
          i = described_class.new("bar bar")
          instance.instance_eval { @parent = i }

          i2 = described_class.new("baz biz")
          i.instance_eval { @parent = i2 }

          i2.shared_examples[name] = block
        end

        it_behaves_like "shared example lookup"
      end

      context "when example in class" do
        before do
          described_class.shared_examples[name] = block
        end

        it_behaves_like "shared example lookup"
      end
    end

    describe "#behaves_as" do
      let(:name) { :bar }

      context "when shared example exists" do
        it "calls block in scope of validator" do
          ref = nil
          example_block = proc { ref = self }

          instance.stubs(:find_shared_example).with(name).returns(example_block)
          instance.behaves_as(name)

          expect(ref).to eql(instance)
        end
      end

      context "when shared example does not exist" do
        it "raises BehaviourNotFoundError" do
          expect { instance.behaves_as(name) }.to raise_error(ApiValidator::Spec::BehaviourNotFoundError)
        end
      end
    end

    describe "#expect_response" do
      it "creates a new response expectation" do
        expect(instance.expect_response).to be_a(ApiValidator::ResponseExpectation)
      end

      it "appends expectation to list of expectations" do
        expect { instance.expect_response }.to change(instance.expectations, :size).by(1)
      end
    end

    describe "#run" do
      it "calls before hooks in context of validator" do
        ref = nil
        before_hook = proc { ref = self }
        instance.before_hooks << before_hook

        instance.run
        expect(ref).to eql(instance)
      end

      context "when before hook is an instance method" do
        it "calls before hooks in context of validator" do
          ref = nil
          instance.class.class_eval do
            define_method :something do
              ref = self
            end
          end
          instance.before_hooks << instance.method(:something)

          instance.run
          expect(ref).to eql(instance)
        end
      end

      it "executes response expectations" do
        response_expectation = stub
        instance.expectations << response_expectation

        response_expectation.expects(:run).returns([])
        instance.run
      end

      it "runs child validations" do
        child = stub
        instance.validations << child

        child.expects(:run).returns(stub(:results => {}))
        instance.run
      end

      it "returns validator results object" do
        child = described_class.new("biz baz")
        instance.validations << child

        child.stubs(:run).returns(stub(
          :results => {
            "biz baz" => {
              :results => [
                { :response_headers => { :valid => true } }
              ]
            }
          }
        ))

        res = instance.run
        expect(res.as_json).to eql(
          instance.name => {
            :results => [],
            child.name => {
              :results => [
                { :response_headers => { :valid => true } }
              ]
            }
          }
        )
      end
    end
  end

  describe "dependencies" do
    before do
      described_class.validations.delete_if { true }
    end

    let(:dependency_1) { described_class.describe("first foo", :name => :foo) }
    let(:instance) { described_class.describe("single foo", :depends_on => :foo) }

    context "when single dependency" do
      it "knows it's dependency" do
        expect(instance.dependencies).to eql([:foo])
      end

      it "gets sorted to run after dependency" do
        instance
        dependency_1

        described_class.sort_validations!

        expect(dependency_index = described_class.validations.index(dependency_1)).to_not be_nil
        expect(instance_index = described_class.validations.index(instance)).to_not be_nil
        expect(instance_index > dependency_index).to be_true, "expected index (#{instance_index}) to be grater than that of dependency (#{dependency_index})"
      end
    end

    context "when multiple dependencies" do
      let(:dependency_2) { described_class.describe("bar baz", :name => :baz) }
      let(:instance) { described_class.describe("single foo", :depends_on => [:foo, :baz]) }

      it "knows it's dependencies" do
        expect(instance.dependencies).to eql([:foo, :baz])
      end

      it "gets sorted to run after dependencies" do
        instance
        dependency_2
        dependency_1

        described_class.sort_validations!

        expect(dependency_1_index = described_class.validations.index(dependency_1)).to_not be_nil
        expect(dependency_2_index = described_class.validations.index(dependency_2)).to_not be_nil
        expect(instance_index = described_class.validations.index(instance)).to_not be_nil
        expect(instance_index > dependency_1_index).to be_true, "expected index (#{instance_index}) to be grater than that of first dependency (#{dependency_1_index})"
        expect(instance_index > dependency_2_index).to be_true, "expected index (#{instance_index}) to be grater than that of second dependency (#{dependency_2_index})"
      end

      it "doesn't alter the natural order for everything else" do
        other_1 = described_class.describe("other 1")
        other_2 = described_class.describe("other 2")
        instance
        other_3 = described_class.describe("other 3")
        dependency_1
        other_4 = described_class.describe("other 4")
        dependency_2
        other_5 = described_class.describe("other 5")

        described_class.sort_validations!

        expect(described_class.validations.map { |v| v.name }).to eql([other_1.name, other_2.name, other_3.name, dependency_1.name, dependency_2.name, instance.name, other_4.name, other_5.name])
      end

      it "sorts before running" do
        instance
        dependency_2
        dependency_1

        described_class.run
        expect(described_class.validations.map { |v| v.name }).to eql([dependency_2.name, dependency_1.name, instance.name])
      end

      it "sorts nested validations before running" do
        instance
        nested_1 = instance.describe("nested one")
        nested_2 = instance.context("nested two", :depends_on => :nested_foo)
        nested_3 = instance.context("nested three", :name => :nested_foo)

        instance.run

        expect(instance.validations.map { |v| v.name }).to eql([nested_1.name, nested_3.name, nested_2.name])
      end
    end
  end
end
