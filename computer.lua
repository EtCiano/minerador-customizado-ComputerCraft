---@diagnostic disable: undefined-global, lowercase-global

rednet.open("right") -- ajuste o lado onde está o modem

local PROTOCOLO = "mineracao"

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
    local id, msg = rednet.receive(PROTOCOLO, 30)
    if id and msg == "pronto" then
        table.insert(turtlesConectadas, id)
        print("Turtle " .. id .. " conectada (" .. #turtlesConectadas .. "/" .. numTurtles .. ")")
    else
        print("Timeout esperando turtles. Conectadas: " .. #turtlesConectadas)
        break
    end
end

-- Envia configuração individual (com offset em X para não colidirem)
for i, id in ipairs(turtlesConectadas) do
    local config = {
        size = {x = x, y = y, z = z},
        tipoEscavacao = tipo,
        offsetX = (i - 1) * (x + 2) -- espaça cada turtle lado a lado
    }
    rednet.send(id, config, PROTOCOLO)
end

print("Configuracao enviada. Iniciando em 3 segundos...")
sleep(3)

-- Sinal de início simultâneo
rednet.broadcast("iniciar", PROTOCOLO)
print("Comando de inicio enviado para todas as turtles!")