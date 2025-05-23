require 'rails_helper'

RSpec.describe Calendar::UpdateEventUsecase do
  let(:user) { double('User', google_oauth2_token: 'token') }
  let(:event_id) { 'event123' }
  let(:valid_params) do
    {
      id: event_id,
      name: 'Meeting',
      description: 'Discuss project',
      start_time: '2025-05-22T10:00:00',
      end_time: '2025-05-22T11:00:00'
    }
  end

  subject { described_class.new(user, event_params).call }

  context 'with valid params' do
    let(:event_params) { valid_params }

    it 'calls Google Calendar API to update event and returns success' do
      service_double = instance_double(Google::Apis::CalendarV3::CalendarService)
      event_double = instance_double(Google::Apis::CalendarV3::Event,
                                     summary: nil,
                                     description: nil,
                                     start: nil,
                                     end: nil)

      # Mock service creation and authorization
      allow(Google::Apis::CalendarV3::CalendarService).to receive(:new).and_return(service_double)
      allow(service_double).to receive(:authorization=).with(user.google_oauth2_token)

      # Mock get_event returning an event instance
      allow(service_double).to receive(:get_event).with('primary', event_id).and_return(event_double)

      # Expect setters on event_double
      expect(event_double).to receive(:summary=).with(event_params[:name])
      expect(event_double).to receive(:description=).with(event_params[:description])
      expect(event_double).to receive(:start=).with(an_instance_of(Google::Apis::CalendarV3::EventDateTime))
      expect(event_double).to receive(:end=).with(an_instance_of(Google::Apis::CalendarV3::EventDateTime))

      # Expect update_event to be called
      expect(service_double).to receive(:update_event).with('primary', event_id, event_double)

      result = subject
      expect(result[:success]).to be true
      expect(result[:errors]).to be_nil.or be_empty
    end
  end

  context 'with invalid params' do
    context 'when name is blank' do
      let(:event_params) { valid_params.merge(name: '') }

      it 'returns validation errors' do
        result = subject
        expect(result[:success]).to be false
        expect(result[:errors][:name]).to eq("Name can't be blank")
      end
    end

    context 'when start_time >= end_time' do
      let(:event_params) { valid_params.merge(start_time: '2025-05-22T12:00:00', end_time: '2025-05-22T11:00:00') }

      it 'returns start_time validation error' do
        result = subject
        expect(result[:success]).to be false
        expect(result[:errors][:start_time]).to eq("Start time must be before end time")
      end
    end

    context 'when required fields are blank' do
      let(:event_params) { { id: event_id, name: '', description: '', start_time: '', end_time: '' } }

      it 'returns multiple validation errors' do
        result = subject
        expect(result[:success]).to be false
        expect(result[:errors].keys).to include(:name, :description, :start_time, :end_time)
      end
    end
  end

  context 'when Google API raises error' do
    let(:event_params) { valid_params }

    it 'returns API error message' do
      service_double = instance_double(Google::Apis::CalendarV3::CalendarService)

      allow(Google::Apis::CalendarV3::CalendarService).to receive(:new).and_return(service_double)
      allow(service_double).to receive(:authorization=).with(user.google_oauth2_token)

      allow(service_double).to receive(:get_event).and_raise(Google::Apis::Error.new('API error occurred'))

      result = subject
      expect(result[:success]).to be false
      expect(result[:errors][:api]).to include('Failed to update event: API error occurred')
    end
  end
end
