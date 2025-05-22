require 'rails_helper'

RSpec.describe Post, type: :model do
  # check factory
  it 'has a valid factory' do
    expect(build(:post)).to be_valid
  end

  # test assocaition
  describe 'association' do
    it { should belong_to(:user) }
  end

  # test validation
  describe 'validation' do
    it { should validate_presence_of(:title)}
    it { should validate_presence_of(:content)}
  end

  # test background jobs
  describe 'callbacks' do
    let(:user) { create(:user)}
    it 'enqueues generate report pdf job after create' do
      ActiveJob::Base.queue_adapter = :test # makes possible test to detect background jobs
      expect{
        create(:post,user: user)
    }.to have_enqueued_job(GeneratePdfReportJob)
    end
  end
end 