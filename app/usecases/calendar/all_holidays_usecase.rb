module Calendar
  class AllHolidaysUsecase
    def initialize(params, action_name)
      @params = params
      @action_name = action_name
    end

    def call
      today = parse_date(@params)

      first_day, last_day =
        if ["all_holidays", "all_events"].include?(@action_name)
          if @params[:month_only] == "true"
            [today.beginning_of_month, today.end_of_month]
          else
            [today.beginning_of_year, today.end_of_year]
          end
        else
          [today.beginning_of_month, today.end_of_month]
        end

      {
        today: today,
        first_day: first_day,
        last_day: last_day
      }
    end

    private

    def parse_date(params)
      params[:date].present? ? Date.parse(params[:date]) : Date.today
    end
  end
end
