#!/usr/bin/perl
use strict;
use warnings;
use autodie;

use FindBin;
use Path::Tiny;
use YAML qw(Dump Load DumpFile LoadFile);

my $forest;

if (defined $ARGV[0] and path($ARGV[0])->is_file) {
    $forest = path($ARGV[0])->slurp;
    if (defined $ARGV[1] and path($ARGV[1])->is_file) {
        my @trans = path($ARGV[1])->lines({chomp => 1});
        for my $tran (@trans) {
            my ($from, $to) = split /,/, $tran;
            next unless defined $from and defined $to;
            $forest =~ s/\b$from\b/$to/g;
        }
    }
}

my $template = path($FindBin::RealBin, "template.tex")->slurp;

if (defined $forest) {
    $template =~ s/\%BEGIN.+\%END/$forest/s;
}

path("out.tex")->spew($template);

__END__
