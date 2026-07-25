---@diagnostic disable: undefined-global, lowercase-global

-- ===== CONFIGURACAO DE REDE =====
local PROTOCOLO_REGISTRO = "mineracao_registro"
local PROTOCOLO_CONFIG   = "mineracao_config"
local PROTOCOLO_INICIO   = "mineracao_inicio"
local LADO_MODEM = "right" -- ajuste para o lado onde o modem esta instalado

pos = {x = 1, y = 1, z = 1}
posBau = {x = 1, y = 1, z = 1}
LIMITE_COMBUSTIVEL = 1000

NORTE = 1
LESTE = 2
SUL = 3
OESTE = 4

CIMA = 1
FRENTE = 2
BAIXO = 3
TRAS = 4

HORIZONTAL = 1
VERTICAL = 2

direcao = NORTE

size = {x = 3, y = 3, z = 3} -- padrão
tipoEscavacao = HORIZONTAL -- padrão

function girar(alvoDirecao)
    while direcao ~= alvoDirecao do
        local diff = alvoDirecao - direcao
        if diff == 1 or diff == -3 then
            turtle.turnRight()
            direcao = direcao + 1
            if direcao > 4 then
                direcao = 1
            end
        else
            turtle.turnLeft()
            direcao = direcao - 1
            if direcao <= 0 then
                direcao = 4
            end
        end
    end
end

function informarCoordenadas()
    print('minerei ', pos.x, pos.y, pos.z)
end

function andar(sentido)
    if sentido == CIMA then
        turtle.digUp()
        turtle.up()
        pos.y = pos.y + 1
        informarCoordenadas()

    elseif sentido == FRENTE then
        turtle.dig()
        turtle.forward()
        if direcao == NORTE then
            pos.z = pos.z + 1
        elseif direcao == LESTE then
            pos.x = pos.x + 1
        elseif direcao == SUL then
            pos.z = pos.z - 1
        elseif direcao == OESTE then
            pos.x = pos.x - 1
        end
        informarCoordenadas()

    elseif sentido == BAIXO then
        turtle.digDown()
        turtle.down()
        pos.y = pos.y - 1
        informarCoordenadas()

    elseif sentido == TRAS then
        turtle.back()
        if direcao == NORTE then
            pos.z = pos.z - 1
        elseif direcao == LESTE then
            pos.x = pos.x - 1
        elseif direcao == SUL then
            pos.z = pos.z + 1
        elseif direcao == OESTE then
            pos.x = pos.x + 1
        end
        informarCoordenadas()
    end
end

-- ===== INTERFACE VIA REDE =====
function interfaceEmTexto()
    if not rednet.isOpen(LADO_MODEM) then
        rednet.open(LADO_MODEM)
    end

    print("=== Aguardando servidor de mineracao ===")
    rednet.broadcast("pronto", PROTOCOLO_REGISTRO)
    print("Sinal 'pronto' enviado. Aguardando configuracao...")

    local idServidor, config = rednet.receive(PROTOCOLO_CONFIG)

    if not config or not config.size then
        print("Configuracao invalida recebida. Abortando.")
        return false
    end

    size = config.size
    tipoEscavacao = (config.tipoEscavacao == "VERTICAL") and VERTICAL or HORIZONTAL
    -- (remova completamente o if config.offsetX então ... end)

    -- aplica offset para essa turtle nao colidir com as outras
    if config.offsetX then
        pos.x = pos.x + config.offsetX
        posBau.x = posBau.x + config.offsetX
    end

    local totalBlocos = size.x * size.y * size.z
    local combustivelAtual = turtle.getFuelLevel()

    print("")
    print("=== Configuracao Recebida ===")
    print(("Tamanho: %dx%dx%d (X x Y x Z)"):format(size.x, size.y, size.z))
    print(("Total de blocos a minerar: %d"):format(totalBlocos))
    print(("Tipo de escavacao: %s"):format(tipoEscavacao == HORIZONTAL and "Horizontal" or "Vertical"))

    if combustivelAtual == "unlimited" then
        print("Combustivel atual: ilimitado")
    else
        print(("Combustivel atual: %d"):format(combustivelAtual))
        if combustivelAtual < totalBlocos then
            print(("AVISO: combustivel pode nao ser suficiente (faltam aprox. %d)"):format(totalBlocos - combustivelAtual))
        end
    end

    print("")
    print("Aguardando sinal de inicio do servidor...")

    -- Só aceita o sinal se vier especificamente do servidor que enviou a config
    local sinal
    repeat
        local idRemetente
        idRemetente, sinal = rednet.receive(PROTOCOLO_INICIO)
    until idRemetente == idServidor

    if sinal ~= "iniciar" then
        print("Sinal invalido recebido. Abortando.")
        return false
    end

    print("Sinal recebido! Iniciando mineracao...")
    return true
end

function movimentacaoSecundaria(alvo)
    if pos.x < alvo.x then
        girar(LESTE)
    elseif pos.x > alvo.x then
        girar(OESTE)
    end
    while pos.x ~= alvo.x do
        andar(FRENTE)
    end

    if pos.z < alvo.z then
        girar(NORTE)
    elseif pos.z > alvo.z then
        girar(SUL)
    end
    while pos.z ~= alvo.z do
        andar(FRENTE)
    end

    if pos.y < alvo.y then
        while pos.y < alvo.y do
            andar(CIMA)
        end
    elseif pos.y > alvo.y then
        while pos.y > alvo.y do
            andar(BAIXO)
        end
    end
end

function depositarItens()
    movimentacaoSecundaria(posBau)
    girar(NORTE)

    local itensDepositados = 0
    for slot = 1, 16 do
        local detalhe = turtle.getItemDetail(slot)
        if detalhe then
            turtle.select(slot)
            local quantidade = turtle.getItemCount(slot)
            if turtle.drop() then
                itensDepositados = itensDepositados + quantidade
            end
        end
    end
    turtle.select(1)

    return itensDepositados
end

function verificarEAbastecer()
    local nivelAtual = turtle.getFuelLevel()

    if nivelAtual == "unlimited" then return end

    if nivelAtual < LIMITE_COMBUSTIVEL then
        print("Combustível baixo (" .. nivelAtual .. "). Procurando combustível...")

        for slot = 1, 16 do
            turtle.select(slot)
            if turtle.refuel(0) then
                turtle.refuel()
            end

            if turtle.getFuelLevel() >= LIMITE_COMBUSTIVEL then
                break
            end
        end

        print("Novo nível de combustível: " .. turtle.getFuelLevel())
    end
end

-- Camadas horizontais: fixa Y, varre X/Z, sobe de camada em camada
function mineracaoHorizontal()
    for iy = 1, size.y, 1 do
        if iy % 2 ~= 0 then
            for iz = 1, size.z, 1 do
                verificarEAbastecer()
                if iz % 2 == 0 then
                    movimentacaoSecundaria({x = size.x, y = iy, z = iz})
                else
                    movimentacaoSecundaria({x = 1, y = iy, z = iz})
                end
            end
            if size.z % 2 == 0 then
                movimentacaoSecundaria{x = 1, y = iy, z = size.z}
            else
                movimentacaoSecundaria{x = size.x, y = iy, z = size.z}
            end
        else
            for iz = size.z, 1, -1 do
                verificarEAbastecer()
                if iz % 2 == 0 then
                    movimentacaoSecundaria({x = 1, y = iy, z = iz})
                else
                    movimentacaoSecundaria({x = size.x, y = iy, z = iz})
                end
            end
            if size.z % 2 == 0 then
                movimentacaoSecundaria{x = size.x, y = iy, z = 1}
            else
                movimentacaoSecundaria{x = 1, y = iy, z = 1}
            end
        end
    end
end

-- Camadas verticais: fixa Z, varre X/Y, avança de camada em camada
function mineracaoVertical()
    for iz = 1, size.z, 1 do
        if iz % 2 ~= 0 then
            for iy = 1, size.y, 1 do
                verificarEAbastecer()
                if iy % 2 == 0 then
                    movimentacaoSecundaria({x = size.x, y = iy, z = iz})
                else
                    movimentacaoSecundaria({x = 1, y = iy, z = iz})
                end
            end
            if size.y % 2 == 0 then
                movimentacaoSecundaria{x = 1, y = size.y, z = iz}
            else
                movimentacaoSecundaria{x = size.x, y = size.y, z = iz}
            end
        else
            for iy = size.y, 1, -1 do
                verificarEAbastecer()
                if iy % 2 == 0 then
                    movimentacaoSecundaria({x = 1, y = iy, z = iz})
                else
                    movimentacaoSecundaria({x = size.x, y = iy, z = iz})
                end
            end
            if size.y % 2 == 0 then
                movimentacaoSecundaria{x = size.x, y = 1, z = iz}
            else
                movimentacaoSecundaria{x = 1, y = 1, z = iz}
            end
        end
    end
end

function main()
    if not interfaceEmTexto() then
        return
    end

    if tipoEscavacao == HORIZONTAL then
        mineracaoHorizontal()
    else
        mineracaoVertical()
    end

    local totalDepositado = depositarItens()

    print("")
    print("=== Mineracao Concluida ===")
    print(("Tamanho minerado: %dx%dx%d"):format(size.x, size.y, size.z))
    print(("Total de blocos percorridos: %d"):format(size.x * size.y * size.z))
    print(("Tipo de escavacao: %s"):format(tipoEscavacao == HORIZONTAL and "Horizontal" or "Vertical"))
    print(("Itens depositados no bau: %d"):format(totalDepositado))

    local combustivelFinal = turtle.getFuelLevel()
    if combustivelFinal == "unlimited" then
        print("Combustivel restante: ilimitado")
    else
        print(("Combustivel restante: %d"):format(combustivelFinal))
    end

    print(("Posicao final: x=%d, y=%d, z=%d"):format(pos.x, pos.y, pos.z))
end

main()