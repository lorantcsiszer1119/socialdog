module DogsHelper
  def image_tag_for_dog(user, size, extra_styles = '')
    dim = user.avatar.styles[size][:geometry].gsub(/[^x0-9]+/i, '')
    dim = dim.split('x').first.to_i
    border_color = user.border_color || 'e9f1f1'
    image_tag user.avatar.url(size), { :class => 'framed', :width => dim, :height => dim,
                                       :style => "border-color: \##{border_color};#{extra_styles}" }
  end
end
