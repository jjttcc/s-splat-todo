require 'ruby-enum'

# Supporting structure and facilities for FileType objects
#!!!!!REMINDER: Move this item to its own separate file!!!!!
class FileTypeSkeleton
  include Ruby::Enum

  public

  # enum/symbols for main media types
  define  :msword,             'ms-word'
  define  :msexcel,             'ms-excel'
  define  :video,              'video'
  define  :audio,              'audio'
  define  :plain_text,         'plain-text'
  define  :pdf,                'pdf'
  define  :image,              'image'
  define  :executable,  'binary-executable'
  define  :html,               'text-html'

  @@regexes_for = {
    :msword      => [ Regexp.new("application/msword") ],
    :msexcel     => [ Regexp.new("application/vnd.ms-excel") ],
    :openspread  => [
      Regexp.new("application/vnd.oasis.opendocument.spreadsheet") ],
    :openxml     => [ Regexp.new(
      "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet") ],
    :executable  => [ Regexp.new("application/x-pie-executable"),
                      Regexp.new("application/x-executable"), ],
    :plain_text  => [ Regexp.new("") ],
    :msword      => [ Regexp.new("") ],
    :msword      => [ Regexp.new("") ],
    :msword      => [ Regexp.new("") ],
    :msword      => [ Regexp.new("") ],
    :msword      => [ Regexp.new("") ],
  }

=begin
# some different media types, according to 'file -i':
application/vnd.oasis.opendocument.spreadsheet; charset=binary
application/vnd.ms-excel; charset=binary
application/msword; charset=binary
application/x-pie-executable; charset=binary
application/vnd.openxmlformats-officedocument.spreadsheetml.sheet; charset=binary
text/plain; charset=us-ascii
application/pdf; charset=binary
audio/mpeg; charset=binary
audio/ogg; charset=binary
video/mp4; charset=binary
video/mpeg; charset=binary
text/x-shellscript; charset=us-ascii
Bourne-Again shell script, ASCII text executable
=end
=begin
OpenDoc.ods: application/vnd.oasis.opendocument.spreadsheet; charset=binary
INETR_Test_Matrix-V5.xls: application/vnd.ms-excel; charset=binary
cochranebill.doc: application/msword; charset=binary
ls: application/x-pie-executable; charset=binary
cam_performance_ZOTEC_20151220-20160312.xlsx: application/vnd.openxmlformats-officedocument.spreadsheetml.sheet; charset=binary
README.txt: text/plain; charset=us-ascii
Heart-Sutra-for-website.pdf: application/pdf; charset=binary
gusty-wind.mp3: audio/mpeg; charset=binary
steinway_imis_2.1_2007-07-03.ogg: audio/ogg; charset=binary
Lin.mp4: video/mp4; charset=binary
101.mpg: video/mpeg; charset=binary
/bin/google-chrome: text/x-shellscript; charset=us-ascii
/bin/google-chrome: Bourne-Again shell script, ASCII text executable
=end
end

=begin
references:
https://www.linux.org/threads/supported-libreoffice-files.11348/
=end

# "type" of specific files, based on the type of application (e.g., text
# editor, video-player, audio-player, MS-Word, etc.) needed to "process"
# the file.
class FileType
end
=begin
# file types:
/bin/ls: application/x-pie-executable
/bin/google-chrome: text/x-shellscript
/bin/google-chrome: inode/symlink
consent.pdf: application/pdf
2022-01-12-140100.webm: video/webm
Screenshot_20220620_000226.png: image/png
8f4e495311d8ded72d419e8d94e9af887f0d4dde-1.jpeg: image/jpeg
src/core/stodotarget.rb: text/x-ruby
/etc/pki/nssdb/pkcs11.txt: text/plain
BBB1_botanic-gardens-1987.mp3: audio/mpegapplication/octet-stream
=end
