#!/usr/bin/perl
use strict;
use warnings;
use autodie;

use FindBin;
use Path::Tiny;

my $template = path($FindBin::RealBin, "template.tex");