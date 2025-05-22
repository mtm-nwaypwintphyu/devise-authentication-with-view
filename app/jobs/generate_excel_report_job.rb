require 'axlsx'

class GenerateExcelReportJob 
  include Sidekiq::Worker

  def perform(user_id)
    user = User.find(user_id)
    users = User.all

    # initialize a new excel workbook package
    package = Axlsx::Package.new

    # get the workbook object
    workbook = package.workbook

    # add work sheet name
    workbook.add_worksheet(name: "Users") do |sheet|
      #  add header row with columns title
      sheet.add_row ["First Name", "Last Name", "Email", "Created date"]

      users.each do |user|
        sheet.add_row [user.first_name, user.last_name, user.email, user.created_at.strftime("%Y-%m-%d %H:%M")]
      end
    end

    # save the file in tmp/user_report.xlsx path
    file_path = Rails.root.join("tmp", "user_report.xlsx")
    package.serialize(file_path)

  end

end
