#!/usr/bin/perl
###############

##
#         Name: x86.pm
#       Author: spoonm <ninjatools [at] hush.com>
#      Version: $Revision$
#      License:
#
#      This file is part of the Metasploit Exploit Framework
#      and is subject to the same licenses and copyrights as
#      the rest of this package.
#
##

package Pex::x86;
use strict;

sub jmpShort {
  my $dist = number(shift, -2);
  return("\xeb" . numberPackLSB($dist));
}

sub number {
  my $number = shift;
  my $delta = @_ ? shift : 0;

  if(substr($number, 0, 2) eq '$+') {
    $number = substr($number, 2);
  }
  else {
    $delta = 0;
  }

  if(substr($number, 0, 2) eq '0x') {
    $number = hex($number);
  }
  $number += $delta;

  return($number);
}

sub numberPackLSB {
  my $number = shift;
  return(substr(numberPack($number), 0, 1));
}

sub numberPack {
  my $number = shift;
  return(pack('V', $number));
}

1;
