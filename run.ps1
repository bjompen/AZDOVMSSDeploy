$Location = 'Sweden Central'
$RGName = 'myBicepDeployedVMSS'

$VnetName ='myvnet'
$VMSSName ='myvmss'

$sshPubKey = Get-Content C:\Users\bjompen\.ssh\id_rsa.pub

## Deploy resources
Connect-AzAccount

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

## Create service account
$AzureADIdentityDisplayName = 'MyBicepADOServiceConnectionIdentity'

$AppIdentity = New-AzADApplication -DisplayName $AzureADIdentityDisplayName 
$AppIdentityPass = New-AzADAppCredential -ObjectId $AppIdentity.id
$SecurePassword = ConvertTo-SecureString $AppIdentityPass.SecretText -AsPlainText -Force

## Grant service account access to the new resource group



## Service connection in azdo
$Context = Get-AzContext

Connect-ADOPS -Username 'bjorn.sundling@gmail.com' -Organization 'bjornsundling' -PersonalAccessToken $PAT

$AzureServicePrincipal = [pscredential]::new($AppIdentity.AppId, $SecurePassword)

$ServiceConenctionSplat = @{
    TenantId = $Context.Tenant.Id 
    SubscriptionId = $Context.Subscription.Id 
    SubscriptionName = $Context.Subscription.Name 
    Project = 'LabProject' 
    ConnectionName = 'MyBicepConnection'
    ServicePrincipal = $AzureServicePrincipal
}
New-ADOPSServiceConnection @ServiceConenctionSplat
