package Client;
use Moose;

has name => (
	is => 'rw',
	required => 1,
	default => 'Anonymous',
	isa => 'Str'	
);

has connection => (
	is => 'ro',
	required => 1
);

1;