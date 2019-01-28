#!/usr/bin/env perl

use strict;
use warnings;
use utf8;
use 5.010_001;

use JSON::Tiny qw(decode_json encode_json);
use Path::Tiny qw/path/;

use Parallel::ForkManager;
use List::Util qw/shuffle/;
use Data::Dump;

# ================================
# Globals
# ................................

my $config = decode_json( path($0)->sibling('thrash.json')->slurp_utf8 );

# --headless --user-agent=\"Http Utils - Canada.ca (load tester)\"

my @urls = shuffle( @{ $config->{'catalog'} } );

@urls = (@urls, shuffle( @{ $config->{'catalog'} } )) for ( 1..1600 );

# Max 30 processes for parallel download
my $pm = Parallel::ForkManager->new($config->{'threads'});
 
LINKS:
foreach my $link (@urls) {
  $pm->start and next LINKS; # do the fork
  system ('/Applications/Google\ Chrome.app/Contents/MacOS/Google\ Chrome --headless '.$link );
  say $link;
  $pm->finish; # do the exit in the child process
}
$pm->wait_all_children;