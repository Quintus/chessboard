folder = Padrino.root("public", "images", "emoticons",  Chessboard.config.emoticons_set)

Chessboard.config.emoticons = Dir["#{folder}/*.gif"].map{|f| File.basename(f).match(/\..*?$/).pre_match}
Chessboard.config.extended_emoticons_regexp = Regexp.union(Chessboard.config.emoticons.map{|e| Regexp.escape(":#{e}:")})
