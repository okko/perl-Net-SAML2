package Net::SAML2::IdP;
use strict;
use warnings;

=head1 NAME

Net::SAML2::IdP - SAML Identity Provider object

=head1 SYNOPSIS

  my $idp = Net::SAML2::IdP->new_from_url($IDP);
  my $sso_url = $idp->sso_url('urn:oasis:names:tc:SAML:2.0:bindings:HTTP-Redirect');

=head1 METHODS

=cut

use HTTP::Request::Common;
use LWP::UserAgent;
use XML::XPath;

=head2 new_from_url($url)

Create an IdP object by retrieving the metadata at the given URL.

Dies if the metadata can't be retrieved.

=cut

sub new_from_url {
        my ($class, $url) = @_;
        
        my $req = GET $url;
        my $ua = LWP::UserAgent->new;

        my $res = $ua->request($req);
        die "no metadata" unless $res->is_success;
        my $xml = $res->content;

	return $class->new($xml);
}

=head2 new($xml)

Constructor. Create an IdP object using the provided metadata XML
document.

=cut

sub new {
	my ($class, $xml) = @_;
        my $self = bless {}, $class;

        my $xpath = XML::XPath->new( xml => $xml );
        $xpath->set_namespace('md', 'urn:oasis:names:tc:SAML:2.0:metadata');

        my @ssos = $xpath->findnodes('//md:EntityDescriptor/md:IDPSSODescriptor/md:SingleSignOnService');
        for my $sso (@ssos) {
                my $binding = $sso->getAttribute('Binding');
                $self->{SSO}->{$binding} = $sso->getAttribute('Location');
        }

        my @slos = $xpath->findnodes('//md:EntityDescriptor/md:IDPSSODescriptor/md:SingleLogoutService');
        for my $slo (@slos) {
                my $binding = $slo->getAttribute('Binding');
                $self->{SLO}->{$binding} = $slo->getAttribute('Location');
        }

        my @arts = $xpath->findnodes('//md:EntityDescriptor/md:IDPSSODescriptor/md:ArtifactResolutionService');
        for my $art (@arts) {
                my $binding = $art->getAttribute('Binding');
                $self->{Art}->{$binding} = $art->getAttribute('Location');
        }
        
        return $self;
}

=head2 sso_url($binding)

Returns the url for the SSO service using the given binding. Binding
name should be the full URI. 

=cut

sub sso_url {
        my ($self, $binding) = @_;
        return $self->{SSO}->{$binding};
}

=head2 slo_url($binding)

Returns the url for the Single Logout Service using the given
binding. Binding name should be the full URI.

=cut

sub slo_url {
        my ($self, $binding) = @_;
        return $self->{SLO}->{$binding};
}

=head2 art_url($binding)

Returns the url for the Artifact Resolution service using the given
binding. Binding name should be the full URI.

=cut

sub art_url {
        my ($self, $binding) = @_;
        return $self->{Art}->{$binding};
}

1;
