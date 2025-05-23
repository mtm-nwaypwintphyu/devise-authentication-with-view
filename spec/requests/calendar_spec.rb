require 'rails_helper'

RSpec.describe "Calendar", type: :request do

  let!(:user) { create(:user) }
  
  let(:mock_event1) do
    double("Event",
      start: double("Start", date_time: DateTime.new(2025,5,22,9,0,0)),
      summary: "Meeting with team"
    )
  end

  let(:mock_event2) do
    double("Event",
      start: double("Start", date_time: DateTime.new(2025,5,22,13,30,0)),
      summary: "Lunch with client"
    )
  end

  before do
    sign_in user

    allow(Calendar::IndexUsecase).to receive(:new).and_return(
      double(call: {
        first_day: Date.today.beginning_of_month,
        last_day: Date.today.end_of_month,
        today: Date.today
      })
    )

    allow_any_instance_of(CalendarController).to receive(:load_google_calendar) do |controller|
      controller.instance_variable_set(:@events_by_day, {
        Date.today => [mock_event1, mock_event2]
      })
    end

    allow_any_instance_of(CalendarController).to receive(:set_calendar_range).and_return(true)
  end

  # calendar index page
  describe "GET /calendar_index_path" do
    it "renders all events in the response body" do
      get calendar_index_path
      
      expect(response.body).to include("Meeting with team")
      expect(response.body).to include("Lunch with client")
    end
  end

  # all events
  describe "Controller method #all_events" do
    it "flattens @events_by_day into @events" do
      controller_instance = CalendarController.new

      controller_instance.instance_variable_set(:@events_by_day, {
        Date.today => [mock_event1],
        Date.tomorrow => [mock_event2]
      })

      controller_instance.send(:all_events)

      events = controller_instance.instance_variable_get(:@events)

      expect(events).to eq([mock_event1, mock_event2])
    end
  end

  # all holidays
  describe "GET /all_holidays_path" do
    before do
      allow(Calendar::AllHolidaysUsecase).to receive(:new).and_return(
        double(call: {
          today: Date.new(2025,5,1),
          first_day: Date.new(2025,5,1).beginning_of_month,
          last_day: Date.new(2025,5,1).end_of_month
        })
      )

      allow_any_instance_of(CalendarController).to receive(:load_google_calendar).and_return(true)
      allow_any_instance_of(CalendarController).to receive(:set_calendar_range).and_return(true)

      mock_google_service = double("Google::Apis::CalendarV3::CalendarService")
      
      allow(mock_google_service).to receive(:authorization=).with(anything)
      
      allow(mock_google_service).to receive(:list_calendar_lists).and_return(double(items: []))
      
      allow(mock_google_service).to receive(:fetch_holidays).and_return([])

      allow(Google::Apis::CalendarV3::CalendarService).to receive(:new).and_return(mock_google_service)
    end

    it "assigns holiday date range variables and renders successfully" do
      get all_holidays_path, params: { date: "2025-05-01" }

      expect(response).to have_http_status(:success)

      expect(assigns(:today)).to eq(Date.new(2025,5,1))
      expect(assigns(:first_day)).to eq(Date.new(2025,5,1).beginning_of_month)
      expect(assigns(:last_day)).to eq(Date.new(2025,5,1).end_of_month)
    end
  end

  # create_event_form
  describe "GET /create_event_form" do
    it "returns success status and displays the create event form page" do
      get create_event_form_calendar_index_path
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Create Event")
    end
  end

  # edit_event_form
  describe "GET /edit_event_form" do
    before do
      mock_event = OpenStruct.new(
        id: "12345",
        summary: "Title",
        description: "Something",
        start: OpenStruct.new(date_time: DateTime.new(2025,5,1,9,0,0)),
        end: OpenStruct.new(date_time: DateTime.new(2025,5,2,17,0,0))
      )

      allow(Calendar::EditEventFormUsecase).to receive(:new).and_return(
        double(call: { event: mock_event })
      )

      mock_google_service = double("Google::Apis::CalendarV3::CalendarService")
      allow(mock_google_service).to receive(:authorization=).with(anything)
      allow(Google::Apis::CalendarV3::CalendarService).to receive(:new).and_return(mock_google_service)
    end

    it "returns success and renders the edit event form" do
      get edit_event_form_calendar_index_path(event_id: "12345")
      expect(response).to have_http_status(:ok)
      expect(response.body).to render_template(:edit_event_form)
    end
  end

  # create event
  describe "POST /create_event" do
    let(:valid_params) do
      {
        event: {
          name: "Title",
          description: "Something",
          start_time: "2025-05-01T09:00",
          end_time: "2025-05-02T17:00"
        }
      }
    end
    let(:invalid_params) do
      {
        event: {
          name: "",
          description: "",
          start_time: "",
          end_time: ""
        }
      }
    end

    before do
      mock_google_service = double("Google::Apis::CalendarV3::CalendarService")
      allow(mock_google_service).to receive(:authorization=).with(anything)
      allow(Google::Apis::CalendarV3::CalendarService).to receive(:new).and_return(mock_google_service)
    end

    context 'with valid params' do
      it "redirects to all_events_path with success flash" do
        usecase_double = double("Calendar::CreateEventUsecase")
        allow(Calendar::CreateEventUsecase).to receive(:new).and_return(usecase_double)
        allow(usecase_double).to receive(:call).and_return({ success: true })
        
        post create_event_calendar_index_path, params: valid_params
        expect(response).to redirect_to(all_events_path)
        expect(flash[:notice]).to eq("Event created successfully!")
      end
    end

    context 'with invalid params' do
      it "redirects to create_event_form with error messages" do
        usecase_double = double("Calendar::CreateEventUsecase")
        error_messages = {
          name: "Name can't be blank",
          description: "Description can't be blank",
          start_time: "Start time can't be blank",
          end_time: "End time can't be blank"
        }
        allow(Calendar::CreateEventUsecase).to receive(:new).and_return(usecase_double)
        allow(usecase_double).to receive(:call).and_return({ success: false, errors: error_messages })
        
        post create_event_calendar_index_path, params: invalid_params
        expect(response).to redirect_to(create_event_form_calendar_index_path)
        expect(flash[:errors]).to eq(error_messages)
      end
    end
  end

  # update event
  describe "POST /update_event" do
    let(:valid_params) do
      {
        event: {
          name: "Title",
          description: "Something",
          start_time: "2025-05-01T09:00",
          end_time: "2025-05-02T17:00"
        }
      }
    end
    let(:invalid_params) do
      {
        event: {
          name: "",
          description: "",
          start_time: "",
          end_time: ""
        }
      }
    end

    before do
      mock_google_service = double("Google::Apis::CalendarV3::CalendarService")
      allow(mock_google_service).to receive(:authorization=).with(anything)
      allow(Google::Apis::CalendarV3::CalendarService).to receive(:new).and_return(mock_google_service)
    end

    context 'with valid params' do
      it "redirects to all_events_path with success flash" do
        usecase_double = double("Calendar::UpdateEventUsecase")
        allow(Calendar::UpdateEventUsecase).to receive(:new).and_return(usecase_double)
        allow(usecase_double).to receive(:call).and_return({ success: true })
        
        post update_event_calendar_index_path, params: valid_params
        expect(response).to redirect_to(all_events_path)
        expect(flash[:notice]).to eq("Event updated successfully!")
      end
    end

    context 'with invalid params' do
      it "redirects to edit_event_form with error messages" do
        usecase_double = double("Calendar::UpdateEventUsecase")
        error_messages = {
          name: "Name can't be blank",
          description: "Description can't be blank",
          start_time: "Start time can't be blank",
          end_time: "End time can't be blank"
        }
        allow(Calendar::UpdateEventUsecase).to receive(:new).and_return(usecase_double)
        allow(usecase_double).to receive(:call).and_return({ success: false, errors: error_messages })
        allow(usecase_double).to receive(:errors).and_return(error_messages)
        
        post update_event_calendar_index_path, params: invalid_params
        expect(response).to redirect_to(edit_event_form_calendar_index_path)
        expect(flash[:errors]).to eq(error_messages)
      end
    end
  end

  # destroy event
  describe "DELETE /delete_event" do
    mock_event = OpenStruct.new(
      id: "12345",
      summary: "Title",
      description: "Something",
      start: OpenStruct.new(date_time: DateTime.new(2025,5,1,9,0,0)),
      end: OpenStruct.new(date_time: DateTime.new(2025,5,2,17,0,0))
    )

    before do
      mock_google_service = double("Google::Apis::CalendarV3::CalendarService")
      allow(mock_google_service).to receive(:authorization=).with(anything)
      allow(Google::Apis::CalendarV3::CalendarService).to receive(:new).and_return(mock_google_service)
    end

    context 'with valid event_id' do
      it "redirects to all_events_path with success message" do
        usecase_double = double("Calendar::DeleteEventUsecase")
        allow(Calendar::DeleteEventUsecase).to receive(:new).and_return(usecase_double)
        allow(usecase_double).to receive(:call).and_return({ success: true })
        
        post delete_event_calendar_index_path, params: mock_event.id
        expect(response).to redirect_to(all_events_path)
        expect(flash[:notice]).to eq("Event deleted successfully!")
      end
    end
  end
end
