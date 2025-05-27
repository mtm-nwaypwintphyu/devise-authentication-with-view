module Calendar
  class SetCalendarRangeUsecase
    def initialize(params, action_name)
      @params = params
      @action_name = action_name
    end

    def call
      today = @params[:date].present? ? Date.parse(@params[:date]) : Date.today

      if @action_name == "all_holidays" || @action_name == "all_events"
        if @params[:month_only] == "true"
          first_day = today.beginning_of_month
          last_day = today.end_of_month
        else
          first_day = today.beginning_of_year
          last_day = today.end_of_year
        end
      else
        first_day = today.beginning_of_month
        last_day = today.end_of_month
      end

      {
        today: today,
        first_day: first_day,
        last_day: last_day
      }
    end
  end
end
