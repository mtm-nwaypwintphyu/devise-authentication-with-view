module Calendar
  class DeleteEventUsecase
    def initialize(user, event_id)
      @event_id = event_id
      @user = user
    end

    def call
      service = Google::Apis::CalendarV3::CalendarService.new
      service.authorization = @user.google_oauth2_token

      begin 
        service.delete_event('primary', @event_id)
        { success: true } 
      rescue Google::Apis::Error => e 
        { success: false, errors: { api: "Failed to delete event: #{e.message}" } }
      end
    end
  end
end