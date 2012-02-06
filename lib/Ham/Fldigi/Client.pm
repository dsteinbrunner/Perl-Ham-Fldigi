#!/usr/bin/perl

#==============================================================================
# Ham::Fldigi::Client
# v0.001
# (c) 2012 Andy Smith, M0VKG
#==============================================================================
# DESCRIPTION
# This module handles communications with a running fldigi instance
#==============================================================================
# SYNOPSIS
# use Ham::Fldigi;
# my $client = Ham::Fldigi::Client->new('localhost', 7362, 'default');
# $client->modem("BPSK125");
# $client->send("CQ CQ CQ DE M0VKG M0VKG M0VKG KN");
#==============================================================================

# Perl documentation is provided inline in pod format.
# To view, run:-
# perldoc Client.pm

package Ham::Fldigi::Client;

use 5.012004;
use strict;
use warnings;

use Moose;
use Data::GUID;
use RPC::XML::Client;
use Data::Dumper;
use Time::HiRes qw( usleep );
use POE qw( Wheel::Run );
use base qw(Ham::Fldigi::Debug);

has 'hostname' => (is => 'rw');
has 'port' => (is => 'rw');
has 'name' => (is => 'rw');
has 'url' => (is => 'ro');
has 'id' => (is => 'ro');
has '_xmlrpc' => (is => 'ro');
has '_session' => (is => 'ro');
has '_buffer_tx' => (is => 'ro');
has '_buffer_rx' => (is => 'ro');

our $VERSION = '0.001';

sub new {
	
	# Get our name, and set an ID
	my $class = shift;
	my $g = Data::GUID->new;

	# Fill in the class ID and version
	my $self =  {
		'version' => $VERSION,
		'id' => $g->as_string,
	};

	# Bless self
	bless $self, $class;

	$self->debug("Constructor called. Version ".$VERSION.", with ID ".$self->id.".");

	# Grab the passed client details
	my ($hostname, $port, $name) = @_;
	$self->hostname($hostname);
	$self->port($port);
	$self->name($name);
	$self->{url} = 'http://'.$hostname.':'.$port.'/RPC2';
	$self->debug("Hostname is ".$hostname.", port is ".$port." and name is ".$name.".");

	# Initialise the RPC::XML::Client object
	$self->{_xmlrpc} = RPC::XML::Client->new('http://'.$hostname.':'.$port.'/RPC2');

	# Check connectivity with the fldigi client by checking the version
	$self->debug("Checking connectivity with fldigi client at http://".$hostname.":".$port."/RPC2...");
	my $fldigi_version = $self->version;

	if(defined($fldigi_version)) {
		$self->debug("Version is ".$fldigi_version.".");
	} else {
		return undef;
	}

	$self->debug("Returning...");
	return $self;
}

sub command {

	my ($self, $cmd, $args) = @_;

	# If $args is unset, set it with an empty value
	if(!defined($args)) { $args = "" };

	$self->debug("Making XMLRPC call '".$cmd."' (args: ".$args.") to http://".$self->hostname.":".$self->port."/RPC2...");
	my $r = $self->_xmlrpc->simple_request($cmd, $args);

	# Check for undef response, which means there's been an error
	if($RPC::XML::ERROR ne "") {
		$self->warning("Error talking to ".$self->url."!");
		$self->warning("RPC::XML::Client reports: ".$RPC::XML::ERROR);
	}

	# If there's no response from XMLRPC, set it to '(null)'
	if(!defined($r)) { $r = "(null)"; };

	$self->debug("Response from XMLRPC request is: ".$r);
	return $r;
}

sub version {

	my ($self) = @_;
	my $r = $self->command('fldigi.version');

	return $r;

}

sub modem {

	my ($self, $modem) = @_;
	my $r = $self->command('modem.set_by_name', $modem);

	return $r;
}

sub send {

	my ($self, $text) = @_;

	# Clear the TX window of any existing text, add our text and then switch to TX.
	# We add a '^r' on the end to tell fldigi to stop once it's transmitted all
	# the waiting text.
	$self->command("text.clear_tx");
	$self->command("text.add_tx", $text."^r");
	$self->command("main.tx");

}

1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

Ham::Fldigi - Perl extension for blah blah blah

=head1 SYNOPSIS

  use Ham::Fldigi;
  blah blah blah

=head1 DESCRIPTION

Stub documentation for Ham::Fldigi, created by h2xs. It looks like the
author of the extension was negligent enough to leave the stub
unedited.

Blah blah blah.

=head2 EXPORT

None by default.



=head1 SEE ALSO

Mention other useful documentation such as the documentation of
related modules or operating system documentation (such as man pages
in UNIX), or any relevant external documentation such as RFCs or
standards.

If you have a mailing list set up for your module, mention it here.

If you have a web site set up for your module, mention it here.

=head1 AUTHOR

Andy Smith, E<lt>andys@E<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2012 by Andy Smith

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.12.4 or,
at your option, any later version of Perl 5 you may have available.


=cut
