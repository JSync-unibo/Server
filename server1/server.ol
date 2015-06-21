include "console.iol"

include "file.iol"
include "string_utils.iol"
include "types/Binding.iol"

include "../server_utilities/interface/fromClient.iol"
include "../server_utilities/interface/serverDef.ol"

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

		//controlla se la repo non sia già stata creata
		exists@File(repoName)(exist);

		//se esiste già la cartella
		//c'è un errore
		if(exist){

			with( responseMessage ){

		  		.error = true;
		  		.message = " Error, "+message.repoName+" is already in use.\n"
			}
		}

		//se la cartella non esisteva la crea
		else{

			mkdir@File(repoName)();

			// Preparazione del file di versione
			with( toSend ){
			  
			  	.filename = repoName+"/vers.txt";
			  	.content = 0;

  				writeFile@File(toSend)();
  				undef( toSend )
			};
			//preparazione del messaggio di ritorno
  			with( responseMessage ){

		  		.error = false;
		  		.message = " Success, repository created.\n";

		  		println@Console(.message)()
			}
		}

	} ] { nullProcess } 

	/*
	 *
	 * ritorna la lita di tutte le repo registrate sul server
	 * sotto forma di stringa
	 */
	[ listRepo()(responseMessage) {

		//lista di tutte le repo del server
		repo.directory = serverRepo;
  		list@File(repo)(risposta);

  		//se ce ne sono
  		if( is_defined( risposta.result ) ){

	  		//stampa tutte le repositories contenute nel server
	  		for(i = 0, i < #risposta.result, i++) {

	  			responseMessage += "       " + risposta.result[i]+"\n"

	  			/*
	  			repo2.directory = repo.directory + risposta.result[i];
	  			
	  			list@File(repo2)(res);

	  				for(j = 0, j < #res.result, j++) {
	  					
	  					responseMessage += "    " + res.result[j] + "\n"
	  				}
	  			*/
		    }
		}
		//se non ci sono, errore
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

		repo.directory = serverRepo;

  		list@File(repo)(risposta);

  		trovato = false;

  		//stampa tutte le repositories contenute nel server
  		for(i = 0, i < #risposta.result, i++) {

  			if(message.repoName == risposta.result[i]) {

  				deleteDir@File(serverRepo+risposta.result[i])(deleted);

  				trovato = true
  			}
  		};

  		if(trovato) {

  			responseMessage.error = false;
	  		responseMessage.message = " Success, removed repository.\n"
  		}

  		else {
  			responseMessage.error = true;
  			responseMessage.message = " Error, selected repository does not exist.\n"
  		}

	}] { println@Console( responseMessage )() }


	
	[ push(vers)(responseMessage){

		println@Console( vers.filename )();

		//leggo il file di versione nel server
		file.filename = vers.filename;
		readFile@File(file)(readed.content);

		//trasformo il contenuto in stringa
		contenuto = string(readed.content);

		println@Console( contenuto )();

		//se le stringhe sono uguali
		with( responseMessage ){

			file.content = int(file.content) + 1;

				writeFile@File(file)();

			  	.error = false;
				.message = " Success.\n"
		}

	}] { 

		println@Console(responseMessage.message)();
		undef( vers );
		undef( responseMessage ) ;
		undef( file )
	}

	/*
	 * riceve una stringa, il nome della repository
	 * inizia una visita ricorsiva (in questo caso basta absolute path)
	 * setta il messaggio positivo 
	 */
	[ pull(repoName)(responseMessage){

		abDirectory = "/"+repoName;

		initializeVisita;

		//preparo la risposta positiva
		with( responseMessage ){
		  
		  	.error = false;
		  	.message = " Success, pull request done.\n";
		  	.folderStructure << folderStructure
		}
		
		//valueToPrettyString@StringUtils(responseMessage)(struc);

		//repoName
		//si vede se esiste
		//si vede se si può leggere
		//vengono mandati tutti i file da server a client
	}] { println@Console(responseMessage.message)();undef( vers ) }
	

	//Sezione di invio/ricezione file

	/*
	 * requestFile accetta una stringa, che è il percorso relativo del file 
	 * la legge, e ritorna il contenuto al client
	 *
	 */
	[ requestFile(fileName)(file) {

		//prepara il file per la lettura
		//salva il contenuto e lo invia al client
		file.filename = fileName;
		readFile@File(file)(file.content)

		//in output il nome del file, pulizia della variabile file
	} ]{ undef( file ) }
	
	/*
	 * riceve il percorso di un file e il suo contenuto
	 * fa il writeFile nel percorso desiderato
	 */
	[ sendFile( file ) ] {
		
		//modifica del percorso 
		file.filename = serverRepo+file.filename;

		//splitto il percorso per /
		toSplit = file.filename;
		toSplit.regex = "/";
		split@StringUtils(toSplit)(splitResult);
		
		println@Console( " Requested: "+ file.fileName )();

		//per ogni cartella nel percorso
		//tranne per il file
		for(j=0, j<#splitResult.result-1, j++){

			dir += splitResult.result[j] + "/";

			//la riscrivo se non c'è già
			mkdir@File(dir)()
		};

		//alla fine scrivo il file
		writeFile@File(file)();

		//pulisco la directory
		undef( dir );

		//output di controllo
		println@Console( " Received : "+file.filename+"\n" )()
	}
}