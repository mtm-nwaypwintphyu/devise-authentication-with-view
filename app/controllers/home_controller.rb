class HomeController < ApplicationController
  helper_method :resource_name, :resource_class

  def resource_name
    :user
  end

  def resource_class
    User
  end
end
