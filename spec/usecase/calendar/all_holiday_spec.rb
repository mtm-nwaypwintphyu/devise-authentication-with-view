require 'rails_helper'

RSpec.describe Calendar::AllHolidaysUsecase do
  subject { described_class.new(params, action_name).call }

  let(:date_str) { '2025-05-22' }
  let(:parsed_date) { Date.parse(date_str) }

  context 'when date param is present' do
    let(:params) { { date: date_str } }

    context 'when action_name is all_holidays or all_events' do
      [ 'all_holidays', 'all_events' ].each do |action|
        context "and action_name is #{action}" do
          let(:action_name) { action }

          context 'and month_only is true' do
            let(:params) { { date: date_str, month_only: 'true' } }

            it 'returns first and last day of the month' do
              result = subject
              expect(result[:today]).to eq(parsed_date)
              expect(result[:first_day]).to eq(parsed_date.beginning_of_month)
              expect(result[:last_day]).to eq(parsed_date.end_of_month)
            end
          end

          context 'and month_only is not true' do
            let(:params) { { date: date_str, month_only: 'false' } }

            it 'returns first and last day of the year' do
              result = subject
              expect(result[:today]).to eq(parsed_date)
              expect(result[:first_day]).to eq(parsed_date.beginning_of_year)
              expect(result[:last_day]).to eq(parsed_date.end_of_year)
            end
          end
        end
      end
    end

    context 'when action_name is something else' do
      let(:action_name) { 'other_action' }

      it 'returns first and last day of the month' do
        result = subject
        expect(result[:today]).to eq(parsed_date)
        expect(result[:first_day]).to eq(parsed_date.beginning_of_month)
        expect(result[:last_day]).to eq(parsed_date.end_of_month)
      end
    end
  end

  context 'when date param is not present' do
    let(:params) { {} }
    let(:action_name) { 'all_holidays' }

    it 'uses Date.today for calculations' do
      today = Date.today
      result = subject
      expect(result[:today]).to eq(today)
      expect(result[:first_day]).to eq(today.beginning_of_year)
      expect(result[:last_day]).to eq(today.end_of_year)
    end
  end
end
