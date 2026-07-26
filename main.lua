---@diagnostic disable: undefined-global, lowercase-global
pos = {x = 1, y = 1, z = 1}

-- Variáveis globais diretas para as direções

--        1       
--        |       
--   4----+----2 
--        |       
--        3       

NORTE = 1
LESTE = 2
SUL = 3
OESTE = 4

-- Variáveis globais diretas para os sentidos

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

function andar(sentido)
    if sentido == CIMA then
        turtle.up()
        pos.y = pos.y + 1

    elseif sentido == FRENTE then
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

    elseif sentido == BAIXO then
        turtle.down()
        pos.y = pos.y - 1

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
    end
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

function main()
    for iy = 1, size.y, 1 do
        movimentacaoSecundaria({x = 1, y = iy, z = 1})
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
    end
end