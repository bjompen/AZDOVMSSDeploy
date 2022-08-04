$Location = 'Sweden Central'
$RGName = 'myBicepDeployedVMSS'

$VnetName ='myvnet'
$VMSSName ='myvmss'

$AzureADIdentityDisplayName = 'MyBicepADOServiceConnectionIdentity'

$AzDOProjectName = 'LabProject' 
$PAT = 'insertPATfromAZDOhere'

$sshPubKey = Get-Content C:\Users\bjompen\.ssh\id_rsa.pub

## Deploy resources
Connect-AzAccount

throw 'select account or die!'

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
$AppIdentity = New-AzADServicePrincipal -DisplayName $AzureADIdentityDisplayName
$SecurePassword = ConvertTo-SecureString $AppIdentity.PasswordCredentials[0].SecretText -AsPlainText -Force

## Grant service account access to the new resource group
$EnterpriceAppObjectId = $AppIdentity.Id

New-AzResourceGroupDeployment -ResourceGroupName $rg.ResourceGroupName -TemplateFile .\roleDefinition.bicep -TemplateParameterObject @{
    principalId = $EnterpriceAppObjectId
} -Verbose

## Service connection in azdo
$Context = Get-AzContext

Connect-ADOPS -Username 'MyAzdoUser' -Organization 'MyAzdoOrganization' -PersonalAccessToken $PAT

$AzureServicePrincipal = [pscredential]::new($AppIdentity.AppId, $SecurePassword)

$ServiceConenctionSplat = @{
    TenantId = $Context.Tenant.Id 
    SubscriptionId = $Context.Subscription.Id 
    SubscriptionName = $Context.Subscription.Name 
    Project = $AzDOProjectName
    ConnectionName = 'MyBicepConnection'
    ServicePrincipal = $AzureServicePrincipal
}
$ADOPSServiceConnection = New-ADOPSServiceConnection @ServiceConenctionSplat

## Create VMSS

$AzureDevOpsProject = Get-ADOPSProject -Project $AzDOProjectName
$AzureVMSS = Get-AzVmss -VMScaleSetName $VMSSName
$ElasticPoolObject = New-ADOPSElasticPoolObject -ServiceEndpointId $ADOPSServiceConnection.id -ServiceEndpointScope $AzureDevOpsProject.Id -AzureId $AzureVMSS.id -MaxCapacity 5 -RecycleAfterEachUse $true
$ElasticPool = New-ADOPSElasticPool -ElasticPoolObject $ElasticPoolObject -PoolName 'MyBicepCreatedElasticPool' -ProjectId $AzureDevOpsProject.id
