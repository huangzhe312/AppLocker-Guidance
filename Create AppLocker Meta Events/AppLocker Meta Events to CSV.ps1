###########################
#This script can be run on a server that collects forwarded AppLocker Meta 
#events to help perform basic analysis by converting the events into a CSV 
#(comma separated value) format that can be imported in Excel for analysis.
#
#This script can take two arguments with the first specifying the number of 
#previous days worth of events to retrieve and the second specifying the number
#of previous hours worth of events to retrieve.  By default, without any 
#arguments specified, the script will retrieve one day's events.
###########################

Import-Module AppLocker

$daysToGet = 7500
$hoursToGet = 0

if($args.Length -ge 1) 
{  
  $daysToGet = $args[0] 
}
if($args.Length -ge 2) 
{ 
  $hoursToGet = $args[1] 
}
$timespan = (get-date) - (new-timespan -Days $daysToGet -Hours $hoursToGet)

#Write-Host Retrieving AppLocker events since $timespan
Write-Host "Event Creation Time", "Event Level", "EventID", "EventRecordID", "Computer", "Username", "Calling Process", "PolicyName", "FilePath", "FileHash", "fqbn" -Separator ","
$events = Get-WinEvent -LogName ForwardedEvents | Where {$_.timecreated -ge $timespan -and $_.ProviderName -eq "AppLocker"} 
if($events -eq $Null) {
  Write-Host No AppLocker events found in the requested time range.
  Exit
}
ForEach ($event in $events) 
{
  $xml = $event.ToXML()
  #Write-Host $xml
  $xd = [xml] $xml
  $innerEvent = $xd.Event.EventData.Data
  $event = [xml] $innerEvent
  $eventID = $event.Event.System.EventID
  $level = $event.Event.System.Level
  $createdTime = $event.Event.System.TimeCreated.Attributes.GetNamedItem("SystemTime").Value
  $eventRecordID = $event.Event.System.EventRecordID
  $computer = $event.Event.System.Computer
  $policyName = $event.Event.UserData.RuleAndFileData.PolicyName
  $filePath = $event.Event.UserData.RuleAndFileData.FilePath
  $fileHash = $event.Event.UserData.RuleAndFileData.FileHash
  $fqbn = $event.Event.UserData.RuleAndFileData.Fqbn
  $username = $event.Event.UserData.RuleAndFileData.Username.InnerText
  $callingProcess = $event.Event.UserData.RuleAndFileData.CallingProcess.InnerText
  Write-Host $createdTime, $level, $eventID, $eventRecordID, $computer, $username, $callingProcess, $policyName, $filePath, $fileHash, $fqbn -Separator ","
}
