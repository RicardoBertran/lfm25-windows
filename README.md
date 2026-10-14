# Liquid AI LFM2.5-24B-A2B en Windows

Descarga el modelo oficial, elige una cuantización y úsalo desde el navegador con llama.cpp. Todo se guarda en una carpeta propia. No necesitas Python, Docker ni compilar nada.

**Para empezar: Q4_K_M, 32 GB de RAM y un contexto de 4096 tokens.** Si no tienes una GPU compatible, puedes utilizar la CPU. La velocidad dependerá de tu equipo.

## 1. Qué modelo vas a descargar

[LFM2.5-24B-A2B](https://huggingface.co/LiquidAI/LFM2.5-24B-A2B) es un modelo de texto de Liquid AI. Usa una arquitectura MoE, o mezcla de expertos: tiene **24.000 millones de parámetros totales** y utiliza aproximadamente **2.450 millones por token**. Selecciona 4 de los 64 expertos de cada bloque MoE.

Activar pocos expertos reduce el trabajo de cálculo. **Los pesos de todos los expertos siguen necesitando memoria**, aunque no se utilicen todos a la vez. Según cómo lo ejecutes, se guardarán en RAM, en VRAM o repartidos entre ambas. No calcules la memoria necesaria como si fuera un modelo de 2,45B.

Esta guía usa los archivos del [repositorio GGUF oficial de Liquid AI](https://huggingface.co/LiquidAI/LFM2.5-24B-A2B-GGUF). GGUF es el formato que lee llama.cpp. Una cuantización reduce el tamaño de los pesos: una versión más pequeña consume menos memoria, pero puede perder precisión. No es necesario descargar todas.

## 2. Elige una cuantización

Los cuatro archivos siguientes existen en el repositorio oficial. Los enlaces fijan la misma revisión para que la descarga sea reproducible.

| Cuantización y archivo oficial | Tamaño exacto en bytes | Tamaño GB / GiB | RAM instalada orientativa para CPU | VRAM orientativa para intentar cargar todos los pesos |
|---|---:|---:|---|---|
| [LFM2.5-24B-A2B-Q4_K_M.gguf](https://huggingface.co/LiquidAI/LFM2.5-24B-A2B-GGUF/resolve/0912d33141f77e10705345a6732bfd83f0252fdc/LFM2.5-24B-A2B-Q4_K_M.gguf) | 14.526.258.464 | 14,53 / 13,53 | 32 GB | 16 GB con poco margen; 24 GB dan más margen |
| [LFM2.5-24B-A2B-Q5_K_M.gguf](https://huggingface.co/LiquidAI/LFM2.5-24B-A2B-GGUF/resolve/0912d33141f77e10705345a6732bfd83f0252fdc/LFM2.5-24B-A2B-Q5_K_M.gguf) | 17.029.602.592 | 17,03 / 15,86 | 32 GB | 20–24 GB |
| [LFM2.5-24B-A2B-Q6_K.gguf](https://huggingface.co/LiquidAI/LFM2.5-24B-A2B-GGUF/resolve/0912d33141f77e10705345a6732bfd83f0252fdc/LFM2.5-24B-A2B-Q6_K.gguf) | 19.689.405.728 | 19,69 / 18,34 | 32 GB con margen limitado; 48 GB más cómodos | 24 GB |
| [LFM2.5-24B-A2B-Q8_0.gguf](https://huggingface.co/LiquidAI/LFM2.5-24B-A2B-GGUF/resolve/0912d33141f77e10705345a6732bfd83f0252fdc/LFM2.5-24B-A2B-Q8_0.gguf) | 25.493.732.640 | 25,49 / 23,74 | 48–64 GB | 32 GB o más |

GB usa 1.000.000.000 bytes; GiB usa 1.073.741.824 bytes. Los tamaños son los de los archivos. Las cifras de RAM y VRAM son **orientaciones para empezar con 4096 tokens**, no garantías de que una configuración vaya a caber. Además de los pesos, hacen falta memoria para el contexto, buffers de cálculo, Windows y otras aplicaciones. Ampliar el contexto aumenta el consumo.

Una GPU de 8 o 12 GB no puede almacenar íntegramente ni siquiera los 13,53 GiB de pesos de Q4_K_M. Aun así, puede ayudar utilizando parte de los pesos en RAM. La RAM y la VRAM son memorias distintas: sumar sus capacidades no garantiza que el reparto quepa o funcione bien.

Si dudas, empieza con **Q4_K_M**. Q5_K_M y Q6_K son alternativas cuando tienes más memoria. Q8_0 ocupa bastante más; no hace falta para seguir esta guía.

## 3. Antes de empezar

- Windows 10 u 11 de 64 bits, en un PC Intel o AMD de arquitectura x64. Los paquetes de esta guía no son para Windows ARM.
- PowerShell 5.1, incluido en Windows. No hace falta abrirlo como administrador.
- Conexión a Internet para la descarga. Después puedes conversar con el modelo sin Internet.
- Una CPU moderna. Si aparece un error de instrucciones de CPU, necesitarás otra compilación adecuada para tu procesador.
- Para Q4_K_M, reserva unos 20 GB libres de disco; para Q8_0, unos 30 GB. Necesitarás más si descargas varias versiones.
- Para GPU: controladores compatibles con CUDA o Vulkan, según la opción elegida abajo.

Si Windows indica que falta `VCRUNTIME140.dll` o `MSVCP140.dll`, instala el [Microsoft Visual C++ Redistributable x64 oficial](https://learn.microsoft.com/en-us/cpp/windows/latest-supported-vc-redist). No descargues DLL sueltas de otras páginas.

## 4. Descarga esta guía y abre PowerShell

1. En GitHub, pulsa el botón verde **Code** y después **Download ZIP**.
2. Extrae el ZIP en una carpeta que puedas localizar fácilmente, por ejemplo dentro de Documentos. No ejecutes los archivos desde el ZIP.
3. Abre la carpeta extraída. Debes ver `README.md`, `instalar.ps1`, `descargar.ps1`, `iniciar.ps1`, `utilidades.ps1` y `catalogo.json`.
4. Haz clic en la barra de direcciones del Explorador, escribe `powershell` y pulsa Enter. Se abrirá PowerShell en esa carpeta.

Copia los comandos de los siguientes pasos en esa ventana. Pulsa Enter después de cada bloque. Las descargas y llama.cpp se guardarán dentro de `local`, junto a la guía; los scripts no cambian otras instalaciones.

## 5. Instala llama.cpp: elige una opción

La guía fija **llama.cpp b11617** y comprueba los ZIP con SHA256 antes de extraerlos. No mezcles ejecutables y DLL de versiones diferentes. Los paquetes CUDA incluyen también la descarga de sus bibliotecas de ejecución; no necesitas instalar el CUDA Toolkit para utilizar estos binarios.

### Opción A: CPU, sin utilizar la tarjeta gráfica

Es la opción más sencilla si no sabes qué GPU tienes:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\instalar.ps1 -Backend cpu
```

### Opción B: GPU NVIDIA con CUDA 12.4

Utiliza un controlador NVIDIA actualizado y compatible con tu tarjeta. Es una alternativa para tarjetas admitidas por CUDA 12.4. Las generaciones de GPU posteriores a ese Toolkit pueden necesitar CUDA 13.4.

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\instalar.ps1 -Backend cuda12
```

### Opción C: GPU NVIDIA reciente con CUDA 13.4

Necesita una GPU admitida por CUDA 13 y un controlador reciente compatible. CUDA 13 deja de admitir algunas arquitecturas antiguas. Si tu tarjeta no es compatible, utiliza CUDA 12.4, Vulkan o CPU.

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\instalar.ps1 -Backend cuda13
```

### Opción D: GPU AMD, Intel o NVIDIA con Vulkan

Necesita un controlador gráfico con Vulkan y las funciones requeridas por llama.cpp. La compatibilidad y el rendimiento dependen de la tarjeta.

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\instalar.ps1 -Backend vulkan
```

`-ExecutionPolicy Bypass` se aplica solamente al proceso que ejecuta ese comando. No cambia permanentemente la política de Windows. Los scripts conservan los ZIP y no sobrescriben una instalación incompleta: si encuentran una, te pedirán utilizar otra carpeta.

## 6. Descarga el modelo: elige solo uno

Para empezar con Q4_K_M:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\descargar.ps1 -Cuantizacion Q4_K_M
```

Si prefieres otra versión, utiliza **uno** de estos comandos:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\descargar.ps1 -Cuantizacion Q5_K_M
```

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\descargar.ps1 -Cuantizacion Q6_K
```

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\descargar.ps1 -Cuantizacion Q8_0
```

La descarga utiliza `curl.exe`, sigue las redirecciones de Hugging Face y reintenta los fallos. Si se corta, **repite el mismo comando**: continúa el archivo `.part`. Al terminar, compara el tamaño y el SHA256 oficial y solo entonces lo convierte en el archivo definitivo. Comprobar un modelo grande puede tardar varios minutos. Espera a que aparezca **Modelo listo**.

Si ya tienes el archivo correcto, volver a ejecutar el comando lo comprueba sin descargarlo otra vez. Si encuentra un archivo distinto, se detiene y lo conserva.

## 7. Arranca el modelo

Los ejemplos usan Q4_K_M. Si descargaste otra versión, cambia `Q4_K_M` por `Q5_K_M`, `Q6_K` o `Q8_0` en el comando de arranque.

### Con CPU

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\iniciar.ps1 -Backend cpu -Cuantizacion Q4_K_M -Modo CPU
```

### Con GPU y reparto automático entre VRAM y RAM

Ejecuta el comando que corresponda a la opción que instalaste:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\iniciar.ps1 -Backend cuda12 -Cuantizacion Q4_K_M -Modo Auto
```

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\iniciar.ps1 -Backend cuda13 -Cuantizacion Q4_K_M -Modo Auto
```

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\iniciar.ps1 -Backend vulkan -Cuantizacion Q4_K_M -Modo Auto
```

Este modo deja que llama.cpp ajuste cuántas capas coloca en la GPU mediante `--fit on`. Puede dejar parte del modelo en RAM. No garantiza que todo quepa en VRAM, ni evita todos los errores de memoria. Mira en la consola las capas descargadas a GPU y los buffers de CPU/GPU; tener una GPU detectada no significa que todo el modelo esté en ella.

### Si tienes poca VRAM: expertos en RAM

Esta opción conserva los expertos MoE en la RAM mediante `--cpu-moe` y permite usar la GPU para otras partes. Necesitas RAM suficiente y puede ser más lenta que cargar todo en GPU. El reparto automático sigue necesitando margen para buffers y contexto.

Ejemplo con CUDA 13.4:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\iniciar.ps1 -Backend cuda13 -Cuantizacion Q4_K_M -Modo ExpertosRAM
```

Con CUDA 12.4 o Vulkan, cambia `cuda13` por `cuda12` o `vulkan`.

### Si tienes varias GPU

llama.cpp puede detectar y utilizar varias. Para elegir una, primero consulta sus nombres. Por ejemplo, con CUDA 13.4:

```powershell
.\local\llama-b11617-cuda13\llama-server.exe --list-devices
```

Si la lista muestra `CUDA0` y quieres utilizar esa tarjeta:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\iniciar.ps1 -Backend cuda13 -Cuantizacion Q4_K_M -Modo Auto -Dispositivo CUDA0
```

Usa el nombre que aparezca en tu equipo. Con otro backend, cambia también la carpeta y `-Backend`. No deduzcas el orden de las GPU por el nombre comercial.

## 8. Abre la interfaz web

1. Deja abierta la ventana del servidor. La primera carga puede tardar.
2. Espera a que la consola indique que el servidor está escuchando y que el modelo ha terminado de cargar.
3. Abre [http://127.0.0.1:18082](http://127.0.0.1:18082) en tu navegador.
4. Crea una conversación y escribe: **Explica en español qué es una mezcla de expertos en tres frases.**
5. Espera la respuesta. Este modelo razona antes de responder, por lo que puede generar razonamiento antes de la respuesta final.

Se utiliza la plantilla de conversación incluida en el GGUF con `--jinja`. Los valores de generación del servidor son los recomendados por Liquid AI: temperatura `0.1`, top-k `50` y penalización de repetición `1.05`. Si la interfaz web envía sus propios valores, configura esos mismos números allí.

El contexto inicial es de **4096 tokens**, compartido entre tus mensajes, el razonamiento y la respuesta. Aunque la ficha admite hasta 131.072 tokens, utilizar ese máximo exige mucha más memoria y no es el punto de partida de esta guía.

La interfaz web permite conversar; no instala un agente, herramientas ni búsquedas en Internet. La comparativa agéntica con Qwen 3.6 queda para otro vídeo. **Todavía no se ha realizado esa comparativa.**

Para detener el servidor, vuelve a su ventana y pulsa **Ctrl+C**. Para utilizarlo otro día, repite únicamente el comando de arranque del paso 7.

## 9. Comprueba que funciona

Abre una segunda ventana de PowerShell y ejecuta:

```powershell
Invoke-RestMethod -Uri 'http://127.0.0.1:18082/health'
```

Cuando el modelo esté listo, debe mostrar `status: ok`. Durante la carga puede devolver un error 503: espera y repite.

Para comprobar también que genera una respuesta:

```powershell
$peticion = @{
    messages = @(@{ role = 'user'; content = 'Responde en español: ¿cuánto es 2 + 2?' })
    temperature = 0.1
    top_k = 50
    repeat_penalty = 1.05
    max_tokens = 512
    stream = $false
} | ConvertTo-Json -Depth 5
$respuesta = Invoke-RestMethod -Uri 'http://127.0.0.1:18082/v1/chat/completions' -Method Post -ContentType 'application/json; charset=utf-8' -Body ([System.Text.Encoding]::UTF8.GetBytes($peticion)) -TimeoutSec 300
$respuesta.choices[0].message | Format-List
```

Deberías recibir texto relacionado con la pregunta. Puede aparecer en `content` y también en un campo de razonamiento. Si llega al límite de 512 tokens sin terminar, repite con `max_tokens = 1024`. Esta comprobación confirma que responde; no mide su velocidad ni su calidad en tareas agénticas.

## Problemas habituales

**No hay memoria suficiente.** Detén el servidor, cierra aplicaciones y empieza con Q4_K_M y 4096 tokens. Prueba `ExpertosRAM` o CPU si el problema es la VRAM. Si falta RAM, cambiar de backend no aumenta la memoria del equipo. No fuerces Q8_0 en una máquina con poco margen.

**La GPU no aparece o hay un error CUDA/Vulkan.** Consulta `--list-devices` en la carpeta del backend elegido. Revisa el controlador y la compatibilidad de la tarjeta. Puedes utilizar la opción CPU mientras lo resuelves. No copies DLL de otra versión ni de una instalación antigua.

**El puerto está ocupado.** Arranca con otro, por ejemplo:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\iniciar.ps1 -Backend cpu -Cuantizacion Q4_K_M -Modo CPU -Puerto 18083
```

Abre entonces `http://127.0.0.1:18083` y cambia el puerto también en las comprobaciones. El servidor escucha solo en tu propio PC (`127.0.0.1`).

**Quiero guardar todo en otro disco.** Utiliza la misma carpeta en los tres pasos. Ejemplo completo:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\instalar.ps1 -Backend cpu -Carpeta 'D:\LFM25'
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\descargar.ps1 -Cuantizacion Q4_K_M -Carpeta 'D:\LFM25'
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\iniciar.ps1 -Backend cpu -Cuantizacion Q4_K_M -Modo CPU -Carpeta 'D:\LFM25'
```

Elige una ruta en un disco que exista en tu equipo. Los scripts no borran archivos. Si hay un archivo incorrecto o una instalación incompleta, puedes elegir una carpeta nueva con `-Carpeta`.

## Enlaces oficiales

- [Ficha del modelo: arquitectura, idiomas y parámetros de generación](https://huggingface.co/LiquidAI/LFM2.5-24B-A2B).
- [Archivos GGUF de la revisión utilizada](https://huggingface.co/LiquidAI/LFM2.5-24B-A2B-GGUF/tree/0912d33141f77e10705345a6732bfd83f0252fdc). `catalogo.json` contiene sus tamaños, SHA256 y enlaces de descarga.
- [llama.cpp b11617: paquetes oficiales](https://github.com/ggml-org/llama.cpp/releases/tag/b11617).
- [Documentación del servidor de esa versión](https://github.com/ggml-org/llama.cpp/blob/b11617/tools/server/README.md).
- [Compilación y compatibilidad de backends](https://github.com/ggml-org/llama.cpp/blob/b11617/docs/build.md).
- [Compatibilidad de CUDA y controladores NVIDIA](https://docs.nvidia.com/deploy/cuda-compatibility/).
- [Licencia del modelo](https://huggingface.co/LiquidAI/LFM2.5-24B-A2B-GGUF/blob/0912d33141f77e10705345a6732bfd83f0252fdc/LICENSE). Los pesos se descargan de Liquid AI y conservan su licencia; este repositorio no los redistribuye.
