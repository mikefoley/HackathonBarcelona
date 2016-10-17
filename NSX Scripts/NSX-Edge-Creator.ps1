
connect-nsxserver -server "mgt-nsxm-01.demo.vmware.com" -username admin -password VMware1! -viusername administrator@vsphere.local -vipassword VMware1! -ViWarningAction "Ignore"

$cl = get-cluster vsancluster
$ds = get-datastore "CPBU_PM_PMM_4"
$InternalIP = "192.168.1.252"
$Uplinklogicalswitch = Get-VirtualPortGroup -Name "MGMT 129"
$InternalLogicalSwitch = Write-Menu  (Get-NsxLogicalSwitch) -PropertyToShow Name -Prompt "Select Logicical Switch"
$natname = $InternalLogicalSwitch.name.substring(0,5)
$NATDescription = $LSS+" Edge"
$numberofEdges = 1..4
$ips = 75..79 |%{"10.134.17.$_"}
$UplinkIP = write-menu -menu ($ips) -Prompt "Select the External IP address for $natname"


$vnic0 = New-NsxEdgeInterfaceSpec -index 1 -Type uplink -Name "$natname Uplink"  -ConnectedTo $Uplinklogicalswitch -PrimaryAddress $UplinkIP -SubnetPrefixLength 24
$vnic1 = New-NsxEdgeInterfaceSpec -index 2 -Type internal -Name "$natname Internal" -ConnectedTo $InternalLogicalSwitch -PrimaryAddress $InternalIP -SubnetPrefixLength 24


New-NsxEdge -Name $natname -Interface $vnic0,$vnic1 -Cluster $cl -Datastore $ds -Username "admin" -password " *8]Gmuxqk2mC" -FwDefaultPolicyAllow -FwEnabled -AutoGenerateRules 

get-nsxedge $natname | get-nsxedgenat | set-nsxedgenat -enabled -confirm:$false

$rule1 = get-nsxedge $natname | get-nsxedgenat | new-nsxedgenatrule -Vnic 1 `
    -OriginalAddress $InternalIP -TranslatedAddress $UplinkIP -action snat `
    -Description "SNAT Outbound" -LoggingEnabled -Enabled

$rule2 = get-nsxedge $natname | get-nsxedgenat | new-nsxedgenatrule `
    -Vnic 0 -OriginalAddress $UplinkIP -TranslatedAddress 192.168.1.10 -action dnat `
    -Protocol tcp -Description "RDP to Domain Controller" -LoggingEnabled `
    -Enabled -OriginalPort 3389 -TranslatedPort 3389

$edge = Get-NsxEdge $natname    
$edge.features.dhcp.enabled = "true"
$edge | Set-NsxEdge
