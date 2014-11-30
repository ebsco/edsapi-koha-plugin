#!/usr/bin/perl

# Copyright 2009 BibLibre
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

use C4::Auth;
use C4::Biblio;
use C4::Items;
use C4::Output;
use C4::VirtualShelves;
use C4::Record;
use C4::Ris;
use C4::Csv;
use utf8;
use Try::Tiny; # SM: EDS

my $query = new CGI;

#EDS patch START
my $PluginDir = C4::Context->config("pluginsdir");
$PluginDir = $PluginDir.'/Koha/Plugin/EDS';
require $PluginDir.'/opac/eds-methods.pl';

my $EDSConfig = decode_json(EDSGetConfiguration());
#use Data::Dumper; die Dumper $EDSConfig->{cataloguedbid};

#EDS patch END

my ( $template, $borrowernumber, $cookie ) = get_template_and_user (
    {
        template_name   => "opac-downloadcart.tmpl",
        query           => $query,
        type            => "opac",
        authnotrequired => 1,
        flagsrequired   => { borrow => 1 },
    }
);

my $bib_list = $query->param('bib_list');
my $format  = $query->param('format');
my $dbh     = C4::Context->dbh;

if ($bib_list && $format) {

    my @bibs = split( /\//, $bib_list );

    my $marcflavour         = C4::Context->preference('marcflavour');
    my $output;

    # CSV   
    if ($format =~ /^\d+$/) {

        $output = marc2csv(\@bibs, $format);

        # Other formats
    } else {
        foreach my $biblio (@bibs) {

            my $record = GetMarcBiblio($biblio, 1);
			
			
			
			#START EDS
			if(eval{C4::Context->preference('EDSEnabled')}){
			
				if(!($biblio =~m/$EDSConfig->{cataloguedbid}/)){
					my $EDSQuery = 'Retrieve?an='.$biblio;
					$EDSQuery =~s/\|/\|dbid\=/g;
					$record = decode_json(EDSSearch($EDSQuery,'n'));
					#use Data::Dumper; die Dumper $record->{Record};
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
									$recordXML .= '  <datafield tag="022" ind1="0" ind2="0">
													<subfield code="a" label="ISSN">'.$EDSRecordIdentifier->{Value}.'</subfield>
												  </datafield>
												  ';	
								}elsif($EDSRecordIdentifier->{Type} =~m/isbn/){
									$recordXML .= '  <datafield tag="020" ind1="0" ind2="0">
													<subfield code="a" label="ISSN">'.$EDSRecordIdentifier->{Value}.'</subfield>
												  </datafield>
												  ';	
								}
							}
					}catch{};
					
					#Dates
					#try{
							my $EDSRecordDate = $record->{Record}->{RecordInfo}->{BibRecord}->{BibRelationships}->{IsPartOfRelationships}[0]->{BibEntity}->{Dates}[0];
							#use Data::Dumper; die Dumper $EDSRecordDate;
							$recordXML .= '<datafield tag="260" ind1=" " ind2=" ">
												<subfield code="c">'.$EDSRecordDate->{Y}.'</subfield>
											</datafield>
											  ';	
					#}catch{};				
					
	
					
					#Accession Number
					try{
							my $EDSRecordAN = $record->{Record}->{Header}->{DbId}.'.'.$record->{Record}->{Header}->{An};
							$recordXML .= '  <datafield tag="999" ind1="0" ind2="0">
												<subfield code="c" label="Accession Number">'.$EDSRecordAN.'</subfield>
												<subfield code="d" label="Accession Number">'.$EDSRecordAN.'</subfield>
											  </datafield>
											  ';
					}catch{};
													
					
					
					$recordXML .= '</record>';
					$recordXML=~s/\&/and/g; # avoid error when converting to marc
					#use Data::Dumper; die Dumper $recordXML;
					
					#$record = $recordXML;
					
					$record = eval { MARC::Record::new_from_xml( $recordXML, "utf8", C4::Context->preference('marcflavour') ) };
				}
				#use Data::Dumper; die Dumper $record;
			
			}#STOP EDS
			
			
			
			
			

            next unless $record;

            if ($format eq 'iso2709') {
                $output .= $record->as_usmarc();
            }
            elsif ($format eq 'ris') {
                $output .= marc2ris($record);
            }
            elsif ($format eq 'bibtex') {
                $output .= marc2bibtex($record, $biblio);
            }
        }
		
    }
#use Data::Dumper; die Dumper $output;

    # If it was a CSV export we change the format after the export so the file extension is fine
    $format = "csv" if ($format =~ m/^\d+$/);

    print $query->header(
	-type => 'application/octet-stream',
	-'Content-Transfer-Encoding' => 'binary',
	-attachment=>"cart.$format");
    print $output;

} else { 
    $template->param(csv_profiles => GetCsvProfilesLoop('marc'));
    $template->param(bib_list => $bib_list); 
    output_html_with_http_headers $query, $cookie, $template->output;
}
