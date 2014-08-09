# -*- coding: utf-8 -*-
Chessboard::App.mailer :posts do

  email :watch_email do |email, nickname, post, posturl, topicurl, boardlink|
    from "automailer@" + Chessboard.config.domain
    to email
    subject "New reply to topic “#{post.topic.title}”"
    locals :nickname => nickname, :post => post, :posturl => posturl, :topicurl => topicurl, :boardlink => boardlink
    render "posts/watch_email"
  end

end
