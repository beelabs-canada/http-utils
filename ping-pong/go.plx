#!/usr/bin/env perl

use strict;
use warnings;
use utf8;
use 5.010_001;

use Mojo::UserAgent;
use Mojo::JSON qw(decode_json encode_json);
use Mojo::Log;
use Mojo::URL;
use Mojo::Log;
use Mojo::File qw/path/;
use Mojo::IOLoop;
use Time::Piece;

use Class::CSV;
use Data::Dmp;

# -------------------------------------------- #
# 					GLOBALS
# -------------------------------------------- #

my $log = Mojo::Log->new( path => path( $0 )->sibling( 'go.log' )->spurt('') );
my $config = decode_json( path( $0 )->sibling( 'go.json' )->slurp );

# -------------------------------------------- #
# 					MAIN
# -------------------------------------------- #
# HTTP CLient
my $ua = Mojo::UserAgent->new( max_redirects => 7 ) ;

$ua->transactor->name( $config->{'http'}->{'agent'} );
$log->info( ' GO v1.0a started ');

my @urls = @{ $config->{'catalog'} };
# User agent with a custom name, following up to 5 redirects

my $csv = Class::CSV->new(
  fields   => ['URL', 'Cached', 'Timestamp' ,'Akamai Cache Code']
);

$csv->add_line(['URL', 'Cached', 'Timestamp' ,'Akamai Cache Code']);


# Use a delay to keep the event loop running until we are done
my $delay = Mojo::IOLoop->delay;

my $fetch;

$fetch = sub {

  # Stop if there are no more URLs
  return unless my $url = shift @urls;

  # Fetch the next title
  my $end = $delay->begin;
  $ua->get($url => { Pragma => 'akamai-x-cache-on, akamai-x-cache-remote-on, akamai-x-check-cacheable, akamai-x-get-cache-key, akamai-x-get-ssl-client-session-id, akamai-x-get-true-cache-key, akamai-x-get-request-id'} => sub {
    my ($ua, $tx) = @_;
	
	$csv->add_line([
		$tx->req->url->to_abs,
		( index( $tx->res->headers->{headers}->{'x-cache'}->[0], '_MISS' ) != -1  ) ? 'NO' : 'YES',
		localtime->datetime,
		$tx->res->headers->{headers}->{'x-cache'}->[0]
	]);
	
	say "[parsed] ",$tx->req->url->to_abs;
	
	# Next request
    $fetch->();
    $end->();
  });
};

# Process two requests at a time
$fetch->() for 1 .. 2;
$delay->wait;

path( $0 )->sibling( 'audit.'.localtime->dmy("-").'_'.localtime->hms('.').'.csv' )->spurt( $csv->string() ) ;

