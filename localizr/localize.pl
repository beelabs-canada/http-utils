#!/usr/bin/env perl

use strict;
use warnings;
use 5.010_001;

use Mojo::UserAgent;
use Mojo::JSON qw(decode_json encode_json);
use Mojo::Util;
use File::Basename;

use Path::Tiny 'path';
use Getopt::Std;
use Data::Dmp;

# ###################################################
# Global
# ...................................................
my ( $ua, $opts, $base, $active ) = (
    Mojo::UserAgent->new( max_redirects => 7),
    { 'c' => 'localize.json', 'd' => 10, 's' => 0, 'x' => 4 },
    path($0)->parent->absolute,
    0
);



# ###################################################
# Runtime Parameters
# ...................................................
getopts("c:dis:xi", $opts);

if ( not $opts->{'s'} )
{
    say " [aborting] .. you need a starting site URL to use localize ( -s https:... )";
    exit;
}
# ###################################################
# Main
# ...................................................
my $config = decode_json( $base->child( $opts->{'c'} )->slurp_utf8 );
my $home = Mojo::URL->new( $opts->{'s'} );

# Lets start the path
$base = $base->child( 'sites', $home->host() );
$base->mkpath;

my @urls = ( $home );

Mojo::IOLoop->recurring(
    0 => sub {
        for ($active + 1 .. $opts->{'x'} ) {

            # Dequeue or halt if there are no active crawlers anymore
            return ( $active or Mojo::IOLoop->stop )
                unless my $url = shift @urls;

            # Fetch non-blocking just by adding
            # a callback and marking as active
            ++$active;
            $ua->get($url => \&get_callback);
        }
    }
);

# Start event loop if necessary
Mojo::IOLoop->start unless Mojo::IOLoop->is_running;

# ###################################################
# Functions
# ...................................................
sub get_callback {
    my (undef, $tx) = @_;

    # Deactivate
    --$active;

    # Parse only OK HTML responses
    return
        if not $tx->res->is_success
        or $tx->res->headers->content_type !~ m{^text/html\b}ix;

    my $path = inflex( $tx->req->url );

    say " [path] >> ".$path->stringify;
    parse_html( $path, $tx );

    return;
}

sub parse_html {
    my ( $path ,$tx ) = @_;

    my $url = $tx->req->url;

    $path->touchpath;

    say " [processing] " . $tx->res->dom->at('html title')->text . ' / '. $url->path->leading_slash(0) ;

    # Extract and enqueue URLs
    for my $e ($tx->res->dom('a[href]')->each) {

        # Validate href attribute
        my $link = Mojo::URL->new($e->{href});
        next if 'Mojo::URL' ne ref $link;

        # "normalize" link
        $link = $link->to_abs($tx->req->url)->fragment(undef);
        next unless grep { $link->protocol eq $_ } qw(http https);

        # Don't go deeper than /a/b/c
        next if @{$link->path->parts} > 3;

        # Access every link only once
        state $uniq = {};
        next if ++$uniq->{$link->to_string} > 1;

        # Don't visit other hosts
        next if $link->host ne $url->host;

        push @urls, $link;
        say " -> $link";
    }
    say '';

    return;
}

sub inflex
{
    my ( $url ) = ( Mojo::URL->new( $_[0] ) );
    if ( $url->path->leading_slash(0) eq '' )
    {
        return  $base->child('index.html');
    }
    my $path = $base->child( $url->path->leading_slash(0) );
    return ( (fileparse( $path->stringify ))[-1] ne '' ) ? $path : $path->child('index.html') ;
}
