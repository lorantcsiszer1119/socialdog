module UpdatesHelper
  def pretty_body(update)
    ret = h(update.body)
    ret = auto_link(ret)
    ret = ret.gsub(/\ ?#([a-z0-9]+)/i, ' <a href="/hashtags/\\1">#\\1</a>') # hashtags
    ret = ret.gsub(/\@([a-z0-9]+)/i, '<a href="/\\1">@\\1</a>') # usernames
    ret = ret.gsub(/ ([0-9]{5})/i, ' <a href="/\\1">\\1</a>')     # zipcodes
    return ret
  end
end
