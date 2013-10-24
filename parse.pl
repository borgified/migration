#!/usr/bin/env perl

use warnings;
use strict;
use Net::LDAPS;
use Unicode::Map8;
use Unicode::String qw(utf16);

sub main {

	my $employees = &parse_csv;
	my $passwd_count = 100;
	open(OUTPUT,">output.log");

	foreach my $key (sort keys %$employees){
		my $password = "Migration_".$passwd_count++;
		print "Processing : $key $$employees{$key}\n";
		my $success = &updateLDAP($key,$password);
		#my $success = 1;
		if($success){
			&email($$employees{$key},$password);
			print "email sent: $$employees{$key}\n";
		}else{
			print "problem with $key $$employees{$key}\n";
		}
		print OUTPUT "$$employees{$key} $password\n";
		print "===================================\n";
		sleep 1;
	}
}

&main;


sub updateLDAP{

	my($employee,$password) = @_;

	my %config = do '/secret/actian.config';

	my($ldap) = Net::LDAPS->new($config{'host'}) or die "Can't bind to ldap: $!\n";


	$ldap->bind(
		dn	=> "$config{'username'}",
		password => "$config{'password'}",
	);

	my($result) = $ldap->search(base => $config{'base'}, filter => "(&(cn=$employee)(objectclass=user))");
#my($result) = $ldap->search(base => $config{'base'}, filter => '(&(cn=Joe Chen)(objectclass=user))');
#my($result) = $ldap->search(base => $config{'base'}, filter => '(&(pwdLastSet=0)(objectclass=user)(!(userAccountControl:1.2.840.113556.1.4.803:=2)))');

	$result->code && die $result->error;

	if($result->entries == 1){
		print "searching for $employee... found.\n";
	}else{
		print "searching for $employee... NOT FOUND\n";
		return 0;
	}

	foreach ($result->entries) {
		my $dn = $_->get_value('distinguishedName');
		my $pwdLastSet = $_->get_value('pwdLastSet');

		print "found user : $dn\n";

		if($pwdLastSet == 0){
			print "found in AD: [X] User must change password at next logon (needs to uncheck)\n";
			$result = $ldap->modify ( $dn, replace => { 'pwdLastSet' => '-1' } );
			$result->code && die $result->error;
		}else{
			print "found in AD: [ ] User must change password at next logon (nothing to do)\n";
		}
		#$result = $ldap->modify ( $dn, replace => { 'postalCode' => '94063' } );


#change password
		my $newPW = $password;
		my $charmap = Unicode::Map8->new('latin1')  or  die;
		my $newUniPW = $charmap->tou('"'.$newPW.'"')->byteswap()->utf16();

		$result = $ldap->modify ( $dn, replace => { 'unicodePwd' => $newUniPW } );
		$result->code && die $result->error;
		print "new passwd: $password\n";

	}	

	$ldap->unbind;
	return 1;
}

sub parse_csv{
	open(INPUT,"Paraccel Mail Users.csv");
#	open(INPUT,"test.csv");
	my %employees;

	while(defined(my $line=<INPUT>)){
		if($line=~/^Display Name/){
			next; #skip header
		}
		chomp $line;
		my @items = split(/,/,$line);
		$employees{$items[0]}=$items[4];
		#print $items[0]." ".$items[4]."\n";
	}
	return \%employees;
}

sub email{

	open(MAIL, "|/usr/sbin/sendmail -t") or die $!;

#output to STDOUT for debug
#	open MAIL, '>&', STDOUT or die "error: $!";

	my %email = do '/secret/email.config';

	my $from=$email{'from'};
	my $subject='Your New Actian Credentials';
	my($to,$password)=@_;

	print MAIL "To: $to\n";
	print MAIL "From: $from\n";
	print MAIL "Subject: $subject\n\n";
	print MAIL <<EOF;
Hello,

  We apologize for the error in the previous email. Corrected username is below:

	Your E-mail will be migrated to Office365 this weekend. Below are your new Actian username and password.
Your e-mail address IS your Username. Please use this information along with the E-mail migration 
instructions provided earlier to test Outlook connectivity.

Your username is: $to

Your password is: $password

EOF
	;

	close(MAIL);
}
