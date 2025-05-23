require 'rails_helper'

RSpec.describe Calendar::EditEventFormUsecase do
  let(:user) { double('User', google_oauth2_token: 'fake-token') }
  let(:event_id) { 'event123' }
  let(:service_instance) { instance_double(Google::Apis::CalendarV3::CalendarService) }

  subject { described_class.new(user, event_id).call }

  before do
    allow(Google::Apis::CalendarV3::CalendarService).to receive(:new).and_return(service_instance)
    allow(service_instance).to receive(:authorization=).with('fake-token')
  end

  context 'when event is successfully fetched' do
    let(:event) { double('GoogleEvent', id: event_id, summary: 'Test Event') }

    before do
      allow(service_instance).to receive(:get_event).with('primary', event_id).and_return(event)
    end

    it 'returns the event' do
      result = subject
      expect(result[:event]).to eq(event)
      expect(result[:error]).to be_nil
    end
  end

  context 'when Google API raises an error' do
    before do
      allow(service_instance).to receive(:get_event).with('primary', event_id).and_raise(Google::Apis::Error.new('API error'))
    end

    it 'returns nil event and error message' do
      result = subject
      expect(result[:event]).to be_nil
      expect(result[:error]).to eq('API error')
    end
  end
end
