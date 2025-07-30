# Extensions to the String class

class String
  # From:
  #https://stackoverflow.com/questions/11566094/trying-to-split-string-into-single-words-or-quoted-words-and-want-to-keep-the
  # Tokenizes a string into an array of words, respecting single and
  # double quotes.
  #
  # This method splits the string by whitespace, but treats content within
  # single or double quotes as a single token, even if it contains spaces.
  # It also removes leading/trailing whitespace and any surrounding quotes
  # from the resulting tokens.
  #
  # @example Basic usage
  #   "word1 word2 'quoted phrase' "another one"".tokenize
  #   # => ["word1", "word2", "quoted phrase", "another one"]
  #
  # @example Handling multiple spaces and empty tokens
  #   "  word1   word2  ".tokenize
  #   # => ["word1", "word2"]
  #
  # @example Handling mixed quotes
  #   "It's a "beautiful day"".tokenize
  #   # => ["It's", "a", "beautiful day"]
  #
  # @return [Array<String>] An array of tokenized strings.
  def tokenize
    self.
      split(/\s(?=(?:[^'"]|'[^']*'|"[^"]*")*$)/).
      select {|s| not s.empty? }.
      map {|s| s.gsub(/(^ +)|( +$)|(^["']+)|(["']+$)/,'')}
  end
end
