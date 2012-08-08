use IO::Socket;
use IO::Select;
use POSIX;
use Gtk2 '-init' ;
use Gtk2::Gdk::Keysyms;

my $window = Gtk2::Window->new( 'toplevel' ) ;
$window->signal_connect('delete_event' , sub { Gtk2->main_quit ; } ) ;
$window->set_title('Tchat') ;
$window->set_border_width(5) ;
$window->set_default_size (450, 500);

my $vbox = Gtk2::VBox->new(0, 0 ) ;
$window->add($vbox);

my $table = Gtk2::Table->new(4 ,3 ,1) ;
$table->set_row_spacings(5);
$table->set_col_spacings(5);

my $textDiscu = Gtk2::TextView->new;
$textDiscu->set_editable(0);
$textDiscu->set_cursor_visible (0);
$textDiscu->set_wrap_mode (GTK_WRAP_WORD_CHAR);

my $scrollDiscu = Gtk2::ScrolledWindow->new();
$scrollDiscu->set_policy('automatic', 'automatic');
$scrollDiscu->add($textDiscu);
$table->attach_defaults($scrollDiscu, 0 , 2 , 0 , 3 ) ;

my $shift = 0;
my $textUser = Gtk2::TextView->new;
$textUser->set_wrap_mode (GTK_WRAP_WORD_CHAR);
$textUser->signal_connect("key_release_event",\&ToucheEntree, $textUser);
$textUser->signal_connect("key_press_event",\&ToucheShift);

my $scrollUser = Gtk2::ScrolledWindow->new();
$scrollUser->set_policy('automatic', 'automatic');
$scrollUser->add($textUser);
$table->attach_defaults($scrollUser, 0 , 2 , 3 , 4 ) ;

my $listUsers = Gtk2::TextView->new;
$listUsers->set_editable(0);
$listUsers->set_cursor_visible (0);

$listUsers->set_wrap_mode (GTK_WRAP_WORD_CHAR);
my $scrollList = Gtk2::ScrolledWindow->new();
$scrollList->set_policy('automatic', 'automatic');
$scrollList->add($listUsers);
$table->attach_defaults($scrollList, 2 , 3 , 0 , 3 ) ;

my $buttonSend = Gtk2::Button->new( 'Send' ) ;
$buttonSend->signal_connect('clicked',\&ButtonSendClicked, $textUser);


$table->attach_defaults($buttonSend, 2 , 3 , 3 , 4 ) ;

$deco = Gtk2::MenuItem->new('Se deconnecter');
$quitter = Gtk2::MenuItem->new('Quitter');
$quitter->signal_connect('activate' , sub { Gtk2->main_quit ; } ) ;

$menubar = Gtk2::MenuBar->new();
$menubar->append($deco);
$menubar->append($quitter);

$vbox->pack_start($menubar,0,0,0 ) ;
$vbox->pack_start($table,1,1,0 ) ;

$window->show_all() ;


#------------------------------------------------------------------
$host = shift || "127.0.0.1" ;
$port = shift || 3500;
print "Tentative de connexion du client sur $host:$port\n";
my $client = IO::Socket::INET->new(
		     Proto => "tcp",
		     PeerAddr => $host,
		     PeerPort => $port
		    ) or die "Impossible de se connecter au serveur.";

my $select = new IO::Select();
$select->add($client);
$select->add(\*STDIN);

$client->autoflush(1);
#------------------------------------------------------------------

Glib::IO->add_watch (fileno $client, [qw/in/], \&recv, $client);

Gtk2->main ;

sub ButtonSendClicked {
    my ( $button, $texteView ) = @_ ;
    $buffer = $texteView->get_buffer;
    $texte = $buffer->get_text($buffer->get_start_iter,$buffer->get_end_iter,1);
    gererSend($texte."\n");
    $buffer->set_text("");
    $texteView->grab_focus;
}

sub ToucheEntree {
    my ($widget, $event, $texteView) = @_;
    if($event->keyval == 65293 and $shift == 0){
        $buffer = $texteView->get_buffer;
        $texte = $buffer->get_text($buffer->get_start_iter,$buffer->get_end_iter,1);
        gererSend($texte);
        $buffer->set_text("");
    }
	elsif($event->keyval == 65505){
		$shift = 0;
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
        insertDiscu("Liste des commandes :\n".
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
			insertDiscu(now()." $pseudo a dit : ".$mess, $textDiscu);
	}
	elsif( $mess =~ /^LIST#/){
	    ($_, @messages) = split("#", $mess);
		    $buffer = $listUsers->get_buffer;
	    $buffer->set_text("");
	    insertDiscu("Liste des participants :\n",$listUsers);
	    foreach $mess (@messages){
		insertDiscu(" -$mess\n",$listUsers);
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
	$texte = shift;
	$texteView = shift;
	$buffer = $texteView->get_buffer;
	$buffer->insert($buffer->get_end_iter, $texte);
	#$a = $scrollDiscu->get_vadjustment;
	#$scrollDiscu->set_vadjustment($a->lower);
}

sub now{
    ($sec,$min,$hour,$mday,$mon) = localtime();
    $sec = sprintf("%02d", $sec);
    $min = sprintf("%02d", $min);
    $hour = sprintf("%02d", $hour);
    $mday = sprintf("%02d", $mday);
    $mon = sprintf("%02d", $mon+1);
    return "$mday/$mon $hour:$min";
}

sub recv{
    $client->recv($donnees, POSIX::BUFSIZ, 0);
    if($donnees ne "") {
print "recue : $donnees\n";
        gererRecv($donnees);
    }else{
        $client->close;
        print "Le serveur a rencontré un probleme.\n";
        exit(1);
    }
	return 1;
}
