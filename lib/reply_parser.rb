module ReplyParser
  def parse_recipient!(micropost)
    return micropost unless micropost.content[0] == '@'

    target                 = micropost.content[1..16].match(/\A(\w|\.|-)+/i)[0]
    recipient              = User.find_by(username: target)
    @micropost.to_id = recipient.id unless recipient.nil?
  end
end
