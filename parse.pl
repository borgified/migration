#!/usr/bin/env perl

use warnings;
use strict;
use Net::LDAPS;
use Unicode::Map8;
use Unicode::String qw(utf16);

my %config = do '/secret/actian.config';

my($ldap) = Net::LDAPS->new($config{'host'}) or die "Can't bind to ldap: $!\n";


$ldap->bind(
	dn	=> "$config{'username'}",
	password => "$config{'password'}",
);

my($result) = $ldap->search(base => $config{'base'}, filter => '(&(cn=Juan Carlos Tong)(objectclass=user))');
#my($result) = $ldap->search(base => $config{'base'}, filter => '(&(cn=Joe Chen)(objectclass=user))');
#my($result) = $ldap->search(base => $config{'base'}, filter => '(&(pwdLastSet=0)(objectclass=user)(!(userAccountControl:1.2.840.113556.1.4.803:=2)))');

$result->code && die $result->error;

foreach ($result->entries) {
	my $dn = $_->get_value('distinguishedName');
	my $pwdLastSet = $_->get_value('pwdLastSet');
	print $dn."\n";
	print $pwdLastSet."\n";
	$result->code && die $result->error;
	#$result = $ldap->modify ( $dn, replace => { 'postalCode' => '94063' } );
#	$result = $ldap->modify ( $dn, replace => { 'pwdLastSet' => '-1' } );
#	$result->code && die $result->error;


#change password
#	my $newPW = 'migration';
#	my $charmap = Unicode::Map8->new('latin1')  or  die;
#	my $newUniPW = $charmap->tou('"'.$newPW.'"')->byteswap()->utf16();
	#
	#$result = $ldap->modify ( $dn, replace => { 'unicodePwd' => $newUniPW } );
	#$result->code && die $result->error;

}

$ldap->unbind;


__END__

open(INPUT,"Paraccel Mail Users.csv");

while(defined(my $line=<INPUT>)){
chomp $line;
my @items = split(/,/,$line);
print $items[0]." ".$items[4]."\n";
}
