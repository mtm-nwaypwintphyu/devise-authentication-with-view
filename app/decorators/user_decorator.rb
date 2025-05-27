class UserDecorator < Draper::Decorator
  delegate_all

  def full_name
    [ object.first_name, object.last_name ].compact.join(" ")
  end


  def formatted_email
    h.mail_to(object.email, object.email)
  end

  def formatted_created_at
    object.created_at.strftime("%m-%d-%Y")
  end

  def formatted_updated_at
    object.updated_at.strftime("%m-%d-%Y")
  end
end
