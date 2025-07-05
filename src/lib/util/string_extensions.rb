# Extensions to the String class

class String
  # From:
  #https://stackoverflow.com/questions/11566094/trying-to-split-string-into-single-words-or-quoted-words-and-want-to-keep-the
  def tokenize
    self.
      split(/\s(?=(?:[^'"]|'[^']*'|"[^"]*")*$)/).
      select {|s| not s.empty? }.
      map {|s| s.gsub(/(^ +)|( +$)|(^["']+)|(["']+$)/,'')}
  end
end
