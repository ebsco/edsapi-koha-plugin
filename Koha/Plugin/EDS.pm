package Koha::Plugin::EDS;

#/*
#=============================================================================================
#* WIDGET NAME: Koha EDS Integration Plugin
#* DESCRIPTION: Integrates EDS with Koha
#* KEYWORDS: Koha, ILS, Integration, API, EDS
#* CUSTOMER PARAMETERS: None
#* EBSCO PARAMETERS: None
#* URL: N/A
#* AUTHOR & EMAIL: Alvet Miranda - amiranda@ebsco.com
#* DATE ADDED: 31/10/2013
#* DATE MODIFIED: 4/Dec/2014
#* LAST CHANGE DESCRIPTION: Updated to 3.1621
#* 							added PageURL function in EDS.pm to refresh if run tool encounters an error.
#=============================================================================================
#*/

use Modern::Perl;
use base qw(Koha::Plugins::Base);
use C4::Context;
use C4::Branch;
use C4::Members;
use C4::Auth;
use Cwd            qw( abs_path );
use File::Basename qw( dirname );
use LWP::Simple qw(get);
use JSON qw/decode_json encode_json/;
use Try::Tiny;


my $PluginDir = C4::Context->config("pluginsdir");
$PluginDir = $PluginDir.'/Koha/Plugin/EDS';

## Here we set our plugin version
our $VERSION = 3.1621;

## Here is our metadata, some keys are required, some are optional
our $metadata = {
    name   => 'Koha EDS API Integration',
    author => 'Alvet Miranda - amiranda@ebsco.com',
    description =>
'This plugin integrates EBSCO Discovery Service(EDS) in Koha.<p>Go to Configure(right) to configure the API Plugin first then Run tool (left) for setup instructions.</p><p>For assistance; email EBSCO support at <a href="mailto:support@ebscohost.com">support@ebsco.com</a> or call the toll free international hotline at +800-3272-6000</p>',
    date_authored   => '2013-10-27',
    date_updated    => '2014-12-04',
    minimum_version => '3.16',
    maximum_version => '',
    version         => $VERSION,
};

## This is the minimum code required for a plugin's 'new' method
## More can be added, but none should be removed
sub new {
    my ( $class, $args ) = @_;

    ## We need to add our metadata here so our base class can access it
    $args->{'metadata'} = $metadata;

    ## Here, we call the 'new' method for our base class
    ## This runs some additional magic and checking
    ## and returns our actual $self
    my $self = $class->SUPER::new($args);

    return $self;
}

sub tool {
    my ( $self, $args ) = @_;

    my $cgi = $self->{'cgi'};

    unless ( $cgi->param('submitted') ) {
        $self->SetupTool();
    }


}

## Logic for configure method
sub configure {
    my ( $self, $args ) = @_;
    my $cgi = $self->{'cgi'};

    unless ( $cgi->param('save') ) {
        my $template = $self->get_template({ file => 'admin/configure.tt' });

        ## Grab the values we already have for our settings, if any exist
        $template->param(
			edsusername 		=> $self->retrieve_data('edsusername'),
			edspassword 		=> $self->retrieve_data('edspassword'),
			edsprofileid 		=> $self->retrieve_data('edsprofileid'),
			edscustomerid 		=> $self->retrieve_data('edscustomerid'),
			cataloguedbid 		=> $self->retrieve_data('cataloguedbid'),
			catalogueanprefix 	=> $self->retrieve_data('catalogueanprefix'),
			defaultsearch 		=> $self->retrieve_data('defaultsearch'),
			cookieexpiry 		=> $self->retrieve_data('cookieexpiry'),
			logerrors			=> $self->retrieve_data('logerrors'),
			edsinfo				=> $self->retrieve_data('edsinfo'),
			lastedsinfoupdate	=> $self->retrieve_data('lastedsinfoupdate'),
			authtoken			=> $self->retrieve_data('authtoken'),
			OPACBaseURL			=> C4::Context->preference('OPACBaseURL'),		
			edsswitchtext	=> $self->retrieve_data('edsswitchtext'),
			kohaswitchtext	=> $self->retrieve_data('kohaswitchtext'),
			edsselecttext	=> $self->retrieve_data('edsselecttext'),
			edsselectinfo	=> $self->retrieve_data('edsselectinfo'),
			kohaselectinfo	=> $self->retrieve_data('kohaselectinfo'),
			defaultparams	=> $self->retrieve_data('defaultparams'),
			instancepath	=> $self->retrieve_data('instancepath'),
			
			
        );

        print $cgi->header();
        print $template->output();
    }
    else {
		
		$self->store_data(
				{
					edsusername 		=> ($cgi->param('edsusername')?$cgi->param('edsusername'):"-"),
					edspassword 		=> ($cgi->param('edspassword')?$cgi->param('edspassword'):"-"),
					edsprofileid 		=> ($cgi->param('edsprofileid')?$cgi->param('edsprofileid'):"-"),
					edscustomerid 		=> ($cgi->param('edscustomerid')?$cgi->param('edscustomerid'):"-"),
					cataloguedbid 		=> ($cgi->param('cataloguedbid')?$cgi->param('cataloguedbid'):"-"),
					catalogueanprefix 	=> ($cgi->param('catalogueanprefix')?$cgi->param('catalogueanprefix'):"-"), 
					defaultsearch 		=> ($cgi->param('defaultsearch')?$cgi->param('defaultsearch'):"-"),
					logerrors			=> ($cgi->param('logerrors')?$cgi->param('logerrors'):"-"),
					cookieexpiry 		=> ($cgi->param('cookieexpiry')?$cgi->param('cookieexpiry'):"-"),
					last_configured_by => C4::Context->userenv->{'number'},
					edsswitchtext	=> ($cgi->param('edsswitchtext')?$cgi->param('edsswitchtext'):"-"),
					kohaswitchtext	=> ($cgi->param('kohaswitchtext')?$cgi->param('kohaswitchtext'):"-"),
					edsselecttext	=> ($cgi->param('edsselecttext')?$cgi->param('edsselecttext'):"-"),
					edsselectinfo	=> ($cgi->param('edsselectinfo')?$cgi->param('edsselectinfo'):"-"),
					kohaselectinfo	=> ($cgi->param('kohaselectinfo')?$cgi->param('kohaselectinfo'):"-"),
					defaultparams	=> ($cgi->param('defaultparams')?$cgi->param('defaultparams'):"-"),
					instancepath	=> ($cgi->param('instancepath')?$cgi->param('instancepath'):"-"),
				}
			);
		
			if($cgi->param('edsinfo') eq 'Update Required'){ 
				
				$self->store_data(
					{
						authtoken 			=> $cgi->param('authtoken'), 
						lastedsinfoupdate	=> $cgi->param('lastedsinfoupdate'),
						edsinfo 			=> $cgi->param('edsinfo'),
						$self->store_data
					}
				);	

			}
        $self->go_home();
    }
}


sub install() {
    my ( $self, $args ) = @_;
##Leaving this code incase this plugin needs its own table in the future
#    my $table = $self->get_qualified_table_name('config');

#    return C4::Context->dbh->do( "
#		CREATE TABLE $table (
#		`edsid` INT NOT NULL AUTO_INCREMENT,
#		`edskey` VARCHAR(100) NOT NULL,
#		`edsvalue` TEXT NOT NULL, 
#		PRIMARY KEY (`edsid`)) ENGINE = INNODB;
#    " ); 
	return C4::Context->dbh->do("INSERT INTO `systempreferences` (`variable`, `value`, `explanation`, `type`) VALUES ('EDSEnabled', '1', 'If ON, enables searching with EDS - Plugin required.For assistance; email EBSCO support at support\@ebscohost.com', 'YesNo') ON DUPLICATE KEY UPDATE `variable`='EDSEnabled', `value`=1, `explanation`='If ON, enables searching with EDS - Plugin required.For assistance; email EBSCO support at support\@ebscohost.com', `type`='YesNo'");
}


sub uninstall() {
    my ( $self, $args ) = @_;
##Leaving this code incase this plugin needs its own table in the future
#    my $table = $self->get_qualified_table_name('config');

#    return C4::Context->dbh->do("DROP TABLE $table");
	return C4::Context->dbh->do("INSERT INTO `systempreferences` (`variable`, `value`, `explanation`, `type`) VALUES ('EDSEnabled', '0', 'If ON, enables searching with EDS - Plugin required.For assistance; email EBSCO support at support\@ebscohost.com', 'YesNo') ON DUPLICATE KEY UPDATE `variable`='EDSEnabled', `value`=1, `explanation`='If ON, enables searching with EDS - Plugin required.For assistance; email EBSCO support at support\@ebscohost.com', `type`='YesNo'");
}

sub PageURL{
	# http://stackoverflow.com/questions/3412280/how-do-i-obtain-the-current-url-in-perl
	my $page_url = 'http';
	if ($ENV{HTTPS} = "on") {
		#$page_url .= "s";
	}
	$page_url .= "://";
	if ($ENV{SERVER_PORT} != "80") {
		$page_url .= $ENV{SERVER_NAME}.":".$ENV{SERVER_PORT}.$ENV{REQUEST_URI};
	} else {
		$page_url .= $ENV{SERVER_NAME}.$ENV{REQUEST_URI};
	}	
	
	return $page_url;
	
}

sub SetupTool {
    my ( $self, $args ) = @_;
    my $cgi = $self->{'cgi'};
	
	require $PluginDir.'/admin/setuptool.pl';
	
	my $shaData = '';
	try{
		$shaData= get('https://widgets.ebscohost.com/prod/api/koha/sha/316.json');
		$shaData=decode_json($shaData);
	}catch{
		my $redirectURL = PageURL();
		print "Location $redirectURL\n\n";
	};
	my $xmlReleaseNotes = get('https://cdn.rawgit.com/ebsco/edsapi-koha-plugin/'.$shaData->{edsplugin}->{version}[0]->{sha}.'/Koha/Plugin/EDS/admin/release_notes.xml');
	#use Data::Dumper; die Dumper $xmlReleaseNotes;
	

    my $template = $self->get_template({ file => 'admin/setuptool.tt' });
	        $template->param(
			edsusername 		=> $self->retrieve_data('edsusername'),
			edspassword 		=> $self->retrieve_data('edspassword'),
			currentversion		=> $VERSION,
			latestversion		=>$shaData->{edsplugin}->{version}[0]->{number},
			releasenotes		=>$xmlReleaseNotes,	
        );

    print $cgi->header();
    print $template->output();
}
1;