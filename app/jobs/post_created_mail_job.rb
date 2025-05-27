class PostCreatedMailJob < ApplicationJob
  queue_as :default

  def perform(params)
    user = params[:user]
    title = params[:title]
    PostMailer.create_email(user, title).deliver_later
  end
end
