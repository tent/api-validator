# ApiValidator [![Build Status](https://travis-ci.org/tent/api-validator.png)](https://travis-ci.org/tent/api-validator)

Framework for integration testing an API server.

## Installation

Add this line to your application's Gemfile:

    gem 'api-validator'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install api-validator

## Usage

```ruby
class MyValidation < ApiValidator::Spec

  def create_resource
    # ...
    set(:resource, data)
  end

  def fudge_resource
    # ...
    set(:resource, fudged_data)
  end

  describe "GET /posts/{entity}/{id}" do
    shared_examples :not_found do
      expect_response(:schema => :error, :status => 404) do
        # ...
        response
      end
    end

    context "when resource exists", :before => :create_resource do
      context "when authorized to read all posts" do
        authorize!(:server => :remote, :scopes => %w[ read_posts ], :read_types => %w[ all ])

        expect_response(:schema => :post, :status => 200) do
          expect_headers({ 'Content-Type' => /json\b/ })
          expect_properties(:entity => get(:resource, :entity), :id => get(:resource, :id))
          expect_schema(:post_content, "/content")

          # ...
          response
        end
      end

      context "when authorize to write resource but not read" do
        authorize!(:server => :remote, :scopes => %w[ write_posts ], :write_types => %w[ all ])
        behaves_as :not_found
      end

      context "when not authorized" do
        behaves_as :not_found
      end
    end

    context "when resource does not exist", :before => :fudge_resource do
      behaves_as :not_found
    end
  end

end
```

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
