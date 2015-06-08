require "rexml/document"

module OpenMarket
  class MO
    ATTRIBUTES = [:account_id, :carrier_id, :data, :data_coding, :destination_address, :destination_ton, :source_address, :source_ton, :ticket_id, :udhi]
    attr_reader *ATTRIBUTES
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
        @source_address = source.attributes["address"]
        @carrier_id = source.attributes["carrier"]
        @source_ton = source.attributes["ton"]
      end
      if destination = xml.elements["destination"]
        @destination_address = destination.attributes["address"]
        @destination_ton = destination.attributes["ton"]
      end
      if option = xml.elements["option"]
        @data_coding = option.attributes["datacoding"]
      end
      if message = xml.elements["message"]
        @udhi = message.attributes["udhi"] == true
        @data = [message.attributes["data"]].pack("H*")
      end
    end

    def ==(rhs)
      rhs.is_a?(self.class) && ATTRIBUTES.all? { |a| send(a) == rhs.send(a) }
    end
  end
end
