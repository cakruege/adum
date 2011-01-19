# http://msdn.microsoft.com/en-us/library/system.net.sockets.tcplistener(v=VS.85).aspx

set-psdebug -strict # Variablen müssen definiert sein
Import-Module ActiveDirectory
. ./checkCommand.ps1

function Resolve-Error ($ErrorRecord=$Error[0])
{
   $ErrorRecord | Format-List * -Force
   $ErrorRecord.InvocationInfo |Format-List *
   $Exception = $ErrorRecord.Exception
   for ($i = 0; $Exception; $i++, ($Exception = $Exception.InnerException))
   {   "$i" * 80
       $Exception |Format-List * -Force
   }
}

try
 {
 $localAddr = [system.net.ipaddress]::parse("127.0.0.1")
 $server = new-object System.Net.Sockets.TcpListener( $localAddr,9000)
 
 #Start listening for client requests.
 $server.Start()
 
 $bytes = New-Object Byte[] (256)
 
 $run = $TRUE
 while($run)
 {
   Write-Host ("Waiting for a connection... ")
   
   $tcpclient = $server.AcceptTcpClient();  
   Write-Host ("Connected!")
   
   $networkstream = $tcpclient.GetStream();
   $disconnect=$false
   while (!((($i = $networkstream.Read($bytes,0,$bytes.length)) -eq 0) -or $disconnect)){  
     [String] $data = [System.Text.Encoding]::ASCII.GetString($bytes, 0, $i).Replace("`n",'')
     Write-Host $data
     $command=checkCommand($data);
     switch ($command.command)
     {
        $ACCINSERT 
        { 
				  # http://technet.microsoft.com/en-us/library/ee617253.aspx
          echo "Versuche Benutzer anzulegen"
          $name=$command.givenname+" "+$command.surname
          try { 
             New-ADUser -SamAccountname $command.username -Name $name 
             Write "Benutzer angelegt"
          }
          catch [Microsoft.ActiveDirectory.Management.ADIdentityAlreadyExistsException]
          {
             $_
             Write-Host "Benutzer schon vorhanden"
          }				
          catch [Microsoft.ActiveDirectory.Management.ADException]
          {
             $_          
         
          }	  
        }
        
        $ACCDELETE
        {
          # http://technet.microsoft.com/en-us/library/ee617206.aspx
          echo "Versuche Benutzer anzulegen"   
          Remove-ADUser $command.username -Confirm:$false
          Write "Benutzer gelöscht"
        }
     }
     
     if ($data -eq "exit") {	 
	   Write-Host "EXIT" 
	   $encoding=New-Object System.Text.ASCIIEncoding
	   $msg=$encoding.GetBytes("bye bye`n");
	   $networkstream.Write($msg, 0, $msg.Length);
	   $disconnect=$TRUE
	   $run=$FALSE	   
	 }

     if ($data -eq "disc") {	 
	   Write-Host "EXIT" 
	   $encoding=New-Object System.Text.ASCIIEncoding
	   $msg=$encoding.GetBytes("bye bye`n");
	   $networkstream.Write($msg, 0, $msg.Length);
	   $disconnect=$TRUE
	 }
	 
   }
   $tcpclient.Close() 
   $disconnect=$FALSE
 }
     }
    catch [System.Net.Sockets.SocketException] # muss noch erweitert werde 
    {
      $_ | fl * -Force
    }
	
	catch [Exception] 
	{
	  $ErrorRecord=$_
	
  $ErrorRecord | Format-List * -Force
   $ErrorRecord.InvocationInfo |Format-List *
   $Exception = $ErrorRecord.Exception
   for ($i = 0; $Exception; $i++, ($Exception = $Exception.InnerException))
   {   "$i" * 80
       $Exception |Format-List * -Force
   }	  
	}
	
    finally
    {
       $server.Stop()
    }