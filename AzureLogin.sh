You can use -Credential parameter, and DPAPI to login.

First, run the following PowerShell once to store a secured password for your account.

Read-Host "Enter Password" -AsSecureString | ConvertTo-SecureString `
-AsPlainText -Force | ConvertFrom-SecureString | Out-File "C:\Password.txt"
And then, you can use the following script to login.

# The azure account here must not be a Live ID.
$username = "<your Azure account>"
$SecurePassword = Get-Content "C:\Password.txt" | ConvertTo-SecureString
$cred = new-object -typename System.Management.Automation.PSCredential `
     -argumentlist $username, $SecurePassword

Login-AzureRmAccount -Credential $cred
An other way would be using Service Principal. First, you should follow the article to create a Service Principal

And then, use the following script to login.

$clientID = "<the client id of your AD Application>"
$key = "<the key of your AD Application>"
$SecurePassword = $key | ConvertTo-SecureString -AsPlainText -Force
$cred = new-object -typename System.Management.Automation.PSCredential `
     -argumentlist $clientID, $SecurePassword

Add-AzureRmAccount -Credential $cred -Tenant "xxxx-xxxx-xxxx-xxxx" -ServicePrincipal
