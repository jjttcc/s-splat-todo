#!/bin/perl

use Modern::Perl;
use Date::Manip;
use Data::Dumper;

my $separator = "";
if (@ARGV == 0) { exit 0; }
my $dateparser = Date::Manip::Date->new;
my $i = 0;
my $date_strings = [];
while ($i < @ARGV) {
    my $err = $dateparser->parse($ARGV[$i]);
    if ($err != 0) {
        push @$date_strings, '<failed>';
    } else {
        push @$date_strings, $dateparser->printf("%Y-%m-%d %H:%M");
    }
    ++$i;
}
print join($separator, @$date_strings), "\n";
