require 'api-validator/version'

module ApiValidator

  require 'api-validator/mixins'

  require 'api-validator/assertion'
  require 'api-validator/base'
  require 'api-validator/json_schemas'
  require 'api-validator/json_schema'
  require 'api-validator/json'
  require 'api-validator/absent'
  require 'api-validator/present'
  require 'api-validator/length'
  require 'api-validator/header'
  require 'api-validator/status'
  require 'api-validator/body'

  require 'api-validator/response_expectation'
  require 'api-validator/spec'

  ##
  # Format validators
  # Map of format-uri => proc { |value| true || false }
  def self.format_validators
    @format_validators ||= Hash.new
  end

  class UnorderedList
    def initialize(list)
      @list = list
    end

    def ==(other_list)
      p [@list.sort, other_list.sort, @list.sort == other_list.sort]
      @list.sort == other_list.sort
    end

    def inspect
      @list.inspect
    end

    def respond_to_missing?(method)
      @list.respond_to?(method)
    end

    def method_missing(method, *args, &block)
      return super unless respond_to_missing?(method)
      @list.send(method, *args, &block)
    end
  end

end
