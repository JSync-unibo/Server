include "console.iol"
include "../server_utilities/interface/fromClient.iol"
include "file.iol"
include "string_utils.iol"
include "types/Binding.iol"

inputPort FromClient {
	Location: "socket://localhost:4000"
  	Protocol: sodep
	Interfaces: ToServerInterface
}

execution{ concurrent }

constants {
	serverRepo = "serverRepo"
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

		//controlla se la repo non sia già stata creata
		exists@File(serverRepo+"/"+message.repoName)(exist);

		//se esiste già la cartella
		//c'è un errore
		if(exist){

			responseMessage.error = true;
			responseMessage.message = " Error, "+message.repoName+" is already in use.\n"
		}

		//se la cartella non esisteva la crea
		else{

			/*root.from = "LocalRepo/"+message.localPath;
			root.to = "repo/"+message.repoName;
			copyDir@File(root)();*/
			mkdir@File(serverRepo+"/"+message.repoName)();

			// Preparazione del file di versione
  			toSend.filename = serverRepo+"/"+message.repoName+"/vers.txt";
  			toSend.content = 0.1;

  			writeFile@File(toSend)();

			responseMessage.error = false;
			responseMessage.message = " Success, repository created.\n"
		}

	} ] { println@Console(responseMessage.message)();undef( toSend ) } 

	/*

	   Lista delle repository
	 */
	[ listRepo(message)(responseMessage) {

		repo.directory = serverRepo;

  		list@File(repo)(risposta);

  		
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
		else
			responseMessage = " void\n"
	  	

		//println@Console( risposta )();isDirectory(risposta.result[i])

		//valueToPrettyString@StringUtils(risposta)(responseMessage)

		/*for(i = 0, i < #risposta.directory, i++) {

			response += risposta.directory[i] + " "
			/*isDirectory@File( risposta.result[i] )( dir );
			if( dir ) {

				for(j = 0, j < #risposta.result[i], j++) {

					responseMessage += risposta.result[i].result[j]
				}
			}
		}*/

	} ] { println@Console( responseMessage )() }


	/*
	 * OneWay che aspetta un file e lo scrive nella nuova repository
	 */
	[ sendFile( file ) ] {

		with( file ) {

			// percorso delle cartelle nel server in cui salvare il file
			.filename = serverRepo + "/" +.folder+ "/"+ .filename;
			// viene rimosso il parametro folder per il writeFile
			undef( .folder )
		};

		if(file.filename == serverRepo + "/" + file.folder+ "/"+ "vers.txt") {

			file.content++;

			writeFile@File(file)()

		}

		else {

			writeFile@File(file)()
		};

		println@Console( " Ricevuto: "+file.filename+"\n" )()
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

  				deleteDir@File(serverRepo+"/"+risposta.result[i])(deleted);

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


	
	[ push(message)(responseMessage){

		undef( responseMessage );

		println@Console( message.repoName )();
		//controlla se la repo non sia già stata creata
		exists@File(serverRepo+"/"+message.repoName)(exist);

		if(exist){

			responseMessage.error = false;
			responseMessage.message = " Success.\n"
		}

		else {

			responseMessage.error = true;
			responseMessage.message = " Error, "+message.repoName+" don't exist.\n"
		}



	}] { println@Console(responseMessage.message)();undef( toSend ) }
	
}