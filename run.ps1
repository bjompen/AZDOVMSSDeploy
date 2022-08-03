$Location = 'Sweden Central'
$RGName = 'myBicepDeployedVMSS'

$VnetName ='myvnet'
$VMSSName ='myvmss'

$sshPubKey = Get-Content C:\Users\bjompen\.ssh\id_rsa.pub

$rg = New-AzResourceGroup -Name $RGName -Location $Location

$vnet = New-AzResourceGroupDeployment -ResourceGroupName $rg.ResourceGroupName -TemplateFile .\vnet.bicep -TemplateParameterObject @{
    name = $VnetName
} -Verbose

$subId = $vnet.Outputs['subnetId'].Value

$vmss = New-AzResourceGroupDeployment -ResourceGroupName $rg.ResourceGroupName -TemplateFile .\vmss.bicep -TemplateParameterObject @{
    name = $VMSSName
    sshPubKey = $sshPubKey
    subnetId = $subId
} -Verbose

## Set it up in AZDO