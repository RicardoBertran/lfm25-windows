param(
    [ValidateSet('Q4_K_M','Q5_K_M','Q6_K','Q8_0')][string]$Cuantizacion = 'Q4_K_M',
    [string]$Carpeta = (Join-Path $PSScriptRoot 'local')
)
. (Join-Path $PSScriptRoot 'utilidades.ps1')
$catalogo = Leer-Catalogo
$raiz = Resolver-Carpeta $Carpeta
$modelos = Join-Path $raiz 'modelos'
New-Item -ItemType Directory -Path $modelos -Force | Out-Null
$modelo = $catalogo.modelos | Where-Object { $_.cuantizacion -eq $Cuantizacion }
if (!$modelo) { throw 'No se encuentra la cuantizacion en el catalogo.' }
Obtener-Archivo $modelo.url (Join-Path $modelos $modelo.nombre) $modelo.bytes $modelo.sha256
Write-Host "Modelo listo: $($modelo.nombre)"
