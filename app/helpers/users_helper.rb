module UsersHelper
  def image_tag_for_user(user, size)
    return image_tag_for_brand_logo(user, size) if user.is_brand?
    dim = user.avatar.styles[size][:geometry].gsub(/[^x0-9]+/i, '')
    dim = dim.split('x').first.to_i
    image_tag user.avatar.url(size), { :class => 'framed', :width => dim, :height => dim }
  end
  
  def image_tag_for_brand_logo(user, size, opts = {})
    if size != :original
      dim = user.logo.styles[size][:geometry].gsub(/[^x0-9]+/i, '')
      dim = dim.split('x').first.to_i
    else
      dim = 'auto'
    end
    wdim, hdim = dim, dim
    wdim = opts[:width] if opts[:width]
    hdim = opts[:height] if opts[:height]
    image_tag (size == :original ? user.logo.url : user.logo.url(size)), { :class => 'framed', :width => wdim, :height => hdim }
  end
end
