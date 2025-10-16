package Koha::Plugin::EDS::EDSController;

use Modern::Perl;
use Koha::Plugin::EDS;
use Mojo::Base 'Mojolicious::Controller';
use JSON;
use warnings;
use strict;

sub eds_raw {
    my $c = shift->openapi->valid_input or return;
    my $q = $c->param('q');

    my $plugin = Koha::Plugin::EDS->new();

    if ($q eq 'info') {
        # Handle info query
        my $edsinfo = $plugin->retrieve_data('edsinfo');
        
        do 'Koha/Plugin/EDS/opac/eds-methods.pl';
        my $updated_edsinfo = EDSSearch('info');
        my $response;

        return $c->render(
            status => 200, 
            text => $edsinfo
        );
    }
    
    elsif ($q eq 'knownitems') {
        # Handle knownitems query
        do 'Koha/Plugin/EDS/opac/eds-methods.pl';
		my $api_response = EDSSearchFields();
        return $c->render(status => 200, json => $api_response);
    }
    elsif ($q eq 'getip') {
        # Handle getip query
        my $ip = $c->tx->remote_address;
        return $c->render(status => 200, json => { ip => $ip });
    }
    else {
        return $c->render(status => 400, json => { error => "Invalid query type: $q" });
    }
}

sub eds_ac {
    my $c = shift->openapi->valid_input or return;

    do 'Koha/Plugin/EDS/opac/eds-methods.pl';
    my $EDSConfig = decode_json(EDSGetConfiguration());
    my $api_response = EDSAuthForAutocomplete($EDSConfig);

    return $c->render(status => 200, json => $api_response);
}

1;