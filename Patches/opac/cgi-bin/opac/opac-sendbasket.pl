#!/usr/bin/perl

# Copyright Doxulting 2004
#
# This file is part of Koha.
#
# Koha is free software; you can redistribute it and/or modify it under the
# terms of the GNU General Public License as published by the Free Software
# Foundation; either version 2 of the License, or (at your option) any later
# version.
#
# Koha is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
# A PARTICULAR PURPOSE.  See the GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License along
# with Koha; if not, write to the Free Software Foundation, Inc.,
# 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.

use strict;
use warnings;

use CGI;
use Encode qw(encode);
use Carp;

use Mail::Sendmail;
use MIME::QuotedPrint;
use MIME::Base64;
use C4::Biblio;
use C4::Items;
use C4::Auth;
use C4::Output;
use C4::Biblio;
use C4::Members;
use Try::Tiny; # SM: EDS
use URI::Escape; # SM: EDS
use JSON qw/decode_json encode_json/; # SM: EDS

my $query = new CGI;

#EDS patch START
my $PluginDir = C4::Context->config("pluginsdir");
$PluginDir = $PluginDir.'/Koha/Plugin/EDS';
require $PluginDir.'/opac/eds-methods.pl';

my $EDSConfig = decode_json(EDSGetConfiguration());

#EDS patch END


my ( $template, $borrowernumber, $cookie ) = get_template_and_user (
    {
        template_name   => "opac-sendbasketform.tmpl",
        query           => $query,
        type            => "opac",
        authnotrequired => 0,
        flagsrequired   => { borrow => 1 },
    }
);

my $bib_list     = $query->param('bib_list');
my $email_add    = $query->param('email_add');
my $email_sender = $query->param('email_sender');
my $eds_data = ""; try{$eds_data = decode_json(uri_unescape($query->param('eds_data')));}catch{}; # EDS


my $dbh          = C4::Context->dbh;

if ( $email_add ) {
    my $user = GetMember(borrowernumber => $borrowernumber);
    my $user_email = GetFirstValidEmailAddress($borrowernumber)
    || C4::Context->preference('KohaAdminEmailAddress');

    my $email_from = C4::Context->preference('KohaAdminEmailAddress');
    my $email_replyto = "$user->{firstname} $user->{surname} <$user_email>";
    my $comment    = $query->param('comment');
    my %mail = (
        To   => $email_add,
        From => $email_from,
    'Reply-To' => $email_replyto,
#    'X-Orig-IP' => $ENV{'REMOTE_ADDR'},
#    FIXME Commented out for now: discussion on privacy issue
    'X-Abuse-Report' => C4::Context->preference('KohaAdminEmailAddress'),
    );

    my ( $template2, $borrowernumber, $cookie ) = get_template_and_user(
        {
            template_name   => "opac-sendbasket.tmpl",
            query           => $query,
            type            => "opac",
            authnotrequired => 0,
            flagsrequired   => { borrow => 1 },
        }
    );

    my @bibs = split( /\//, $bib_list );
    my @results;
    my $iso2709;
    my $marcflavour = C4::Context->preference('marcflavour');
    foreach my $biblionumber (@bibs) {
        $template2->param( biblionumber => $biblionumber );

        my $dat              = GetBiblioData($biblionumber);
        my $record           = GetMarcBiblio($biblionumber);
		 
		
		
			#START EDS - based - code from downloadcart.pl
			if((eval{C4::Context->preference('EDSEnabled')})){
			
				if((!($biblionumber =~m/$EDSConfig->{cataloguedbid}/)) and (($biblionumber =~m/\|/))){
					
					$record = $eds_data->{Records}[0]->{$biblionumber};
					
					my $recordJSON = "{";
					my $recordXML = '<?xml version="1.0" encoding="UTF-8"?> 
								<record
									xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
									xsi:schemaLocation="http://www.loc.gov/MARC21/slim http://www.loc.gov/standards/marcxml/schema/MARC21slim.xsd"
									xmlns="http://www.loc.gov/MARC21/slim">
									 <leader>000000000000000000000000</leader>
									';
									
					#Title
					try{
							my $EDSRecordTitle = $record->{Record}->{RecordInfo}->{BibRecord}->{BibEntity}->{Titles}[0]->{TitleFull};
							$recordXML .= '  <datafield tag="245" ind1="0" ind2="0">
												<subfield code="a" label="Titles">'.$EDSRecordTitle.'</subfield>
											  </datafield>
											  ';	
							$recordJSON .= '"title":"'.$EDSRecordTitle.'",';
					}catch{};
					
					#Subject
					try{
							my $EDSRecordSubjects = $record->{Record}->{RecordInfo}->{BibRecord}->{BibEntity}->{Subjects};
							foreach my $EDSRecordSubject (@{$EDSRecordSubjects}){	
								$recordXML .= '  <datafield tag="611" ind1="0" ind2="0">
												<subfield code="a" label="Subject">'.$EDSRecordSubject->{SubjectFull}.'</subfield>
											  </datafield>
											  ';
							}
					}catch{};
					
					#Author
					try{
							my $EDSRecordAuthors = $record->{Record}->{RecordInfo}->{BibRecord}->{BibRelationships}->{HasContributorRelationships};
							foreach my $EDSRecordAuthor (@{$EDSRecordAuthors}){	
								$recordXML .= '  <datafield tag="100" ind1="0" ind2="0">
												<subfield code="a" label="Subject">'.$EDSRecordAuthor->{PersonEntity}->{Name}->{NameFull}.'</subfield>
											  </datafield>
											  ';
								$recordJSON .= '"author":"'.$EDSRecordAuthor->{PersonEntity}->{Name}->{NameFull}.'",';
							}
					}catch{};
					
					
					#URL
					try{
							my $EDSRecordURL = $record->{Record}->{PLink};
							$recordXML .= '  <datafield tag="856" ind1="0" ind2="0">
												<subfield code="u" label="Accession Number">'.$EDSRecordURL.'</subfield>
												<subfield code="y" label="Accession Number">'.$EDSRecordURL.'</subfield>
												<subfield code="z" label="Accession Number">'.$EDSRecordURL.'</subfield>
											  </datafield>
											  ';
					}catch{};
					
					#Document Type - TODO needs work.
					try{
							my $EDSRecordType = $record->{Record}->{Header}->{PubType};
							$recordXML .= '  <datafield tag="006" ind1="0" ind2="0">
												<subfield code="a" label="Accession Number">'.$EDSRecordType.'</subfield>
											  </datafield>
											  ';
							$recordXML .= '  <datafield tag="007" ind1="0" ind2="0">
												<subfield code="a" label="Accession Number">'.$EDSRecordType.'</subfield>
											  </datafield>
											  ';
							$recordXML .= '  <datafield tag="008" ind1="0" ind2="0">
												<subfield code="a" label="Accession Number">'.$EDSRecordType.'</subfield>
											  </datafield>
											  ';
					}catch{};
					
					#Identifiers: ISSN/ISBN
					try{
							my $EDSRecordIdentifiers = $record->{Record}->{RecordInfo}->{BibRecord}->{BibRelationships}->{IsPartOfRelationships}[0]->{BibEntity}->{Identifiers};
	
							foreach my $EDSRecordIdentifier (@{$EDSRecordIdentifiers}){	
								if($EDSRecordIdentifier->{Type} =~m/issn/){
									$recordJSON .= '"issn":"'.$EDSRecordIdentifier->{Value}.'",';
									$recordXML .= '  <datafield tag="022" ind1="0" ind2="0">
													<subfield code="a" label="ISSN">'.$EDSRecordIdentifier->{Value}.'</subfield>
												  </datafield>
												  ';	
								}elsif($EDSRecordIdentifier->{Type} =~m/isbn/){
									$recordJSON .= '"isbn":"'.$EDSRecordIdentifier->{Value}.'",';
									$recordXML .= '  <datafield tag="020" ind1="0" ind2="0">
													<subfield code="a" label="ISSN">'.$EDSRecordIdentifier->{Value}.'</subfield>
												  </datafield>
												  ';	
								}
							}
					}catch{};
					
					#Dates
					try{
							my $EDSRecordDate = $record->{Record}->{RecordInfo}->{BibRecord}->{BibRelationships}->{IsPartOfRelationships}[0]->{BibEntity}->{Dates}[0];
							$recordJSON .= '"copyrightdate":"'.$EDSRecordDate->{Y}.'",';
							$recordXML .= '<datafield tag="260" ind1=" " ind2=" ">
												<subfield code="c">'.$EDSRecordDate->{Y}.'</subfield>
											</datafield>
											  ';	
					}catch{};				
					
	
					
					#Accession Number
					try{
							my $EDSRecordAN = $record->{Record}->{Header}->{DbId}.'.'.$record->{Record}->{Header}->{An};
							$recordJSON .= '"biblioitemnumber":"'.$EDSRecordAN.'"';
							$recordXML .= '  <datafield tag="999" ind1="0" ind2="0">
												<subfield code="c" label="Accession Number">'.$EDSRecordAN.'</subfield>
												<subfield code="d" label="Accession Number">'.$EDSRecordAN.'</subfield>
											  </datafield>
											  ';
					}catch{};
													
					
					$recordJSON .= "}";
					$recordXML .= '</record>';
					$recordXML=~s/\&/and/g; # avoid error when converting to marc
					$dat = from_json($recordJSON); # used instead of decode_json and encode('utf-8',$recordJSON) first.
					
					$record = eval { MARC::Record::new_from_xml( $recordXML, "utf8", C4::Context->preference('marcflavour') ) };
				}
			
			}#STOP EDS	
		
		
		
		
		
		
		
        my $marcnotesarray   = GetMarcNotes( $record, $marcflavour );
        my $marcauthorsarray = GetMarcAuthors( $record, $marcflavour );
        my $marcsubjctsarray = GetMarcSubjects( $record, $marcflavour );

        my @items = GetItemsInfo( $biblionumber );

        my $hasauthors = 0;
        if($dat->{'author'} || @$marcauthorsarray) {
          $hasauthors = 1;
        }
	

        $dat->{MARCNOTES}      = $marcnotesarray;
        $dat->{MARCSUBJCTS}    = $marcsubjctsarray;
        $dat->{MARCAUTHORS}    = $marcauthorsarray;
        $dat->{HASAUTHORS}     = $hasauthors;
        $dat->{'biblionumber'} = $biblionumber;
        $dat->{ITEM_RESULTS}   = \@items;

        $iso2709 .= $record->as_usmarc();

        push( @results, $dat );
    }

    my $resultsarray = \@results;
    
    $template2->param(
        BIBLIO_RESULTS => $resultsarray,
        email_sender   => $email_sender,
        comment        => $comment,
        firstname      => $user->{firstname},
        surname        => $user->{surname},
    );

    # Getting template result
    my $template_res = $template2->output();
    my $body;
	
	foreach my $biblionumber (@bibs) { # SM: EDS	
		if((!($biblionumber =~m/$EDSConfig->{cataloguedbid}/)) and (($biblionumber =~m/\|/))){
		
			$biblionumber =~s/\|/\&dbid\=/;
			$template_res =~s/\|/\&dbid\=/;
			$template_res =~s/\/cgi\-bin\/koha\/opac-detail\.pl\?biblionumber\=$biblionumber/\/plugin\/Koha\/Plugin\/EDS\/opac\/eds-detail.pl\?q\=Retrieve\?an\=$biblionumber/; 
		}else{
			$template_res =~s/\|$EDSConfig->{cataloguedbid}//;
		}		
	}
	$template_res =~s/\&dbid/\|dbid/g;

    # Analysing information and getting mail properties

    if ( $template_res =~ /<SUBJECT>(.*)<END_SUBJECT>/s ) {
        $mail{subject} = $1;
        $mail{subject} =~ s|\n?(.*)\n?|$1|;
    }
    else { $mail{'subject'} = "no subject"; }

    my $email_header = "";
    if ( $template_res =~ /<HEADER>(.*)<END_HEADER>/s ) {
        $email_header = $1;
        $email_header =~ s|\n?(.*)\n?|$1|;
        $email_header = encode_qp($email_header);
    }

    my $email_file = "basket.txt";
    if ( $template_res =~ /<FILENAME>(.*)<END_FILENAME>/s ) {
        $email_file = $1;
        $email_file =~ s|\n?(.*)\n?|$1|;
    }

    if ( $template_res =~ /<MESSAGE>(.*)<END_MESSAGE>/s ) {
        $body = $1;
        $body =~ s|\n?(.*)\n?|$1|;
        $body = encode_qp($body);
    }

    $mail{body} = $body;

    my $boundary = "====" . time() . "====";

    $mail{'content-type'} = "multipart/mixed; boundary=\"$boundary\"";
    my $isofile = encode_base64(encode("UTF-8", $iso2709));
    $boundary = '--' . $boundary;
    $mail{body} = <<END_OF_BODY;
$boundary
MIME-Version: 1.0
Content-Type: text/plain; charset="UTF-8"
Content-Transfer-Encoding: quoted-printable

$email_header
$body
$boundary
Content-Type: application/octet-stream; name="basket.iso2709"
Content-Transfer-Encoding: base64
Content-Disposition: attachment; filename="basket.iso2709"

$isofile
$boundary--
END_OF_BODY

    # Sending mail (if not empty basket)
    if ( defined($iso2709) && sendmail %mail ) {
    # do something if it works....
        $template->param( SENT      => "1" );
    }
    else {
        # do something if it doesnt work....
    carp "Error sending mail: empty basket" if !defined($iso2709);
        carp "Error sending mail: $Mail::Sendmail::error" if $Mail::Sendmail::error;
        $template->param( error => 1 );
    }
    $template->param( email_add => $email_add );
    output_html_with_http_headers $query, $cookie, $template->output;
}
else {
    $template->param( bib_list => $bib_list );
    $template->param(
        url            => "/cgi-bin/koha/opac-sendbasket.pl",
        suggestion     => C4::Context->preference("suggestion"),
        virtualshelves => C4::Context->preference("virtualshelves"),
    );
    output_html_with_http_headers $query, $cookie, $template->output;
}