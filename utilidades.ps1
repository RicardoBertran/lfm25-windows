$ErrorActionPreference = 'Stop'

function Obtener-Archivo {
    param([string]$Url, [string]$Destino, [long]$Bytes, [string]$Sha256)
    if (Test-Path -LiteralPath $Destino) {
        if ((Get-Item -LiteralPath $Destino).Length -ne $Bytes -or
            (Get-FileHash -LiteralPath $Destino -Algorithm SHA256).Hash -ne $Sha256) {
            throw "El archivo existente no coincide: $Destino. No se ha sobrescrito. Usa otra carpeta para descargarlo."
        }
        Write-Host "Archivo comprobado: $Destino"
        return
    }
    $parcial = "$Destino.part"
    if (Test-Path -LiteralPath $parcial) {
        if ((Get-Item -LiteralPath $parcial).Length -gt $Bytes) {
            throw "La descarga parcial es mayor de lo esperado: $parcial. Usa otra carpeta."
        }
    }
    if (!(Test-Path -LiteralPath $parcial) -or (Get-Item -LiteralPath $parcial).Length -lt $Bytes) {
        & curl.exe --location --fail --retry 5 --retry-delay 3 --continue-at - --output $parcial $Url
        if ($LASTEXITCODE -ne 0) { throw 'Descarga interrumpida. Ejecuta el mismo comando para continuar.' }
    }
    if ((Get-Item -LiteralPath $parcial).Length -ne $Bytes) { throw 'El tamaño de la descarga no coincide.' }
    Write-Host 'Comprobando SHA256. En un modelo grande puede tardar varios minutos...'
    if ((Get-FileHash -LiteralPath $parcial -Algorithm SHA256).Hash -ne $Sha256) {
        throw "La descarga no supera la comprobacion SHA256: $parcial. Se conserva el archivo; usa otra carpeta para volver a descargar."
    }
    Move-Item -LiteralPath $parcial -Destination $Destino
}

function Leer-Catalogo {
    Get-Content -LiteralPath (Join-Path $PSScriptRoot 'catalogo.json') -Raw | ConvertFrom-Json
}

function Resolver-Carpeta {
    param([string]$Carpeta)
    $ruta = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($Carpeta)
    New-Item -ItemType Directory -Path $ruta -Force | Out-Null
    return $ruta
}
