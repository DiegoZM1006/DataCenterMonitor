#!/bin/bash

# Función para listar procesos en formato HTML que están en estado "Running"
get_process_table() {
    echo "<table><tr><th>PID</th><th>Nombre</th><th>% Memoria</th><th>% CPU</th><th>Acción</th></tr>"
    
    # Usamos "comm" para obtener únicamente el nombre del ejecutable
    ps -eo pid,comm,%mem,%cpu --no-headers --sort=-%mem | awk '{
        mem=$3; cpu=$4; pid=$1; 
        if (mem ~ /^[0-9]/ && cpu ~ /^[0-9]/) {
            printf "<tr><td>%s</td><td>%s</td><td>%s</td><td>%s</td><td><button class=\"terminate-btn\" onclick=\"terminateProcess(%s)\">Terminar</button></td></tr>\n", pid, $2, mem, cpu, pid
        }
    }'
    echo "</table>"
}


# Función para terminar un proceso por su ID
terminate_process() {
    local pid=$1
    if kill -9 "$pid" 2>/dev/null; then
        echo '{"success":true}'
    else
        echo '{"success":false, "error":"No se pudo terminar el proceso"}'
    fi
}

# Invocar la función correspondiente basada en el argumento
if [[ $# -gt 0 ]]; then
    "$@"
else
    echo "Uso: $0 {get_process_table|terminate_process <pid>}"
fi
