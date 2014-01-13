require 'digest/md5'

xml.instruct! :xml, :version => "1.0"
xml.rss :version => "2.0" do
  xml.channel do
    xml.title "My Social Dog / #{@page_title}"
    xml.description "My Social Dog is the first social network to connect local dog owners in real-time. It links together neighbors, giving them the ability to chat and set up playdates on the fly."
    xml.link 'http://www.mysocialdog.com/'

    unless !@updates || @updates.empty?
      for update in @updates
        xml.item do
          xml.title "#{update.user.login}: #{update.body}"
          xml.guid Digest::MD5.hexdigest(update.id.to_s)
          xml.description "#{update.user.login}: #{update.body}"
          xml.pubDate update.created_at.to_s(:rfc822)
          xml.link "http://www.mysocialdog.com/#{update.user.login}/updates/#{update.id}"
        end
      end
    end
  end
end