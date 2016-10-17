#Based on a script from Christopher Lewis "Thecloudexper"
#downloaded from: https://gist.github.com/thecloudxpert/40300ed0819c042658dfcada47453bb4
#Modified for vSphere 6.5
# Deploy VC using vCSA-Deploy
# Convert JSON file to PowerShell object 
$ConfigLoc = "C:\Users\Administrator\Dropbox\My Code Library\vLab Deployment\vCSA_on_VC.json"
$Installer = "F:\vcsa-cli-installer\win32\vcsa-deploy.exe"
$UpdatedConfig = "c:\temp\VC.configuration-readyto-deploy.json"
$CodeLibrary = "C:\Users\Administrator\Dropbox\My Code Library\vLab Deployment\"

$json = (Get-Content -Raw $ConfigLoc) | ConvertFrom-Json


# Deploy to vCSA system information
$json."target.vcsa".vc.hostname="mgt-vc-01.demo.vmware.com"
$json."target.vcsa".vc.username="Administrator@vsphere.local"
$json."target.vcsa".vc.password="VMware1!"
$json."target.vcsa".vc."deployment.network"="vxw-dvs-38-virtualwire-3-sid-5003-NAT-2 Switch"
$json."target.vcsa".vc.datacenter="Datacenter"
$json."target.vcsa".vc.datastore="vsanDatastore"
$json."target.vcsa".vc.target="VSANCluster"
$json."target.vcsa".vc."vm.folder"="NAT-2"


#Appliance Information
$json."target.vcsa".appliance."thin.disk.mode"=$true
$json."target.vcsa".appliance."deployment.option"="management-small"
$json."target.vcsa".appliance.name="NAT-2 VC 01"



# Networking
$json."target.vcsa".network."system.name" = "mgt-vc-01.lab1.local"
$json."target.vcsa".network.mode = "static"
$json."target.vcsa".network.ip = "192.168.1.11"
$json."target.vcsa".network."ip.family" = "ipv4"
$json."target.vcsa".network.prefix = "24"
$json."target.vcsa".network.gateway = "192.168.1.252"
$json."target.vcsa".network."dns.servers"="192.168.1.10"

#OS Information
$json."target.vcsa".os.password="VMware1!"
$json."target.vcsa".os."ssh.enable"=$true


# VCSA SSO information
$json."target.vcsa".sso.password = "VMware1!"
$json."target.vcsa".sso."domain-name" = "vsphere.local"
$json."target.vcsa".sso."platform.services.controller" = "mgt-psc-01.lab1.local"
$json."target.vcsa".sso."sso.port"="443"

#CEIP (Not used on VC, just PSC)
#$json.ceip.settings."ceip.enabled" = $false
#Write out updated JSON for Deployment
$json | ConvertTo-Json | Set-Content -Path "$UpdatedConfig"
$command="$installer install  --acknowledge-ceip --accept-eula --no-esx-ssl-verify $updatedConfig"
$verify="$installer install  --acknowledge-ceip --accept-eula --no-esx-ssl-verify --verify-only $updatedConfig"
#Invoke-Expression $command
Invoke-Expression $verify
