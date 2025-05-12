
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