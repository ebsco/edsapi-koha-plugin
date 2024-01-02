#!/usr/bin/perl

# Copyright 2009 BibLibre
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
use Encode qw( encode );

use C4::Auth qw( get_template_and_user );
use C4::Biblio qw( GetFrameworkCode GetISBDView GetMarcBiblio );
use C4::Output qw( output_html_with_http_headers );
use C4::Record;
use C4::Ris qw( marc2ris );
use Koha::CsvProfiles;
use Koha::RecordProcessor;
use Koha::Biblios;

use utf8;
my $query = CGI->new();
do '../eds-methods.pl';
my ( $template, $borrowernumber, $cookie ) = get_template_and_user (
    {
        template_name   => "opac-downloadcart.tt",
        query           => $query,
        type            => "opac",
        authnotrequired => ( C4::Context->preference("OpacPublic") ? 1 : 0 ),
    }
);
my $eds_data = "";
my $bib_list = $query->param('bib_list');
#convert _dot_ to . to properly search for items
$bib_list =~s/\_dot\_/\./g;
my $format  = $query->param('format');
my $dbh     = C4::Context->dbh;
$eds_data = $query->param('eds_data'); #EDS Patch
if ($bib_list && $format) {

    my $borcat = q{};
    if ( C4::Context->preference('OpacHiddenItemsExceptions') ) {
        # we need to fetch the borrower info here, so we can pass the category
        my $borrower = Koha::Patrons->find( { borrowernumber => $borrowernumber } );
        $borcat = $borrower ? $borrower->categorycode : $borcat;
    }

    my @bibs = split( /\//, $bib_list );

    my $marcflavour = C4::Context->preference('marcflavour');
    my $output;
    my $extension;
    my $type;

    # CSV   
    if ($format =~ /^\d+$/) {

        my $csv_profile = Koha::CsvProfiles->find($format);
        if ( not $csv_profile or $csv_profile->staff_only ) {
            print $query->redirect('/cgi-bin/koha/errors/404.pl');
            exit;
        }

        $output = marc2csv(\@bibs, $format);

        # Other formats
    } else {
        my $record_processor = Koha::RecordProcessor->new({
            filters => 'ViewPolicy'
        });
        foreach my $biblio (@bibs) {

            my $biblio_object  = Koha::Biblios->find($biblionumber);
            my $record = $biblio_object->metadata->record;
            next unless $record;

                my $dat = "";
            if($biblio =~m/\_\_/){
                ($record,$dat)= ProcessEDSCartItems($biblio,$eds_data,$record,$dat);
                } #EDS Patch
                
            my $framework = &GetFrameworkCode( $biblio );
            $record_processor->options({
                interface => 'opac',
                frameworkcode => $framework
            });
            $record_processor->process($record);

            next unless $record;

            if ($format eq 'iso2709') {
                #NOTE: If we don't explicitly UTF-8 encode the output,
                #the browser will guess the encoding, and it won't always choose UTF-8.
                $output .= encode("UTF-8", $record->as_usmarc()) // q{};
            }
            elsif ($format eq 'ris') {
                $output .= marc2ris($record);
            }
            elsif ($format eq 'bibtex') {
                $output .= marc2bibtex($record, $biblio);
            }
            elsif ( $format eq 'isbd' ) {
                my $framework = GetFrameworkCode( $biblio );
                $output   .= GetISBDView({
                    'record'    => $record,
                    'template'  => 'opac',
                    'framework' => $framework,
                });
                $extension = "txt";
                $type      = "text/plain";
            }
        }
    }

    # If it was a CSV export we change the format after the export so the file extension is fine
    $format = "csv" if ($format =~ m/^\d+$/);

    print $query->header(
                               -type => ($type) ? $type : 'application/octet-stream',
        -'Content-Transfer-Encoding' => 'binary',
                         -attachment => ($extension) ? "cart.$format.$extension" : "cart.$format"
    );
    print $output;

} else { 
    $template->param(
        csv_profiles => Koha::CsvProfiles->search(
            {
                type       => 'marc',
                used_for   => 'export_records',
                staff_only => 0
            }
        ),
        bib_list => $bib_list,
    );
    output_html_with_http_headers $query, $cookie, $template->output;
}