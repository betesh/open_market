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

  describe "#send_sms" do
    it "should send an SMS" do
      result = subject.send_sms(phone, "Test of OpenMarket API", carrier_id: carrier_id)
      expect(result.code).to eq(2)
      expect(result.description).to eq("Message received.")
      expect(result.ticket_id).not_to be_nil
    end

    it "looks up the carrier_id if it is not passed as an option and returns it" do
      expect(OpenMarket::Api::Http).to receive(:post).and_wrap_original do |original, *args, &block|
        expect(args[0]).to eq("/wmp")
        puts args[1][:body].inspect
        expect(args[1][:body]).to match /\A<\?xml version=\"1.0\" encoding=\"UTF-8\"\?><request version=\"3.0\" protocol=\"wmp\" type=\"preview\"><user agent=\"openmarket_rubygem\/SMS\/0\.0\.1\"\/><account id=\"#{id}\" password=\"#{password}\"\/><destination ton=\"1\" address=\"1#{phone}\"\/><\/request>\z/
        original.call(*args, &block)
      end
      expect(OpenMarket::Api::Http).to receive(:post).and_wrap_original do |original, *args, &block|
        expect(args[0]).to eq("/wmp")
        expect(args[1][:body]).to match /\A<\?xml version=\"1.0\" encoding=\"UTF-8\"\?><request version=\"3.0\" protocol=\"wmp\" type=\"submit\"><user agent=\"openmarket_rubygem\/SMS\/0\.0\.1\"\/><account id=\"#{id}\" password=\"#{password}\"\/><option charge_type=\"0\" program_id=\"#{program_id}\" mlc=\"0\"\/><source ton=\"3\" address=\"#{short_code}\"\/><destination ton=\"1\" address=\"1#{phone}\" carrier=\"#{carrier_id}\"\/><message text=\"Test of OpenMarket API\"\/><\/request>\z/
        original.call(*args, &block)
      end
      result = subject.send_sms(phone, "Test of OpenMarket API")
      expect(result.carrier_id).to eq(carrier_id)
    end

    describe "message_length_control" do
      describe "when SmsValidation.configuration.on_message_too_long is truncate" do
        it "should be 1" do
          SmsValidation.configuration.on_message_too_long = :truncate
          expect(OpenMarket::Api::Http).to receive(:post).and_wrap_original do |original, *args, &block|
            expect(args[0]).to eq("/wmp")
            expect(args[1][:body]).to match /\A<\?xml version=\"1.0\" encoding=\"UTF-8\"\?><request version=\"3.0\" protocol=\"wmp\" type=\"submit\"><user agent=\"openmarket_rubygem\/SMS\/0\.0\.1\"\/><account id=\"#{id}\" password=\"#{password}\"\/><option charge_type=\"0\" program_id=\"#{program_id}\" mlc=\"1\"\/><source ton=\"3\" address=\"#{short_code}\"\/><destination ton=\"1\" address=\"1#{phone}\" carrier=\"#{carrier_id}\"\/><message text=\"Test of OpenMarket API\"\/><\/request>\z/
            original.call(*args, &block)
          end
          subject.send_sms(phone, "Test of OpenMarket API", carrier_id: carrier_id)
        end
      end

      describe "when SmsValidation.configuration.on_message_too_long is split" do
        it "should be 2" do
          SmsValidation.configuration.on_message_too_long = :split
          expect(OpenMarket::Api::Http).to receive(:post).and_wrap_original do |original, *args, &block|
            expect(args[0]).to eq("/wmp")
            expect(args[1][:body]).to match /\A<\?xml version=\"1.0\" encoding=\"UTF-8\"\?><request version=\"3.0\" protocol=\"wmp\" type=\"submit\"><user agent=\"openmarket_rubygem\/SMS\/0\.0\.1\"\/><account id=\"#{id}\" password=\"#{password}\"\/><option charge_type=\"0\" program_id=\"#{program_id}\" mlc=\"2\"\/><source ton=\"3\" address=\"#{short_code}\"\/><destination ton=\"1\" address=\"1#{phone}\" carrier=\"#{carrier_id}\"\/><message text=\"Test of OpenMarket API\"\/><\/request>\z/
            original.call(*args, &block)
          end
          subject.send_sms(phone, "Test of OpenMarket API", carrier_id: carrier_id)
        end
      end

      describe "when SmsValidation.configuration.on_message_too_long is raise_error" do
        it "should be 0" do
          SmsValidation.configuration.on_message_too_long = :raise_error
          expect(OpenMarket::Api::Http).to receive(:post).and_wrap_original do |original, *args, &block|
            expect(args[0]).to eq("/wmp")
            expect(args[1][:body]).to match /\A<\?xml version=\"1.0\" encoding=\"UTF-8\"\?><request version=\"3.0\" protocol=\"wmp\" type=\"submit\"><user agent=\"openmarket_rubygem\/SMS\/0\.0\.1\"\/><account id=\"#{id}\" password=\"#{password}\"\/><option charge_type=\"0\" program_id=\"#{program_id}\" mlc=\"0\"\/><source ton=\"3\" address=\"#{short_code}\"\/><destination ton=\"1\" address=\"1#{phone}\" carrier=\"#{carrier_id}\"\/><message text=\"Test of OpenMarket API\"\/><\/request>\z/
            original.call(*args, &block)
          end
          subject.send_sms(phone, "Test of OpenMarket API", carrier_id: carrier_id)
        end
      end
    end

    describe "invalid keys" do
      it "should raise a gramatically correct error with 1 unknown option" do
        expect{subject.send_sms(phone, "Test of OpenMarket API", carrier_id: carrier_id, unknown_option: true)}.to raise_error(OpenMarket::Api::InvalidOptions, "unknown_option is not a valid option")
      end

      it "should raise a gramatically correct error with 2 unknown options" do
        expect{subject.send_sms(phone, "Test of OpenMarket API", carrier_id: carrier_id, unknown_option: true, other_unknown: false)}.to raise_error(OpenMarket::Api::InvalidOptions, "unknown_option, other_unknown are not valid options")
      end

      it "automatically converts String keys to Symbol" do
        expect{subject.send_sms(phone, "Test of OpenMarket API", "carrier_id" => carrier_id, "ticket_id_for_retry" => "ABC", "dr_url" => dr_url, "note" => "ABCDEFFF", "minutes_to_retry" => 10, "short_code" => 99998)}.not_to raise_error
      end
    end

    describe "valid keys" do
      describe "carrier_id" do
        let(:carrier_id) { 1000000 }
        it "should be in the XML" do
          expect(OpenMarket::Api::Http).to receive(:post).and_wrap_original do |original, *args, &block|
            expect(args[0]).to eq("/wmp")
            expect(args[1][:body]).to match /\A<\?xml version=\"1.0\" encoding=\"UTF-8\"\?><request version=\"3.0\" protocol=\"wmp\" type=\"submit\"><user agent=\"openmarket_rubygem\/SMS\/0\.0\.1\"\/><account id=\"#{id}\" password=\"#{password}\"\/><option charge_type=\"0\" program_id=\"#{program_id}\" mlc=\"0\"\/><source ton=\"3\" address=\"#{short_code}\"\/><destination ton=\"1\" address=\"1#{phone}\" carrier=\"#{carrier_id}\"\/><message text=\"Test of OpenMarket API\"\/><\/request>\z/
            original.call(*args, &block)
          end
          subject.send_sms(phone, "Test of OpenMarket API", carrier_id: carrier_id)
        end
      end

      describe "note" do
        let(:note) { "The quick brown fox jumps over the lazy dog" }
        it "should be in the XML" do
          expect(OpenMarket::Api::Http).to receive(:post).and_wrap_original do |original, *args, &block|
            expect(args[0]).to eq("/wmp")
            expect(args[1][:body]).to match /\A<\?xml version=\"1.0\" encoding=\"UTF-8\"\?><request version=\"3.0\" protocol=\"wmp\" type=\"submit\"><user agent=\"openmarket_rubygem\/SMS\/0\.0\.1\"\/><account id=\"#{id}\" password=\"#{password}\"\/><option note=\"#{note}\" charge_type=\"0\" program_id=\"#{program_id}\" mlc=\"0\"\/><source ton=\"3\" address=\"#{short_code}\"\/><destination ton=\"1\" address=\"1#{phone}\" carrier=\"#{carrier_id}\"\/><message text=\"Test of OpenMarket API\"\/><\/request>\z/
            original.call(*args, &block)
          end
          subject.send_sms(phone, "Test of OpenMarket API", carrier_id: carrier_id, note: note)
        end
      end

      describe "ticket_id_for_retry" do
        let(:ticket_id_for_retry) { 1999998888 }
        it "should be in the XML" do
          expect(OpenMarket::Api::Http).to receive(:post).and_wrap_original do |original, *args, &block|
            expect(args[0]).to eq("/wmp")
            expect(args[1][:body]).to match /\A<\?xml version=\"1.0\" encoding=\"UTF-8\"\?><request ticket_id_for_retry=\"#{ticket_id_for_retry}\" version=\"3.0\" protocol=\"wmp\" type=\"submit\"><user agent=\"openmarket_rubygem\/SMS\/0\.0\.1\"\/><account id=\"#{id}\" password=\"#{password}\"\/><option charge_type=\"0\" program_id=\"#{program_id}\" mlc=\"0\"\/><source ton=\"3\" address=\"#{short_code}\"\/><destination ton=\"1\" address=\"1#{phone}\" carrier=\"#{carrier_id}\"\/><message text=\"Test of OpenMarket API\"\/><\/request>\z/
            original.call(*args, &block)
          end
          subject.send_sms(phone, "Test of OpenMarket API", carrier_id: carrier_id, ticket_id_for_retry: ticket_id_for_retry)
        end
      end

      describe "dr_url" do
        let(:dr_url) { "example.com" }
        it "should be in the XML" do
          expect(OpenMarket::Api::Http).to receive(:post).and_wrap_original do |original, *args, &block|
            expect(args[0]).to eq("/wmp")
            expect(args[1][:body]).to match /\A<\?xml version=\"1.0\" encoding=\"UTF-8\"\?><request version=\"3.0\" protocol=\"wmp\" type=\"submit\"><user agent=\"openmarket_rubygem\/SMS\/0\.0\.1\"\/><account id=\"#{id}\" password=\"#{password}\"\/><delivery receipt_requested=\"true\" url=\"#{dr_url}\"\/><option charge_type=\"0\" program_id=\"#{program_id}\" mlc=\"0\"\/><source ton=\"3\" address=\"#{short_code}\"\/><destination ton=\"1\" address=\"1#{phone}\" carrier=\"#{carrier_id}\"\/><message text=\"Test of OpenMarket API\"\/><\/request>\z/
            original.call(*args, &block)
          end
          subject.send_sms(phone, "Test of OpenMarket API", dr_url: dr_url, carrier_id: carrier_id)
        end
      end

      describe "minutes_to_retry" do
        it "should be in the XML" do
          expect(OpenMarket::Api::Http).to receive(:post).and_wrap_original do |original, *args, &block|
            expect(args[0]).to eq("/wmp")
            expect(args[1][:body]).to match /\A<\?xml version=\"1.0\" encoding=\"UTF-8\"\?><request version=\"3.0\" protocol=\"wmp\" type=\"submit\"><user agent=\"openmarket_rubygem\/SMS\/0\.0\.1\"\/><account id=\"#{id}\" password=\"#{password}\"\/><delivery receipt_requested=\"true\" url=\"#{dr_url}\"\/><option charge_type=\"0\" program_id=\"#{program_id}\" mlc=\"0\"\/><source ton=\"3\" address=\"#{short_code}\"\/><destination ton=\"1\" address=\"1#{phone}\" carrier=\"#{carrier_id}\"\/><message validity_period=\"1080\" text=\"Test of OpenMarket API\"\/><\/request>\z/
            original.call(*args, &block)
          end
          subject.send_sms(phone, "Test of OpenMarket API", dr_url: dr_url, carrier_id: carrier_id, minutes_to_retry: 18)
        end

        describe "can be a fraction of a number and is rounded to the nearest integer number of seconds" do
          [19, 20, 21].each do |divisor|
            describe do
              it "should be in the XML" do
                expect(OpenMarket::Api::Http).to receive(:post).and_wrap_original do |original, *args, &block|
                  expect(args[0]).to eq("/wmp")
                  expect(args[1][:body]).to match /\A<\?xml version=\"1.0\" encoding=\"UTF-8\"\?><request version=\"3.0\" protocol=\"wmp\" type=\"submit\"><user agent=\"openmarket_rubygem\/SMS\/0\.0\.1\"\/><account id=\"#{id}\" password=\"#{password}\"\/><delivery receipt_requested=\"true\" url=\"#{dr_url}\"\/><option charge_type=\"0\" program_id=\"#{program_id}\" mlc=\"0\"\/><source ton=\"3\" address=\"#{short_code}\"\/><destination ton=\"1\" address=\"1#{phone}\" carrier=\"#{carrier_id}\"\/><message validity_period=\"3\" text=\"Test of OpenMarket API\"\/><\/request>\z/
                  original.call(*args, &block)
                end
                subject.send_sms(phone, "Test of OpenMarket API", dr_url: dr_url, carrier_id: carrier_id, minutes_to_retry: 1.0/divisor )
              end
            end
          end
        end
      end

      describe "short_code" do
        let(:short_code) { 66666 }
        it "should be in the XML" do
          expect(OpenMarket::Api::Http).to receive(:post).and_wrap_original do |original, *args, &block|
            expect(args[0]).to eq("/wmp")
            expect(args[1][:body]).to match /\A<\?xml version=\"1.0\" encoding=\"UTF-8\"\?><request version=\"3.0\" protocol=\"wmp\" type=\"submit\"><user agent=\"openmarket_rubygem\/SMS\/0\.0\.1\"\/><account id=\"#{id}\" password=\"#{password}\"\/><option charge_type=\"0\" program_id=\"#{program_id}\" mlc=\"0\"\/><source ton=\"3\" address=\"#{short_code}\"\/><destination ton=\"1\" address=\"1#{phone}\" carrier=\"#{carrier_id}\"\/><message text=\"Test of OpenMarket API\"\/><\/request>\z/
            original.call(*args, &block)
          end
          subject.send_sms(phone, "Test of OpenMarket API", carrier_id: carrier_id, short_code: short_code)
        end
      end
    end
  end

  describe "#status" do
    let(:sms) { subject.send_sms(phone, "Test of OpenMarket API") }
    let(:ticket_id) { sms.ticket_id }

    def get_status
      subject.status(ticket_id)
    end

    it "should look up the status of a ticket" do
      status = get_status
      expect(status.code).to eq(0)
      expect(status.description).to eq("No Error")
      expect(status.status_code).to eq(3)
      expect(status.status_description).to eq("Message buffered with carrier and waiting for delivery response.")
      print "Waiting for the message to be delivered..."
      i = 0
      SmsValidation.configuration.logger = nil
      begin
        sleep 1
        print "."
        status = get_status
        break if 4 == status.status_code
        i += 1
      end while i < 5
      expect(status.code).to eq(0)
      expect(status.description).to eq("No Error")
      expect(status.status_code).to eq(4)
      expect(status.status_description).to eq("Message successfully delivered.")
    end
  end
end
