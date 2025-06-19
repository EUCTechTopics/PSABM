function Get-ABMSecret {
    param (
        [string]$Name,
        [switch]$AsPlainText = $false,
        [switch]$UseSecretManagement = $false
    )
    if ($UseSecretManagement) {
        try {
            return Get-Secret -Name $Name.ToUpper() -AsPlainText:$AsPlainText
        }
        catch [System.Management.Automation.ItemNotFoundException] {
            Write-Verbose "Secret $Name not found. Attempting to retrieve secret in lowercase."
            return Get-Secret -Name $Name.ToLower() -AsPlainText:$AsPlainText
        }
        catch {
            throw $_
        }
    } else {
        # Try both original and lowercase formatted versions
        $formattedNames = @(
            $name.ToUpper().Replace('-', '_'),
            $name.ToLower().Replace('-', '_')
        )

        foreach ($formattedName in $formattedNames) {
            $value = [environment]::GetEnvironmentVariable($formattedName)
            if (-not [string]::IsNullOrEmpty($value)) {
                return $value
            }
        }

        throw "Secret $Name not found."

    }
}