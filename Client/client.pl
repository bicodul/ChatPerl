use IO::Socket;
use IO::Select;
use POSIX;
use v5.10;


use constant {
# --- <Protocol infos> ---
  SEPARATION_CHAR 	=> '#',
  RECV_MESSAGE 		=> 'MESS',
  RECV_LIST 		=> 'LIST',
  RECV_PSEUDO 		=> 'NAME',
  RECV_ACCEPT 		=> 'OK',
  RECV_REFUSE 		=> 'KO',
  
  SEND_MESSAGE 		=> 'MESS',
  SEND_PSEUDO 		=> 'NAME',
  SEND_LIST 		=> 'LIST',
# --- </Protocol infos> ---
# --- <User command> ---
  USER_SEPARATION 	=> ' ',
  USER_PSEUDO 		=> '/name',
  USER_LIST 		=> '/list',
  USER_HELP 		=> '/help',
# --- </User command> ---
};



sub now{
    ($sec,$min,$hour,$mday,$mon) = localtime();
    $sec = sprintf("%02d", $sec);
    $min = sprintf("%02d", $min);
    $hour = sprintf("%02d", $hour);
    $mday = sprintf("%02d", $mday);
    $mon = sprintf("%02d", $mon+1);
    return "$mday/$mon $hour:$min";
}

# sub gererRecv{
#     $mess = shift;
#     if( $mess =~ /^$protocol_headers{recv_message}/){
#                     ($_, $pseudo, @messages) = split(":",$mess);
#                     return (now()." $pseudo a dit : ".join(":", @messages));
#     }
#     elsif( $mess =~ /^$protocol_headers{client_list}/){
#         ($_, @messages) = split(":", $mess);
#         print "Liste des participants :\n";
#         foreach $mess (@messages){
#             print " -$mess\n";
#         }
#     }
#     elsif($mess =~ /^$protocol_headers{edit_pseudo}/){
#         ($_, $mess) = split(":", $mess);
#         if($mess =~ /^$protocol_headers{server_refuse}/){
#             print "Le pseudo est deja utilise ou reserve\n";
#         }else{
#             print "Pseudo attribue\n";
#         }
#     }
#     else{
#         say "Le serveur a envoyé une commande inconnue";
#         say $mess;
#     }
# }

sub parseRecv{

  my $recv_message = shift || '';
  my @exploded_message = split( SEPARATION_CHAR,$recv_message );
  
  my $head = shift @exploded_message;  
  
  if( $head eq RECV_MESSAGE){
    return join( SEPARATION_CHAR,@exploded_message );
  }
  if( $head eq RECV_LIST){
    return join( "\n",@exploded_message );
  }
  if( $head eq RECV_PSEUDO){
    my $complementary_infos = shift @exploded_message;
    if( $complementary_infos eq RECV_ACCEPT){
      return 'Pseudo edited';
    }
    else{
      return 'Pseudo refused';
    }
  }
  
  return 'Unknow command';
}

sub buildSend{
  my $type = shift || SEND_MESSAGE;
  my $content;
  if( $type eq SEND_MESSAGE ){
    $content = shift || '';
    return SEND_MESSAGE.SEPARATION_CHAR.$content;
  }
  if( $type eq SEND_PSEUDO ){
    $content = shift || '';
    return SEND_PSEUDO.SEPARATION_CHAR.$content;
  }
  if( $type eq SEND_LIST ){
    return SEND_LIST;
  }
  return '';
}

sub parseUserCommand{
  my ( $command, $content ) = split( USER_SEPARATION,shift,1 );
  if( $command eq USER_PSEUDO ){
    return buildSend( SEND_PSEUDO,$content );
  }
  if( $command eq USER_LIST ){
    return buildSend( SEND_LIST );
  }
  if( $command eq USER_HELP ){
    return USER_PSEUDO.' '.USER_HELP.' '.USER_LIST;
  }
}

# sub gererSend{
#     $mess = shift;
#     if($mess =~ /^\/name/){
#         ($_, $mess) = split(" ", $mess);
#         $client->send("NAME:".$mess) or die "Server unreachable";
#     }elsif($mess =~ /^\/list/){
#         $client->send("LIST:") or die "Server unreachable";
#     }elsif($mess =~ /^\/help/){
#         print "Liste des commandes :\n";
#         print "/name <pseudo> : changer de pseudo.\n";
#         print "/list : liste les participants.\n";
#         print "/help : affiche ce message.\n";
#     }else{
#         $client->send("MESS:".$mess) or die "Server unreachable";
#     }
# }

# --- <Main> ---
my $host = shift || '127.0.0.1' ;
my $port = shift || 3500;
say "Tentative de connexion du client sur $host:$port";
$client = IO::Socket::INET->new(
			  Proto => 'tcp',
			  PeerAddr => $host,
			  PeerPort => $port
			) or die "Impossible de se connecter au serveur.\n";
			
my $select = new IO::Select();
$select->add($client);
$select->add(\*STDIN);
$client->autoflush(1);

while(1){
    foreach $test ($select->can_read(.5)) {
        if($test == $client){
            $test->recv($donnees, POSIX::BUFSIZ, 0);
            if($donnees ne '') {
                #print gererRecv($donnees);
                say parseRecv($donnees);
            }else{
                $test->close;
                print "Le serveur a rencontré un probleme.\n";
                exit(1);
            }
	}
        elsif($test == \*STDIN){
            $input = <STDIN>;
            $client->send( parseUserCommand( $input ) );
        }
    }
}
# --- </Main> ---

