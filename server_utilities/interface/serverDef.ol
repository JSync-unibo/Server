/*
*
* Author => Gruppo LOBSTER
* Data => 21/06/2015
* Parent => Server
* 
*/


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

		// Viene controllato se la cartella ha delle sottocartelle. Se non ha sottocartelle
		// Viene salvato tutto il percorso per arrivare in quella cartella
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

	// Se non si è arrivati alla fine dell'array cartelle, l'attributo mark della cartella viene
	// Settato a true, e si richiama il metodo visita
	if( is_defined( cartelle.sottocartelle[i].abNome )) {

		cartelle.sottocartelle[i].mark = true;

		abDirectory = cartelle.sottocartelle[i].abNome;

		i = #cartelle.sottocartelle;

		visita
	}
}


/*
 * Inizializzazione della visita e chiamata ricorsiva
 */ 
define initializeVisita
{

	// Predispongo la visita
	i = 1;
	visita
}