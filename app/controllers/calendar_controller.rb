require "ostruct"
class CalendarController < ApplicationController
  before_action :authenticate_user!
  before_action :set_calendar_range
  before_action :load_google_calendar, only: [:index, :all_events]
  before_action :load_holiday_calendar, only: [:all_holidays]

  # show calendar
  def index
    result = Calendar::IndexUsecase.new(params).call

    @first_day = result[:first_day]
    @last_day = result[:last_day]
    @today = result[:today]

  end

  
  # get all events
  def all_events
    # flatten >> array of arrays into a single array
    @events = @events_by_day.values.flatten
  end

  # get holidays
  def all_holidays
    result = Calendar::AllHolidaysUsecase.new(params, action_name).call
    @today  = result[:today]
    @first_day = result[:first_day]
    @last_day = result[:last_day]
  end 

  # get to form
  def create_event_form
    @event = OpenStruct.new(name: '', description: '', start_time: nil, end_time: nil)
  end

  # get to edit form
  def edit_event_form
    result = Calendar::EditEventFormUsecase.new(current_user,params[:event_id]).call
    @event  = result[:event]
  end
  
  # update event
  def update_event
    usecase = Calendar::UpdateEventUsecase.new(current_user,event_params)
    result = usecase.call
    if result[:success]
      flash[:notice] = "Event updated successfully!"
      redirect_to all_events_path
    else
     flash[:errors] = usecase.errors
     redirect_to edit_event_form_calendar_index_path
    end
  end
  
  # create event
  def create_event
    usecase = Calendar::CreateEventUsecase.new(current_user,event_params)
    result = usecase.call
    if result[:success] 
      flash[:notice] = "Event created successfully!"
      redirect_to all_events_path
    else
      flash[:errors] = result[:errors]
      redirect_to create_event_form_calendar_index_path
    end
  end

  # delete event
  def delete_event
    usecase = Calendar::DeleteEventUsecase.new(current_user,params[:event_id])
    result = usecase.call
    if result[:success]   
      flash[:notice] = "Event deleted successfully!"
      redirect_to all_events_path
    else
      flash[:errors] = result[:errors]
      redirect_to all_events_path
    end
  end
  
  private

  def load_google_calendar
    @user = current_user.decorate
    service = Google::Apis::CalendarV3::CalendarService.new
    credentials = google_credentials(@user)
  
    # if credentials is expired
    if credentials.expired?
      flash[:alert] = "Your Google session has expired. Please log in again."
      sign_out(:user)            
      reset_session           
      redirect_to new_user_session_path and return
    end
  
    service.authorization = credentials
  
    begin
      # get the list of calendars
      calendar_list = service.list_calendar_lists.items
    rescue Google::Apis::ClientError => e
      flash[:error] = "We encountered a problem while loading your Google Calendar. Please sign in again."
      redirect_to new_user_session_path and return
    rescue StandardError => e
      flash[:error] = "You must log in with a Google account to use Google services."
      redirect_to home_index_path and return
    end
  
    @events_by_day = {}
  
    # Loop through each calendar to fetch events
    calendar_list.each do |calendar|
      if action_name == "all_events" && calendar.summary.downcase.include?("holiday")
        next
      end
  
      params = {
        single_events: true,
        time_min: @first_day.rfc3339,
        time_max: @last_day.rfc3339
      }

      params[:order_by] = 'startTime' unless calendar.access_role == 'reader'
  
      begin
        events = service.list_events(calendar.id, **params)
  
        events.items.each do |event|
          start_time = event.start.date || event.start.date_time&.to_date
          next unless start_time
  
          @events_by_day[start_time] ||= []
          @events_by_day[start_time] << event
        end
      rescue Google::Apis::ClientError => e
        Rails.logger.error("Error fetching events for calendar #{calendar.id}: #{e.message}")
        next
      rescue StandardError => e
        Rails.logger.error("Unexpected error while fetching events: #{e.message}")
        next
      end
    end
  end
    
  def load_holiday_calendar
    @user = current_user.decorate
    service = Google::Apis::CalendarV3::CalendarService.new
    credentials = google_credentials(@user)
    credentials.refresh! if credentials.expired?
    service.authorization = credentials
  
    calendar_list = service.list_calendar_lists.items
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
        events = service.list_events(calendar.id, **params)
  
        events.items.each do |event|
          start_time = event.start.date || event.start.date_time&.to_date
          next unless start_time
  
          @events_by_day[start_time] ||= []
          @events_by_day[start_time] << event
        end
      rescue Google::Apis::ClientError => e
        puts "Error fetching holidays for #{calendar.summary}: #{e.message}"
      end
    end
  end
    
  def google_credentials(user)
    Google::Auth::UserRefreshCredentials.new(
      client_id: ENV['GOOGLE_CLIENT_ID'],
      client_secret: ENV['GOOGLE_CLIENT_SECRET'],
      access_token: user.google_oauth2_token,
      refresh_token: user.google_oauth2_refresh_token,
      scope: [
        'https://www.googleapis.com/auth/calendar',
        'https://www.googleapis.com/auth/calendar.events'
      ],
      expiration_time_millis: user.token_expires_at.to_i * 1000
    )
  end

  def set_calendar_range
    result = Calendar::SetCalendarRangeUsecase.new(params,action_name).call
    @today = result[:today]
    @first_day = result[:first_day]
    @last_day = result[:last_day]
  end
    
  def event_params
    params.require(:event).permit(:id, :name, :description, :start_time, :end_time)
  end

end
