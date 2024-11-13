# web_interface.ps1
Import-Module .\app.ps1
Add-Type -AssemblyName System.Web

$listener = New-Object System.Net.HttpListener
$listener.Prefixes.Add("http://localhost:8080/")

try {
    $listener.Start()
    Write-Output "Servidor web iniciado en http://localhost:8080/"

    while ($listener.IsListening) {
        try {
            $context = $listener.GetContext()
            $request = $context.Request
            $response = $context.Response
            $buffer = $null

            # Ruta para la página principal
            if ($request.Url.AbsolutePath -eq "/") {
                try {
                    $html = Get-Content -Path ".\static\index.html" -Raw
                    $html = $html -replace "{{processTable}}", (Get-ProcessTable)
                    $buffer = [System.Text.Encoding]::UTF8.GetBytes($html)
                }
                catch {
                    Write-Error "Error al cargar la página principal: $_"
                    $buffer = [System.Text.Encoding]::UTF8.GetBytes("<html><body><h1>Error interno del servidor</h1></body></html>")
                }
            }
            # Ruta para terminar un proceso
            elseif ($request.Url.AbsolutePath -eq "/terminate") {
                try {
                    $processIdStr = $request.QueryString["pid"]

                    if ([int]::TryParse($processIdStr, [ref]$null)) {
                        $processIdToKill = [System.Int32]::Parse($processIdStr)
                        
                        # Validación adicional del ProcessId
                        if ($processIdToKill -gt 0) {
                            try {
                                Terminate-ProcessById -ProcessId $processIdToKill
                                $buffer = [System.Text.Encoding]::UTF8.GetBytes('{"success":true}')
                                $response.ContentType = "application/json"
                            }
                            catch {
                                $errorMessage = "Error al terminar el proceso: $_"
                                Write-Error $errorMessage
                                $buffer = [System.Text.Encoding]::UTF8.GetBytes(
                                    "{`"success`":false,`"error`":`"$($errorMessage -replace '"', '\"')`"}")
                                $response.ContentType = "application/json"
                            }
                        }
                        else {
                            $buffer = [System.Text.Encoding]::UTF8.GetBytes('{"success":false,"error":"ProcessId inválido"}')
                            $response.ContentType = "application/json"
                        }
                    }
                    else {
                        $buffer = [System.Text.Encoding]::UTF8.GetBytes('{"success":false,"error":"ProcessId debe ser un número"}')
                        $response.ContentType = "application/json"
                    }
                }
                catch {
                    Write-Error "Error en el endpoint terminate: $_"
                    $buffer = [System.Text.Encoding]::UTF8.GetBytes('{"success":false,"error":"Error interno del servidor"}')
                    $response.ContentType = "application/json"
                }
            }
            else {
                # Ruta no encontrada
                $response.StatusCode = 404
                $buffer = [System.Text.Encoding]::UTF8.GetBytes("<html><body><h1>404 - No encontrado</h1></body></html>")
            }

            # Enviar respuesta
            $response.ContentLength64 = $buffer.Length
            $response.OutputStream.Write($buffer, 0, $buffer.Length)
        }
        catch {
            Write-Error "Error en el ciclo principal: $_"
        }
        finally {
            if ($response) {
                $response.OutputStream.Close()
            }
        }
    }
}
catch {
    Write-Error "Error fatal en el servidor: $_"
}
finally {
    $listener.Stop()
    Write-Output "Servidor detenido"
}