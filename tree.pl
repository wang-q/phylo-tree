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
        <infile> is a (newick) tree file, stdin for STDIN.
      Options:
        --help      -?          brief help message
        --format    -f  STR     Bio::Phylo supported tree formats, default is [newick]
        --wbl       -w          with branch lengths
        --out       -o  STR     output filename, default is [infile =~ s/\.\w+/.forest/]
                                stdout for screen

=cut

GetOptions(
    'help|?' => sub { Getopt::Long::HelpMessage(0) },
    'format|f=s' => \( my $format = "newick" ),
    'wbl|w'      => \( my $wbl ),
    'out|o=s'    => \( my $outfile ),
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

my @tips      = @{ $tree->get_terminals() };
my $max_depth = List::Util::max( map { depth_to_root($_) } @tips );
my $max_path  = List::Util::max( map { path_to_root($_) } @tips );

# clades have no branch lengths
if ( $max_path and $wbl ) {
    $wbl = 1;
}
else {
    $wbl = 0;
}

warn YAML::Syck::Dump {
    max_depth           => $max_depth,
    with_branch_lengths => $wbl,
    max_path            => $max_path,
    outfile             => $outfile,
};

my $out_string;
$out_string .= "[\n";
$tree->visit_breadth_first(
    -order           => 'rtl',
    '-pre_daughter'  => sub { $out_string .= "\n"; },
    '-post_daughter' => sub {

        #@type Bio::Phylo::Forest::Node
        my $node = shift;

        my $depth = depth_to_root( $node, 1 );

        my $str;
        $str        .= " " x 4 x $depth;
        $str        .= "]\n";
        $out_string .= $str;
    },
    '-in' => sub {

        #@type Bio::Phylo::Forest::Node
        my $node = shift;

        my $cur_depth = depth_to_root( $node, 1 );

        #        warn YAML::Syck::Dump {
        #            cur_depth => $cur_depth,
        #            cur_path  => $cur_path,
        #        };

        my ( $tier, $branch_length );
        if ($wbl) {
            $branch_length = calc_length( $node->get_branch_length, $max_path );
        }
        else {
            $tier = depth_to_root($node) - $cur_depth;
        }

        if ( $node->is_internal ) {
            my $str;
            $str .= " " x 4 x $cur_depth;
            $str .= "[";
            if ( length $node->get_name ) {
                $str .= ", label=" . $node->get_name;
                $str .= ", dot";
            }
            $str .= ", tier=$tier" if ( defined $tier );

            # set branch length
            $str .= ", l = ${branch_length} mm, l sep = 0 mm" if ( defined $branch_length );

            $out_string .= $str;
        }
        else {
            my $str;
            $str .= " " x 4 x $cur_depth;
            $str .= "[";
            if ( length $node->get_name ) {
                $str .= sprintf "{%s}", $node->get_name;
            }
            else {
                $str .= "{~}";    # non-breaking space in latex
            }
            $str .= ", tier=$tier" if ( defined $tier );

            # set branch length and add an inviable node
            if ( defined $branch_length ) {
                $str .= ", l = ${branch_length} mm, l sep = 0 mm";
                $str .= " [{~}, tier=0, edge={draw=none}] " if ( defined $branch_length );
            }
            $str .= "]\n";

            $out_string .= $str;
        }
    },
);
$out_string .= "]\n";

if ($wbl) {
    $out_string
        .= sprintf "\\draw[-, grey, line width=1pt]"
        . " (current bounding box.south) --++ (-10mm,0mm)"
        . " node[midway, below]{\\scriptsize%f};\n",
        ( $max_path / 100 * 10 );
}

if ( lc $outfile eq "stdout" ) {
    print $out_string;
}
else {
    path($outfile)->spew($out_string);
}

sub depth_to_root {

    #@type Bio::Phylo::Forest::Node
    my $node    = shift;
    my $current = shift;    # just current node, not all terminals

    my @values;
    if ($current) {
        push @values, $node->calc_nodes_to_root;
    }
    else {
        for my $tip ( @{ $node->get_terminals } ) {
            push @values, $tip->calc_nodes_to_root;
        }
    }

    return List::Util::max(@values);
}

sub path_to_root {

    #@type Bio::Phylo::Forest::Node
    my $node    = shift;
    my $current = shift;    # just current node, not all terminals

    my @values;
    if ($current) {
        push @values, $node->calc_path_to_root;
    }
    else {
        for my $tip ( @{ $node->get_terminals } ) {
            push @values, $tip->calc_path_to_root;
        }
    }

    return List::Util::max(@values);
}

sub calc_length {
    my $path = shift;
    my $max  = shift;

    $path = 0 if !defined $path;

    my $length = int( $path * 100 / $max );

    return $length;
}

__END__
