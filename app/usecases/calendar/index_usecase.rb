# app/usecases/calendar/index_usecase.rb
module Calendar
  class IndexUsecase
    def initialize(params)
      @params = params
    end

    def call
      date = parse_date(@params)
      {
        first_day: date.beginning_of_month,
        last_day: date.end_of_month,
        today: Date.today
      }
    end

    private

    def parse_date(params)
      if params[:date].present?
        begin
          Date.parse(params[:date])
        rescue
          Date.today
        end
      else
        month = (1..12).include?(params[:month].to_i) ? params[:month].to_i : Date.today.month
        year = (1900..2100).include?(params[:year].to_i) ? params[:year].to_i : Date.today.year
        Date.new(year, month, 1)
      end
    end
  end
end
