#!/usr/bin/perl -w

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
#* DATE MODIFIED: 03/11/2013
#* LAST CHANGE DESCRIPTION: Added session and guest cookies
#=============================================================================================
#*/
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
use C4::Auth;    # get_template_and_user
use C4::Output;
use LWP;
use IO::File;
use JSON;
use URI::Escape;
use HTML::Entities;
use Cwd            qw( abs_path );
use File::Basename qw( dirname );
use utf8;
use open ':encoding(utf-8)';
use Modern::Perl;
use base qw(Koha::Plugins::Base);
use C4::Context;
use C4::Members;
use LWP::Simple qw(get);
use Try::Tiny;
use File::Find qw(finddepth);
use POSIX qw(strftime);

my $PluginDir = C4::Context->config("pluginsdir");
$PluginDir = $PluginDir.'/Koha/Plugin/EDS';
my $htaccessWrite = 0;

sub CheckWriteStatus{
	my($FilePath) = @_;
	my $checkStatus=0;
	#use Data::Dumper; die Dumper $PluginDir.$FilePath;
	#try{
		open FILE, "<", $PluginDir.$FilePath or die $!;
		if(-f FILE){
			if(-w FILE){
				$checkStatus=1;
			}
		}
		close(FILE);
	#}catch{}
	
	return $checkStatus;
}

sub GetCustomJS{
	my @customJSCode;
	my $customjsFile = $PluginDir."/js/custom/custom.js";

	if(-e $customjsFile){
		open FILE, "<", $customjsFile or die $!;
		@customJSCode = <FILE>;
		close FILE;
	}

	return @customJSCode;
}

sub SetCustomJS{
	my ($jsCode) = @_;	
	
	unless (-f $PluginDir."/js/custom/custom.js") {
		open my $fc, ">", $PluginDir."/js/custom/custom.js";
    	close $fc;
	}
	open FILE, "+>", $PluginDir."/js/custom/custom.js" or die $!;
	print FILE $jsCode;
	close FILE;
}

sub UpdateEDSPlugin{

my ($PluginSha) = @_;
	my $updateLog="";
	#use Data::Dumper; die Dumper "ok-".$PluginSha;

	my @files;
	 finddepth(sub {
		  return if($_ eq '.' || $_ eq '..');
		  push @files, $File::Find::name;
	 }, $PluginDir);
	 
	 #use Data::Dumper; die Dumper @files;
	 
	 foreach my $file (@files){
		if(-f $file ){
			if(not $file =~m/\/admin/){
				if(not $file =~m/custom\.js/){
					my $gitFile = $file;
					$gitFile=~s/$PluginDir//;
					my $gitURL = 'https://cdn.rawgit.com/ebsco/edsapi-koha-plugin/'.$PluginSha.'/Koha/Plugin/EDS'.$gitFile;
					my $sourceCode = get($gitURL);
					try{
						open FILE, "+>", $file or die $!;
						print FILE $sourceCode;
						close(FILE);
						$updateLog .= "<p class='alert-success'> Updated at [".strftime('%Y-%m-%d %H:%M:%S',localtime)."]: ".$file."</p>";
					}catch{
						$updateLog .= " <p class='alert-danger'> Error at [".strftime('%Y-%m-%d %H:%M:%S',localtime)."]: ".$file." $_</p>";
					}
				}
			}
	 	}
			# Applying .htaccess here in the foreach. TODO - move this out so the check doesnt need to happen
				if($htaccessWrite==0){
					$htaccessWrite = 1;
					try{
						open FILE, "+>", $PluginDir."/opac/.htaccess"  or die $!;
						print FILE "Options +ExecCGI \nAddHandler cgi-script .cgi .pl";
						close(FILE);
						$updateLog .= " <p class='alert-info'> Applied at [".strftime('%Y-%m-%d %H:%M:%S',localtime)."]: +ExecCGI for opac directory </p>";
					}catch{
						$updateLog .= " <p class='alert-danger'> Error at [".strftime('%Y-%m-%d %H:%M:%S',localtime)."]: Failed to apply +ExecCGI for opac directory $_</p>";
					}
				}
	 }	 
	# http://www.perlfect.com/articles/perlfile.shtml - PERL file operations 
	#use Data::Dumper; die Dumper $PluginDir."/opac/.htaccess";

	return $updateLog;	
	 
}
 
1;