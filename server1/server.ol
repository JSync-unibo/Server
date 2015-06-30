/*
*
* Author => Gruppo LOBSTER
* Data => 26/06/2015
* 
* Server
*
* Servizio collegato con clientUtilities attraverso una porta con una location specifica,
* utilizzato per la condivisione delle repositories tra i diversi Clients, ricevendo delle
* richieste e ritornando il contenuto desiderato
*/


// Importazione delle interfacce 
include "console.iol"

include "file.iol"
include "string_utils.iol"
include "types/Binding.iol"
include "time.iol"

include "../server_utilities/interface/fromClient.iol"

// Importazione del servizio contenente i "define" richiamati dalle operazioni
include "../server_utilities/serverDefine.ol"

// Porta che collega il server con il client, in attesa di sue richieste
inputPort FromClient {

	Location: "socket://localhost:4000"
  	Protocol: sodep
	Interfaces: ToServerInterface
}

execution{ concurrent }

// Costante richiamata nelle diverse input choices
constants 
{
	serverRepo = "serverRepo/"
}

/*
 * Inizializzazione delle variabili globali:
 * - readers -> count[0]
 * - writers -> count[1]
 */
init
{
  	global.count[0] = 0;
  	global.count[1] = 0
}

main
{


	/*
	 * Il Server riceve un messaggio con nome della repository e percorso 
	 * della directory locale da creare
	 */
	[ addRepository( message )( responseMessage ) {

		// Pulizia del messaggio di risposta inviato in altre input choices
		undef( responseMessage );

		// Creazione del percorso dove salvare la nuova repository
		repoName = serverRepo + message.repoName;

		// Controlla se la repository non sia già stata creata
		exists@File( repoName )( exist );

		// Se esiste già, ritorna un errore
		if(exist){

			with( responseMessage ){

		  		.error = true;
		  		.message = " Error, " + message.repoName + " is already in use.\n"
			}
		}

		// Se la cartella non esiste la crea
		else{

			mkdir@File( repoName )();

			// Preparazione del file di versione e scrittura
			with( toSend ){
			  
			  	.filename = repoName + "/vers.txt";
			  	.content = 0;

  				writeFile@File( toSend )();
  				undef( toSend )
			};

			// Preparazione del messaggio di ritorno
  			with( responseMessage ){

		  		.error = false;
		  		.message = " Success, repository created.\n";

		  		println@Console( .message )()
			}
		}

	} ] { nullProcess } 



	/*
	 * Ritorna la lita di tutte le repositories registrate sul Server
	 * (sotto forma di stringa)
	 */
	[ listRepo()( responseMessage ) {

		repo.directory = serverRepo;

		// Lista di tutte le repository del server
  		list@File( repo )( risposta );

  		// Se sono presenti
  		if( is_defined( risposta.result ) ){

	  		// Stampa tutte le repositories contenute nel server
	  		for(i = 0, i < #risposta.result, i++) {

	  			responseMessage += "       " + risposta.result[i] + "\n"

		    }
		}

		// Se non sono presenti, ritorna un errore
		else{

			responseMessage = "       There are not registred repositories.\n"
		}

	// Stampa del messaggio di risposta e pulizia di esso
	} ] { 

		println@Console( responseMessage )();
		undef( responseMessage )

		}



	/*
	 * Cancellazione di una repository salvata sul Server
	 */
	[ delete( message )( responseMessage ) {

		repo.directory = serverRepo;

		// Lista di tutte le repositories sul Server
  		list@File( repo )( risposta );

  		// Inizializzazione della variabile a "false" della repository trovata 
  		trovato = false;

  		// Controlla tutte le repositories
  		for(i = 0, i < #risposta.result, i++) {

  			// Se quella ricevuta in input è uguale ad una repository sul Server
  			if(message.repoName == risposta.result[i]) {

  				// Viene cancellata tutta la cartella
  				deleteDir@File( serverRepo+risposta.result[i] )( deleted ) ;

  				trovato = true
  			}
  		};

  		with( responseMessage ){
  		  
  		  	// Se è stata trovata, ritorna un messaggio di successo
	  		if(trovato) {

	  			.error = false;
		  		.message = " Success, removed repository.\n"
	  		}

	  		// Altrimenti significa che la repository non esiste sul server
	  		else {

	  			.error = true;
	  			.message = " Error, selected repository does not exist.\n"
	  		}
  		}

  	// Stampa del messaggio di risposta e pulizia di esso	
	}] 
	{ 

		println@Console( responseMessage )(); 
		undef( responseMessage ) 

		}



	/* 
	 * Riceve il file di versione locale dal Client, 
	 * modifica il percorso e legge il contenuto della versione online.
	 * Confronta i due contenuti, se quella locale è minore di quella sul Server
	 * viene inviato un messaggio di errore, altrimenti incrementa la propria versione
	 */
	[ push( vers )( responseMessage ){

		// Si splitta il percorso per /
		toSplit = vers.filename;

		toSplit.regex = "/";

		split@StringUtils( toSplit )( splitResult );

		// Si rinomina la repository su cui fare la push
		repoName = serverRepo + splitResult.result[1];

		// Controlla se la repository non sia già stata creata
		exists@File( repoName )( exist );

		// Se esiste, allora si confrontano i due file di versione
		if( exist ) {

			// Lettura del contenuto del file di versione
			file.filename = vers.filename;

			readFile@File( file )( readed.content );

			// Se la versione del Client è minore di quella del Server
			if(vers.content < readed.content) {

				// Messaggio di errore (è necessaria la pull prima)
				with( responseMessage ) {

					.error = true;
					.message = " The version is old, need to pull! \n"
				}
			}

			// Se la versione del Client è maggiore o uguale
			else {

				// Trasformazione del contenuto in stringa
				contenuto = string(readed.content);
				
				// Per rendere atomica l'operazione di incremento del file di versione
				// si inserisce dentro il metodo synchronized
				synchronized( increaseFileVersion ){

					with( responseMessage ){

						// Incremento del numero di versione e scrittura sul file
						file.content = int(contenuto) +1;

						writeFile@File( file )();
							
						.error = false;
						.message = " Success.\n"

					}
				}
			}
		}

		// Se la repository non esiste, la crea
		else {

			mkdir@File( repoName )();

			vers.filename = repoName + "/vers.txt";

			// Si scrive nella repository il file di versione inviato dal Client
			writeFile@File( vers )();

			with( responseMessage ){
			  
			  .error = false;
			  .message = " Success, repository created.\n"
			
			}

		}

	// Output del messaggio e pulizia della variabile ricevuta, 
	// del messaggio stampato e del file
	}] { 

		println@Console( responseMessage.message )();
		undef( vers );
		undef( responseMessage ) ;
		undef( file )
	}



   /*
	* Incremento della variabile globale 
	* (reader o writer a seconda se viene richiamata la pull o la push) 
	*/

	[ increaseCount( var )( responseMessage ){
		
		// Utilizzo dell'operazione modulo
		// (richiamato dal servizio serverDefine)
		operando = var.id;

		modulo;

		// Se il numero di writers (per la pull) o di readers (per la push)
		// è maggiore o uguale a 1, allora si blocca l'operazione
		if( global.count[mod] >= 1 ) {

			responseMessage.error = true;
			responseMessage.message = " " + var.operation + " operation in progress...\n"
		}

		// Altrimenti si rende l'operazione di incremento atomica e si aumenta
		// il numero di readers (pull) o di writers (push)
		else {

			synchronized( increase ){

				global.count[var.id]++

			};

			responseMessage.error = false;
			responseMessage.message = "You can do the operation"
		}

	// Pulizia del messaggio di risposta
	} ] { undef( responseMessage ) }

	

	/*
	 * Il Server riceve una stringa, il nome della repository, ed
	 * inizia una visita ricorsiva (in questo caso basta absolute path),
	 * poi setta il messaggio positivo, ritornando anche la struttura delle cartelle 
	 */
	[ pull( repoName )( responseMessage ){

		abDirectory = serverRepo+repoName;

		// Visita ricorsiva delle cartelle
		// (richiamata dal servizio serverDefine)
		initializeVisita;

		// Preparazione del messaggio di risposta
		with( responseMessage ){
		  
		  	// Se sono presenti files da inviare nella repository richiesta,
		  	// si invia un messaggio di successo e la struttura della repository
		  	if(folderStructure.file[0] != null) {

			  	.error = false;
			  	.message = " Success, pull request done.\n";
			  	.folderStructure << folderStructure
			} 

			// Altrimenti significa che la repository è vuota
			else {

				.error = true;
				.message = " The repository is empty.\n"
			}
		};

		// Stampa della struttura della repository
		valueToPrettyString@StringUtils(responseMessage)(struc);
		println@Console( struc )()

	// Stampa del messaggio di risposta e pulizia di esso e del file di versione
	}] { 

		println@Console( responseMessage.message )(); 
		undef( vers ); 
		undef( responseMessage )

		}
	


   /*
	* Decremento della variabile dei readers (pull)
	* o writers (push), quando la loro operazione è completata
	*/
	[ decreaseCount(var) ] {

		// Decremento nel synchronized, per renderlo atomico
		synchronized( decrease ){
		  
			global.count[var]--

		}

	}

	
	// Sezione di invio/ricezione file

	/*
	 * RequestFile accetta una stringa, che è il percorso relativo del file, 
	 * la legge, e ritorna il contenuto al Client
	 *
	 */
	[ requestFile( fileName )( file ) {

		// Preparazione del file per la lettura e
		// ritorno del contenuto che viene inviato al Client
		file.filename = fileName;

		readFile@File( file )( file.content );

		// Stampa dei files richiesti dal Client
		println@Console( " Requested: " + file.fileName )()

	// Pulizia del file, dopo averlo inviato
	} ]{ 

		undef( file ) 
		
	   }
	


	/*
	 * SendFile riceve il percorso di un file ed il suo contenuto,
	 * che viene scritto sul Server nella repository selezionata
	 */
	[ sendFile( file ) ] {
		
		// Modifica del percorso del file ricevuto, cambiando la repository globale
		file.filename = serverRepo + file.filename;

		// Si splitta il percorso per /
		toSplit = file.filename;

		toSplit.regex = "/";

		split@StringUtils( toSplit )( splitResult );

		// Creazione di ogni cartella nel percorso
		// (tranne per il file)
		for(j=0, j<#splitResult.result-1, j++){

			dir += splitResult.result[j] + "/";

			mkdir@File( dir )()
		};

		// Infine si scrive il file ricevuto
		writeFile@File( file )();

		// Pulizia della directory
		undef( dir );

		// Stampa dei files ricevuti
		println@Console( " Received : " + file.filename + "\n" )()
	}
}