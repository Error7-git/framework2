#!/usr/bin/perl
###############

##
#         Name: Socket.pm
#       Author: H D Moore <hdm [at] metasploit.com>
#      Version: $Revision$
#      License:
#
#      This file is part of the Metasploit Exploit Framework
#      and is subject to the same licenses and copyrights as
#      the rest of this package.
#
##

package Pex::Socket;
use strict;
use IO::Socket;
use IO::Select;

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT = qw(socks_setup);
our @EXPORT_OK = qw(socks_setup);

my $SSL_SUPPORT;

# Determine if SSL support is enabled
BEGIN
{
    if (eval "require Net::SSLeay")
    {
        Net::SSLeay->import();
        Net::SSLeay::load_error_strings();
        Net::SSLeay::SSLeay_add_ssl_algorithms();
        Net::SSLeay::randomize(time() + $$);
        $SSL_SUPPORT++;
    }
}


sub new {
  my $class = shift;
  my $self = bless({ }, $class);

  my $hash = shift;
  $self->SetOptions($hash);

  return($self);
}

sub SetOptions {
  my $self = shift;
  my $hash = shift;

  if(exists($hash->{'UseSSL'})) {
    my $use = $hash->{'UseSSL'};
    if($SSL_SUPPORT == 0 && $use) {
      $self->SetError('UseSSL option is set, but Net::SSLeay has not been installed.');
      return;
    }
    $self->UseSSL($use);
  }
  if(exists($hash->{'Proxies'})) {
    my $proxies = $hash->{'Proxies'};
    $self->AddProxies(@{$proxies});
    return if($self->GetError);
  }

  return;
}

sub UseSSL {
  my $self = shift;
  $self->{'UseSSL'} = shift if(@_);
  return($self->{'UseSSL'});
}

sub GetProxies {
  my $self = shift;
  return($self->{'Proxies'});
}

sub AddProxies {
  my $self = shift;
  while(@_ >= 3) {
    my $type = shift;
    my $ip = shift;
    my $port = shift;
#    if($type eq 'Socks4' || $type eq 'Socks5') {
#      if(!$SOCKS_SUPPORT) {
#        $self->SetError('A Socks proxy is set, but Net::SOCKS has not been installed.');
#        return;
#      }
#      push(@{$self->['Proxies']}, [ $type, $ip, $port ]);
#    }
  }
}

sub SetError {
  my $self = shift;
  my $error = shift;
  $self->{'Error'} = $error;
}

sub GetError {
  my $self = shift;
  return($self->{'Error'});
}

sub GetSocket {
  my $self = shift;
  return($self->{'Socket'});
}

sub SetBuffer {
  my $self = shift;
  my $buffer = shift;
  $self->{'Buffer'} = $buffer;
}
sub AddBuffer {
  my $self = shift;
  my $buffer = shift;
  $self->{'Buffer'} .= $buffer;
}
sub GetBuffer {
  my $self = shift;
  my $size = @_ ? shift : 999999999;

  return(substr($self->{'Buffer'}, 0, $size));
}

sub RemoveBuffer {
  my $self = shift;
  my $size = @_ ? shift : 999999999;

  return(substr($self->{'Buffer'}, 0, $size, ''));
}

sub SocketError {
  my $self = shift;
  my $ignoreConn = shift;

  my $reason;
  if(!$self->GetSocket) {
    $reason = 'no socket';
  }
  elsif(!$ignoreConn && !$self->GetSocket->connected) {
    $reason = 'not connected';
  }

  if($reason) {
    $self->SetError('Invalid socket: ' . $reason);
    return(1);
  }

  return(0);
}

sub Close {
  my $self = shift;
  if($self->GetSocket) {
    if($self->UseSSL) {
      Net::SSLeay::Free($self->{'SSLFd'});
      Net::SSLeay::CTX_free($self->{'SSLCtx'});
    }
    $self->GetSocket->close;
  }
}

sub TcpConnectSocket {
  my $self = shift;
  my $host = shift;
  my $port = shift;
  my $localPort = shift;

  my $proxies = $self->GetProxies;
  if($localPort && $proxies) {
    $self->SetError('A local port was specified and proxies are enabled, they are mutually exclusive.');
    return;
  }

  # Proxy stuff goes here, currently unsupported.

  my %config = (
    'PeerAddr'  => $host,
    'PeerPort'  => $port,
    'Proto'     => 'tcp',
    'ReuseAddr' => 1,
  );

  $config{'LocalPort'} = $localPort if($localPort);

  my $sock = IO::Socket::INET->new(%config);

  if(!$sock || !$sock->connected) {
    $self->SetError('Connection failed: ' . $!);
    return;
  }

  return($sock)
}

sub Tcp {
  my $self = shift;
  my $host = shift;
  my $port = shift;
  my $localPort = shift;

  return if($self->GetError);

  $self->{'Socket'} == undef;
  $self->SetError(undef);

  my $sock = $self->TcpConnectSocket($host, $port, $localPort);
  return if($self->GetError || !$sock);

  $self->{'Socket'} = $sock;


  if($self->UseSSL) {
    # Create SSL Context
    $self->{'SSLCtx'} = Net::SSLeay::CTX_new;
    # Configure session for maximum interoperability
    Net::SSLeay::CTX_set_options($self->{'SSLCtx'}, &Net::SSLeay::OP_ALL);
    # Create the SSL file descriptor
    $self->{'SSLFd'}  = Net::SSLeay::new($self->{'SSLCtx'});
    # Bind the SSL descriptor to the socket
    Net::SSLeay::set_fd($self->{'SSLFd'}, $sock->fileno);        
    # Negotiate connection
    my $sslConn = Net::SSLeay::connect($self->{'SSLFd'});

    if($sslConn <= 0) {
      $self->SetError('Error setting up ssl: ' . Net::SSLeay::print_errs);
      $self->close;
      return;
    }
  }

  # we have to wait until after the SSL negotiation before 
  # setting the socket to non-blocking mode

  $sock->blocking(0);
  $sock->autoflush(1);

  return($sock->fileno);
}

sub Udp {
  my $self = shift;
  my $host = shift;
  my $port = shift;
  my $localPort = shift;

  return if($self->GetError);

  my %config = (
    'PeerAddr'   => $host,
    'PeerPort'   => $port,
    'Proto'      => 'udp',
    'ReuseAddr'  => 1,
  );

  $config{'LocalPort'} = $localPort if($localPort);
  $config{'Broadcast'} = 1 if($host =~ /\.255$/);

  my $sock = IO::Socket::INET->new(%config);

  if(!$sock) {
    $self->SetError('Socket failed: ' . $!);
    return;
  }

  $sock->blocking(0);
  $sock->autoflush(1);

  # Disable SSL
  $self->UseSSL(0);
  $self->{'Socket'} = $sock;
  return($sock->fileno);
}

sub Send {
  my $self = shift;
  my $data = shift;
  my $delay = @_ ? shift : .1;

  return if($self->GetError);

  my $failed = 5;
  while(length($data)) {
    return if($self->SocketError);

    my $sent;
    if($self->UseSSL) {
      $sent = Net::SSLeay::ssl_write_all($self->{'SSLFd'}, $data);
    }
    else {
      $sent = $self->GetSocket->send($data);
    }

    last if($sent == length($data));

    $data = substr($data, $sent);
    if(!--$failed) {
      $self->SetError("Write retry limit reached.");
      return(0);
    }
    select(undef, undef, undef, $delay); # sleep
  }
  return(1);
}


sub Recv {
  my $self = shift;
  my $length = shift;
  my $timeout = @_ ? shift : 0;

  $length = 99999999 if($length == -1);

  return if($self->GetError);
  return if($self->SocketError(1));

  # Try to get any data out of our own buffer first
  my $data = $self->RemoveBuffer($length);
  $length -= length($data);

  my $selector = IO::Select->new($self->GetSocket);

  my $sslEmptyRead = 5;

  while($length) {
    my ($ready) = $selector->can_read($timeout);

    if(!$ready) {
      $self->SetError("Timeout $timeout reached.");
      $self->SetError("Socket disconnected.") if(!$self->GetSocket->connected);
      return($data);
    }

    # We gotz data y0
    my $tempData;
    if($self->UseSSL) {
      # Using select() with SSL is tricky, even though the socket
      # may have data, the SSL session may not. There isn't really
      # a clean way around this, so we just try until we get two
      # empty reads in a row or we time out
      
      $tempData = Net::SSLeay::read($self->{'SSLFd'});
      if(!length($tempData)) {
        if($timeout && !--$sslEmptyRead) {
          $self->SetError('Dry ssl read, out of tries');
          return($data);
        }
        select(undef, undef, undef, .1);
        next;
      }
    }
    else {
      $self->GetSocket->recv($tempData, $length);
      if(!length($tempData)) {
        $self->SetError('Socket is dead.');
        return($data);
      }
    }

    $data .= $tempData;
    if(length($tempData) > $length) {
      $self->AddBuffer(substr($tempData, $length));
      $tempData = substr($tempData, 0, $length);
    }
    $length -= length($tempData);
  }

  return($data);
}

1;
