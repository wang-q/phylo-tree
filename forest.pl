#!/usr/bin/perl
use strict;
use warnings;
use autodie;

use Getopt::Long;
use FindBin;
use YAML::Syck;

use Path::Tiny;

#----------------------------------------------------------#
# GetOpt section
#----------------------------------------------------------#

=head1 NAME

forest.pl - tikz/forest to tex

=head1 SYNOPSIS

    perl forest.pl <infile> [options]
        <infile> is a forest file, stdin for STDIN.
      Options:
        --help          -?          brief help message
        --trans         -t  STR     translation file, csv
        --append        -a          append translations
        --reverse       -r          tree directrion
        --pdf           -p          create pdf with xelatex

=cut

GetOptions(
    'help|?'    => sub { Getopt::Long::HelpMessage(0) },
    'trans|t=s' => \( my $translation ),
    'append|a'  => \( my $append ),
    'reverse|r' => \( my $reverse ),
    'pdf|p'     => \( my $create_pdf ),
) or Getopt::Long::HelpMessage(1);

my $forest;
my $outdir  = ".";
my $outbase = "output";

if ( defined $ARGV[0] ) {
    if ( lc $ARGV[0] eq "stdin" ) {
        $forest = do { local $/; <STDIN> };
    }
    elsif ( path( $ARGV[0] )->is_file ) {
        $forest  = path( $ARGV[0] )->slurp;
        $outdir  = path( $ARGV[0] )->parent->absolute->stringify;
        $outbase = path( $ARGV[0] )->basename( ".forest", ".tree" );
    }
}

# print YAML::Syck::Dump($forest);

#----------------------------------------------------------#
# Run
#----------------------------------------------------------#

my $template = path( $FindBin::RealBin, "template.tex" )->slurp;

if ( defined $forest and $forest =~ /\[/ ) {
    if ( defined $translation and path($translation)->is_file ) {
        $outbase .= ".trans";
        my @lines = path($translation)->lines( { chomp => 1 } );
        for my $line (@lines) {
            next if $line =~ /^#/;
            my ( $from, $to ) = split /,/, $line;
            next unless defined $from and defined $to;
            if ($append) {
                $forest =~ s/\b$from\b/$from $to/gi;
            }
            else {
                $forest =~ s/\b$from\b/$to/gi;
            }
        }
    }

    $template =~ s/\%BEGIN.+\%END/$forest/s;
}

if ($reverse) {
    $template =~ s/\s+^.*tree_direction.*$//m;
}

my $outfile = path( $outdir, $outbase . ".tex" )->stringify;
path($outfile)->spew($template);

if ($create_pdf) {
    chdir $outdir;
    system "latexmk -xelatex $outfile";
    system "latexmk -c $outfile";
}

__END__
