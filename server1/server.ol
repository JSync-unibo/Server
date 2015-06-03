include "console.iol"

inputPort fromClient {
	Interfaces: 
}

init
{
  	//cambiare queste righe per definire il server

  	fromClient.Location = "";
  	fromClient.Protocol = "sodep";
}