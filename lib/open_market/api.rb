require "open_market/configuration"
require "open_market/response"
require "open_market/version"

require "builder"
require "httparty"
require "sms_validation"

module OpenMarket
  class Api
    class Http
      include HTTParty
      base_uri "https://smsc.openmarket.com"
    end

    def carrier_lookup(phone)
      CarrierLookupResponse.new(post(:preview) do |b|
        b.destination(ton: 1, address: "1#{phone.to_s[-10..-1]}")
      end)
    end

    private
    def configuration
      @configuration ||= Module.nesting.last.configuration
    end

    def filtered(value)
      [:account, :user].inject(value) { |v, k| v.gsub(/<#{k}.*?\/>/, "") }
    end

    def post(type)
      builder = Builder::XmlMarkup.new
      builder.instruct!(:xml, version: 1.0)
      body = builder.request(version: 3.0, protocol: :wmp, type: type) do |r|
        r.user(agent: "openmarket_rubygem/SMS/#{OpenMarket::VERSION}")
        r.account(id: configuration.id, password: configuration.password)
        yield r
      end
      SmsValidation.log { "OpenMarket API: POST #{filtered(body)}" }
      Http.post("/wmp", body: body.to_s).tap do |result|
        SmsValidation.log { "OpenMarket API Result: #{result.respond_to?(:body) ? result.body : result}" }
      end
    end
  end

  API ||= Api.new
end
