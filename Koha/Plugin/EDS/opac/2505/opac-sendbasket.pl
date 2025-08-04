#!/usr/bin/perl

# Copyright Doxulting 2004
#
# This file is part of Koha.
#
# Koha is free software; you can redistribute it and/or modify it
# under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 3 of the License, or
# (at your option) any later version.
#
# Koha is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with Koha; if not, see <http://www.gnu.org/licenses>.

use Modern::Perl;

use CGI qw ( -utf8 );
use Encode;

use C4::Auth   qw( get_template_and_user );
use C4::Biblio qw(GetMarcSubjects);
use C4::Output qw( output_html_with_http_headers );
use C4::Templates;
use Koha::Biblios;
use Koha::Email;
use Koha::Patrons;
use Koha::Token;

my $query = CGI->new;

my $pluginsdir = C4::Context->config("pluginsdir");
my @pluginsdir = ref($pluginsdir) eq 'ARRAY' ? @$pluginsdir : $pluginsdir;
my ($PluginDir) = grep { -f $_ . "/Koha/Plugin/EDS.pm" } @pluginsdir;
$PluginDir = $PluginDir.'/Koha/Plugin/EDS';

do '../eds-methods.pl';
my $eds_data = $query->param('eds_data'); #EDS Patch

my ( $template, $borrowernumber, $cookie ) = get_template_and_user(
    {
        template_name => "opac-sendbasketform.tt",
        query         => $query,
        type          => "opac",
    }
);
my $patron     = Koha::Patrons->find($borrowernumber);
my $user_email = $patron ? $patron->notice_email_address : undef;

my $op        = $query->param('op')       || q{};
my $bib_list  = $query->param('bib_list') || '';
#convert _dot_ to . to properly search for items
$bib_list =~s/\_dot\_/\./g;

my $email_add = $query->param('email_add');

if ( $op eq "cud-send" && $email_add && $user_email ) {
    die "Wrong CSRF token"
      unless Koha::Token->new->check_csrf(
        {
            session_id => scalar $query->cookie('CGISESSID'),
            token      => scalar $query->param('csrf_token'),
        }
      );

    my $comment = $query->param('comment');

    my @bibs = split( /\//, $bib_list );
    my $iso2709;
    my $catbibs;
    my $edscounter = 0;
    foreach my $biblionumber (@bibs) {
        my $biblio = '';
        my $record = '';
        if($biblionumber =~m/\_\_/){
            #if biblionumber matches on __, split into an and db
            my ($biblio_an, $biblio_db)  = split(/__/, $biblionumber);
            #add header if EDS items are sent in basket
            if ($edscounter == 0){
                $comment .= "\n\n________________________________";
                $comment .= "\n\nEBSCO Discovery Service items are listed first, followed by your library catalog items.\n";
            }
            my $dat = '';
            ($record,$dat)= ProcessEDSCartItems($biblionumber,$eds_data,$record,$dat);                    
            $iso2709 .= $record->as_usmarc() // q{};
            $edscounter++;
            #EDS data added to comment
            $comment .= "\n".$edscounter.". ".$record->title."\n";
            $comment .= "Author(s): ".$record->author."\n";
            #form URL with OPACBaseURL, plugin path for Koha eds-detail.pl, and add biblio_an, biblio_db to form link back to Koha catalog for EDS item
            $comment .= "URL: ".C4::Context->preference('OPACBaseURL').'/plugin/Koha/Plugin/EDS/opac/eds-detail.pl?q=Retrieve?an='.$biblio_an.'|dbid='.$biblio_db."\n";
        } #EDS Patch
        else {
            $catbibs .= $biblionumber."|";
            $biblio = Koha::Biblios->find($biblionumber) or next;
            $iso2709 .= $biblio->metadata->record->as_usmarc();        
        }
    }
    if ( !defined $iso2709 ) {
        $template->param( error => 'NO_BODY' );
    }
    else {
        my %loops;
        if ($catbibs){
            my @catbibsloops = split( /\|/, $catbibs );
            %loops = ( biblio => \@catbibsloops, );
        } 
        my %substitute = ( comment => $comment, );

        my $letter = C4::Letters::GetPreparedLetter(
            module      => 'catalogue',
            letter_code => 'CART',
            lang        => $patron->lang,
            tables      => {
                borrowers => $borrowernumber,
            },
            message_transport_type => 'email',
            loops                  => \%loops,
            substitute             => \%substitute,
        );

        my $attachment = {
            filename => 'basket.iso2709',
            type     => 'application/octet-stream',
            content  => Encode::encode( "UTF-8", $iso2709 ),
        };

        my $message_id = C4::Letters::EnqueueLetter(
            {
                letter                 => $letter,
                message_transport_type => 'email',
                to_address             => $email_add,
                reply_address          => $user_email,
                attachments            => [$attachment],
            }
        );

        C4::Letters::SendQueuedMessages( { message_id => $message_id } ) if $message_id;

        $template->param( SENT => 1 );
    }

    $template->param( email_add => $email_add );
    output_html_with_http_headers $query, $cookie, $template->output, undef,
        { force_no_caching => 1 };

} elsif ( !$user_email ) {
    $template->param( email_add => 1, error => 'NO_REPLY_ADDRESS' );
    output_html_with_http_headers $query, $cookie, $template->output;

} else {
    my $new_session_id = $query->cookie('CGISESSID');
    $template->param(
        bib_list       => $bib_list,
        url            => "/cgi-bin/koha/opac-sendbasket.pl",
        suggestion     => C4::Context->preference("suggestion"),
        virtualshelves => C4::Context->preference("virtualshelves"),
        csrf_token =>
          Koha::Token->new->generate_csrf( { session_id => $new_session_id, } ),
    );
    output_html_with_http_headers $query, $cookie, $template->output, undef,
        { force_no_caching => 1 };
}
