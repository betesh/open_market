require "rexml/document"

module OpenMarket
  class MO
    attr_reader :account_id, :carrier_id, :data, :data_coding, :destination_address, :destination_ton, :source_address, :source_ton, :ticket_id, :udhi
    def initialize(data)
      (class << self; self; end).class_eval do
        # Defining a member variable for xml would pollute #inspect
        # This solution is inspired by https://github.com/jordansissel/software-patterns/tree/master/dont-log-secrets/ruby
        define_method(:xml) { REXML::Document.new(data).root }
        private :xml
      end
      if ticket = xml.elements["ticket"]
        @ticket_id = ticket.attributes["id"]
      end
      if account = xml.elements["account"]
        @account_id = account.attributes["id"]
      end
      if source = xml.elements["source"]
        @carrier_id = source.elements["carrier"]
        @source_ton = source.elements["ton"]
        @source_address = source.elements["address"]
      end
      if destination = xml.elements["destination"]
        @destination_ton = destination.elements["ton"]
        @destination_address = destination.elements["address"]
      end
      if option = xml.elements["option"]
        @data_coding = option.attributes["datacoding"]
      end
      if message = xml.elements["message"]
        @udhi = message.attributes["udhi"] == true
        @data = message.attributes["data"]
      end
    end
  end
end
