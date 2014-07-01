Chessboard::App.mailer :user do

  email :warning_email do |email, nickname, modname, text, boardlink|
    from "automailer@" + Chessboard.config.domain
    to email
    subject "You received a warning"
    locals :nickname => nickname, :modname => modname, :text => text, :boardlink => boardlink
    render "user/warning_email"
  end

end
