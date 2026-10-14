param(
    [ValidateSet('cpu','cuda12','cuda13','vulkan')][string]$Backend = 'cpu',
    [string]$Carpeta = (Join-Path $PSScriptRoot 'local')
)
. (Join-Path $PSScriptRoot 'utilidades.ps1')
$catalogo = Leer-Catalogo
$raiz = Resolver-Carpeta $Carpeta
$destino = Join-Path $raiz ("llama-" + $catalogo.llama_version + '-' + $Backend)
if (Test-Path -LiteralPath $destino) {
    $marca = Join-Path $destino 'instalacion-completa.txt'
    if ((Test-Path -LiteralPath $marca) -and
        (Get-Content -LiteralPath $marca -Raw).Trim() -eq $catalogo.llama_version -and
        (Test-Path -LiteralPath (Join-Path $destino 'llama-server.exe'))) {
        Write-Host "Ya esta instalado: $destino"
        exit 0
    }
    throw "Ya existe una carpeta sin una instalacion completa: $destino. No se ha sobrescrito. Usa -Carpeta con otra ruta."
}
$paquetes = @($catalogo.paquetes | Where-Object { $_.backend -eq $Backend })
if ($paquetes.Count -eq 0) { throw 'No hay paquetes para este backend.' }
$descargas = Join-Path $raiz 'descargas'
New-Item -ItemType Directory -Path $descargas -Force | Out-Null
foreach ($paquete in $paquetes) {
    Obtener-Archivo $paquete.url (Join-Path $descargas $paquete.nombre) $paquete.bytes $paquete.sha256
}
New-Item -ItemType Directory -Path $destino | Out-Null
foreach ($paquete in $paquetes) {
    Expand-Archive -LiteralPath (Join-Path $descargas $paquete.nombre) -DestinationPath $destino
}
if (!(Test-Path -LiteralPath (Join-Path $destino 'llama-server.exe'))) { throw 'No se encuentra llama-server.exe en el paquete.' }
& (Join-Path $destino 'llama-server.exe') --version
if ($LASTEXITCODE -ne 0) { throw 'La compilacion no arranca. Revisa los requisitos del backend en la guia.' }
Set-Content -LiteralPath (Join-Path $destino 'instalacion-completa.txt') -Value $catalogo.llama_version -Encoding ASCII
Write-Host "Instalacion terminada: $destino"
