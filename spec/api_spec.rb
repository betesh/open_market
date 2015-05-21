require "open_market/api"
require "support/configuration_from_yaml"

describe OpenMarket::Api do
  subject { OpenMarket::API }

  describe "#carrier_lookup" do
    it "should succeed without a 1 preceding the phone number" do
      result = subject.carrier_lookup(phone)
      expect(result).to be_a(OpenMarket::CarrierLookupResponse)
      expect(result.code).to eq(0)
      expect(result.description).to eq("No Error")
      expect(result.carrier_id).to eq(carrier_id)
    end

    it "should succeed with a 1 preceding the phone number" do
      result = subject.carrier_lookup("1#{phone}")
      expect(result).to be_a(OpenMarket::CarrierLookupResponse)
      expect(result.code).to eq(0)
      expect(result.description).to eq("No Error")
      expect(result.carrier_id).to eq(carrier_id)
    end
  end
end
