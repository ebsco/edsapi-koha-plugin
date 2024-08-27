package Koha::Plugin::EDS;

use Modern::Perl;
use base qw(Koha::Plugins::Base);
use C4::Context;
use Encode qw(encode);
use URI::Escape;
use C4::Members;
use C4::Auth;
use Cwd            qw( abs_path );
use File::Basename qw( dirname );
use JSON qw/decode_json encode_json/;
use Try::Tiny;
use IO::Socket::SSL qw();
use WWW::Mechanize qw();
use MIME::Base64 qw( encode_base64 decode_base64 );
use Template;
use Template::Constants qw( :debug );
use Template::Filters;
Template::Filters->use_html_entities;
my $mech = WWW::Mechanize->new(ssl_opts => {
    SSL_verify_mode => IO::Socket::SSL::SSL_VERIFY_NONE,
    verify_hostname => 0,
});


my $pluginsdir = C4::Context->config("pluginsdir");
my @pluginsdir = ref($pluginsdir) eq 'ARRAY' ? @$pluginsdir : $pluginsdir;
my ($PluginDir) = grep { -f $_ . "/Koha/Plugin/EDS.pm" } @pluginsdir;
$PluginDir = $PluginDir.'/Koha/Plugin/EDS';

################# DO NOT TOUCH - CONTROLLED BY build.py
our $MAJOR_VERSION = "22.11";
our $SUB_VERSION = "002";
our $VERSION = $MAJOR_VERSION . "" . $SUB_VERSION;
our $SHA_ADD = "https://widgets.ebscohost.com/prod/api/koha/sha/1711.json";
our $DATE_UPDATE = '2024-04-15';
######################################################

## Here is our metadata, some keys are required, some are optional
our $metadata = {
    name   => 'Koha EDS API',
    author => 'EBSCO Library Service Engineers',
    description =>
'This plugin integrates EBSCO Discovery Service (EDS) in Koha. '. 
'Click the action drop down and select Configure to set up the API Plugin. '.
'More information is available at https://github.com/ebsco/edsapi-koha-plugin.  '.
'If you need additional help or need to report an issue to EBSCO, please contact us through https://connect.ebsco.com.',
    date_authored   => '2013-10-27',
    date_updated    => $DATE_UPDATE,
    minimum_version => $MAJOR_VERSION,
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

	#Get OpacUserJS Data
		my $OpacUserJS = C4::Context->preference("OpacUserJS");

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
			iprange				=> $self->retrieve_data('iprange'),
			edsinfo				=> $self->retrieve_data('edsinfo'),
			lastedsinfoupdate	=> $self->retrieve_data('lastedsinfoupdate'),
			authtoken			=> $self->retrieve_data('authtoken'),
			OPACBaseURL			=> C4::Context->preference('OPACBaseURL'),
			defaultparams	    => $self->retrieve_data('defaultparams'),
			autocomplete_mode	=> $self->retrieve_data('autocomplete_mode'),
			autocomplete	    => $self->retrieve_data('autocomplete'),
			PLUGIN_HTTP_PATH	=> $self->get_plugin_http_path(),


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
					iprange				=> ($cgi->param('iprange')?$cgi->param('iprange'):"-"),
					cookieexpiry 		=> ($cgi->param('cookieexpiry')?$cgi->param('cookieexpiry'):"-"),
					last_configured_by => C4::Context->userenv->{'number'},
					defaultparams	=> ($cgi->param('defaultparams')?$cgi->param('defaultparams'):"-"),
					autocomplete_mode	=> ($cgi->param('autocomplete_mode')?$cgi->param('autocomplete_mode'):"-"),
					autocomplete	=> ($cgi->param('autocomplete')?$cgi->param('autocomplete'):"-"),
					PLUGIN_HTTP_PATH	=> $self->get_plugin_http_path(),
				}
			);

			#Run script to update files from templates
			$self->update_EDSScript_js($cgi);
			
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
    }
    $self->go_home();
}

sub update_EDSScript_js {
    my ($self, $cgi) = @_;
	my $vars = {
		edsusername 		=> quotemeta(($cgi->param('edsusername')?$cgi->param('edsusername'):"-")),
		edspassword 		=> quotemeta(($cgi->param('edspassword')?$cgi->param('edspassword'):"-")),
		edsprofileid 		=> ($cgi->param('edsprofileid')?$cgi->param('edsprofileid'):"-"),
		edscustomerid 		=> ($cgi->param('edscustomerid')?$cgi->param('edscustomerid'):"-"),
		cataloguedbid 		=> ($cgi->param('cataloguedbid')?$cgi->param('cataloguedbid'):"-"),
		catalogueanprefix 	=> ($cgi->param('catalogueanprefix')?$cgi->param('catalogueanprefix'):"-"),
		defaultsearch 		=> ($cgi->param('defaultsearch')?$cgi->param('defaultsearch'):"-"),
		logerrors			=> ($cgi->param('logerrors')?$cgi->param('logerrors'):"-"),
		iprange				=> ($cgi->param('iprange')?$cgi->param('iprange'):"-"),
		cookieexpiry 		=> ($cgi->param('cookieexpiry')?$cgi->param('cookieexpiry'):"-"),
		defaultparams		=> ($cgi->param('defaultparams')?$cgi->param('defaultparams'):"-"),
		autocomplete_mode	=> ($cgi->param('autocomplete_mode')?$cgi->param('autocomplete_mode'):"-"),
		autocomplete		=> ($cgi->param('autocomplete')?$cgi->param('autocomplete'):"-"),
		authtoken 			=> $cgi->param('authtoken'),
		lastedsinfoupdate	=> $cgi->param('lastedsinfoupdate'),
		edsinfo 			=> quotemeta($self->retrieve_data('edsinfo')),
		PLUGIN_HTTP_PATH 	=> $self->get_plugin_http_path(),
	};
    #my $pluginsdir = C4::Context->config('pluginsdir');
    #my @pluginsdir = ref($pluginsdir) eq 'ARRAY' ? @$pluginsdir : $pluginsdir;
    #my @plugindirs;
    #foreach my $plugindir ( @pluginsdir ){
    #        $plugindir .= "/Koha/Plugin/EDS/js";
    #        push @plugindirs, $plugindir
    #}
    my $template = Template->new({
		INCLUDE_PATH 		=> $PluginDir,
		OUTPUT_PATH 		=> $PluginDir,
		PLUGIN_HTTP_PATH 	=> $self->get_plugin_http_path(),
    });
	$template->process('js/EDSScript.tt',$vars, 'js/EDSScript.js');
	$template->process('opac/templates/eds-methods.tt',$vars, 'opac/eds-methods.pl');
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



	#my $enableEDS = C4::Context->dbh->do("INSERT INTO `systempreferences` (`variable`, `value`, `explanation`, `type`) VALUES ('EDSEnabled', '1', 'If ON, enables searching with EDS - Plugin required.For assistance; email EBSCO support at support\@ebscohost.com', 'YesNo') ON DUPLICATE KEY UPDATE `variable`='EDSEnabled', `value`=1, `explanation`='If ON, enables searching with EDS - Plugin required.For assistance; email EBSCO support at support\@ebscohost.com', `type`='YesNo'");


	#my $enableEDSUpdate = C4::Context->dbh->do("UPDATE `systempreferences` SET `value`='1' WHERE `variable`='EDSEnabled'");

	my $pluginSQL = C4::Context->dbh->do("INSERT INTO `plugin_data` (`plugin_class`, `plugin_key`, `plugin_value`) VALUES ('Koha::Plugin::EDS', 'installedversion', '".$VERSION."')");
	#use Data::Dumper; die Dumper $pluginSQL;
}




sub uninstall() {
    my ( $self, $args ) = @_;
##Leaving this code incase this plugin needs its own table in the future
#    my $table = $self->get_qualified_table_name('config');

#    return C4::Context->dbh->do("DROP TABLE $table");
	#my $enableEDS = C4::Context->dbh->do("INSERT INTO `systempreferences` (`variable`, `value`, `explanation`, `type`) VALUES ('EDSEnabled', '0', 'If ON, enables searching with EDS - Plugin required.For assistance; email EBSCO support at support\@ebscohost.com', 'YesNo') ON DUPLICATE KEY UPDATE `variable`='EDSEnabled', `value`=1, `explanation`='If ON, enables searching with EDS - Plugin required.For assistance; email EBSCO support at support\@ebscohost.com', `type`='YesNo'");

	#my $enableEDSUpdate = C4::Context->dbh->do("UPDATE `systempreferences` SET `value`='0' WHERE `variable`='EDSEnabled'");
}

#Update the JS file to include the correct variables without needing to call SQL
sub update_search {
	my ( $self, $default_search) = @_;

}

sub opac_js {
    my ( $self ) = @_;
    my $default_search = $self->retrieve_data('defaultsearch');

    return q|
    <script>
    var defaultSearch="| . $default_search . q|";
    </script>
    <script src="|. $self->get_plugin_http_path() . q|/js/EDSScript.js">
    </script>
    |;
}


sub PageURL{
	# https://stackoverflow.com/questions/3412280/how-do-i-obtain-the-current-url-in-perl
	my $page_url = 'http';
	if ($ENV{HTTPS} == "on") {
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

	###BEGIN UpdatePlugin

	my $updateSHA = $cgi->param('updateto');
	my $updateVersion = $cgi->param('v');
	my $checkFile = $cgi->param('check');
	my $customJS = $cgi->param('js');
	my $jsCode = $cgi->param('code');


	my $updateLog = '';
	my $readWriteStatus = '';
	my @customJSContent;

	if(defined $checkFile){
		require $PluginDir.'/admin/setuptool.pl';
		$readWriteStatus = CheckWriteStatus($checkFile);
	}

	if(defined $customJS){
		require $PluginDir.'/admin/setuptool.pl';

		if($customJS eq "2"){
			SetCustomJS($jsCode);
		}

		@customJSContent = GetCustomJS();
		#use Data::Dumper; die Dumper scalar(@customJSContent);
		if(scalar(@customJSContent) eq 0){
			push(@customJSContent,'//Enter JavaScript here');
		}

	}

	if(defined $updateSHA){
		if($updateSHA ne 'done'){
			require $PluginDir.'/admin/setuptool.pl';
			$updateLog = UpdateEDSPlugin($updateSHA);
			my $updateInstalledVersion = C4::Context->dbh->do("UPDATE `plugin_data` SET `plugin_value`='".$updateVersion."' WHERE `plugin_class`='Koha::Plugin::EDS' and `plugin_key`='installedversion'");

		}
	}

	###END UpdatePlugin

	### Setup installed version no. in plugin table if this was not set during installation.
	my $installedVersionNo = $self->retrieve_data('installedversion');
	if(not defined $installedVersionNo){

		$self->store_data(
		{
			installedversion 		=> $VERSION,
		});
		$self->go_home();

	}


	## Pull SHA data for version info.
	my $shaData = '';
	try{
		$mech->get($SHA_ADD);
		$shaData= $mech->content();
		$shaData=decode_json($shaData);
	}catch{
		$shaData=decode_json('{"edsplugin": {"version": [{"number": "3.2201","sha": "9a10c2acfca0a4c7e13d74dd9dca4ff117b28a0e"}]}}');
	};
	$mech->get('https://cdn.jsdelivr.net/gh/ebsco/edsapi-koha-plugin@'.$shaData->{edsplugin}->{version}[0]->{sha}.'/Koha/Plugin/EDS/admin/release_notes.xml');
	my $xmlReleaseNotes = $mech->content();
	#use Data::Dumper; die Dumper $xmlReleaseNotes;

	my $currentVersion ="<select id='liveupdate-version'>";

	my @pluginVersions = @{$shaData->{edsplugin}->{version}};

	foreach my $pluginVersion (@pluginVersions){
			my $selectedVersion="";
			if($self->retrieve_data('installedversion') eq $pluginVersion->{number}){
				$selectedVersion=" selected='selected'";
			}
			$currentVersion .="<option value='".$pluginVersion->{sha}."'".$selectedVersion.">";
			$currentVersion .=$pluginVersion->{number};
			$currentVersion .="</option>";
	}


	$currentVersion .="</select>";


    my $template = $self->get_template({ file => 'admin/setuptool.tt' });
	        $template->param(
			edsusername 		=> $self->retrieve_data('edsusername'),
			edspassword 		=> $self->retrieve_data('edspassword'),
			pluginversion		=> $VERSION,
			installedversion	=> $currentVersion,
			latestversion		=>$shaData->{edsplugin}->{version}[0]->{number},
			releasenotes		=>$xmlReleaseNotes,
			updatelog			=>$updateLog,
			readwritestatus		=>$readWriteStatus,
			customjs			=>\@customJSContent,
			jsstate				=>$customJS,
			plugin_dir			=>$PluginDir,
        );

    print $cgi->header();
    print $template->output();
}
1;
