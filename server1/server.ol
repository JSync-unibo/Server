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

		println@Console( "arrivato mexx" )();

		prova.directory = "repo";

  		list@File(prova)(risposta);

		println@Console( risposta )();

		valueToPrettyString@StringUtils(risposta)(responseMessage)

	} ] { println@Console( responseMessage )() }
}