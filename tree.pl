#!/usr/bin/perl
use strict;
use warnings;
use autodie;

use FindBin;
use Path::Tiny;
use YAML qw(Dump Load DumpFile LoadFile);

my $forest;
my $outdir = ".";
my $outbase = "template";

if (defined $ARGV[0] and path($ARGV[0])->is_file) {
    $forest = path($ARGV[0])->slurp;
    $outdir = path($ARGV[0])->parent->absolute->stringify;
    $outbase = path($ARGV[0])->basename(".forest", ".tree");
    if (defined $ARGV[1] and path($ARGV[1])->is_file) {
        $outbase .= ".trans";
        my @trans = path($ARGV[1])->lines({chomp => 1});
        for my $tran (@trans) {
            my ($from, $to) = split /,/, $tran;
            next unless defined $from and defined $to;
            $forest =~ s/\b$from\b/$to/gi;
        }
    }
}

my $template = path($FindBin::RealBin, "template.tex")->slurp;

if (defined $forest) {
    $template =~ s/\%BEGIN.+\%END/$forest/s;
}

my $outfile = path($outdir, $outbase . ".tex" )->stringify;
path($outfile)->spew($template);

chdir $outdir;
system "latexmk -xelatex $outfile";
system "latexmk -c $outfile";

__END__
