Chessboard::App.mailer :personal_messages do

  email :pm_email do |email, nickname, authorname, title, boardlink|
    from "automailer@" + Chessboard.config.domain
    to email
    subject "New PM received"
    locals :nickname => nickname, :authorname => authorname, :title => title, :boardlink => boardlink
    render "personal_messages/pm_email"
  end

  email :pp_email do |email, nickname, authorname, title, boardlink|
    from "automailer@" + Chessboard.config.domain
    to email
    subject "PM reply received"
    locals :nickname => nickname, :authorname => authorname, :title => title, :boardlink => boardlink
    render "personal_messages/pp_email"
  end

end
