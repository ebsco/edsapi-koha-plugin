package Koha::Plugin::EDS::EDSController;

use Modern::Perl;
use Koha::Plugin::EDS;
use Mojo::Base 'Mojolicious::Controller';
use warnings;
use strict;

sub get_info {
    my $c = shift->openapi->valid_input or return;

    return try {
    my $plugin = Koha::Plugin::EDS->new();

    my $edsinfo = $plugin->retrieve_data('edsinfo');

    do 'Koha/Plugin/EDS/opac/eds-methods.pl';
    my $updated_edsinfo = EDSSearch('info');
    my $response;

    return $c->render(
        status => 200, 
        text => $edsinfo
        );
    }
    catch {
        return $c->render(
            status => 500,
            text => { error => "500 error in EDSController.pm"}
        );
    };
}
1;