---@diagnostic disable: undefined-global, lowercase-global

local PROTOCOLO_REGISTRO = "mineracao_registro"
local PROTOCOLO_CONFIG   = "mineracao_config"
local PROTOCOLO_INICIO   = "mineracao_inicio"
local LADO_MODEM = "back" -- ajuste para o lado onde o modem esta instalado

rednet.open(LADO_MODEM)

print("=== Servidor de Mineracao ===")
io.write("Largura (eixo X): ")
local x = tonumber(read())
io.write("Altura (eixo Y): ")
local y = tonumber(read())
io.write("Profundidade (eixo Z): ")
local z = tonumber(read())

io.write("Tipo (H/V): ")
local tipoResp = read()
local tipo = (tipoResp == "v" or tipoResp == "V") and "VERTICAL" or "HORIZONTAL"

io.write("Quantas turtles vao participar? ")
local numTurtles = tonumber(read())

print("Aguardando turtles se registrarem... (" .. numTurtles .. " esperadas)")

local turtlesConectadas = {}
while #turtlesConectadas < numTurtles do
    local id, msg = rednet.receive(PROTOCOLO_REGISTRO, 30)
    if id and msg == "pronto" then
        table.insert(turtlesConectadas, id)
        print("Turtle " .. id .. " conectada (" .. #turtlesConectadas .. "/" .. numTurtles .. ")")
    else
        print("Timeout esperando turtles. Conectadas: " .. #turtlesConectadas)
        break
    end
end

if #turtlesConectadas == 0 then
    print("Nenhuma turtle conectada. Abortando.")
    return
end

-- Envia configuração individual (com offset em X para não colidirem)
for i, id in ipairs(turtlesConectadas) do
    local config = {
        size = {x = x, y = y, z = z},
        tipoEscavacao = tipo
    }
    rednet.send(id, config, PROTOCOLO_CONFIG)
end

print("Configuracao enviada para " .. #turtlesConectadas .. " turtle(s).")
print("Iniciando em 3 segundos...")
sleep(3)

rednet.broadcast("iniciar", PROTOCOLO_INICIO)
print("Comando de inicio enviado para todas as turtles!")