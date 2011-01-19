set-psdebug -strict # Variablen müssen definiert sein

Set-Variable ACCINSERT -option Constant -value 'ACCINSERT'
Set-Variable PWDCHANGE -option Constant -value 'PWDCHANGE'
Set-Variable PWDVERIFY -option Constant -value 'PWDVERIFY'
Set-Variable ACCACTIVATE -option Constant -value 'ACCACTIVATE'
Set-Variable ACCDEACTIVATE -option Constant -value 'ACCDEACTIVATE'
Set-Variable ACCDELETE -option Constant -value 'ACCDELETE'
Set-Variable PWDRESET -option Constant -value 'PWDRESET'

Set-Variable ADUMERROR -option Constant -value 'ERROR'
Set-Variable ERRORCODE -option Constant -value 'ERRORCODE'
Set-Variable ERRORMESSAGE -option Constant -value 'ERRORMESSAGE'

# neuen Objecttyp erzeugen
add-type @"
public struct adumcommand {
   public string command;
   public string givenname;
   public string surname;
   public string username;
   public string userpassword;
   public string okz;
   public string domain;     
   
   public int errorcode;          
   public string errormessage;      
}
"@

#http://blogs.msdn.com/b/powershell/archive/2009/03/11/how-to-create-an-object-in-powershell.aspx
function checkCommand {param ($commandStr)

   # ersetzen durch Logging
   trap [Exception] { 
      write-host
      write-host $("TRAPPED: " + $_.Exception.GetType().FullName); 
      write-host $("TRAPPED: " + $_.Exception.Message); 
      continue; 
   }
     
  $command = new-object adumcommand;
  $idxFirstPipe=$commandStr.IndexOf('|')
  $len=0;
  $lenstr="";
  $lenstr=$commandStr.subString(0,$idxFirstPipe) 
  if ($lenstr -match '^\d+$')
  {
    $len=[int]$lenstr
  }
  if ($commandStr.Length -$idxFirstPipe -eq $len) 
    {
         switch -regex ($commandstr) {
           "^(\d+)\|(ACCINSERT)\|([^\|]+?)\|([^\|]+?)\|([^\|]+?)\|([^\|]+?)\|([^\|]+?)\|([^\|]+?)\|$"  
            {
              $command.command=$ACCINSERT;
              $command.givenname=$matches[3];
              $command.surname=$matches[4];
              $command.username=$matches[5];
              $command.userpassword=$matches[6];
              $command.okz=$matches[7];
              $command.domain=$matches[8];
            }
           "^(\d+)\|(PWDCHANGE)\|([^\|]+?)\|([^\|]+?)\|$" 
            {
              $command.command=$PWDCHANGE;
              $command.username=$matches[3];
              $command.userpassword=$matches[4];      
            }           
           "^(\d+)\|(PWDVERIFY)\|([^\|]+?)\|([^\|]+?)\|$"
            {
              $command.command=$PWDVERIFY;
              $command.username=$matches[3];
              $command.userpassword=$matches[4];           
            }              
           "^(\d+)\|(ACCACTIVATE)\|([^\|]+?)\|$"
            {
              $command.command=$ACCACTIVATE;
              $command.username=$matches[3];
            }              
           "^(\d+)\|(ACCDEACTIVATE)\|([^\|]+?)\|$"
            {
              $command.command=$ACCDEACTIVATE;
              $command.username=$matches[3];
            }              
           "^(\d+)\|(ACCDELETE)\|([^\|]+?)\|$"
            {
              $command.command=$ACCDELETE;
              $command.username=$matches[3];
            }              
           "^(\d+)\|(PWDRESET)\|([^\|]+?)\|$"
            {
              $command.command=$PWDRESET;
              $command.username=$matches[3];
            }              
           default 
           { 
             $command.command=$ADUMERROR;
             $command.errormessage="Fehlerhaftes Kommando";
           }
         }
    } 
  else 
  {
     $command.command=$ADUMERROR;
     $command.errormessage="Länge des Kommandos stimmt nicht";
  }   
  return $command;
}

<#
checkCommand('70|ACCINSERT|')
checkCommand('70|ACCINSERT|julia|Meyer|Julia|B3rserker|5A3x|abctest.xp2k.hu-berlin.de|')
checkCommand('72|ACCINSERT|julia|Meyer|Julia|B3rserker|5A3x|abctest.xp2k.hu-berlin.de|x|')
checkCommand('28|PWDCHANGE|julia|S4r55skwod|')
checkCommand('28|PWDVERIFY|julia|S4r55skwod|')
checkCommand('21|ACCDEACTIVATE|julia|')
checkCommand('19|ACCACTIVATE|julia|')
checkCommand('17|ACCDELETE|julia|')
checkCommand('16|PWDRESET|julia|')
#>