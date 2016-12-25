#!/usr/bin/perl
use strict;
use warnings;
use autodie;

use Getopt::Long;
use FindBin;
use YAML::Syck;

use Path::Tiny;
use Bio::Phylo::IO;
use List::Util;

#----------------------------------------------------------#
# GetOpt section
#----------------------------------------------------------#

=head1 NAME

tree.pl - newick to tikz/forest

=head1 SYNOPSIS

    perl tree.pl <infile> [options]
      Options:
        --help          -?          brief help message
        --format        -f  STR     Bio::Phylo supported tree formats, default is [newick]
        --out           -o  STR     output filename, default is [infile =~ s/\.\w+/.forest/]
                                    stdout for screen

=cut

GetOptions(
    'help|?' => sub { Getopt::Long::HelpMessage(0) },
    'format|f=s' => \( my $format = "newick" ),
    'out|o=s' => \( my $outfile ),
) or Getopt::Long::HelpMessage(1);

my $contents;

if ( !defined $ARGV[0] ) {
    die "Need a newick file\n";
}
elsif ( lc $ARGV[0] eq "stdin" ) {
    $contents = do { local $/; <STDIN> };
}
elsif ( !path( $ARGV[0] )->is_file ) {
    die "$ARGV[0] doesn't exist\n";
}
else {
    $contents = path( $ARGV[0] )->slurp;
}

if ( !defined $outfile ) {
    $outfile = $ARGV[0];
    $outfile =~ s/\.\w+$/.forest/;
}

# latex panics with underscores
$contents =~ s/_/-/g;

#----------------------------------------------------------#
# Run
#----------------------------------------------------------#

#@type Bio::Phylo::Forest::Tree
my $tree = Bio::Phylo::IO->parse( -string => $contents, -format => $format )->next;

my $max_depth = $tree->get_tallest_tip->calc_nodes_to_root;
warn YAML::Syck::Dump {
    max_depth => $max_depth,
    outfile   => $outfile,
};

my $out_string;
$out_string .= "[\n";
$tree->visit_breadth_first(
    -order           => 'rtl',
    '-pre_daughter'  => sub { $out_string .= "\n"; },
    '-post_daughter' => sub {
        my $str;
        $str        .= " " x 4 x shift->calc_nodes_to_root;
        $str        .= "]\n";
        $out_string .= $str;
    },
    '-in' => sub {

        #@type Bio::Phylo::Forest::Node
        my $node = shift;

        my $depth         = $node->calc_nodes_to_root;
        my @depths        = map { $_->calc_nodes_to_root } @{ $node->get_terminals };
        my $reverse_depth = List::Util::max(@depths) - $depth;
        if ( $node->is_internal ) {
            my $str;
            $str .= " " x 4 x $depth;
            $str .= "[";
            if ( length $node->get_name ) {
                $str .= ", label=" . $node->get_name;
                $str .= ", dot";
            }
            $str .= ", tier=" . $reverse_depth;
            $out_string .= $str;
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
            $out_string .= $str;
        }
    },
);
$out_string .= "]\n";

if ( lc $outfile eq "stdout" ) {
    print $out_string;
}
else {
    path($outfile)->spew($out_string);
}

__END__
