class PdfReportService
  def initialize
    @posts = posts
  end

  def generate
    html = ApplicationController.render(
      template: "posts/pdf_report",
      layout: "pdf",
      assigns: { posts: @posts }
    )

    WickedPdf.new.pdf_form_string(html)
  end
end
