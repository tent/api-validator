module ApiValidator
  class ResponseExpectation

    class PropertyAbsent
    end

    require 'api-validator/response_expectation/results'

    attr_accessor :status_validator, :body_validator
    def initialize(validator, options = {}, &block)
      @validator, @block = validator, block
      initialize_headers(options.delete(:headers))
      initialize_status(options.delete(:status))
      initialize_schema(options.delete(:schema))
    end

    def initialize_headers(expected_headers)
      return unless expected_headers
      self.header_validators << ApiValidator::Header.new(expected_headers)
    end

    def initialize_status(expected_status)
      return unless expected_status
      self.status_validator = ApiValidator::Status.new(expected_status)
    end

    def initialize_schema(expected_schema)
      return unless expected_schema
      schema_validators << ApiValidator::JsonSchema.new(expected_schema)
    end

    def property_absent
      PropertyAbsent.new
    end

    def unordered_list(list)
      UnorderedList.new(list)
    end

    def json_validators
      @json_validators ||= []
    end

    def absent_validators
      @absent_validators ||= []
    end

    def present_validators
      @present_validators ||= []
    end

    def length_validators
      @length_validators ||= []
    end

    def schema_validators
      @schema_validators ||= []
    end

    def header_validators
      @header_validators ||= []
    end

    def response_filters
      @response_filters ||= []
    end

    def expectations
      [status_validator, body_validator].compact + header_validators + schema_validators + json_validators + absent_validators + present_validators + length_validators
    end

    def expect_body(body)
      self.body_validator = ApiValidator::Body.new(body)
    end

    def expect_properties(properties)
      json_validators << ApiValidator::Json.new(properties)
    end

    def expect_properties_absent(*paths)
      absent_validators << ApiValidator::Absent.new(*paths)
    end

    def expect_properties_present(*paths)
      present_validators << ApiValidator::Present.new(*paths)
    end

    def expect_property_length(path, length)
      length_validators << ApiValidator::Length.new(path, length)
    end

    def expect_schema(expected_schema, path=nil, options = {})
      schema_validators << ApiValidator::JsonSchema.new(expected_schema, path, options)
    end

    def expect_headers(expected_headers)
      header_validators << ApiValidator::Header.new(expected_headers)
    end

    def expect_post_type(type_uri)
      response_filters << proc { |response| response.env['expected_post_type'] = type_uri }
      type_uri
    end

    def after_hooks
      @after_hooks ||= []
    end

    def after(&block)
      after_hooks << block
    end

    def run
      return unless @block
      response = instance_eval(&@block)
      results = validate(response)
      after_hooks.each { |hook| hook.call(response, results, @validator) }
      Results.new(response, results)
    end

    def validate(response)
      response_filters.each { |filter| filter.call(response) }
      expectations.map { |expectation| expectation.validate(response) }
    end

    def respond_to_missing?(method)
      @validator.respond_to?(method)
    end

    def method_missing(method, *args, &block)
      if respond_to_missing?(method)
        @validator.send(method, *args, &block)
      else
        super
      end
    end

  end
end
