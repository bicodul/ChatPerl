# MESS#NAME## envoyer un message
# NAME##envoyer une demande de pseudo le serveur repond NAME:OK ou NAME:KO
# LIST#requete de liste des utilisateurs

use IO::Socket;
use IO::Select;
use POSIX;

my $port = shift || 3500;

my $serveur = IO::Socket::INET->new(LocalPort => $port, Listen => 10, Reuse => 1)
or die "pb socket: $@\n";

print scalar localtime();
print " : Server started on port $port.\n";

$s = IO::Select->new();
$s->add(\*STDIN);
$s->add( $serveur );

my @clients;
my %client_pseudo;

sub liste{
$client = shift;
$client->send("LIST#".join("#", values %client_pseudo)."##");
}
sub listAll{
foreach $client (@clients){
liste($client);
}

}

while(1) {
READ :
foreach $test ($s->can_read(.5)) {
if($test == $serveur) {
$client = $serveur->accept();
$s->add($client);
push @clients, $client;
$client_pseudo{$client} = "AnonymousClient";
print "Connexion d'un nouveau client\n";
listAll;
}
else{

$test->recv($recv, POSIX::BUFSIZ, 0);
print "message recu :$recv: \n";
if($recv ne "") {
@donnees = split("##", $recv);
foreach $donnees (@donnees){
if($donnees =~ /^MESS#/) {
($_,$donnees) = split("#", $donnees);
foreach $client (@clients){
$client->send("MESS#".$client_pseudo{$test}."#".$donnees."##");
}
}
elsif($donnees =~ /^NAME#/){

print "-:", $client_pseudo{$test}, "Tentative de chgmt de pseudo.\n";
($_,$donnees) = split("#", $donnees);
foreach $pseudo (values %client_pseudo){
if($pseudo eq $donnees){
$test->send("NAME#KO##");
next READ;
}
}
$test->send("NAME#OK##");
$client_pseudo{$test} = $donnees;
print $client_pseudo{$test}, "\n";
listAll();
}
elsif($donnees =~ /^LIST#/){
liste($test);
}
else{
foreach $client ( @clients ){
$client->send("MESS#".$client_pseudo{$test}."#".$donnees."##");
}
}
print "Client ", $client_pseudo{$test}, ": ";
print $donnees, "\n";
}
}else {
print "Deconnexion d'un client\n";
delete $client_pseudo{$test};
@clients = grep { $_ != $test } @clients;
$s->remove($test);
$test->close;
listAll();
}

}

}
}