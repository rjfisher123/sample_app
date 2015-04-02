atom_feed do |feed|
  feed.title @user.name
  feed.description "Recent posts"
  feed.link user_url(@user)

    @user.microposts.each do |micropost|
      feed.entry(micropost) do |entry|
        entry.title("#{micropost.content[0..10]}...")
        entry.content(micropost.content, :type => 'html')
        entry.pubDate(micropost.created_at.to_s(:rfc822), :type => 'html')
        entry.author(@user.username, :type => 'html')
      end
    end 

end