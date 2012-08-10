package Server;

use IO::Socket;
use IO::Select;
use POSIX;

use Moose;

has port => ( 
	is => 'ro',
	required => 1,
	default => '3500'
);

has clients => (
	is => 'rw',
);

has _listener => (
	is => 'rw',
	builder => '_build_listener',
	lazy => 1
);

has _event => (
	is => 'rw',
	builder => '_build_event',
	lazy => 1
); 

sub _build_listener{
	my $self = shift;
	return IO::Socket::INET->new(
		LocalPort => $self->port,
		Listen => 10,
		Reuse => 1
		);
}

sub _build_event{
	my $self = shift;
	my $select = IO::Select->new();
	$select->add(\*STDIN);
	$select->add( $self->_listener );
	return $select;
}

sub _edit_event{
	my ( $self, $client_socket, $action ) = @_;
	if( $action == 1 ){
		$self->_event->add($client_socket);
	}
	elsif( $action == 0 ){
		$self->_event->remove($client_socket);		
	}
}

sub run{
	
}

1;