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

    ALLOWED_OPTIONS = [:dr_url, :ticket_id_for_retry, :carrier_id, :note, :minutes_to_retry, :short_code]
    class InvalidOptions < ::StandardError; end

    def carrier_lookup(phone)
      CarrierLookupResponse.new(post(:preview) do |b|
        b.destination(ton: 1, address: "1#{phone.to_s[-10..-1]}")
      end)
    end

    def send_sms(phone, message, options = {})
      phone = SmsValidation::Sms.new(phone, message).phone
      options = options.inject({}) { |hash, (k,v)| hash[k.to_sym] = v; hash }
      unrecognized_keys = options.keys - ALLOWED_OPTIONS
      raise InvalidOptions, "#{unrecognized_keys.join(", ")} #{1 == unrecognized_keys.size ? "is not a" : "are not"} valid option#{:s if unrecognized_keys.size > 1}" unless unrecognized_keys.empty?
      request_options = options.select{ |k,v| k.to_sym == :ticket_id_for_retry }
      carrier_id = options[:carrier_id] || carrier_lookup(phone).carrier_id
      SendSmsResponse.new(post(:submit, request_options) do |b|
        b.delivery(receipt_requested: true, url: options[:dr_url]) if options[:dr_url]
        b.option((options[:note] ? { note: options[:note] } : {}).merge(charge_type: 0, program_id: configuration.program_id, mlc: message_length_control))
        b.source(ton: 3, address: options[:short_code] || configuration.short_code)
        b.destination(ton: 1, address: phone, carrier: carrier_id)
        b.message((options[:minutes_to_retry] ? { validity_period: (options[:minutes_to_retry].to_f * 60).round } : {}).merge(text: message))
      end, carrier_id)
    end

    def status(ticket_id)
      StatusResponse.new(post(:query) do |b|
        b.ticket(id: ticket_id)
      end)
    end

    private
    def configuration
      @configuration ||= Module.nesting.last.configuration
    end

    def filtered(value)
      [:account, :user].inject(value) { |v, k| v.gsub(/<#{k}.*?\/>/, "") }
    end

    def post(type, options = {})
      builder = Builder::XmlMarkup.new
      builder.instruct!(:xml, version: 1.0)
      body = builder.request(options.merge(version: 3.0, protocol: :wmp, type: type)) do |r|
        r.user(agent: "openmarket_rubygem/SMS/#{OpenMarket::VERSION}")
        r.account(id: configuration.id, password: configuration.password)
        yield r
      end
      SmsValidation.log { "OpenMarket API: POST #{filtered(body)}" }
      Http.post("/wmp", body: body.to_s).tap do |result|
        SmsValidation.log { "OpenMarket API Result: #{result.respond_to?(:body) ? result.body : result}" }
      end
    end

    def message_length_control
      case SmsValidation.configuration.on_message_too_long
        when :truncate
          1
        when :raise_error
          0
        when :split
          2
      end
    end
  end

  API ||= Api.new
end
