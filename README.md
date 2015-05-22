# OpenMarket

We use HTTParty to send SMS messages using the OpenMarket API.  See USAGE below for details.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'openmarket'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install openmarket

## Usage

### Configuratiion

The openmarket gem requires you to provide an id, password, program_id and short_code.  Configure them before attempting any API calls.

```ruby
OpenMarket.configure do |config|
  config.id = "000-000-000-00000"
  config.password = "Re@llyL0ngR&om$tr1ng"
  config.program_id = "ABC"
  config.short_code = 99999 # You can override this on an individual message if necessary
end
```

Since the openmarket gem depends on sms_validation (https://github.com/betesh/sms_validation/), it is also recommended that you configure sms_validation.
openmarket uses sms_validation's logger.  In a Rails environment, you will probably want to rely on the default configuration,
but outside of Rails, you will need to configure it if you want any logging:

```ruby
SmsValidation.configure do |config|
  config.logger = ::Logger.new(STDOUT)
end
```

### API calls

`OpenMarket::API` supports 3 API calls: `carrier_lookup`, `send_sms`, and `status`.

#### carrier_lookup

```ruby
require  'openmarket'
phone = 2125551212
result = OpenMarket::API.carrier_lookup(phone)

# First, make sure the call succeeded
puts result.code # should be 0
puts result.description # should be 'No Error'

# If the call succeeded, you can check the carrier_id:
puts result.carrier_id # You are probably most interested in the carrier_id
puts result.inspect # But there are a lot of other attributes returned by this API call as well
```

#### send_sms

```ruby
require  'openmarket'
phone = 2125551212
message = "Hello, this is a test of the OpenMarket API"
result = OpenMarket::API.send_sms(phone, message)

# First, make sure the call succeeded
puts result.code # should be 2
puts result.description # should be 'Message received.'

# Save the ticket ID for later.  We'll use this to query the status of the ticket.
ticket_id = result.ticket_id

# There are some options you can pass along as well:
result = OpenMarket::API.send_sms(
  phone,
  message,

  # If you want to receive DR's, you must pass a dr_url option.  If you don't pass a URL, no DR will be sent to the default URL.
  dr_url: "http://www.example.com/drs",

  # It is highly recommended to pass a carrier_id.  If you don't, the openmarket gem will make an extra API call to look up the carrier before sending the message.
  carrier_id: 788,

  # If you don't want to the short_code you configured above, provide another short_code to send to:
  short_code: 33333,

  # By default, OpenMarket re-attempts delivery for 3 days.  To make OpenMarket give up and report it as a failure sooner, pass a number of minutes you would like to retry for:
  minutes_to_retry: 120, # 2 hours

  note: "Information that will be passed on to the DR",

  ticket_id_for_retry: ticket_id # If this is a re-try of a failed ticket.
)

```
#### status

```ruby
require  'openmarket'
result = OpenMarket::API.status(ticket_id) # Remember the ticket ID we saved from #send_sms?

# First, make sure the call succeeded
puts result.code # should be 0
puts result.description # should be 'No Error'

# Check the result of the SMS message
puts result.status_code
puts result.status_description

```

## Contributing

1. Fork it ( https://github.com/betesh/open_market/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
