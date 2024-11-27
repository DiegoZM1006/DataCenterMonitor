#!/bin/bash

# Función para listar procesos en formato JSON
get_process_table() {
    ps -eo pid,comm,%mem,%cpu --sort=-%mem | awk 'NR==1{print "["} NR>1{printf "%s{\"pid\":\"%s\",\"name\":\"%s\",\"mem\":\"%s\",\"cpu\":\"%s\"}", sep, $1, $2, $3, $4; sep=",\n"} END{print "\n]"}'
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
