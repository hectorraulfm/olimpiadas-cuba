# Servidor estático mínimo para probar la web en local (Windows, sin instalar nada).
#   .\dev-server.ps1
# Luego abre http://localhost:8765
#
# Hace falta porque los módulos ES no funcionan abriendo el HTML con doble clic
# (protocolo file://). Si tienes Python, `python -m http.server 8000` vale igual.

param([int]$Port = 8765)

$root = $PSScriptRoot
$listener = New-Object System.Net.HttpListener
$listener.Prefixes.Add("http://localhost:$Port/")
$listener.Start()
Write-Host "Sirviendo $root en http://localhost:$Port/  (Ctrl+C para parar)"

$mime = @{
  ".html" = "text/html"; ".css" = "text/css"; ".js" = "text/javascript"
  ".json" = "application/json"; ".svg" = "image/svg+xml"
  ".sql" = "text/plain"; ".md" = "text/plain"; ".ico" = "image/x-icon"
}

try {
  while ($listener.IsListening) {
    $ctx = $listener.GetContext()
    $path = [System.Uri]::UnescapeDataString($ctx.Request.Url.AbsolutePath)
    if ($path -eq "/") { $path = "/index.html" }
    $file = Join-Path $root ((($path -replace '^/', '') -replace '/', '\'))

    if (Test-Path $file -PathType Leaf) {
      $bytes = [System.IO.File]::ReadAllBytes($file)
      $ext = [System.IO.Path]::GetExtension($file).ToLower()
      $ct = $mime[$ext]
      if (-not $ct) { $ct = "application/octet-stream" }
      $ctx.Response.ContentType = "$ct; charset=utf-8"
      $ctx.Response.Headers.Add("Cache-Control", "no-store")
      $ctx.Response.OutputStream.Write($bytes, 0, $bytes.Length)
    }
    else {
      $ctx.Response.StatusCode = 404
      $b = [Text.Encoding]::UTF8.GetBytes("404 Not Found: $path")
      $ctx.Response.OutputStream.Write($b, 0, $b.Length)
    }
    $ctx.Response.Close()
  }
}
finally {
  $listener.Stop()
}
