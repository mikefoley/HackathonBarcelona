
Connect-NSXserver -server "mgt-NSXm-01.demo.vmware.com" -username admin -password VMware1! -viusername administrator@vsphere.local -vipassword VMware1! -ViWarningAction "Ignore"

$cl = get-cluster vsancluster
$ds = get-datastore "CPBU_PM_PMM_4"
$ExternalGWIP = "10.134.17.253"
$InternalGWIP = "192.168.1.252"
$originalAddress="192.168.1.0/24"
$Uplinklogicalswitch = Get-VDPortGroup -Name "MGMT 129"
$InternalLogicalSwitch = Write-Menu  (Get-NSXLogicalSwitch) -PropertyToShow Name -Prompt "Select Logicical Switch" -AddExit
$natname = $InternalLogicalSwitch.name.substring(0,5)

#<future>
#Rather than using the IP array it would be better to add logic to get the FQDN's of the NAT's and decipher the IP address
#using Resolve-DnsName mgt-NSXe-03.demo.vmware.com
#<\future>

$ips = 75..79 |%{"10.134.17.$_"}
$UplinkIP = write-menu -menu ($ips) -Prompt "Select the External IP address for $natname" -AddExit


$vnic0 = New-NSXEdgeInterfaceSpec -Index 0 -Type uplink   -Name "$natname Uplink"   -ConnectedTo $Uplinklogicalswitch   -PrimaryAddress $UplinkIP     -SubnetPrefixLength 24 
$vnic1 = New-NSXEdgeInterfaceSpec -index 1 -Type internal -Name "$natname Internal" -ConnectedTo $InternalLogicalSwitch -PrimaryAddress $InternalGWIP -SubnetPrefixLength 24


New-NSXEdge -Name $natname -Interface $vnic0,$vnic1 -Cluster $cl -Datastore $ds -Username "admin" -password " *8]Gmuxqk2mC" -FwDefaultPolicyAllow -FwEnabled -AutoGenerateRules 

Get-NSXedge $natname | get-NSXedgenat | set-NSXedgenat -enabled -confirm:$false
Get-NSXEdge $natname | Get-NSXEdgeRouting | Set-NSXEdgeRouting -DefaultGatewayVnic 0 -DefaultGatewayAddress $ExternalGWIP -Confirm:$false

$rule1 = get-NSXedge $natname | get-NSXedgenat | new-NSXedgenatrule -Vnic 1 `
    -OriginalAddress $originalAddress -TranslatedAddress $UplinkIP -action snat `
    -Description "SNAT Outbound" -LoggingEnabled -Enabled

$rule2 = get-NSXedge $natname | get-NSXedgenat | new-NSXedgenatrule `
    -Vnic 0 -OriginalAddress $UplinkIP -TranslatedAddress 192.168.1.10 -action dnat `
    -Protocol tcp -Description "RDP to Domain Controller" -LoggingEnabled `
    -Enabled -OriginalPort 3389 -TranslatedPort 3389

$edge = Get-NSXEdge $natname    
$edge.features.dhcp.enabled = "true"
$edge | Set-NSXEdge -Confirm:$false
