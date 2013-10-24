#!/usr/bin/env perl

open(MAIL, "|/usr/sbin/sendmail -t");

my %email = do '/secret/email.config';

my $from=$email{'from'};
my $subject='test';
my $to=$email{'to'};

print MAIL "To: $to\n";
print MAIL "From: $from\n";
print MAIL "Subject: $subject\n\n";
print MAIL <<EOF;
this is a template for emailing
it has this field and that field
and 3 lines.

EOF
;

close(MAIL);
