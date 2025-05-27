# create pdf documents
require "prawn"

class GeneratePdfReportJob < ApplicationJob
  queue_as :default

  def perform
    # create pdf doc object using prawn
    pdf = Prawn::Document.new
    # add text with style
    pdf.text "Post Report", size: 20, style: :bold
    pdf.move_down 10

    Post.find_each do |post|
      pdf.text "Title: #{post.title}"
      pdf.text "Body: #{post.content}"
      pdf.move_down 10
    end

    # writing pdf to a file
    # open/create post_report.pdf in public folder
    # wb mode> write in binary mode
    File.open(Rails.root.join("public", "post_report.pdf"), "wb") do |f|
      # generate binary pdf data
      f.write(pdf.render)
    end
  end
end
