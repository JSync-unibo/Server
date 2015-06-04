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

	[ addRepository(message)(responseMessage) {

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

			mkdir@File("repo/"+message.repoName)();
			responseMessage.message = " Successo\n";
			responseMessage.error = false
		}

	} ] { println@Console(responseMessage.message)() } 

	[ listRepo(message)(responseMessage) {

		undef( responseMessage );

		repo.directory = "repo/";

  		list@File(repo)(risposta);

  		
  		//stampa tutte le repositories contenute nel server
  		for(i = 0, i < #risposta.result, i++) {

  			responseMessage += risposta.result[i] + " "

  			/*isDirectory@File(risposta.result[i])(dir);
  			
  			if(dir) {

  				list@File(risposta.result[i])(sottoDir);
  				for(j = 0, j < #sottoDir.result, j++) 
  					responseMessage += sottoDir.result[j] + " "
  			}*/
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
}