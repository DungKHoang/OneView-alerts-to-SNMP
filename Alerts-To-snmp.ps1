Param ( [string]$OVApplianceIP      ="",
        [string]$OVAdminName        ="Administrator", 
        [string]$OVAdminPassword    ="password",
        [string]$OneViewModule      = "HPOneView.410",  

        [string]$Start              = '01/01/2019' ,
        [string]$End                = '01/01/2019' , 
        [string]$Severity           = 'Critical',

        [string]$OVAuthDomain       = "local"

)
#$ErrorActionPreference = 'SilentlyContinue'
$DoubleQuote    = '"'
$CRLF           = "`r`n"
$Delimiter      = "\"   # Delimiter for CSV profile file
$SepHash        = ";"   # USe for multiple values fields
$Sep            = ";"
$hash           = '@'
$SepChar        = '|'
$CRLF           = "`r`n"
$OpenDelim      = "{"
$CloseDelim     = "}" 
$CR             = "`n"
$Comma          = ','
$Equal          = '='
$Dot            = '.'
$Underscore     = '_'

$Syn12K                   = 'SY12000' # Synergy enclosure type

Function Prepare-OutFile ([string]$Outfile)
{

    $filename   = $outFile.Split($Delimiter)[-1]
    $ovObject   = $filename.Split($Dot)[0] 
    
    New-Item $OutFile -ItemType file -Force -ErrorAction Stop | Out-Null
    
    $HeaderText = "Alert_TypeID|Alert_description|snmpOID"

    Set-content -path $outFile -Value $HeaderText
}


Function Out-ToScriptFile ([string]$Outfile)
{
    if ($ScriptCode)
    {
        Prepare-OutFile -outfile $OutFile
        
        Add-Content -Path $OutFile -Value $ScriptCode
        

    } 
}

import-module HPOneView.410




# ---------------- Connect to OneView appliance
#
write-host -ForegroundColor Cyan "-----------------------------------------------------"
write-host -ForegroundColor Cyan "Connect to the OneView appliance..."
write-host -ForegroundColor Cyan "-----------------------------------------------------"
$connection = Connect-HPOVMgmt -appliance $OVApplianceIP -user $OVAdminName -password $OVAdminPassword -LoginAcknowledge:$true -AuthLoginDomain $OVAuthDomain
$appliance = $connection.name
# ---------------------------
#  Generate Output files

$timeStamp          = get-date -format MMM-dd-yyyy
    
$OutFile            = "alert-snmp-$appliance.CSV"

Write-Host -ForegroundColor Cyan "CSV file -->     $OutFile  "
write-host -ForegroundColor CYAN "##NOTE: Delimiter used in the CSV file is '|' "

$scriptCode         =  New-Object System.Collections.ArrayList

$ListofAlerts   = get-hpovalert -Start $Start -End $End -Severity $Severity
foreach ($alert in $ListofAlerts)
{
    $alertDescription           = $alert.Description
    $alertTypeID                = $alert.alertTypeID
    foreach ($eventUri in $alert.associatedEventUris)
    {
        if ($eventUri)
        {
            $ev      = send-HPOVRequest -uri $eventUri
            foreach ($evItem in $ev.eventDetails)
            {
                $eventName      = $evItem.eventItemName
                $eventSnmpOid   = $evItem.eventItemSnmpOid
                $value          = ""
                if ($eventName -match '^\d.')
                {
                    $value              = "$alertTypeID|$alertDescription|$eventName"
                    [void]$scriptCode.Add('{0}' -f $value)
                }
                else 
                {
                    if ($eventSnmpOid -match '^\d.')
                    {
                        $value          = "$alertTypeID|$alertDescription|$eventSnmpOid"
                        [void]$scriptCode.Add('{0}' -f $value) 
                    }

                }


            }
        }
    }
}
$scriptCode = $scriptCode.ToArray() 
Out-ToScriptFile -Outfile $outFile 


write-host -ForegroundColor Cyan "-----------------------------------------------------"
write-host -ForegroundColor Cyan "Disconnect from OneView appliance ................"
write-host -ForegroundColor Cyan "-----------------------------------------------------"

Disconnect-HPOVMgmt 