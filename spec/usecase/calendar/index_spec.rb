require 'rails_helper'

RSpec.describe Calendar::IndexUsecase do
  describe '#call' do
    subject { described_class.new(params).call }

    context 'when :date param is present and valid' do
      let(:params) { { date: '2025-05-15' } }

      it 'returns first_day and last_day for that date\'s month and today' do
        result = subject
        expect(result[:first_day]).to eq(Date.new(2025, 5, 1))
        expect(result[:last_day]).to eq(Date.new(2025, 5, 31))
        expect(result[:today]).to eq(Date.today)
      end
    end

    context 'when :date param is present but invalid' do
      let(:params) { { date: 'invalid-date' } }

      it 'returns first_day and last_day for current month and today' do
        today = Date.today
        result = subject
        expect(result[:first_day]).to eq(today.beginning_of_month)
        expect(result[:last_day]).to eq(today.end_of_month)
        expect(result[:today]).to eq(today)
      end
    end

    context 'when :date param is not present but valid :month and :year given' do
      let(:params) { { month: '3', year: '2024' } }

      it 'returns first_day and last_day for given month/year and today' do
        result = subject
        expect(result[:first_day]).to eq(Date.new(2024, 3, 1))
        expect(result[:last_day]).to eq(Date.new(2024, 3, 31))
        expect(result[:today]).to eq(Date.today)
      end
    end

    context 'when :date param is not present and month is invalid' do
      let(:params) { { month: '99', year: '2024' } }

      it 'defaults month to current month' do
        today = Date.today
        result = subject
        expect(result[:first_day].month).to eq(today.month)
        expect(result[:last_day].month).to eq(today.month)
      end
    end

    context 'when :date param is not present and year is invalid' do
      let(:params) { { month: '5', year: '3000' } }

      it 'defaults year to current year' do
        today = Date.today
        result = subject
        expect(result[:first_day].year).to eq(today.year)
        expect(result[:last_day].year).to eq(today.year)
      end
    end

    context 'when no params given' do
      let(:params) { {} }

      it 'defaults to current month and year' do
        today = Date.today
        result = subject
        expect(result[:first_day]).to eq(today.beginning_of_month)
        expect(result[:last_day]).to eq(today.end_of_month)
        expect(result[:today]).to eq(today)
      end
    end
  end
end
