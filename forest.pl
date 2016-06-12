#!/usr/bin/perl
use strict;
use warnings;
use autodie;

use Getopt::Long qw(HelpMessage);
use FindBin;
use YAML qw(Dump Load DumpFile LoadFile);

use Path::Tiny;

#----------------------------------------------------------#
# GetOpt section
#----------------------------------------------------------#

=head1 NAME

forest.pl - tikz/forest to tex

=head1 SYNOPSIS

    perl forest.pl <forest file> [options]
      Options:
        --help          -?          brief help message
        --trans         -t  STR     translation file, csv
        --append        -a          append translations
        --reverse       -r          tree directrion
        --pdf           -p          create pdf with xelatex

=cut

GetOptions(
    'help|?'    => sub { HelpMessage(0) },
    'trans|t=s' => \( my $translation ),
    'append|a'  => \( my $append ),
    'reverse|r' => \( my $reverse ),
    'pdf|p'     => \( my $create_pdf ),
) or HelpMessage(1);

my $forest;
my $outdir  = ".";
my $outbase = "template";

if ( defined $ARGV[0] and path( $ARGV[0] )->is_file ) {
    $forest  = path( $ARGV[0] )->slurp;
    $outdir  = path( $ARGV[0] )->parent->absolute->stringify;
    $outbase = path( $ARGV[0] )->basename( ".forest", ".tree" );
}

#----------------------------------------------------------#
# Run
#----------------------------------------------------------#

if ( defined $translation and path($translation)->is_file ) {
    $outbase .= ".trans";
    my @trans = path($translation)->lines( { chomp => 1 } );
    for my $tran (@trans) {
        my ( $from, $to ) = split /,/, $tran;
        next unless defined $from and defined $to;
        if ($append) {
            $forest =~ s/\b$from\b/$from $to/gi;
        }
        else {
            $forest =~ s/\b$from\b/$to/gi;
        }
    }
}

my $template = path( $FindBin::RealBin, "template.tex" )->slurp;

if ( defined $forest ) {
    $template =~ s/\%BEGIN.+\%END/$forest/s;
}

if ($reverse) {
    if ( $template =~ s/\s+^.*tree_direction.*$//m ) {
        warn "Draw reverse tree\n";
    }
}

my $outfile = path( $outdir, $outbase . ".tex" )->stringify;
path($outfile)->spew($template);

if ($create_pdf) {
    chdir $outdir;
    system "latexmk -xelatex $outfile";
    system "latexmk -c $outfile";
}

__END__
