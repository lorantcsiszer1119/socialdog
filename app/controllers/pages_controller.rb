class PagesController < ApplicationController
  def static_page
    safe_slug     = params[:slug].gsub(/[^-_a-z]+/, '')
    @no_landscape = true
    @page_class   = 'pages'
    @page_title   = safe_slug.capitalize
    render "pages/#{safe_slug}"
  end
end
