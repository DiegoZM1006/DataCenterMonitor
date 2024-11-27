# app.ps1

function Get-ProcessTable {
    $processes = Get-Process | Where-Object { $_.Responding } | Select-Object Id, ProcessName, CPU, WorkingSet
    $html = "<table><tr><th>PID</th><th>Nombre</th><th>CPU</th><th>Memoria</th><th>Accion</th></tr>"

    foreach ($process in $processes) {
        $html += "<tr><td>$($process.Id)</td><td>$($process.ProcessName)</td><td>$($process.CPU)</td><td>$([math]::round($process.WorkingSet / 1KB, 2))</td>"
        $html += "<td><button class='terminate-btn' onclick='terminateProcess($($process.Id))'>Terminar</button></td></tr>"
    }

    $html += "</table>"

    # Usar Write-Output para enviar el resultado a la salida estándar
    Write-Output $html
}

function Stop-ProcessById {
    param (
        [Parameter(Mandatory=$true)]
        [ValidateRange(1, [int]::MaxValue)]
        [int]$ProcessId
    )

    try {
        $process = Get-Process -Id $ProcessId -ErrorAction Stop
        
        # Verificación adicional de seguridad
        if ($process.ProcessName -in @("System", "Idle", "svchost", "lsass")) {
            throw "No se permite terminar procesos críticos del sistema"
        }

        Stop-Process -Id $ProcessId -Force -ErrorAction Stop
        Write-Output "Proceso $ProcessId terminado exitosamente"
        return $true
    }
    catch {
        Write-Error "Error al terminar el proceso $ProcessId : $_"
        throw
    }
}

# Export-ModuleMember -Function Get-ProcessTable, Stop-ProcessById
