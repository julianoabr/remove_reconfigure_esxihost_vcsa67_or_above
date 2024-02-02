<#
.Synopsis
   Script to help admins to change boot san or reinstall a ESXi Host
.DESCRIPTION
   Script to help admins to change boot san or reinstall a ESXi Host
   You must be connected to vCenter before run this script
.EXAMPLE
   Example of how to use this cmdlet
.EXAMPLE
   Another example of how to use this cmdlet
.AUTHOR
   Juliano Alves de Brito Ribeiro (Find me at: julianoalvesbr@live.com or https://github.com/JULIANOABR or https://twitter.com/powershell_tips)
.VERSION
   v.0.2
.ENVIRONMENT
   DEV - TEST
.TOTHINK
   JOHN 14.6-7
   Jesus Answered: "I am the way and the truth and the life. No one comes to the Father except through me. If you really know me, you will know my Father as well.
   From now on, you do know him and have seen him"
#>

Clear-Host

Set-PowerCLIConfiguration -InvalidCertificateAction Ignore -Confirm:$false -Verbose

#VALIDATE MODULE
$moduleExists = Get-Module -Name Vmware.VimAutomation.Core

if ($moduleExists){
    
    Write-Output "The Module Vmware.VimAutomation.Core is already loaded"

}#if validate module
else{
    
    Import-Module -Name Vmware.VimAutomation.Core -WarningAction SilentlyContinue -ErrorAction Stop
    
}#else validate module

#FUNCTION PAUSE POWERSHELL
function Pause-PSScript
{

   Read-Host 'Press Enter to continue...' | Out-Null
}

#Found on https://gist.github.com/ctigeek/bd637eeaeeb71c5b17f4
function Start-ModSleep($seconds) {
    $doneDT = (Get-Date).AddSeconds($seconds)
    while($doneDT -gt (Get-Date)) {
        $secondsLeft = $doneDT.Subtract((Get-Date)).TotalSeconds
        $percent = ($seconds - $secondsLeft) / $seconds * 100
        Write-Progress -Activity "Waiting to continue the PS Script" -Status "Now I'm Sleeping..." -SecondsRemaining $secondsLeft -PercentComplete $percent
        [System.Threading.Thread]::Sleep(500)
    }
    Write-Progress -Activity "Waiting to continue the PS Script" -Status "Now I'm Sleeping..." -SecondsRemaining 0 -Completed
       
}


#VALIDATE IF OPTION IS NUMERIC
function isNumeric ($x) {
    $x2 = 0
    $isNum = [System.Int32]::TryParse($x, [ref]$x2)
    return $isNum
} #end function is Numeric


#FUNCTION CONNECT TO VCENTER
function Connect-vCenterServer
{
    [CmdletBinding()]
    Param
    (
        # Param1 help description
        [Parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true,
                   Position=0)]
        [ValidateSet('Manual','Auto')]
        $methodToConnect = 'Manual',

        # Param2 help description
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true,
                   Position=1)]
        [System.String]$vCenterToConnect, 
        
        [Parameter(Mandatory=$false,
                   Position=2)]
        [System.String[]]$vcServerList, 
                
        [Parameter(Mandatory=$false,
                   Position=3)]
        [System.String]$suffix, 

        [Parameter(Mandatory=$false,
                   Position=4)]
        [ValidateSet('80','443')]
        [System.String]$port = '443'
    )

    if ($methodToConnect -eq 'Automatic'){
                
        $Script:workingServer = $vCenterToConnect + '.' + $suffix
        
        Disconnect-VIServer -Server * -Confirm:$false -Force -Verbose -ErrorAction SilentlyContinue -WarningAction SilentlyContinue

        $vcInfo = Connect-VIServer -Server $Script:WorkingServer -Port $Port -WarningAction Continue -ErrorAction Stop
           
    
    }#end of If Method to Connect
    else{
        
        Disconnect-VIServer -Server * -Confirm:$false -Force -Verbose -ErrorAction SilentlyContinue -WarningAction SilentlyContinue

        $workingLocationNum = ""
        
        $tmpWorkingLocationNum = ""
        
        $Script:WorkingServer = ""
        
        $i = 0

        #MENU SELECT VCENTER
        foreach ($vcServer in $vcServerList){
	   
                $vcServerValue = $vcServer
	    
                Write-Output "            [$i].- $vcServerValue ";	
	            
                $i++	
                
                }#end foreach	
                
                Write-Output "            [$i].- Exit this script ";

                while(!(isNumeric($tmpWorkingLocationNum)) ){
	                
                    $tmpWorkingLocationNum = Read-Host "Type the number of vCenter that you want to connect to:"
                
                }#end of while

                    $workingLocationNum = ($tmpWorkingLocationNum / 1)

                if(($WorkingLocationNum -ge 0) -and ($WorkingLocationNum -le ($i-1))  ){
	                
                    $Script:WorkingServer = $vcServerList[$WorkingLocationNum]
                
                }#end of IF
                else{
            
                    Write-Host "Exit selected, or Invalid choice number. End of Script " -ForegroundColor Red -BackgroundColor White
            
                    Exit;
                }#end of else

        #Connect to Vcenter
        $Script:vcInfo = Connect-VIServer -Server $Script:WorkingServer -Port $port -WarningAction Continue -ErrorAction Continue -Verbose
  
    
    }#end of Else Method to Connect

}#End of Function Connect to vCenter



##################################### MAIN SCRIPT ############################################

#DEFINE VCENTER LIST
$tmpvCServerList = @();

#ADD OR REMOVE VCs        
$tmpvCServerList = ('VCSA01','VCSA02','VCSA03','VCSA04')

#Your License Key
[System.String]$myOwnLicenseKey = 

Do
{
 
        $tmpMethodToConnect = Read-Host -Prompt "Type the word 'Manual' if you want to choose VC to Connect. Type 'Auto' if you want to Type the Name of vCenter to Connect:"

        if ($tmpMethodToConnect -notmatch "^(?:Manual\b|Auto\b)"){
    
            Write-Host "You typed an invalid word. Type only (manual) or (automatic)" -ForegroundColor White -BackgroundColor Red
    
        }
        else{
    
            Write-Host "You typed a valid word. I will continue =D" -ForegroundColor White -BackgroundColor DarkBlue
    
        }
    
    }While ($tmpMethodToConnect -notmatch "^(?:Manual\b|Auto\b)")


if ($tmpMethodToConnect -match "^\bAuto\b$"){

    $tmpSuffix = Read-Host "Write the suffix of vCenter that you want to connect (company.local or company.intranet)"

    $tmpVC = Read-Host "Write the hostname of vCenter that you want to connect"

    Connect-vCenterServer -vCenterToConnect $tmpVC -suffix $tmpSuffix -methodToConnect Auto

}#end of IF
else{

    Connect-vCenterServer -methodToConnect $tmpMethodToConnect -vcServerList $tmpvCServerList

}#end of Else



##################################### CHOOSE HOST  ############################################

Write-Host "Choose which vSphere Host to put into Maintenance Mode." -ForegroundColor White -BackgroundColor Red

Write-Host "`n"

$esxiHostList = @()

$esxiHostList = Get-VMHost | Select-Object -ExpandProperty Name | Sort-Object

$iterator = 1

$esxiHostList | ForEach-Object {Write-Host $iterator ":" $_ ; $iterator ++}

$hostNumber = Read-Host "Type the number of ESXi Host to put into Maintenance Mode." -Verbose

$selectedHost = $esxiHostList[$hostNumber - 1]

Write-Host "You have selected ESXi Host:" -NoNewline

Write-host " $selectedHost" -ForegroundColor White -BackgroundColor DarkGreen

Pause-PSScript

[System.String] $esxiHostName = $selectedHost

################ FOR TEST PURPOSE ONLY ##############################

#[System.String] $esxiHostName = 'host01.worldstar.gc'

#####################################################################

#Create Host Object 

#CREATE VARIABLES

[System.String]$noteReason = "Change LUN of Boot - Reconfigure Host"

$hostObj = Get-VMHost -Name $esxiHostName -Verbose

#Place Selected host into Maintenance Mode

Set-VMHost -VMHost $hostObj -State Maintenance -Reason $noteReason -Evacuate -Confirm:$true -Verbose

############################### Move ESXi Host #####################################################
###### Based on: https://jreypo.io/2011/02/07/moving-hosts-between-datacenters-with-powercli/ ######

Pause-PsScript

#COLLECT INFO ABOUT VMK0 - Mgmt Network | VMK1 - vMotion Network | VMK2 - NAS Network

#View VMK Adapters

Get-VMHost -Name $esxiHostName | Get-VMHostNetworkAdapter | Where-Object -FilterScript {$PSItem.Name -like "*vmk*"} | Select-Object -Property Name,PortGroupName,Mac,IP, SubnetMask,VmHost | Format-Table -AutoSize

#VMK0 - Management Network Parameters

$vmk0MgmtNetworkObj = Get-VMHost -Name $esxiHostName | Get-VMHostNetworkAdapter | Where-Object -FilterScript {$PSItem.PortGroupName -like "*Management*"}

$vmk0MgmtNetworkPortGrpObj = Get-VMHost -Name $esxiHostName | Get-VirtualPortGroup -Name "*Management*"

$vmk0MgmtNetworkIP = $vmk0MgmtNetworkObj.IP

$vmk0MgmtNetworkSubnetMask = $vmk0MgmtNetworkObj.SubnetMask

[System.Boolean] $vmk0MgmtNetworkMgmtTrafficEnabled = $vmk0MgmtNetworkObj.ManagementTrafficEnabled

#VMK1 - vMotion Parameters

$vmk1vMotionObj = Get-VMHost -Name $esxiHostName | Get-VMHostNetworkAdapter | Where-Object -FilterScript {$PSItem.PortGroupName -like "*Motion*"}

$vmk1vMotionPortGrpObj = Get-VMHost -Name $esxiHostName | Get-VirtualPortGroup -Name "*Motion*"

[System.Int32]$vmk1vMotionVlanID = $vmk1vMotionPortGrpObj.VLanId

$vmk1vMotionIP = $vmk1vMotionObj.IP

$vmk1vMotionSubnetMask = $vmk1vMotionObj.SubnetMask

[System.Boolean] $vmk1vMotionEnabled = $vmk1vMotionObj.VMotionEnabled

#VMK2 - NAS Parameters

$vmk2NasObj = Get-VMHost -Name $esxiHostName | Get-VMHostNetworkAdapter | Where-Object -FilterScript {$PSItem.PortGroupName -like "NAS"}

$vmk2NasPortGrpObj = Get-VMHost -Name $esxiHostName | Get-VirtualPortGroup -Name "NAS"

[System.Int32] $vmk2NasVlanID = $vmk2NasPortGrpObj.VLanId

$vmk2NasIP = $vmk2NasObj.IP

$vmk2NasSubnetMask = $vmk2NasObj.SubnetMask

#####################################################################

$dcName = Get-Datacenter | Select-Object -ExpandProperty Name

$dcObj = Get-Datacenter -Name $dcName

Move-VMHost -VMHost $hostObj -Destination $dcObj -Verbose

#WAIT 5 SECONDS TO VALIDATE IF TASK IS RUNNING

Start-Sleep -Seconds 5 -Verbose

#DO WHILE TASK IS RUNNING TO VERIFY IF NSX UNINSTALL IS COMPLETED
$counter = 1
  
do{
        
    Write-Host "Iteration Number: $counter. Verifying task of uninstall NSX Agent" -BackgroundColor Cyan  -ForegroundColor White

    $hostObjID = $hostObj.Id

    Start-Sleep -Seconds 2 -Verbose

    $taskObjUninstallNSXAgent = Get-task | Where-Object -FilterScript {$PSItem.Name -like "*Uninstall*" -and $PSItem.ObjectId -eq $hostObjID}
       
    if ($taskObjUninstallNSXAgent -eq $null){
    
        Write-Host "No Task of Uninstall NSX Agent on Host $esxiHostName was not found or is completed" -ForegroundColor White -BackgroundColor Blue
    
    }#end of if task is null
    else{
    
        $taskObjUninstallNSXAgentMainState = $taskObjUninstallNSXAgent[0].State

        $taskObjUninstallNSXAgentSubTask = $taskObjUninstallNSXAgent[1].State

        $taskObjUninstallNSXAgentSubTaskPercent = $taskObjUninstallNSXAgent[1].PercentComplete    
    
        
        if ($taskObjUninstallNSXAgentMainState -like 'Running'){

            Write-Host "The Main Task of Uninstall NSX Agent on Host $esxiHostName is in state: $taskObjUninstallNSXAgentMainState."
        
            Write-Host "The sub task removal of NSX Agent is in: $taskObjUninstallNSXAgentSubTaskPercent percent"

            Start-Sleep -Seconds 10 -Verbose

        }
        else{
      
            Write-Host "The Main Task of Uninstall NSX Agent on Host $esxiHostName is completed" -ForegroundColor White -BackgroundColor Blue

            Write-Host "We can continue..."

            Start-Sleep -Seconds 5 -Verbose
              
        }
    
    }#end of else task is not null

    $counter ++
       
}while($taskObjUninstallNSXAgent -ne $null)

Pause-PSScript

#Disconnect Host only if task of removal nsx agent finished

$vDSListName = @()

$vDSListName = ('VDS01','VDS02','VDS03')

foreach ($vDSName in $vDSListName)
{
    
    Get-VDSwitch -Name $vDSName | Remove-VDSwitchVMHost -VMHost $hostObj -Confirm:$false -Verbose

}

#https://vdc-repo.vmware.com/vmwb-repository/dcr-public/0a01c8b1-4515-46e5-ade9-d457877d167e/f63b3243-b9c0-4199-bfc9-8a6b3b11151a/doc/Set-VMHost.html

Stop-VMHost -VMHost $hostObj -Reason "Upgrade Boot LUN" -Confirm:$true -RunAsync -Verbose

#Set-VMHost -VMHost $hostObj -State Connected -Verbose

Set-VMHost -VMHost $hostObj -State Disconnected -Verbose

Remove-VMHost -VMHost $hostObj -Confirm:$true -Verbose

Start-ModSleep -seconds 30

#WAIT HOST BECOME ONLINE TO CONTINUE THE SCRIPT

$httpsPortHost = '443'

do
{
 Write-Host "Waiting for $esxiHostName become online again to continue this script..." -ForegroundColor White -BackgroundColor Red
 
 Start-Sleep -Seconds 5 -Verbose

 $resultTestConnection = Test-NetConnection -ComputerName $esxiHostName -Port $httpsPortHost -Verbose

 [System.Boolean]$validateValue = $resultTestConnection.TcpTestSucceeded
    
}
until ($validateValue)


####################### ONLY RUN AFTER REINSTALL ESXI HOST ########################

#Change to your own password
Add-VMHost -Name $esxiHostName -Location $dcObj -User 'root' -Password 'YourPassword' -Confirm:$true -Force -Verbose


Get-VMhost -Name $esxiHostName | Set-VMhost -LicenseKey $myOwnLicenseKey -Verbose

$hostObj = Get-VMHost -Name $esxiHostName -Verbose

Set-VMHost -VMHost $hostObj -State Maintenance -Reason $noteReason -Confirm:$true -Verbose

#Rename PortGroup VM Network on vSwitch0

$vSwitchZeroName = 'vSwitch0'

$vSwitchOneName = 'vSwitch1'

$hostPortGrpName = 'VM Network'

$hostPortGrpNewName = 'vlan-3450'

Get-VirtualSwitch -VMHost $hostObj -Name $vSwitchZeroName | Get-VirtualPortGroup -Name $hostPortGrpName | Set-VirtualPortGroup -Name $hostPortGrpNewName -Confirm:$true -Verbose


#CREATE VSWITCH1

$vmHostPhysicalAdapters = Get-VMHostNetwork -VMHost $hostObj

$phNic01 = $vmHostPhysicalAdapters.PhysicalNic[1].DeviceName

New-VirtualSwitch -VMHost $hostObj -Name $vSwitchOneName -Nic $phNic01 -Confirm:$true -Verbose

$vSwitch1Obj = Get-VirtualSwitch -VMHost $hostObj -Name $vSwitchOneName

#CREATE VMK1 - vMotion e VMK2 - NAS on vSwitch1
#https://developer.vmware.com/docs/powercli/latest/vmware.vimautomation.core/commands/new-virtualportgroup/#Default

[System.String]$vMotionPortGrpName = 'vMotion'

[System.String]$vNASPortGrpName = 'NAS'

#CREATE VMOTION VMK
$vMotionPortGrp =  New-VirtualPortGroup -VirtualSwitch $vSwitch1Obj -Name $vMotionPortGrpName -VLanId $vmk1vMotionVlanID -Verbose

$vmkvMotionNic = New-VMHostNetworkAdapter -VMHost $hostObj -VirtualSwitch $vSwitch1Obj -PortGroup $vMotionPortGrp -IP $vmk1vMotionIP -SubnetMask $vmk1vMotionSubnetMask -VMotionEnabled $true -Verbose

#CREATE NAS VMK
$vNASPortGrp = New-VirtualPortGroup -VirtualSwitch $vSwitch1Obj -Name $vNASPortGrpName -VLanId $vmk2NasVlanID -Verbose

$vmkNASNic = New-VMHostNetworkAdapter -VMHost $hostObj -VirtualSwitch $vSwitch1Obj -PortGroup $vNASPortGrp -IP $vmk2NasIP -SubnetMask $vmk2NasSubnetMask -Verbose


#View VMK Adapters

Get-VMHost -Name $esxiHostName | Get-VMHostNetworkAdapter | Where-Object -FilterScript {$PSItem.Name -like "*vmk*"} | Select-Object -Property Name,PortGroupName,Mac,IP, SubnetMask,VmHost | Format-Table -AutoSize

#Attach Host Profile - Put the name of your standard host profile

$hostProfileStd = Get-VMHostProfile -Name "Host_Profile_Standard_Cluster01" -Verbose

#Set-VMHost -VMHost $hostObj -Profile $hostProfileStd -Confirm:$true -Verbose

Invoke-VMHostProfile -Profile $hostProfileStd -Entity $hostObj -AssociateOnly -Confirm:$true -Verbose

Pause-PSScript

#Check Host Profile Compliance

Test-VMHostProfileCompliance -VMHost $hostObj -Verbose

Pause-PSScript

#disable IPV6 only on vmkernel adapters

Get-VMHost -Name $esxiHostName | Get-VMHostNetworkAdapter | Where-Object -FilterScript {$PSItem.PortGroupName -eq 'Management Network'} | Set-VMHostNetworkAdapter -IPv6Enabled $false -Confirm:$false -Verbose

Get-VMHost -Name $esxiHostName | Get-VMHostNetworkAdapter | Where-Object -FilterScript {$PSItem.PortGroupName -eq 'vMotion'} | Set-VMHostNetworkAdapter -IPv6Enabled $false -Confirm:$false -Verbose

Get-VMHost -Name $esxiHostName | Get-VMHostNetworkAdapter | Where-Object -FilterScript {$PSItem.PortGroupName -eq 'NAS'} | Set-VMHostNetworkAdapter -IPv6Enabled $false -Confirm:$false -Verbose


#Move ESXi Host to YOUR_CLUSTER Cluster

$destinationClusterObj = VMware.VimAutomation.Core\Get-Cluster -Name 'YOUR_CLUSTER'

Move-VMHost -VMHost $hostObj -Destination $destinationClusterObj -Confirm:$true -Verbose

#WAIT 5 SECONDS TO VALIDATE IF TASK IS RUNNING

Start-Sleep -Seconds 5 -Verbose

#DO WHILE TASK IS RUNNING TO VERIFY IF NSX INSTALL IS COMPLETED
$counter = 1
  
do{
        
    Write-Host "Iteration Number: $counter. Verifying task of Install NSX Agent" -BackgroundColor Cyan  -ForegroundColor White

    $hostObjID = $hostObj.Id

    Start-Sleep -Seconds 2 -Verbose

    $taskObjInstallNSXAgent = Get-task | Where-Object -FilterScript {$PSItem.Name -like "*Install*" -and $PSItem.ObjectId -eq $hostObjID}
       
    if ($taskObjInstallNSXAgent -eq $null){
    
        Write-Host "No Task of Install NSX Agent on Host: $esxiHostName was not found or is completed" -ForegroundColor White -BackgroundColor Blue
    
    }#end of if task is null
    else{
    
        $taskObjInstallNSXAgentMainState = $taskObjInstallNSXAgent[0].State

        $taskObjInstallNSXAgentSubTask = $taskObjInstallNSXAgent[1].State

        $taskObjInstallNSXAgentTaskPercent = $taskObjInstallNSXAgent[0].PercentComplete

        $taskObjInstallNSXAgentSubTaskPercent = $taskObjInstallNSXAgent[1].PercentComplete    
    
        
        if ($taskObjInstallNSXAgentMainState -like 'Running'){

            Write-Host "The Main Task of Install NSX Agent on Host: $esxiHostName is in state: $taskObjInstallNSXAgentMainState." -ForegroundColor White -BackgroundColor Green

            Write-Host "The Main Task of Install NSX Agent on Host: $esxiHostName is : $taskObjInstallNSXAgentTaskPercent percent concluded " -ForegroundColor Green -BackgroundColor Black
        
            Write-Host "The sub-task of installing NSX Agent is in: $taskObjInstallNSXAgentSubTaskPercent percent" -ForegroundColor White -BackgroundColor Green

            Start-Sleep -Seconds 10 -Verbose

        }
        else{
      
            Write-Host "The Main Task of Install NSX Agent on Host $esxiHostName is completed" -ForegroundColor White -BackgroundColor Blue

            Write-Host "We can continue..." -ForegroundColor Blue -BackgroundColor White

            Start-Sleep -Seconds 5 -Verbose
              
        }
    
    }#end of else task is not null

    $counter ++
       
}while($taskObjInstallNSXAgent -ne $null)

Pause-PSScript

#Remove Host Profile

Set-VMHost -VMHost $hostObj -Profile $null -Confirm:$true -Verbose

#Disable Maintenance Mode

Set-VMHost -VMHost $hostObj -State Connected -Confirm:$true -RunAsync -Verbose

Write-Host "End of Script" -ForegroundColor White -BackgroundColor DarkYellow

Pause-PSScript
