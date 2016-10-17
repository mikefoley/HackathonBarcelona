#Based on a script from Christopher Lewis "Thecloudexper"
#downloaded from: https://gist.github.com/thecloudxpert/40300ed0819c042658dfcada47453bb4
#Modified for vSphere 6.5
# Deploy VC using vCSA-Deploy
# Convert JSON file to PowerShell object 


$json = (Get-Content -Raw $ConfigLoc) | ConvertFrom-Json
$ConfigLoc = ".\vCSA_on_VC.json"
$drive = (gwmi Win32_cdromdrive).drive
$Installer = "\vcsa-cli-installer\win32\vcsa-deploy.exe"
if (get-item $drive\$installer) {
    Write-host "CLI Installer found. Continuing..."
}
    else {
        Write-host "Installer not found on $drive. Exiting"
        Exit
    }
    $filename = "VC.configuration-readyto-deploy" + (Get-Date -Format "mm-dd-yyyy") + ".json"
$UpdatedConfig = "$temp\VC.configuration-readyto-deploy.json"

#Query setup information
#
$vcsaorpsc = Write-Menu -menu "VCSA","PSC" -Prompt "Select VC password" -addexit -HeaderColor green -TextColor Yellow
$appliancename = read-host "Enter appliance name"


if ($vcsa) {
    $PSCname = read-host "Enter PSC FQDN: "
    $deploymentoption = Write-Menu -menu "tiny","small","large" -Prompt "Select VCSCA size" -addexit -HeaderColor green -TextColor Yellow
    $json."target.vcsa".appliance.name="$appliancename"  
    # VCSA SSO information
    $json."target.vcsa".sso.password = "VMware1!"
    $json."target.vcsa".sso."domain-name" = "vsphere.local"
    $json."target.vcsa".sso."platform.services.controller" = "$PSCname"
    $json."target.vcsa".sso."sso.port"="443"  
    $json."target.vcsa".appliance."deployment.option"="management-small"

}
elseif ($psc) {
    $json."target.vcsa".appliance."deployment.option"="infrastructure"
    $json."target.vcsa".sso.password = "VMware1!"
    $json."target.vcsa".sso."domain-name" = "vsphere.local"
    $json."target.vcsa".sso."site-name" = "Default-First-Site"
}

#
$viserver = "mgt-vc-01.demo.vmware.com"
$vcusername = "Administrator@vsphere.local"
$vcpassword = "VMware1!"
$selectedVCHostname = Write-Menu -menu "$viserver",(read-host "Enter VC or press return to select the default") -Prompt "Select VC" -addexit -HeaderColor green -TextColor Yellow
$selectedUsername = Write-Menu -menu "$vcusername",(read-host "Enter VC username or press return to select the default") -Prompt "Select VC username" -addexit -HeaderColor green -TextColor Yellow
$selectedPassword = Write-Menu -menu "$vcpassword",(read-host "Enter VC password or press return to select the default") -Prompt "Select VC password" -addexit -HeaderColor green -TextColor Yellow
#
try {
Connect-VIserver $selectedVCHostname -user $selectedUsername -password $selectedPassword    
}
catch [System.Exception] {
    
}

#
$datacenter = write-menu -menu (get-datacenter |select Name ) -prompt 'Select a datacenter these VMs should run in' -AddExit -HeaderColor Green -TextColor Yellow 
$cluster = write-menu -menu (get-cluster |select Name ) -prompt 'Select a datacenter these VMs should run in' -AddExit -HeaderColor Green -TextColor Yellow 
$folder = write-menu -menu (get-folder |select Name ) -prompt 'Select a folder these VMs should run in' -AddExit -HeaderColor Green -TextColor Yellow 
$datastore = write-menu -menu (get-datastore |select Name ) -prompt 'Select a datacenter these VMs should run in' -AddExit -HeaderColor Green -TextColor Yellow 
$deploymentnetwork = write-menu -menu (get-vdportgroup |select Name ) -prompt 'Select a network to run on' -AddExit -HeaderColor Green -TextColor Yellow 
$selectedvcsaname = Write-Menu -menu "$vcpassword",(read-host "Enter VC password or press return to select the default") -Prompt "Select VC password" -addexit -HeaderColor green -TextColor Yellow



# Deploy to vCSA system information
$json."target.vcsa".vc.hostname="$selectedVCHostname"
$json."target.vcsa".vc.username="$selectedUsername"
$json."target.vcsa".vc.password="$selectedPassword"
$json."target.vcsa".vc."$deploymentnetwork"
$json."target.vcsa".vc.datacenter="$datacenter"
$json."target.vcsa".vc.datastore="$datastore"
$json."target.vcsa".vc.target="$cluster"
$json."target.vcsa".vc."vm.folder"="$folder"


#Appliance Information
$json."target.vcsa".appliance."thin.disk.mode"=$true
$json."target.vcsa".os.password="VMware1!"
$json."target.vcsa".os."ssh.enable"=$true
 
function Set-IPAddress {
    param(
        [string]$ipaddress = $(read-host "Enter an IP Address (ie 10.10.10.10)"),
        [string]$mask = $(read-host "Enter the subnet prefix (e.g. 24)"),
        [string]$gateway = $(read-host "Enter the current name of the NIC you want to rename"),
        [string]$dns1 = $(read-host "Enter the first DNS Server (ie 10.2.0.28)"),
        )
}

#parse IP address
#$ipaddress = (read-host "Enter IP Address")
#IF ([system.net.ipaddress]::tryparse($ipaddress,[ref]$null)){
#  Write-Host "$ipaddress is a valid address" 
#} else {
#  write-Host -ForegroundColor Red "is an invalid address"
#  break
#}

Set-IPAddress
# Networking
$json."target.vcsa".network."system.name" = "mgt-vc-01.lab1.local"
$json."target.vcsa".network.mode = "static"
$json."target.vcsa".network.ip = "$ipaddress
$json."target.vcsa".network."ip.family" = "ipv4"
$json."target.vcsa".network.prefix = "$mask"
$json."target.vcsa".network.gateway = "$gateway"
$json."target.vcsa".network."dns.servers"="$dns1"







#CEIP (Not used on VC, just PSC)
#$json.ceip.settings."ceip.enabled" = $false
#Write out updated JSON for Deployment
$json | ConvertTo-Json | Set-Content -Path "$UpdatedConfig"
$command="$installer install  --acknowledge-ceip --accept-eula --no-esx-ssl-verify $updatedConfig"
$verify="$installer install  --acknowledge-ceip --accept-eula --no-esx-ssl-verify --verify-only $updatedConfig"
#Invoke-Expression $command
Invoke-Expression $verify
