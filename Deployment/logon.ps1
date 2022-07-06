Start-Transcript -Path C:\WindowsAzure\Logs\extensionlog.txt -Append

#InstallAzmodule
Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force
Set-PSRepository -Name "PSGallery" -Installationpolicy Trusted
Install-Module -Name Az.Synapse -Force
Import-Module -Name Az.Synapse

. C:\LabFiles\AzureCreds.ps1



$userName = $AzureUserName # READ FROM FILE
$password = $AzurePassword # READ FROM FILE
$Sid = $AzureSubscriptionID # READ FROM FILE
$deployId = $DeploymentID
$synapseworkspaceName = "scm"+"synapse-ws"


$securePassword = $password | ConvertTo-SecureString -AsPlainText -Force
$cred = new-object -typename System.Management.Automation.PSCredential -argumentlist $userName, $SecurePassword

Connect-AzAccount -Credential $cred | Out-Null

$rgName = (Get-AzResourceGroup | Where-Object { $_.ResourceGroupName -like "many*" }).ResourceGroupName

$storageAccounts = Get-AzResource -ResourceGroupName $rgName -ResourceType "Microsoft.Storage/storageAccounts"
$storageName = $storageAccounts | Where-Object { $_.Name -like 'synapsestrg*' }
$storageaccountname = $storageName.Name

#adding roles
$id3 = $userName
New-AzRoleAssignment -SignInName $id3 -RoleDefinitionName "Storage Blob Data Contributor" -Scope "/subscriptions/$Sid/resourceGroups/$rgName/providers/Microsoft.Storage/storageAccounts/$storageaccountname"

$id1 = (Get-AzADServicePrincipal -DisplayName $synapseworkspaceName).id
New-AzRoleAssignment -ObjectId $id1 -RoleDefinitionName "Storage Blob Data Contributor" -Scope "/subscriptions/$Sid/resourceGroups/$rgName/providers/Microsoft.Storage/storageAccounts/$storageaccountname"

#adding clientIP
New-AzSynapseFirewallRule -WorkspaceName $synapseworkspaceName -Name all -StartIpAddress "0.0.0.0" -EndIpAddress "255.255.255.255"
sleep 20

#uploading notebooks to Synapse
Set-AzSynapseNotebook -WorkspaceName $synapseworkspaceName -DefinitionFile "C:\LabFiles\00_preparedata.ipynb"
Set-AzSynapseNotebook -WorkspaceName $synapseworkspaceName -DefinitionFile "C:\LabFiles\01_train_deploy_model.ipynb"


Set-AzSynapsePipeline -WorkspaceName $synapseworkspaceName -Name Pipeline 1 -DefinitionFile "C:\pipeline.json"

Invoke-AzSynapsePipeline -WorkspaceName $synapseworkspaceName -PipelineName Pipeline 1
