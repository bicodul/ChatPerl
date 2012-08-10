use IO::Socket;
use IO::Select;
use POSIX;
use Gtk2 '-init' ;
use Gtk2::Gdk::Keysyms;
use v5.10;

require "configureWidget.pl";

my $client;
my $connected = 0;

my ($window, $vbox, $table, $textDiscu, $scrollDiscu, $shift, $textUser, $scrollUser, $listUsers, $scrollList, $buttonSend,
    $menuFichiers, $fichiers, $menuOptions, $menuName, $menuHelp, $options, $vboxConnec, $hboxHost, $hboxHost2, $hboxPort, $hboxPort2, $hboxButtonCo,
    $hboxPseudo, $hbox2Pseudo, $labelPseudo, $zonePseudo, $labelConnec, $labelHost, $labelPort, $zoneHost, $zonePort, $buttonConnec)
  = configureWidgets();

Gtk2->main ;

sub ButtonSendClicked {
  my ( $button, $texteView ) = @_ ;
  $buffer = $texteView->get_buffer;
  $texte = $buffer->get_text($buffer->get_start_iter,$buffer->get_end_iter,1);
  $buffer->set_text("");
  gererSend($texte."\n");
  $texteView->grab_focus;
}

sub ToucheEntree {
  my ($widget, $event, $texteView) = @_;
  if($event->keyval == 65293 and $shift == 0){
    $buffer = $texteView->get_buffer;
    $texte = $buffer->get_text($buffer->get_start_iter,$buffer->get_end_iter,1);
    $buffer->set_text("");
    gererSend($texte);
  }
  elsif($event->keyval == 65505){
    $shift = 0;
  }
}

sub ToucheEntreeMode1 {
  my ($widget, $event) = @_;
  if($event->keyval == 65293){
    seConnecter();
  }
}

sub gererSend{
  $mess = shift;
  if($mess =~ /^\/name/){
    ($_, $mess) = split(" ", $mess);
    $client->send("NAME#".$mess."##") or die "Server unreachable";
  }elsif($mess =~ /^\/list/){
    $client->send("LIST# ##") or die "Server unreachable";
  }elsif($mess =~ /^\/help/){
    insertDiscu("", "Liste des commandes :\n".
    "/name <pseudo> : changer de pseudo.\n".
    "/list : liste les participants.\n".
    "/help : affiche ce message.\n", $textDiscu);
  }else{
    $client->send("MESS#".$mess."##") or die "Server unreachable";
  }
}


sub gererRecv{
  $message = shift;
  @mess = split("##", $message);
  foreach $mess (@mess){
    if( $mess =~ /^MESS#/){
      ($_, $pseudo, $mess) = split("#",$mess);
      insertDiscu("date", now()."\n", $textDiscu);
      insertDiscu("pseudo", "$pseudo : ", $textDiscu);
      insertDiscu("", $mess, $textDiscu);
      if($window->has_focus) {
	$window->set_title('Gato (1)') ;
      }
    }
    elsif( $mess =~ /^LIST#/){
      ($_, @messages) = split("#", $mess);
      $buffer = $listUsers->get_buffer;
      $buffer->set_text("");
      insertDiscu("", "Liste des participants :\n",$listUsers);
      foreach $mess (@messages){
	insertDiscu("listeNoms", " - $mess\n",$listUsers);
      }
    }
    elsif($mess =~ /^NAME#/){
      ($_, $mess) = split("#", $mess);
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
}

sub ToucheShift {
  my ($widget, $event) = @_;
  if($event->keyval == 65505){
    $shift = 1;
  }
}

sub insertDiscu {
  $tag = shift;
  $texte = shift;
  $texteView = shift;
  $buffer = $texteView->get_buffer;
  if ($tag ne "") {
    $buffer->insert_with_tags_by_name($buffer->get_end_iter, $texte, $tag);
  }
  else {
    $buffer->insert($buffer->get_end_iter, $texte);
  }
  $insert =$buffer->get_insert;
  $texteView->scroll_to_mark($insert, 0, 0, 1, 1);
}

sub now{
  ($sec,$min,$hour,$mday,$mon) = localtime();
  $sec = sprintf("%02d", $sec);
  $min = sprintf("%02d", $min);
  $hour = sprintf("%02d", $hour);
  $mday = sprintf("%02d", $mday);
  $mon = sprintf("%02d", $mon+1);
  return "$mday/$mon $hour:$min.$sec";
}

sub recv{
  $result = $client->recv($donnees, POSIX::BUFSIZ, 0);
  if($donnees ne "" && $result != -1) {
    print "recue : $donnees\n";
    gererRecv($donnees);
  }else{
    $client->close;
    print "Le serveur a rencontré un probleme.\n";
    exit(1);
  }
  return 1;
}

sub seDeconnecter {
  $vboxConnec->show;
  $vboxConnec->set_child_visible(1);
  $connec->show;

  $deconnec->visible(0);
  $table->visible(0);
  $table->set_child_visible(0);
  $options->visible(0);
  $options->set_child_visible(0);

  $client->close;
}

sub seConnecter {
  $deconnec->show;
  $table->show;
  $table->set_child_visible(1);
  $options->show;
  $options->set_child_visible(1);
  $vboxConnec->visible(0);
  $vboxConnec->set_child_visible(0);
  $connec->visible(0);

  $host = $zoneHost->get_text;
  $port = int($zonePort->get_text);

  print "Tentative de connexion du client sur $host:$port\n";

  $client = IO::Socket::INET->new(
		    Proto => "tcp",
		    PeerAddr => $host ,
		    PeerPort => $port
		    ) or die "erreur connection socket";


  $client->autoflush(1);
  if(!$connected){
    $connected = 1;
    Glib::IO->add_watch (fileno $client, [qw/in/], \&recv, $client);
  }
  if($zonePseudo->get_text ne ""){
    $client->send("NAME#".$zonePseudo->get_text."##")
  }
}

sub creerFenetreHelp{
    $windowHelp = Gtk2::Window->new( 'toplevel' ) ;
    $windowHelp->set_title('Liste des commandes') ;
    $windowHelp->set_border_width(5) ;
    $windowHelp->set_resizable(0);

    $label = Gtk2::Label->new( "Liste des commandes :\n".
    "	/name <pseudo> : changer de pseudo.\n".
    "	/list : liste les participants.\n".
    "	/help : affiche ce message.\n" );

    $windowHelp->add($label); 
    $windowHelp->show_all;
}

sub creerFenetreName{
    $windowName = Gtk2::Window->new( 'toplevel' ) ;
    $windowName->set_title('Changer de nom') ;
    $windowName->set_border_width(5) ;
    $windowName->set_resizable(0);

    $box = Gtk2::VBox->new( FALSE, 5 ) ;
    $label = Gtk2::Label->new( "Nouveau nom :" );
    $box->pack_start($label, FALSE, FALSE, 0 );
    
    $zoneTexte = Gtk2::Entry->new();
    $box->pack_start($zoneTexte, FALSE, FALSE, 0 );
    $zoneTexte->signal_connect("key_release_event", sub {
	my ($widget, $event) = @_;
	if($event->keyval == 65293){
	  if($zoneTexte->get_text ne "") {
	    $client->send("NAME#".$zoneTexte->get_text."##") or die "Server unreachable";
	  }
	  $windowName->destroy;
	}
    });
    
    my $buttonValiderN = Gtk2::Button->new( 'Valider' ) ;
    $buttonValiderN->signal_connect('clicked',sub {
      if($zoneTexte->get_text ne "") {
	$client->send("NAME#".$zoneTexte->get_text."##") or die "Server unreachable";
      }
      $windowName->destroy;
    });
    $box->pack_start($buttonValiderN, FALSE, FALSE, 0 );

    $windowName->add($box); 
    $windowName->show_all;
}