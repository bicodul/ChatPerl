use v5.10;


sub configureWidgets{
    
my ($window, $vbox, $table, $textDiscu, $scrollDiscu, $shift, $textUser, $scrollUser, $listUsers, $scrollList, $buttonSend,
$menuFichiers, $fichiers, $menuOptions, $menuName, $menuHelp, $options, $vboxConnec, $hboxHost, $hboxHost2, $hboxPort, $hboxPort2, $hboxButtonCo,
$hboxPseudo, $hbox2Pseudo, $labelPseudo, $zonePseudo, $labelConnec, $labelHost, $labelPort, $zoneHost, $zonePort, $buttonConnec);
    
$window = Gtk2::Window->new('toplevel');
    $vbox = Gtk2::VBox->new(0, 0);
        $menubar = Gtk2::MenuBar->new();
            $fichiers = Gtk2::MenuItem->new_with_label("Fichiers");
                $menuFichiers = Gtk2::Menu->new();
                    $connec = Gtk2::MenuItem->new('Se connecter');
                    $deconnec = Gtk2::MenuItem->new('Se deconnecter');
                    $quitter = Gtk2::MenuItem->new('Quitter');
            $options = Gtk2::MenuItem->new_with_label("Options") ;
                $menuOptions= Gtk2::Menu->new();
                    $menuName = Gtk2::MenuItem->new_with_label("Changer de nom") ;
                    $menuHelp = Gtk2::MenuItem->new_with_label("Liste des commandes") ;
        $table = Gtk2::Table->new(6 ,3 ,1);
            $scrollDiscu = Gtk2::ScrolledWindow->new();
                $textDiscu = Gtk2::TextView->new;
            $scrollUser = Gtk2::ScrolledWindow->new();
                $textUser = Gtk2::TextView->new;
            $scrollList = Gtk2::ScrolledWindow->new();
                $listUsers = Gtk2::TextView->new;
            $buttonSend = Gtk2::Button->new('Send');
        $vboxConnec = Gtk2::VBox->new(0, 10);
            $labelConnec = Gtk2::Label->new("CONNECTION :");
            $hboxPseudo = Gtk2::HBox->new(0, 0);
                $hbox2Pseudo = Gtk2::HBox->new(0, 0);
                    $labelPseudo = Gtk2::Label->new("Pseudo :");
                    $zonePseudo = Gtk2::Entry->new();
            $hboxHost = Gtk2::HBox->new(0, 0);
                $hboxHost2 = Gtk2::HBox->new(0, 0);
                    $labelHost = Gtk2::Label->new("IP serveur :");
                    $zoneHost = Gtk2::Entry->new();
            $hboxPort = Gtk2::HBox->new(0, 0);
                $hboxPort2 = Gtk2::HBox->new(0, 0);
                    $labelPort = Gtk2::Label->new("Port :");
                    $zonePort = Gtk2::Entry->new();
            $hboxButtonCo = Gtk2::HBox->new(0, 0) ;
                $buttonConnec = Gtk2::Button->new( 'Valider' ) ;








$shift = 0;







#========== Declaration des widgets ===============

$window->signal_connect('delete_event' , sub { Gtk2->main_quit ; } ) ;
$window->set_title('Gato') ;
$window->set_border_width(5) ;
$window->set_default_size (450, 500);
$window->add($vbox);
$window->set_icon_from_file("./icon.png");

$table->set_row_spacings(5);
$table->set_col_spacings(5);


$textDiscu->set_editable(0);
$textDiscu->set_cursor_visible (0);
$textDiscu->set_wrap_mode (GTK_WRAP_WORD_CHAR);
$textDiscu->get_buffer->create_tag ("date","style", PANGO_STYLE_ITALIC, "size_points", 8);
$textDiscu->get_buffer->create_tag ("pseudo", "weight", 700);


$scrollDiscu->set_policy('automatic', 'automatic');
$scrollDiscu->add($textDiscu);
$table->attach_defaults($scrollDiscu, 0 , 2 , 0 , 5 ) ;



$textUser->set_wrap_mode (GTK_WRAP_WORD_CHAR);
$textUser->signal_connect("key_release_event",\&ToucheEntree, $textUser);
$textUser->signal_connect("key_press_event",\&ToucheShift);


$scrollUser->set_policy('automatic', 'automatic');
$scrollUser->add($textUser);
$table->attach_defaults($scrollUser, 0 , 2 , 5 , 6 ) ;


$listUsers->set_editable(0);
$listUsers->set_cursor_visible (0);
$listUsers->set_wrap_mode (GTK_WRAP_WORD_CHAR);

$listUsers->get_buffer->create_tag ("listeNoms","foreground", "green", "weight", 700);


$scrollList->set_policy('automatic', 'automatic');
$scrollList->add($listUsers);
$table->attach_defaults($scrollList, 2 , 3 , 0 , 5 ) ;


$buttonSend->signal_connect('clicked',\&ButtonSendClicked, $textUser);


$table->attach_defaults($buttonSend, 2 , 3 , 5 , 6 ) ;


$connec->signal_connect("activate",\&seConnecter);

$deconnec->signal_connect("activate",\&seDeconnecter);

$quitter->signal_connect('activate' , sub { Gtk2->main_quit ; } ) ;

$menuFichiers->append($connec) ;
$menuFichiers->append($deconnec) ;
$menuFichiers->append($quitter) ;
$fichiers->set_submenu($menuFichiers); 


$menuOptions->append($menuName) ;
$menuName->signal_connect("activate", \&creerFenetreName) ;
$menuOptions->append($menuHelp) ;
$menuHelp->signal_connect("activate", \&creerFenetreHelp) ;
$options->set_submenu($menuOptions); 


$menubar->append($fichiers);
$menubar->append($options);

$vbox->pack_start($menubar,0,0,0 ) ;
$vbox->pack_start($table,1,1,0 ) ;


$hbox2Pseudo->pack_start($labelPseudo,0,0,0 ) ;
$hbox2Pseudo->pack_start($zonePseudo,0,0,0 ) ;
$hboxPseudo->pack_start($hbox2Pseudo,1,0,0 ) ;




$zoneHost->set_text("127.0.0.1");

$zonePort->set_text("3500");



$hboxHost2->pack_start($labelHost,0,0,0 ) ;
$hboxHost2->pack_start($zoneHost,0,0,0 ) ;
$hboxPort2->pack_start($labelPort,0,0,0 ) ;
$hboxPort2->pack_start($zonePort,0,0,0 ) ;
$hboxPort->pack_start($hboxPort2,1,0,0 ) ;
$hboxHost->pack_start($hboxHost2,1,0,0 ) ;
$hboxButtonCo->pack_start($buttonConnec,1,0,0 ) ;
$vboxConnec->pack_start($labelConnec,0,0,10 ) ;
$vboxConnec->pack_start($hboxPseudo,0,0,0 ) ;
$vboxConnec->pack_start($hboxHost,0,0,0 ) ;
$vboxConnec->pack_start($hboxPort,0,0,0 ) ;
$vboxConnec->pack_start($hboxButtonCo,0,0,10 ) ;

$vboxConnec->signal_connect("key_release_event",\&ToucheEntreeMode1);

$vbox->pack_start($vboxConnec,1,1,0 ) ;

$window->show_all() ;
$table->visible(0);
$table->set_child_visible(0);
$options->visible(0);
$deconnec->visible(0);
$buttonConnec->signal_connect('clicked',\&seConnecter);

return ($window, $vbox, $table, $textDiscu, $scrollDiscu, $shift, $textUser, $scrollUser, $listUsers, $scrollList, $buttonSend,
    $menuFichiers, $fichiers, $menuOptions, $menuName, $menuHelp, $options, $vboxConnec, $hboxHost, $hboxHost2, $hboxPort, $hboxPort2, $hboxButtonCo,
    $hboxPseudo, $hbox2Pseudo, $labelPseudo, $zonePseudo, $labelConnec, $labelHost, $labelPort, $zoneHost, $zonePort, $buttonConnec);

}

1;