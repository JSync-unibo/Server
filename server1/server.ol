include "console.iol"
include "../server_utilities/interface/toServer.iol"

inputPort FromClient {
	Interfaces: ToServerInterface

}

init
{
  	//cambiare queste righe per definire il server

  	FromClient.Location = "socket://localhost:8000";
  	FromClient.Protocol = "sodep";
}