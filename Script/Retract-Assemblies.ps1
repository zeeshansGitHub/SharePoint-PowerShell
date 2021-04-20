# Variables
$webapp = "SharePoint - 801"

## Parsing the Config XML 
write-host “Parsing the input file…” 
[System.Xml.XmlDocument] $xd = new-object System.Xml.XmlDocument 
$file = resolve-path ("../Config.xml") 
$xd.load($file) 
$Settings = $xd.selectNodes("/Configurations/Setting") 
if($Settings.count -gt 0) 
{ 
	foreach($Setting in $Settings) 
    { 
        $Key = $Setting.getAttribute("Key")    
		if($Key -eq "WebApp")
		{
			$webapp = $Setting.getAttribute("Value") 				
			break					
		}	
	} 
	
} 


$wsp = "CW.Sharepoint.Assemblies.wsp"
$spAdminServiceName = "SPAdminV4"



$fullpath = Get-Location -PSProvider FileSystem
$fullpath = $fullpath.Path + "\" + $wsp

function Wait4TimerJob()
{
 $solution = Get-SPSolution $wsp
 if ($solution -ne $null)
 {
  $counter = 1  
  $maximum = 50  
  $sleeptime = 2 
  
  Write-Host "Waiting to finish solution timer job"
  while( ($solution.JobExists -eq $true ) -and ( $counter -lt $maximum ) )
  {  
   Write-Host "Please wait..."
   sleep $sleeptime 
   $counter++  
  }
  
  #Write-Host "Finished the solution timer job"   
 }
}

# Add the SharePoint snap-in
if((Get-PSSnapin | Where-Object {$_.Name -eq "Microsoft.SharePoint.PowerShell"}) -eq $null) 
{ 
	Add-PSSnapIn "Microsoft.SharePoint.Powershell" 
	Write-Host "SharePoint snap-in registered"
}

# Restart the timer job
Stop-Service -Name $spAdminServiceName
Start-SPAdminJob -Verbose
Start-Service -Name $spAdminServiceName    
Write-Host "SharePoint service restarted"

# Retract solution
Write-Host "Retracting $wsp solution"
Uninstall-SPSolution -Identity $wsp -confirm:$false 

#Block while the solution is still deployed
#do { Start-Sleep 2 } while ((Get-SPSolution $wsp).Deployed)
#Write-Host "$wsp Solution Retracted"
Wait4TimerJob
Write-Host "$wsp Solution Retracted"

# Remove solution
Remove-SPSolution -Identity $wsp -confirm:$false
Write-Host "$wsp Solution Removed"