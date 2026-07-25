---@diagnostic disable: undefined-global, lowercase-global
pos = {x = 1, y = 1, z = 1}
posBau = {x = 1, y = 1, z = 1}

NORTE = 1
LESTE = 2
SUL = 3
OESTE = 4

CIMA = 1
FRENTE = 2
BAIXO = 3
TRAS = 4

direcao = NORTE

size = {x = 3, y = 3, z = 3} -- padrão

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

function interfaceEmTexto()
    print("=== Configuracao da Mineracao ===")

    io.write("Largura (eixo X): ")
    local x = tonumber(read())
    io.write("Altura (eixo Y): ")
    local y = tonumber(read())
    io.write("Profundidade (eixo Z): ")
    local z = tonumber(read())

    if not x or not y or not z or x < 1 or y < 1 or z < 1 then
        print("Valores invalidos! Usando tamanho padrao (3x3x3).")
    else
        size = {x = x, y = y, z = z}
    end

    local totalBlocos = size.x * size.y * size.z
    local combustivelAtual = turtle.getFuelLevel()
    local combustivelEstimado = totalBlocos

    print("")
    print("=== Informacoes da Mineracao ===")
    print(("Tamanho: %dx%dx%d (X x Y x Z)"):format(size.x, size.y, size.z))
    print(("Total de blocos a minerar: %d"):format(totalBlocos))

    if combustivelAtual == "unlimited" then
        print("Combustivel atual: ilimitado")
        print("Combustivel suficiente: SIM")
    else
        print(("Combustivel atual: %d"):format(combustivelAtual))
        print(("Combustivel necessario (estimado): %d"):format(combustivelEstimado))
        if combustivelAtual >= combustivelEstimado then
            print("Combustivel suficiente: SIM")
        else
            print(("Combustivel suficiente: NAO (faltam aprox. %d)"):format(combustivelEstimado - combustivelAtual))
        end
    end

    print("")
    io.write("Deseja iniciar a mineracao? (s/n): ")
    local resposta = read()

    if resposta ~= "s" and resposta ~= "S" then
        print("Mineracao cancelada pelo usuario.")
        return false
    end

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

function main()
    if not interfaceEmTexto() then
        return
    end

    for iy = 1, size.y, 1 do
        if iy % 2 ~= 0 then
            for iz = 1, size.z, 1 do
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

    local totalDepositado = depositarItens()

    print("")
    print("=== Mineracao Concluida ===")
    print(("Tamanho minerado: %dx%dx%d"):format(size.x, size.y, size.z))
    print(("Total de blocos percorridos: %d"):format(size.x * size.y * size.z))
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
