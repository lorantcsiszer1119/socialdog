# Methods added to this helper will be available to all templates in the application.
module ApplicationHelper
  def devland?
    RAILS_ENV == 'development'
  end
end
