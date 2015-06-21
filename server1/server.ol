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

			folderStructure.file[len] = cartelle.sottocartelle[i].abNome
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

define initializeVisita{

	//predispongo la visita
	i = 1;
	visita
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
  			toSend.content = 0;

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

	  			responseMessage += " Folders: " + risposta.result[i]+"\n"

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

	} ] { println@Console( responseMessage )();
	undef( responseMessage ) }


	/*
	 * OneWay che aspetta un file e lo scrive nella nuova repository
	 */
	[ sendFile( file ) ] {
		
		println@Console( " Received : "+file.filename+"\n" )();

		with( file ){
		  
		  	.filename = "ServerRepo/"+.filename
		};

		// scrive il file
		scope( FileNotFoundException )
		{
			//se manca una cartella nel percorso
		  	install( IOException => 

		  		//splitta tutto il percorso
		  		toSplit = file.filename;
		  		toSplit.regex = "/";

		  		split@StringUtils(toSplit)(splitResult);

		  		//per ogni cartella nel percorso
		  		//tranne per il file
		  		for( i=0, i<#splitResult.result-1, i++)
		  		{
		  			//la crea se non esiste
		  			dir += splitResult.result[i] +"/";
		  			mkdir@File(dir)()
		  		};

		  		//infine scrive il file
		  		writeFile@File(file)()
		  	);

	  		// Prova a scrivere il file
	  		writeFile@File(file)()
	  	}

		/*
		with( file ) {

			// percorso delle cartelle nel server in cui salvare il file
			.filename = serverRepo + "/" +.folder+ "/"+ .filename
			
		};

		

		if(file.filename == serverRepo + "/" + file.folder+ "/"+ "vers.txt") {
			
			// viene rimosso il parametro folder per il writeFile
			undef( file.folder );

			file.content++;	

			writeFile@File(file)()

		}

		else {

			undef( file.folder );

			writeFile@File(file)()
		};

		println@Console( " Ricevuto: "+file.filename+"\n" )()
		*/
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


	
	[ push(vers)(responseMessage){

		with( file ) {

			// percorso delle cartelle nel server in cui salvare il file
			.filename = serverRepo + "/" + vers.folder+ "/"+ "vers.txt";
			.format = "binary"
		};

		println@Console( file.filename )();

		readFile@File(file)(readed.content);

		println@Console( readed.content )();

		if( vers.content == readed.content) {
			
			// viene rimosso il parametro folder per il writeFile
			undef( vers.folder );

			file.content++;	

			writeFile@File(file)();

			responseMessage.error = false;
			responseMessage.message = " Success.\n"

		}

		else {

			responseMessage.error = true;
			responseMessage.message = " Error, need to upgrade the repo  .\n"
		}


	}] { 

		println@Console(responseMessage.message)();
		undef( vers );
		undef( responseMessage ) 
	}

	
	[ pull(repoName)(responseMessage){

		abDirectory = "serverRepo/"+repoName;

		initializeVisita;

		//preparo la risposta
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
		

	}] { undef( vers ) }
	

	[ requestFile(fileName)(file) {

		file.filename = fileName;

		println@Console( " Requested: "+ fileName )();

		readFile@File(file)(file.content)


	} ]{ undef( file ) }
	
}