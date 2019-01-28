#!/usr/bin/env perl

use strict;
use warnings;
use 5.010_001;

use Mojo::UserAgent;
use Mojo::JSON qw(decode_json encode_json);
use Mojo::Util;

use Path::Tiny 'path';
use Getopt::Std;
use Data::Dmp;

# ###################################################
# Global
# ...................................................
my ( $ua, $opts, $base ) = (
    Mojo::UserAgent->new,
    { 'c' => 'localize.json', 'd' => 10, 's' => 0 },
    path($0)->parent->absolute
);



# ###################################################
# Runtime Parameters
# ...................................................
getopts("c:d:s:", $opts);

if ( not $opts->{'s'} )
{
    say " [aborting] .. you need a starting site URL to use localize ( -s https:... )";
    exit();
}
# ###################################################
# Main
# ...................................................
my $config = decode_json( $base->child( $opts->{'c'} )->slurp_utf8 );
my $home = Mojo::URL->new( $opts->{'s'} );

# Lets start the path
$base = $base->child( 'sites', $home->host() )->mkpath;


dd( $opts );

