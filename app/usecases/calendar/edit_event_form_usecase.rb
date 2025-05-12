module Calendar
  class EditEventFormUsecase
    def initialize(user,event_id)
      @event_id = event_id
      @user = user
    end

    def call
      service = Google::Apis::CalendarV3::CalendarService.new
      service.authorization = @user.google_oauth2_token
      event = service.get_event('primary', @event_id)
      { event: event } 
    
    rescue Google::Apis::Error => e
      { event:  nil, error: e.message}
    end

  end
end