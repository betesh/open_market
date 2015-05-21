require "support/configuration_from_yaml"
require "open_market/configuration"

describe OpenMarket::Configuration do
  subject { OpenMarket.configuration }
  let(:skip_open_market_configuration) { true }

  [:id, :password, :program_id].each do |configuration_option|
    describe "##{configuration_option}" do
      it "cannot be nil" do
        expect{subject.public_send("#{configuration_option}=", nil)}.to raise_error(OpenMarket::Configuration::Error, "#{configuration_option} cannot be blank")
      end

      it "cannot be an empty String" do
        expect{subject.public_send("#{configuration_option}=", "")}.to raise_error(OpenMarket::Configuration::Error, "#{configuration_option} cannot be blank")
      end

      it "cannot be a Hash" do
        expect{subject.public_send("#{configuration_option}=", {})}.to raise_error(OpenMarket::Configuration::Error, "#{configuration_option} must be a String")
      end

      it "must be set before accessing it" do
        expect{subject.public_send(configuration_option)}.to raise_error(OpenMarket::Configuration::Error, "#{configuration_option} has not been set.  Set it with `OpenMarket.configuration.#{configuration_option} = ...`")
      end

      describe "when configured" do
        let(:skip_open_market_configuration) { false }

        it "is accessible" do
          expect(subject.public_send(configuration_option)).to eq(public_send(configuration_option))
        end
      end
    end
  end
end
