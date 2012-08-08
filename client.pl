use IO::Socket;
use IO::Select;
use POSIX;

my $client;
sub now{
    ($sec,$min,$hour,$mday,$mon) = localtime();
    $sec = sprintf("%02d", $sec);
    $min = sprintf("%02d", $min);
    $hour = sprintf("%02d", $hour);
    $mday = sprintf("%02d", $mday);
    $mon = sprintf("%02d", $mon+1);
    return "$mday/$mon $hour:$min";
}
sub gererRecv{
    $mess = shift;
    if( $mess =~ /^MESS:/){
                    ($_, $pseudo, @messages) = split(":",$mess);
                    return (now()." $pseudo a dit : ".join(":", @messages));
    }
    elsif( $mess =~ /^LIST:/){
        ($_, @messages) = split(":", $mess);
        print "Liste des participants :\n";
        foreach $mess (@messages){
            print " -$mess\n";
        }
    }
    elsif($mess =~ /^NAME:/){
        ($_, $mess) = split(":", $mess);
        if($mess =~ /^KO/){
            print "Le pseudo est deja utilise ou reserve\n";
        }else{
            print "Pseudo attribue\n";
        }
    }
    else{
        print "Le serveur a envoyé une commande inconnue\n";
    }
}
sub gererSend{
    $mess = shift;
    if($mess =~ /^\/name/){
        ($_, $mess) = split(" ", $mess);
        $client->send("NAME:".$mess) or die "Server unreachable";
    }elsif($mess =~ /^\/list/){
        $client->send("LIST:") or die "Server unreachable";
    }elsif($mess =~ /^\/help/){
        print "Liste des commandes :\n";
        print "/name <pseudo> : changer de pseudo.\n";
        print "/list : liste les participants.\n";
        print "/help : affiche ce message.\n";
    }else{
        $client->send("MESS:".$mess) or die "Server unreachable";
    }
}



my $select = new IO::Select();

    $host = "127.0.0.1";
    $port = 3500;

    $client = IO::Socket::INET->new(
			     Proto => "tcp",
			     PeerAddr => $host,
			     PeerPort => $port
			    ) or die "Impossible de se connecter au serveur.";
    
    
    $select->add($client);
    $select->add(\*STDIN);
    
    $client->autoflush(1);

while(1){
    foreach $test ($select->can_read(.5)) {
        if($test == $client){
            $test->recv($donnees, POSIX::BUFSIZ, 0);
            if($donnees ne "") {
                print gererRecv($donnees);
                
            }else{
                $test->close;
                print "Le serveur a rencontré un probleme.\n";
                exit(1);
            }
	}
        elsif($test == \*STDIN){
            $foo = <STDIN>;
            gererSend($foo);
        }
    }
}
