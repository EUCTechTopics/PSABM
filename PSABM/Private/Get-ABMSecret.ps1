function Get-ABMSecret {
    param (
        [string]$Name,
        [switch]$AsPlainText = $false
    )

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