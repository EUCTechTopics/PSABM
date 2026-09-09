function Get-ABMJWT {
    [CmdletBinding(
        SupportsShouldProcess = $False,
        ConfirmImpact = "None",
        SupportsPaging = $False,
        PositionalBinding = $True)
    ]
    [OutputType([string])]

    param (
        [Parameter(Mandatory = $true)]
        [String] $ClientId,

        [Parameter(Mandatory = $true)]
        [String] $KeyId,

        [Parameter(Mandatory = $true)]
        [String] $Key
    )

    # Replace these with your actual Apple values:
    $team_id = $ClientId
    $audience = "https://account.apple.com/auth/oauth2/v2/token"
    $alg = "ES256"

    # Extract base64 key by removing PEM headers/footers and whitespace
    $base64Key = ($Key -replace '-----.*-----', '') -replace '\s', ''
    $keyBytes = [Convert]::FromBase64String($base64Key)

    # Create ECDsa instance and import PKCS#8 private key
    $ecdsa = [System.Security.Cryptography.ECDsa]::Create()
    $bytesRead = 0
    $ecdsa.ImportPkcs8PrivateKey($keyBytes, [ref]$bytesRead)

    # JWT Header (keep order consistent)
    $header = [ordered]@{
        alg = $alg
        kid = $KeyId
        typ = "JWT"
    }

    # JWT Payload with iat and exp (180 days max)
    $now = Get-Date
    $payload = [ordered]@{
        sub = $ClientId
        aud = $audience
        iat = Get-UnixTime $now
        exp = Get-UnixTime $now.AddDays(180)
        jti = [guid]::NewGuid().ToString()
        iss = $team_id
    }

    # Convert header and payload to JSON then base64url encode
    $headerJson = $header | ConvertTo-Json -Compress
    $payloadJson = $payload | ConvertTo-Json -Compress

    $encodedHeader = ConvertTo-Base64 ([System.Text.Encoding]::UTF8.GetBytes($headerJson))
    $encodedPayload = ConvertTo-Base64 ([System.Text.Encoding]::UTF8.GetBytes($payloadJson))

    # Create the message to sign
    $jwtData = "$encodedHeader.$encodedPayload"
    $jwtBytes = [System.Text.Encoding]::UTF8.GetBytes($jwtData)

    # Hash the message
    $sha256 = [System.Security.Cryptography.SHA256]::Create()
    $hash = $sha256.ComputeHash($jwtBytes)

    # Sign the hash returns raw r||s signature
    $rawSignature = $ecdsa.SignHash($hash)

    # Base64url encode the signature
    $encodedSignature = ConvertTo-Base64 $rawSignature

    # Combine to final JWT
    $jwt = "$jwtData.$encodedSignature"

    return $jwt
}