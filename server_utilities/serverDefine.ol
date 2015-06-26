/*
*
* Author => Gruppo LOBSTER
* Data => 26/06/2015
* 
* Parent => Server
*
* Servizio di define, i quali sono richiamati dal servizio
* server, per eseguire i comandi seguenti:
* - inizializzazione della visita delle cartelle
* - visita ricorsiva delle cartelle
* - operazione modulo per gestire l'incremento dei readers/writers
*/



/*
 * Inizializzazione della visita e chiamata ricorsiva
 */ 
define initializeVisita
{

	i = 1;

	visita
}



/* 
 * Definizione della visita ricorsiva di tutte le cartelle
 */
define visita
{
	 
    root.directory = abDirectory;

	list@File(root)(subDir);

	for(j = 0, j < #subDir.result, j++) {

		// Salva il percorso assoluto e relativo
		cartelle.sottocartelle[i].abNome = abDirectory + "/" + subDir.result[j];

		newRoot.directory = cartelle.sottocartelle[i].abNome;

		// Viene controllato se la cartella ha delle sottocartelle, 
		// se non le ha si salva tutto il percorso per arrivare in quella cartella
		list@File( newRoot )( last );

		if(#last.result == 0)  {

			len = #folderStructure.file;

			currentFileAbsName -> cartelle.sottocartelle[i].abNome;

		 	currentFileAbsName.substring = ".";

		 	contains@StringUtils( currentFileAbsName )( containsAFile );

		 	if( containsAFile == true ) 

			 	folderStructure.file[len] = currentFileAbsName
		};

		i++
    };

	i = 1;

	// Finchè una sottocartella è già stata visitata, si passa alla successiva
	while( cartelle.sottocartelle[i].mark == true && i < #cartelle.sottocartelle) {

		i++
	};

	// Se non si è arrivati alla fine di tutte le sottocartelle, l'attributo mark della cartella viene
	// settato a true, e si richiama il metodo visita
	if( is_defined( cartelle.sottocartelle[i].abNome )) {

		cartelle.sottocartelle[i].mark = true;

		abDirectory = cartelle.sottocartelle[i].abNome;

		i = #cartelle.sottocartelle;

		visita
	}
}



/*
 * Definizione del modulo, nel quale si passa l'id del reader o writer e si esegue
 * il modulo per individuare l'indice dove è contenuto il numero di readers/writers,
 * da controllare per sapere se poter eseguire l'incremento oppure bloccarsi
 * (se il numero di readers/writers è maggiore o uguale di 1)
 */
define modulo 
{

	a = operando;
	b = 1;

	if( a < b ) {

		mod = a+1
	}

	else {

		mod = a%b
	}

}