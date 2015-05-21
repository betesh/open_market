require "rexml/document"

module OpenMarket
  class Response
    attr_reader :code, :description
    def initialize(http_response)
      (class << self; self; end).class_eval do
        # Defining a member variable for xml would pollute #inspect
        # This solution is inspired by https://github.com/jordansissel/software-patterns/tree/master/dont-log-secrets/ruby
        define_method(:xml) do
          if http_response.respond_to?(:body)
            REXML::Document.new(http_response.body).root
          else
            REXML::Document.new(http_response.to_xml).root.elements["response"]
          end
        end
        private :xml
      end
      error = xml.elements["error"]
      @code = (error.attributes["code"] || error.elements["code"].text).to_i
      @description = error.attributes["description"] || error.elements["description"].text
    end
  end

  class CarrierLookupResponse < Response
    attr_reader :country_code, :national_number, :intl_notation, :area_code, :area_code_length, :num_min_length, :num_max_length, :na_nxx, :na_line, :local_notation, :local_format, :digits_all, :digits_local, :ported, :ported_from
    attr_reader :city, :country, :country_name, :estimated_latitude, :estimated_longitude, :region, :region_name, :timezone_min, :timezone_max, :zone, :zone_name
    attr_reader :carrier_id, :name, :binary_length, :text_length, :unicode_length, :binary, :ems, :smart_messaging, :unicode, :wap_push

    def initialize(http_response)
      super
      if destination = xml.elements["destination"]
        @country_code = destination.attributes["country_code"].to_i
        @national_number = destination.attributes["national_number"]
        @intl_notation = destination.attributes["intl_notation"]
        @area_code = destination.attributes["area_code"]
        @area_code_length = destination.attributes["area_code_length"].to_i
        @num_min_length = destination.attributes["num_min_length"].to_i
        @num_max_length = destination.attributes["num_max_length"].to_i
        @na_nxx = destination.attributes["na_nxx"]
        @na_line = destination.attributes["na_line"]
        @local_notation = destination.attributes["local_notation"]
        @local_format = destination.attributes["local_format"]
        @digits_all = destination.attributes["digits_all"].to_i
        @digits_local = destination.attributes["digits_local"].to_i
        @ported = destination.attributes["ported"] == "true"
        @ported_from = destination.attributes["ported_from"]
      end
      if location = xml.elements["location"]
        @city = location.attributes["city"]
        @country = location.attributes["country"]
        @country_name = location.attributes["country_name"]
        @estimated_latitude = location.attributes["estimated_latitude"].to_f
        @estimated_longitude = location.attributes["estimated_longitude"].to_f
        @region = location.attributes["region"]
        @region_name = location.attributes["region_name"]
        @timezone_min = location.attributes["timezone_min"].to_i
        @timezone_max= location.attributes["timezone_max"].to_i
        @zone = location.attributes["zone"].to_i
        @zone_name = location.attributes["zone_name"]
      end
      if operator = xml.elements["operator"]
        @carrier_id = operator.attributes["id"].to_i
        @name = operator.attributes["name"]
        @binary_length = operator.attributes["binary_length"].to_i
        @text_length = operator.attributes["text_length"].to_i
        @unicode_length = operator.attributes["unicode_length"].to_i
        @binary = operator.attributes["binary"] == "true"
        @ems = operator.attributes["ems"] == "true"
        @smart_messaging = operator.attributes["smart_messaging"] == "true"
        @unicode = operator.attributes["unicode"] == "true"
        @wap_push = operator.attributes["wap_push"] == "true"
      end
    end
  end
end
