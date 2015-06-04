include "console.iol"
include "../server_utilities/interface/FromClient.iol"
include "file.iol"
include "string_utils.iol"
include "types/Binding.iol"

inputPort FromClient {
	Location: "socket://localhost:4000"
  	Protocol: sodep
	Interfaces: ToServerInterface
}

execution{ concurrent }

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
		exists@File("repo/"+message.repoName)(exist);

		//se esiste già la cartella
		//c'è un errore
		if(exist){

			responseMessage.error = true;
			responseMessage.message = " Errore\n"
		}

		//se la cartella non esisteva la crea
		else{

			/*root.from = "LocalRepo/"+message.localPath;
			root.to = "repo/"+message.repoName;
			copyDir@File(root)();*/
			mkdir@File("repo/"+message.repoName)();

			responseMessage.error = false;
			responseMessage.message = " Successo\n"
		}

	} ] { println@Console(responseMessage.message)() } 

	/*

	   Lista delle repository
	 */
	[ listRepo(message)(responseMessage) {

		undef( responseMessage );

		repo.directory = "repo/";

  		list@File(repo)(risposta);

  		
  		//stampa tutte le repositories contenute nel server
  		for(i = 0, i < #risposta.result, i++) {

  			responseMessage += risposta.result[i] + " / ";

  			repo2.directory = repo.directory + risposta.result[i];
  			
  			list@File(repo2)(res);

  				for(j = 0, j < #res.result, j++) {
  					
  					responseMessage += res.result[j] + "\n"
  				}
	    }
	  	

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


	[ sendFile( file ) ] {

		with( file ){

		  .filename = "repo/"+ .filename

		};
		
		writeFile@File(file)();

		println@Console( " Ricevuto: "+file.filename+"\n" )()
	}

	[ delete(message)(responseMessage) {

		repo.directory = "repo/";

  		list@File(repo)(risposta);

  		trovato = false;

  		//stampa tutte le repositories contenute nel server
  		for(i = 0, i < #risposta.result, i++) {

  			if(message.repoName == risposta.result[i]) {

  				deleteDir@File("repo/"+risposta.result[i])(deleted);

  				trovato = true
  			}
  		};

  		if(trovato) {

  			responseMessage.error = false;
	  		responseMessage.message = " Repository eliminata \n"
  		}

  		else {
  			responseMessage.error = true;
  			responseMessage.message = " Directory non trovata \n"
  		}

	}] { println@Console( responseMessage )() }

}