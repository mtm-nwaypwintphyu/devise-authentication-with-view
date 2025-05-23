require 'rails_helper'

RSpec.describe Calendar::CreateEventUsecase do
  let(:user) { double('User', google_oauth2_token: 'fake-token') }
  let(:valid_params) do
    {
      name: 'Meeting',
      description: 'Discuss project',
      start_time: '2025-05-22T10:00:00',
      end_time: '2025-05-22T11:00:00'
    }
  end

  subject { described_class.new(user, event_params).call }

  before do
    allow(Google::Apis::CalendarV3::CalendarService).to receive(:new).and_return(service_instance)
    allow(service_instance).to receive(:authorization=).with('fake-token')
  end

  let(:service_instance) { instance_double(Google::Apis::CalendarV3::CalendarService) }

  context 'with valid params' do
    let(:event_params) { valid_params }
    let(:created_event) { double('GoogleEvent', id: 'event123', summary: 'Meeting') }

    before do
      allow(service_instance).to receive(:insert_event)
        .with('primary', kind_of(Google::Apis::CalendarV3::Event))
        .and_return(created_event)
    end

    it 'returns success with created event' do
      result = subject
      expect(result[:success]).to be true
      expect(result[:event]).to eq(created_event)
      expect(result[:errors]).to be_nil.or be_empty
    end
  end

  context 'with missing required params' do
    let(:event_params) { { name: '', description: '', start_time: '', end_time: '' } }

    it 'returns errors for each missing field' do
      result = subject
      expect(result[:success]).to be false
      expect(result[:errors]).to include(:name, :description, :start_time, :end_time)
      expect(result[:errors][:name]).to eq("Name can't be blank")
      expect(result[:errors][:description]).to eq("Description can't be blank")
      expect(result[:errors][:start_time]).to eq("Start time can't be blank")
      expect(result[:errors][:end_time]).to eq("End time can't be blank")
    end
  end

  context 'when start_time is not before end_time' do
    let(:event_params) do
      valid_params.merge(start_time: '2025-05-22T12:00:00', end_time: '2025-05-22T11:00:00')
    end

    it 'returns a validation error on start_time' do
      result = subject
      expect(result[:success]).to be false
      expect(result[:errors][:start_time]).to eq('Start time must be before end time')
    end
  end

  context 'when Google API raises an error' do
    let(:event_params) { valid_params }

    before do
      allow(service_instance).to receive(:insert_event)
        .and_raise(Google::Apis::Error.new('API failure'))
    end

    it 'returns failure with api error message' do
      result = subject
      expect(result[:success]).to be false
      expect(result[:errors][:api]).to eq('Failed to create event: API failure')
    end
  end
end
