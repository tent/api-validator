require 'uri'

module ApiValidator
  class Base

    def initialize(expected)
      @expected = expected
      initialize_assertions(expected)
    end

    def assertions
      @assertions ||= []
    end

    def validate(response)
      {
        :assertions => assertions.map(&:to_hash)
      }
    end

    private

    def assertion_valid?(assertion, actual)
      value = assertion.value
      case value
      when Regexp
        value.match(actual.to_s)
      when Numeric
        (Numeric === actual) && (value == actual)
      else
        value == actual
      end
    end

    def assertion_format_valid?(assertion, actual)
      return true unless format = assertion.format
      if format == 'uri'
        uri = URI(actual)
        uri.scheme && uri.host
      elsif format_validator = format_validators[format]
        format_validator.call(actual)
      end
    rescue URI::InvalidURIError, ArgumentError
      false
    end

    def format_validators
      ApiValidator.format_validators
    end

  end
end
