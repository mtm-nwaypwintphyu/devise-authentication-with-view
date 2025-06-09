class CalendarController < ApplicationController
  before_action :authenticate_user!
  before_action :set_calendar_range
  before_action :load_google_calendar, only: [:index, :all_events]
  before_action :load_holiday_calendar, only: [:all_holidays]

  def index
    result = Calendar::IndexUsecase.new(params).call
    @first_day = result[:first_day]
    @last_day = result[:last_day]
    @today = result[:today]
  end

  def all_events
    @events = @events_by_day.values.flatten
  end

  def all_holidays
    result = Calendar::AllHolidaysUsecase.new(params, action_name).call
    @today     = result[:today]
    @first_day = result[:first_day]
    @last_day  = result[:last_day]
  end

  def create_event_form
    @event = Event.new
  end

  def edit_event_form
    result = Calendar::EditEventFormUsecase.new(current_user, params[:event_id]).call
    @event = result[:event]
  end

  def update_event
    usecase = Calendar::UpdateEventUsecase.new(current_user, event_params)
    result = usecase.call
    if result[:success]
      flash[:notice] = "Event updated successfully!"
      redirect_to all_events_path
    else
      flash[:errors] = usecase.errors
      redirect_to create_event_form_calendar_index_path
    end
  end

  def create_event
    usecase = Calendar::CreateEventUsecase.new(current_user, event_params)
    result = usecase.call
    if result[:success]
      flash[:notice] = "Event created successfully!"
      redirect_to all_events_path
    else
      flash[:errors] = result[:errors]
      redirect_to create_event_form_calendar_index_path
    end
  end

  def delete_event
    usecase = Calendar::DeleteEventUsecase.new(current_user, params[:event_id])
    result = usecase.call
    if result[:success]
      flash[:notice] = "Event deleted successfully!"
    else
      flash[:errors] = result[:errors]
    end
    redirect_to all_events_path
  end

  private

  def load_google_calendar
    initialize_google_calendar_service

    begin
      calendar_list = @calendar_service.list_calendar_lists.items
    rescue Google::Apis::ClientError
      flash[:error] = "We encountered a problem while loading your Google Calendar. Please sign in again."
      redirect_to new_user_session_path and return
    rescue StandardError
      flash[:error] = "You must log in with a Google account to use Google services."
      redirect_to home_index_path and return
    end

    @events_by_day = {}

    calendar_list.each do |calendar|
      next if action_name == "all_events" && calendar.summary.downcase.include?("holiday")

      params = {
        single_events: true,
        time_min: @first_day.rfc3339,
        time_max: @last_day.rfc3339
      }
      params[:order_by] = 'startTime' unless calendar.access_role == 'reader'

      begin
        events = @calendar_service.list_events(calendar.id, **params)

        events.items.each do |event|
          start_time = event.start.date || event.start.date_time&.to_date
          next unless start_time

          @events_by_day[start_time] ||= []
          @events_by_day[start_time] << event
        end
      rescue StandardError => e
        Rails.logger.error("Error fetching events: #{e.message}")
      end
    end
  end

  def load_holiday_calendar
    initialize_google_calendar_service
    calendar_list = @calendar_service.list_calendar_lists.items
    @events_by_day = {}

    calendar_list.each do |calendar|
      next unless calendar.summary.downcase.include?("holiday")

      params = {
        single_events: true,
        time_min: @first_day.rfc3339,
        time_max: @last_day.rfc3339,
        order_by: 'startTime'
      }

      begin
        events = @calendar_service.list_events(calendar.id, **params)

        events.items.each do |event|
          start_time = event.start.date || event.start.date_time&.to_date
          next unless start_time

          @events_by_day[start_time] ||= []
          @events_by_day[start_time] << event
        end
      rescue Google::Apis::ClientError => e
        Rails.logger.error("Error fetching holidays: #{e.message}")
      end
    end
  end

  def initialize_google_calendar_service
    @user = current_user.decorate
    @calendar_service = Google::Apis::CalendarV3::CalendarService.new

    credentials = GoogleCredentialsService.new(@user).credentials
    credentials.fetch_access_token!

    if credentials.expired?
      flash[:alert] = "Your Google session has expired. Please log in again."
      sign_out(:user)
      reset_session
      redirect_to new_user_session_path and return
    end

    @calendar_service.authorization = credentials
  end

  def set_calendar_range
    result = Calendar::SetCalendarRangeUsecase.new(params, action_name).call
    @today = result[:today]
    @first_day = result[:first_day]
    @last_day = result[:last_day]
  end

  def event_params
    params.require(:event).permit(:id, :name, :description, :start_time, :end_time)
  end
end
