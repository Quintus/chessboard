# This script feeds the database with some sample data to work with.
# It also creates two fake mailinglists the Chessboard instance runs on.
# It requires mlmmj and Imagemagick to be installed.

require_relative "../lib/chessboard"
require "fileutils"
require "faker"

include FileUtils::Verbose

ML_ROOT_DIR = "/tmp/chessboard-mls".freeze
ML_NAMES = %w[test-ml1 test-ml-2].freeze

def sh(cmd)
  puts(cmd)
  system(cmd) || raise("Command failed with status #{$?.exitstatus}: #{cmd}")
end

def fake_user
  u                 = Chessboard::User.new
  u.uid             = Faker::Internet.user_name
  u.email           = Faker::Internet.email
  u.homepage        = Faker::Internet.url
  u.display_name    = Faker::Name.name
  u.confirmed       = true
  u.view_mode_ident = Chessboard::User::VIEWMODE2IDENT.values.sample
  u.change_password(Faker::Internet.password)
  u.save
end

def fake_tag
  t             = Chessboard::Tag.new
  t.name        = Faker::Hipster.word
  t.description = Faker::Hipster.sentence
  t.color       = Faker::Color.hex_color.sub("#", "")
  t.save
end

def create_ml(name)
  puts("/usr/bin/mlmmj-make-ml -L '#{name}' -s '#{ML_ROOT_DIR}'")
  IO.popen(["/usr/bin/mlmmj-make-ml", "-L", name, "-s", ML_ROOT_DIR], "w") do |io|
    io.puts "localhost"
    io.puts "postmaster@localhost"
    io.puts "en"
    io.close_write
  end

  unless $?.exitstatus == 0
    raise("Command failed with status #{$?.exitstatus}.")
  end

  f                  = Chessboard::Forum.new
  f.name             = name.capitalize
  f.description      = Faker::Lorem.sentence.chop
  f.mailinglist      = "#{ML_ROOT_DIR}/#{name}"
  f.ml_tag           = "[#{name}]"
  f.ml_subscribe_url = Faker::Internet.url
  f.ordernum         = rand(10)
  f.save

  # Subscribe some random people
  emails = Chessboard::User.select_map(:email).reject{ rand(2) == 1 }
  emails.each do |email|
    sh("/usr/bin/mlmmj-sub -L '#{ML_ROOT_DIR}/#{name}' -a '#{email}'")
  end
end

def fake_thread(ml, refs = [])
  author = Chessboard::User.all.sample

  mail = Mail.new do
    if rand(10) > 9
      # ML-only user without Chessboard account
      from "#{Faker::Name.name} <#{Faker::Internet.email}>"
    else
      # Regular user
      from "#{author.display_name} <#{author.email}>"
    end

    to "#{ml}@localhost"
    subject "[#{ml}] #{Faker::Lorem.sentence.chop}"
    body Faker::Lorem.paragraphs(rand(5)).join("\n\n")

    unless refs.empty? # Root post if emtpy
      in_reply_to "<#{refs.last}>"
      references refs.map{|r| "<#{r}>"}.join(" ")
    end

    if rand(30) > 28
      # Generate a screenshot as a random image to attach
      sh("import -window root -silent /tmp/cbtest.png && convert /tmp/cbtest.png -resize #{32+rand(500)}x /tmp/cbtest.png")
      add_file "/tmp/cbtest.png"
    end
  end

  mail["User-Agent"] = "#{Faker::App.name}/#{Faker::App.version}"

  if rand(5) > 2
    tags = Chessboard::Tag.select_map(:name).reject{rand(2) == 1}
    mail["X-Chessboard-Tags"] = tags.shuffle.join(",") unless tags.empty?
  end

  mail.charset = 'UTF-8'
  mail.content_transfer_encoding = '8bit'

  @post_counters ||= {}
  @post_counters[ml] ||= 0
  @post_counters[ml] += 1

  File.open("#{ML_ROOT_DIR}/#{ml}/archive/#{@post_counters[ml]}", "wb") do |f|
    f.write(mail.to_s)
  end

  # Clean up attachment file, if any
  rm_f "/tmp/cbtest.png"

  # Generate replies (but not deeper than 15 levels)
  if refs.count < 15
    rand(3).times do |i|
      fake_thread(ml, refs + [mail.message_id])
    end
  end

  mail.message_id
end

rm_rf ML_ROOT_DIR
mkdir_p ML_ROOT_DIR
10.times { fake_user }
6.times { fake_tag }
ML_NAMES.each { |mlname| create_ml(mlname) }

50.times { fake_thread(ML_NAMES.sample) }
