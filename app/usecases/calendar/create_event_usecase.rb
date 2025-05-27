module Calendar
  class CreateEventUsecase
    attr_reader :errors

    def initialize(user, event_params)
      @user = user
      @event_params = event_params
      @errors = {}
    end

    def call
      validate_params
      return { success: false, errors: @errors } if @errors.any?

      service = Google::Apis::CalendarV3::CalendarService.new
      service.authorization = @user.google_oauth2_token
      event = Google::Apis::CalendarV3::Event.new(
        summary: @event_params[:name],
        description: @event_params[:description],
        start: Google::Apis::CalendarV3::EventDateTime.new(
          date_time: @event_params[:start_time].to_datetime.rfc3339,
          time_zone: "Asia/Yangon"
        ),
        end: Google::Apis::CalendarV3::EventDateTime.new(
          date_time: @event_params[:end_time].to_datetime.rfc3339,
          time_zone: "Asia/Yangon"
        )
      )
      event = service.insert_event("primary", event)
      { success: true, event: event }
    rescue Google::Apis::Error => e
      { success: false, errors: { api: "Failed to create event: #{e.message}" } }
    end

    private

    def validate_params
      @errors[:name] = "Name can't be blank" if @event_params[:name].blank?
      @errors[:description] = "Description can't be blank" if @event_params[:description].blank?
      @errors[:start_time] = "Start time can't be blank" if @event_params[:start_time].blank?
      @errors[:end_time] = "End time can't be blank" if @event_params[:end_time].blank?

      if @event_params[:start_time].present? && @event_params[:end_time].present?
        start_time = DateTime.parse(@event_params[:start_time]) rescue nil
        end_time = DateTime.parse(@event_params[:end_time]) rescue nil

        if start_time && end_time && start_time >= end_time
          @errors[:start_time] = "Start time must be before end time"
        end
      end
    end
  end
end
