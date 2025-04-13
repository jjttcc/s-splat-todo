require 'os'

class SystemTools
  def self.rss_kbytes_used
    OS.rss_bytes
  end
end
