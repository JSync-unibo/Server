/*
*
* Author => Gruppo LOBSTER
* Data => 21/06/2015
* 
* Server
*/

// Importazione delle interfacce e servizio relativo alla visita delle repo
include "console.iol"

include "file.iol"
include "string_utils.iol"
include "types/Binding.iol"

include "../server_utilities/interface/fromClient.iol"
include "../server_utilities/interface/serverDef.ol"

// Porta che collega il server con il client, in attesa di sue richieste
inputPort FromClient {
	Location: "socket://localhost:4000"
  	Protocol: sodep
	Interfaces: ToServerInterface
}

execution{ concurrent }

constants 
{
	serverRepo = "serverRepo/"
}

init
{
  	global.readerCount = 0;
  	global.writerCount = 0
}

main
{

	/*
	 * Viene inviato un messaggio con repoName e localPath
	 * 
	 * Controlla se la repository non esista già
	 * in caso esiste, non la crea e da' errore
	 *
	 * Se non esiste crea la cartella e torna un boolean
	 */
	[ addRepository(message)(responseMessage) {

		undef( responseMessage );

		repoName = serverRepo+message.repoName;

		// Controlla se la repo non sia già stata creata
		exists@File(repoName)(exist);

		// Se esiste già la cartella, ritorna un errore
		if(exist){

			with( responseMessage ){

		  		.error = true;
		  		.message = " Error, "+message.repoName+" is already in use.\n"
			}
		}

		// Se la cartella non esiste la crea
		else{

			mkdir@File(repoName)();

			// Preparazione del file di versione e scrittura
			with( toSend ){
			  
			  	.filename = repoName+"/vers.txt";
			  	.content = 0;

  				writeFile@File(toSend)();
  				undef( toSend )
			};

			// Preparazione del messaggio di ritorno
  			with( responseMessage ){

		  		.error = false;
		  		.message = " Success, repository created.\n";

		  		println@Console(.message)()
			}
		}

	} ] { nullProcess } 


	/*
	 * Ritorna la lita di tutte le repo registrate sul server
	 * (sotto forma di stringa)
	 */
	[ listRepo()(responseMessage) {

		// Lista di tutte le repo del server
		repo.directory = serverRepo;

  		list@File(repo)(risposta);

  		// Se sono presenti
  		if( is_defined( risposta.result ) ){

	  		// Stampa tutte le repositories contenute nel server
	  		for(i = 0, i < #risposta.result, i++) {

	  			responseMessage += "       " + risposta.result[i]+"\n"

		    }
		}

		// Se non sono presenti, ritorna un errore
		else{

			responseMessage = "       There are not registred repositories.\n"
		}

	} ] { 

		println@Console( responseMessage )();
		undef( responseMessage )

		}


	/*
	 * Cancella una repository salvata sul server
	 */
	[ delete(message)(responseMessage) {

		// Lista di tutte le repo sul server
		repo.directory = serverRepo;

  		list@File(repo)(risposta);

  		// Inizializzata la variabile della repo trovata a false
  		trovato = false;

  		// Controlla tutte le repo
  		for(i = 0, i < #risposta.result, i++) {

  			// Se quella ricevuta in input è uguale ad una repo sul server
  			if(message.repoName == risposta.result[i]) {

  				deleteDir@File(serverRepo+risposta.result[i])(deleted);

  				trovato = true
  			}
  		};

  		// Se è stata trovata, ritorna un messaggio di successo
  		if(trovato) {

  			responseMessage.error = false;
	  		responseMessage.message = " Success, removed repository.\n"
  		}

  		// Altrimenti significa che la repo non esiste sul server
  		else {
  			responseMessage.error = true;
  			responseMessage.message = " Error, selected repository does not exist.\n"
  		}

	}] { 

		println@Console( responseMessage )(); 
		undef( responseMessage ) 

		}


	/* 
	 * Riceve il file di versione locale dal client, 
	 * modifica il percorso e legge il contenuto della versione online.
	 * Confronta i due contenuti e poi incrementa la versione online,
	 * infine ritorna un messaggio di successo o errore
	 */
	[ push(vers)(responseMessage){


		println@Console( vers.filename )();

		// Lettura del contenuto del file di versione
		file.filename = vers.filename;

		readFile@File(file)(readed.content);

		if(vers.content < readed.content) {

			with( responseMessage ) {

				.error = true;
				.message = " The version is old, need to pull! \n"
			}
		}

		else {

			//releas
			// Trasformo il contenuto in stringa
			contenuto = string(readed.content);

			println@Console( contenuto )();

			// Se le stringhe sono uguali
			with( responseMessage ){

				// Incremento del numero di versione e scrittura sul file
				file.content = int(contenuto) +1;

				writeFile@File(file)();
					
				.error = false;
				.message = " Success.\n"

			}
		}

		// Output del messaggio e pulizia della variabile ricevuta, 
		// del messaggio stampato e file nel server
	}] { 

		println@Console(responseMessage.message)();
		undef( vers );
		undef( responseMessage ) ;
		undef( file )
	}


	
	/*
	 * Riceve una stringa, il nome della repository, ed
	 * inizia una visita ricorsiva (in questo caso basta absolute path),
	 * poi setta il messaggio positivo, ritornando anche la struttura delle cartelle 
	 */
	[ pull(repoName)(responseMessage){

		readerCount++;
		//println@Console( "/"+repoName )();

		abDirectory = serverRepo+repoName;

		// Chiamata ricorsiva delle visita delle cartelle
		initializeVisita;

		// Preparo la risposta positiva
		with( responseMessage ){
		  
		  	if(folderStructure.file[0] != null) {

			  	.error = false;
			  	.message = " Success, pull request done.\n";
			  	.folderStructure << folderStructure
			} 
			else {

				.error = true;
				.message = " The repository is empty.\n"
			}
		};
		
		valueToPrettyString@StringUtils(responseMessage)(struc);
		println@Console( struc )()

		//repoName
		//si vede se esiste
		//si vede se si può leggere
		//vengono mandati tutti i file da server a client
	}] { 

		println@Console(responseMessage.message)(); 
		undef( vers ); 
		undef(responseMessage)

		}
	
	
	// Sezione di invio/ricezione file

	/*
	 * RequestFile accetta una stringa, che è il percorso relativo del file, 
	 * la legge, e ritorna il contenuto al client
	 *
	 */
	[ requestFile(fileName)(file) {

		// Prepara il file per la lettura,
		// salva il contenuto e lo invia al client
		file.filename = fileName;

		readFile@File(file)(file.content)

		// In output il nome del file e poi pulizia della variabile file
	} ]{ 

		undef( file ) 
		
	   }
	
	/*
	 * Riceve il percorso di un file ed il suo contenuto,
	 * poi fa il writeFile nel percorso desiderato
	 */
	[ sendFile( file ) ] {
		
		// Modifica del percorso 
		file.filename = serverRepo+file.filename;

		// Splitto il percorso per /
		toSplit = file.filename;
		toSplit.regex = "/";
		split@StringUtils(toSplit)(splitResult);
		
		println@Console( " Requested: "+ file.fileName )();

		// Per ogni cartella nel percorso
		// (tranne per il file)
		for(j=0, j<#splitResult.result-1, j++){

			dir += splitResult.result[j] + "/";

			// Riscrivo la cartella, se non c'è già
			mkdir@File(dir)()
		};

		// Alla fine scrivo il file
		writeFile@File(file)();

		// Pulisco la directory
		undef( dir );

		// Output di controllo
		println@Console( " Received : "+file.filename+"\n" )()
	}
}