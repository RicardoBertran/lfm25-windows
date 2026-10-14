param(
    [ValidateSet('cpu','cuda12','cuda13','vulkan')][string]$Backend = 'cpu',
    [ValidateSet('Q4_K_M','Q5_K_M','Q6_K','Q8_0')][string]$Cuantizacion = 'Q4_K_M',
    [ValidateSet('CPU','Auto','ExpertosRAM')][string]$Modo = 'CPU',
    [string]$Dispositivo = '',
    [ValidateRange(1024,131072)][int]$Contexto = 4096,
    [ValidateRange(1024,65535)][int]$Puerto = 18082,
    [string]$Carpeta = (Join-Path $PSScriptRoot 'local')
)
. (Join-Path $PSScriptRoot 'utilidades.ps1')
if ($Backend -eq 'cpu' -and $Modo -ne 'CPU') { throw 'Con el backend cpu utiliza -Modo CPU.' }
$catalogo = Leer-Catalogo
$raiz = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($Carpeta)
$exe = Join-Path $raiz ("llama-" + $catalogo.llama_version + '-' + $Backend + '/llama-server.exe')
$entrada = $catalogo.modelos | Where-Object { $_.cuantizacion -eq $Cuantizacion }
$modelo = Join-Path $raiz ('modelos/' + $entrada.nombre)
if (!(Test-Path -LiteralPath $exe)) { throw 'Primero ejecuta instalar.ps1 con este backend.' }
if (!(Test-Path -LiteralPath $modelo)) { throw 'Primero ejecuta descargar.ps1 con esta cuantizacion.' }
if ((Get-Item -LiteralPath $modelo).Length -ne $entrada.bytes) { throw 'El tamano del modelo no coincide. Ejecuta descargar.ps1 para comprobarlo.' }
if (Get-NetTCPConnection -State Listen -LocalPort $Puerto -ErrorAction SilentlyContinue) { throw "El puerto $Puerto esta ocupado. Elige otro con -Puerto." }
$argumentos = @('-m', $modelo, '-c', "$Contexto", '-np', '1', '--host', '127.0.0.1', '--port', "$Puerto", '--jinja', '--temp', '0.1', '--top-k', '50', '--repeat-penalty', '1.05')
if ($Modo -eq 'CPU') {
    $argumentos += @('--device','none','-ngl','0','--fit','off')
} else {
    if ($Dispositivo) { $argumentos += @('--device', $Dispositivo) }
    $argumentos += @('--fit','on')
    if ($Modo -eq 'ExpertosRAM') { $argumentos += '--cpu-moe' }
}
Write-Host "Espera a que termine de cargar. Abre http://127.0.0.1:$Puerto cuando este listo. Para detenerlo: Ctrl+C."
& $exe @argumentos
if ($LASTEXITCODE -ne 0) { throw 'El servidor se ha detenido con un error. Revisa el mensaje anterior y la guia.' }
