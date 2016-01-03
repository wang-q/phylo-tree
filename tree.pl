#!/usr/bin/perl
use strict;
use warnings;
use autodie;

use Getopt::Long qw(HelpMessage);
use FindBin;
use YAML qw(Dump Load DumpFile LoadFile);

use Path::Tiny;
use Bio::Phylo::IO;
use List::Util qw(max);

#----------------------------------------------------------#
# GetOpt section
#----------------------------------------------------------#

=head1 NAME

tree.pl - newick to tikz/forest

=head1 SYNOPSIS

    perl tree.pl <newick file> [options]
      Options:
        --help          -?          brief help message
        --format        -f  STR     Bio::Phylo supported tree formats, default is [newick]

=cut

my $file;
my $outfile;

GetOptions(
    'help|?' => sub { HelpMessage(0) },
    'format|f=s' => \( my $format = "newick" ),
) or HelpMessage(1);

if ( !defined $ARGV[0] ) {
    die "Need a newick file\n";
}
elsif ( !path( $ARGV[0] )->is_file ) {
    die "$ARGV[0] doesn't exist\n";
}
else {
    $file = path( $ARGV[0] )->absolute->stringify;
    my $outdir = path($file)->parent->absolute->stringify;
    my $outbase = path($file)->basename( ".newick", ".nwk", ".nw", ".nh" );
    $outfile = path( $outdir, $outbase . ".forest" );
    $outfile->remove;
}

#----------------------------------------------------------#
# Run
#----------------------------------------------------------#

my $tree = Bio::Phylo::IO->parse( -file => $file, -format => $format )->next;

my $max_depth = $tree->get_tallest_tip->calc_nodes_to_root;
warn Dump {
    max_depth => $max_depth,
    outfile   => $outfile->stringify
};

$outfile->append("[\n");
$tree->visit_breadth_first(
    -order           => 'rtl',
    '-pre_daughter'  => sub { $outfile->append("\n"); },
    '-post_daughter' => sub {
        my $str;
        $str .= " " x 4 x shift->calc_nodes_to_root;
        $str .= "]\n";
        $outfile->append($str);
    },
    '-in' => sub {
        my $node = shift;

        #return if $node->is_internal;
        my $depth         = $node->calc_nodes_to_root;
        my @depths        = map { $_->calc_nodes_to_root } @{ $node->get_terminals };
        my $reverse_depth = max(@depths) - $depth;
        if ( $node->is_internal ) {
            my $str;
            $str .= " " x 4 x $depth;
            $str .= "[";
            if ( length $node->get_name ) {
                $str .= ", label=" . $node->get_name;
                $str .= ", dot";
            }
            $str .= ", tier=" . $reverse_depth;
            $outfile->append($str);
        }
        else {
            my $str;
            $str .= " " x 4 x $depth;
            $str .= "[";
            $str .= $node->get_name;
            if ( $reverse_depth != 0 ) {
                $str .= ", tier=" . $reverse_depth;
            }
            $str .= "]\n";
            $outfile->append($str);
        }
    },
);
$outfile->append("]\n");
