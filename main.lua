-- ============================================================
--  Mining Turtle - Área configurável via input
--  Posição inicial: canto inferior esquerdo, camada 1 (Y mais baixo)
--  A tartaruga deve estar virada para +X (frente = direção das fileiras)
-- ============================================================

-- ============================================================
--  Input interativo
-- ============================================================

local function lerNumero(prompt, minimo, maximo)
    while true do
        io.write(prompt)
        local entrada = io.read()
        local numero = tonumber(entrada)
        if numero == nil then
            print("  [!] Digite um numero valido.")
        elseif numero < minimo or numero > maximo then
            print("  [!] Valor deve ser entre " .. minimo .. " e " .. maximo .. ".")
        else
            return math.floor(numero)
        end
    end
end

local function confirmar(prompt)
    while true do
        io.write(prompt .. " (s/n): ")
        local entrada = io.read():lower()
        if entrada == "s" then return true
        elseif entrada == "n" then return false
        else print("  [!] Digite 's' para sim ou 'n' para nao.") end
    end
end

-- ============================================================
--  Tela de configuração
-- ============================================================

term.clear()
term.setCursorPos(1, 1)
print("============================================")
print("       Mining Turtle - Configuracao         ")
print("============================================")
print("")
print("Posicione a tartaruga no canto inferior")
print("esquerdo da area, virada para frente (+X).")
print("")

local LARGURA     = lerNumero("Largura     (eixo X, blocos por fileira) [1-100]: ", 1, 100)
local COMPRIMENTO = lerNumero("Comprimento (eixo Z, num. de fileiras)   [1-100]: ", 1, 100)
local CAMADAS     = lerNumero("Camadas     (eixo Y, altura para cima)   [1-50] : ", 1, 50)

print("")
print("--------------------------------------------")
print("  Area:             " .. LARGURA .. " x " .. COMPRIMENTO .. " x " .. CAMADAS)
print("  Total de blocos:  " .. (LARGURA * COMPRIMENTO * CAMADAS))
print("  Combustivel atual: " .. turtle.getFuelLevel())
print("--------------------------------------------")
print("")

if not confirmar("Confirmar e iniciar mineracao?") then
    print("Cancelado.")
    return
end

print("")
print("Iniciando em 3 segundos...")
sleep(3)

-- ============================================================
--  Rastreamento de posição relativa
--  Origem = (0, 0), direção inicial = +X
--
--  face: 0=+X  1=+Z  2=-X  3=-Z
--  pos.x, pos.z acompanham cada movimento
-- ============================================================

local pos  = { x = 0, z = 0 }
local face = 0   -- começa virado para +X

local DELTA = {
    [0] = { x =  1, z =  0 },  -- +X
    [1] = { x =  0, z =  1 },  -- +Z
    [2] = { x = -1, z =  0 },  -- -X
    [3] = { x =  0, z = -1 },  -- -Z
}

local function virarEsquerda()
    turtle.turnLeft()
    face = (face - 1) % 4
end

local function virarDireita()
    turtle.turnRight()
    face = (face + 1) % 4
end

-- ============================================================
--  Combustível
-- ============================================================

local function reabastecer()
    for slot = 1, 16 do
        if turtle.getItemCount(slot) > 0 then
            turtle.select(slot)
            if turtle.refuel(0) then turtle.refuel() end
        end
    end
    turtle.select(1)
end

local function verificarCombustivel()
    if turtle.getFuelLevel() < 20 then
        reabastecer()
        if turtle.getFuelLevel() < 5 then
            print("[AVISO] Combustivel baixo! Adicione combustivel ao inventario.")
            repeat sleep(5); reabastecer() until turtle.getFuelLevel() >= 5
        end
    end
end

-- ============================================================
--  Movimentos — avançar MINERA; recuar NUNCA minera
-- ============================================================

-- Avança 1 passo minerando obstáculos; atualiza pos
local function moverFrente()
    verificarCombustivel()
    local tentativas = 0
    while not turtle.forward() do
        tentativas = tentativas + 1
        if turtle.detect() then
            turtle.dig()
            sleep(0.2)
        else
            turtle.attack()
            sleep(0.3)
        end
        if tentativas > 20 then
            print("[ERRO] Nao foi possivel avancar apos 20 tentativas.")
            break
        end
    end
    pos.x = pos.x + DELTA[face].x
    pos.z = pos.z + DELTA[face].z
end

-- Recua 1 passo SEM minerar; atualiza pos
-- (turtle.back() nunca minera blocos)
local function recuar()
    verificarCombustivel()
    local tentativas = 0
    while not turtle.back() do
        tentativas = tentativas + 1
        sleep(0.3)
        if tentativas > 20 then
            print("[ERRO] Nao foi possivel recuar apos 20 tentativas.")
            break
        end
    end
    -- recuar move no sentido oposto à face atual
    pos.x = pos.x - DELTA[face].x
    pos.z = pos.z - DELTA[face].z
end

local function moverCima()
    verificarCombustivel()
    local tentativas = 0
    while not turtle.up() do
        tentativas = tentativas + 1
        if turtle.detectUp() then
            turtle.digUp()
            sleep(0.2)
        else
            turtle.attackUp()
            sleep(0.3)
        end
        if tentativas > 20 then
            print("[ERRO] Nao foi possivel subir apos 20 tentativas.")
            break
        end
    end
end

local function minarBaixo()
    if turtle.detectDown() then turtle.digDown(); sleep(0.2) end
end

local function minarCima()
    if turtle.detectUp() then turtle.digUp(); sleep(0.2) end
end

-- ============================================================
--  Virar para encarar uma face alvo (0..3)
-- ============================================================

local function virarPara(alvo)
    local diff = (alvo - face) % 4
    if diff == 1 then
        virarDireita()
    elseif diff == 2 then
        virarDireita(); virarDireita()
    elseif diff == 3 then
        virarEsquerda()
    end
    -- diff == 0: já está na direção certa
end

-- ============================================================
--  Retorno à origem (0,0) usando recuar() — SEM minerar nada
--
--  Estratégia: olha para o eixo com maior deslocamento,
--  recua até zerar, depois faz o outro eixo.
--  Usa turtle.back() via recuar(), que nunca minera.
-- ============================================================

local function retornarOrigem()
    -- 1. Zera o eixo Z: precisa estar virado para ±Z
    if pos.z ~= 0 then
        -- Queremos recuar em Z, ou seja, mover em -Z se pos.z > 0
        -- recuar() move no sentido oposto à face, então
        -- se face aponta para +Z (face=1), recuar() move em -Z ✓
        -- se face aponta para -Z (face=3), recuar() move em +Z ✓
        -- precisamos estar virados para o eixo Z
        if pos.z > 0 then
            virarPara(1)   -- +Z: recuando iremos em -Z
        else
            virarPara(3)   -- -Z: recuando iremos em +Z
        end
        local passos = math.abs(pos.z)
        for _ = 1, passos do recuar() end
    end

    -- 2. Zera o eixo X
    if pos.x ~= 0 then
        if pos.x > 0 then
            virarPara(0)   -- +X: recuando iremos em -X
        else
            virarPara(2)   -- -X: recuando iremos em +X
        end
        local passos = math.abs(pos.x)
        for _ = 1, passos do recuar() end
    end

    -- 3. Reorienta para +X (face=0) pronto para próxima camada
    virarPara(0)
end

-- ============================================================
--  Serpentina de mineração numa camada
--
--  Fileiras ímpares (1,3,…) → percorridas em +X → vira esquerda p/ +Z
--  Fileiras pares   (2,4,…) → percorridas em -X → vira direita  p/ +Z
-- ============================================================

local function minerarCamada()
    for linha = 1, COMPRIMENTO do
        minarBaixo()

        for _ = 1, LARGURA - 1 do
            moverFrente()
            minarBaixo()
        end

        if linha < COMPRIMENTO then
            if linha % 2 == 1 then
                virarEsquerda()
                moverFrente()
                virarEsquerda()
            else
                virarDireita()
                moverFrente()
                virarDireita()
            end
        end
    end
end

-- ============================================================
--  Execução principal
-- ============================================================

print("=== Minerando " .. LARGURA .. "x" .. COMPRIMENTO .. "x" .. CAMADAS .. " ===")

for camada = 1, CAMADAS do
    print(">> Camada " .. camada .. "/" .. CAMADAS
          .. "  pos=(" .. pos.x .. "," .. pos.z .. ")  face=" .. face)

    minerarCamada()

    if camada < CAMADAS then
        retornarOrigem()  -- volta a (0,0) SEM minerar nada no caminho
        moverCima()       -- sobe 1 bloco
        minarCima()       -- limpa teto da nova camada
    end
end

print("")
print("============================================")
print("  Mineracao concluida!")
print("  Combustivel restante: " .. turtle.getFuelLevel())
print("============================================")
