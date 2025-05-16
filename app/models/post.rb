class Post < ApplicationRecord
  after_create :generate_full_post_pdf_report
  belongs_to :user
  validates :title, presence: true
  validates :content, presence: true

  private

  def generate_full_post_pdf_report
    GeneratePdfReportJob.perform_later
  end
end
