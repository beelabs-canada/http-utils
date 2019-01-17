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

use Class::CSV;
use Data::Dmp;


# -------------------------------------------- #
# 					MAIN
# -------------------------------------------- #
# HTTP CLient
my $ua = Mojo::UserAgent->new( max_redirects => 7 ) ;

my $base = 'https://www.canada.ca/fr/nouvelles.api.json?'.time;

say " trying $base";

for my $article (@{$ua->get('https://www.canada.ca/fr/nouvelles.api.json?bc='.time )->result->json->{data}}) {
	say "\"$article->{link}\",";
}