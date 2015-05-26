require "rexml/document"

module OpenMarket
  class DR
    attr_reader :code, :description, :note, :parent_ticket_id, :segment_number, :state_description, :state_id, :ticket_id, :timestamp
    def initialize(data)
      (class << self; self; end).class_eval do
        # Defining a member variable for xml would pollute #inspect
        # This solution is inspired by https://github.com/jordansissel/software-patterns/tree/master/dont-log-secrets/ruby
        define_method(:xml) { REXML::Document.new(data).root }
        private :xml
      end
      @ticket_id = xml.attributes["ticketId"]
      @parent_ticket_id = xml.attributes["parentTicketId"]
      @note = xml.attributes["note"]
      response = xml.elements["response"]
      @description = response.attributes["description"]
      @code = response.attributes["code"].to_i
      message = xml.elements["message"]
      @segment_number = message.attributes["segmentNumber"]
      @timestamp = DateTime.strptime(message.attributes["deliveryDate"] + "+0000", '%FT%T.%LZ%z').utc
      state = message.elements["state"]
      @state_id = state.attributes["id"].to_i
      @state_description = state.attributes["description"]
    end
  end
end
