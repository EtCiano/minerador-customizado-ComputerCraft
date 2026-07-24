--[[
    MINERADOR AUTOMATICO - ComputerCraft
    ------------------------------------
    Pergunta a area (X, Y, Z) que a turtle deve minerar em formato de cubo,
    mostra estatisticas da mineracao e, apos confirmacao, executa a mineracao
    em padrao "cobra" (boustrophedon), descendo camada por camada.

    Requisitos:
      - Uma Mining Turtle (ou turtle comum com pickaxe equipada).
      - Combustivel suficiente no inventario (ou ja abastecida).
      - Recomendado: colocar a turtle EM CIMA de uma chest antes de iniciar.
        Quando o inventario encher, ela volta ao ponto inicial e descarrega
        os itens nessa chest (turtle.dropDown), depois continua o trabalho.
]]

------------------------------------------------------------
-- ESTADO / POSICAO
------------------------------------------------------------

-- Posicao relativa ao ponto inicial (0,0,0)
local pos = { x = 0, y = 0, z = 0 }

-- Direcao atual (0,1,2,3) relativa a direcao inicial da turtle.
-- Vetores de deslocamento (dx, dz) para cada direcao.
local dirs = {
    { dx = 0, dz = 1 },  -- 0
    { dx = 1, dz = 0 },  -- 1
    { dx = 0, dz = -1 }, -- 2
    { dx = -1, dz = 0 }, -- 3
}
local facing = 0

------------------------------------------------------------
-- UTILITARIOS DE ENTRADA
------------------------------------------------------------

local function lerNumero(mensagem)
    while true do
        io.write(mensagem)
        local entrada = read()
        local numero = tonumber(entrada)
        if numero ~= nil and numero == math.floor(numero) and numero > 0 then
            return math.floor(numero)
        end
        print("Valor invalido. Digite um numero inteiro maior que zero.")
    end
end

local function lerSimNao(mensagem)
    while true do
        io.write(mensagem .. " (s/n): ")
        local entrada = string.lower(read() or "")
        if entrada == "s" or entrada == "sim" then
            return true
        elseif entrada == "n" or entrada == "nao" or entrada == "não" then
            return false
        end
        print("Responda com 's' ou 'n'.")
    end
end

------------------------------------------------------------
-- COMBUSTIVEL
------------------------------------------------------------

local function tentarReabastecer()
    if turtle.getFuelLevel() == "unlimited" then return end
    for slot = 1, 16 do
        turtle.select(slot)
        if turtle.refuel(0) then -- item no slot serve de combustivel?
            turtle.refuel()
        end
    end
    turtle.select(1)
end

local function combustivelSuficiente(necessario)
    if turtle.getFuelLevel() == "unlimited" then return true end
    return turtle.getFuelLevel() >= necessario
end

------------------------------------------------------------
-- INVENTARIO
------------------------------------------------------------

local function inventarioCheio()
    for slot = 1, 16 do
        if turtle.getItemCount(slot) == 0 then
            return false
        end
    end
    return true
end

local function descarregarNaChestInicial()
    -- Assume que ha uma chest embaixo do ponto inicial (0,0,0)
    for slot = 1, 16 do
        turtle.select(slot)
        turtle.dropDown()
    end
    turtle.select(1)
end

------------------------------------------------------------
-- MOVIMENTO SEGURO (cava obstaculos, trata gravidade/areia/cascalho)
------------------------------------------------------------

local function cavarFrenteSeNecessario()
    while turtle.detect() do
        if not turtle.dig() then break end
        sleep(0.3)
    end
end

local function cavarCimaSeNecessario()
    while turtle.detectUp() do
        if not turtle.digUp() then break end
        sleep(0.3)
    end
end

local function cavarBaixoSeNecessario()
    while turtle.detectDown() do
        if not turtle.digDown() then break end
        sleep(0.3)
    end
end

local function garantirCombustivel()
    if turtle.getFuelLevel() ~= "unlimited" and turtle.getFuelLevel() < 5 then
        tentarReabastecer()
    end
end

local function mover_frente()
    garantirCombustivel()
    cavarFrenteSeNecessario()
    while not turtle.forward() do
        cavarFrenteSeNecessario()
        turtle.attack()
        sleep(0.3)
    end
    pos.x = pos.x + dirs[facing + 1].dx
    pos.z = pos.z + dirs[facing + 1].dz
end

local function mover_cima()
    garantirCombustivel()
    cavarCimaSeNecessario()
    while not turtle.up() do
        cavarCimaSeNecessario()
        turtle.attackUp()
        sleep(0.3)
    end
    pos.y = pos.y + 1
end

local function mover_baixo()
    garantirCombustivel()
    cavarBaixoSeNecessario()
    while not turtle.down() do
        cavarBaixoSeNecessario()
        turtle.attackDown()
        sleep(0.3)
    end
    pos.y = pos.y - 1
end

local function virar_direita()
    turtle.turnRight()
    facing = (facing + 1) % 4
end

local function virar_esquerda()
    turtle.turnLeft()
    facing = (facing - 1) % 4
end

-- Vira a turtle para encarar uma direcao absoluta especifica (0..3)
local function virarPara(direcaoAlvo)
    local diff = (direcaoAlvo - facing) % 4
    if diff == 1 then
        virar_direita()
    elseif diff == 2 then
        virar_direita()
        virar_direita()
    elseif diff == 3 then
        virar_esquerda()
    end
end

------------------------------------------------------------
-- RETORNAR AO PONTO INICIAL (0,0,0) E VOLTAR DEPOIS
------------------------------------------------------------

local function irParaCoordenada(destX, destY, destZ)
    -- Ajusta Y primeiro
    while pos.y < destY do mover_cima() end
    while pos.y > destY do mover_baixo() end

    -- Ajusta X
    if pos.x < destX then
        virarPara(1) -- direcao +x
        while pos.x < destX do mover_frente() end
    elseif pos.x > destX then
        virarPara(3) -- direcao -x
        while pos.x > destX do mover_frente() end
    end

    -- Ajusta Z
    if pos.z < destZ then
        virarPara(0) -- direcao +z
        while pos.z < destZ do mover_frente() end
    elseif pos.z > destZ then
        virarPara(2) -- direcao -z
        while pos.z > destZ do mover_frente() end
    end
end

local function verificarEDescarregar()
    if inventarioCheio() then
        print("Inventario cheio! Retornando ao ponto inicial para descarregar...")
        local voltaX, voltaY, voltaZ, voltaFacing = pos.x, pos.y, pos.z, facing
        irParaCoordenada(0, 0, 0)
        descarregarNaChestInicial()
        print("Descarregado. Retomando mineracao...")
        irParaCoordenada(voltaX, voltaY, voltaZ)
        virarPara(voltaFacing)
    end
end

------------------------------------------------------------
-- ENTRADA DE DADOS DA AREA
------------------------------------------------------------

term.clear()
term.setCursorPos(1, 1)
print("=== MINERADOR AUTOMATICO ===")
print("Informe as dimensoes do cubo a ser minerado.")
print("")

local largura = lerNumero("Largura (eixo X): ")
local profundidade = lerNumero("Comprimento (eixo Z): ")
local altura = lerNumero("Altura/Profundidade (eixo Y, sentido para baixo): ")

------------------------------------------------------------
-- CALCULO DE ESTATISTICAS
------------------------------------------------------------

local totalBlocos = largura * profundidade * altura

-- Estimativa de movimentos: percorre largura*profundidade em cada camada,
-- mais os movimentos verticais entre camadas.
local movimentosPorCamada = (largura * profundidade)
local movimentosVerticais = (altura - 1)
local totalMovimentosEstimados = (movimentosPorCamada * altura) + movimentosVerticais

-- Estimativa de combustivel com margem de seguranca de 20%
local combustivelEstimado = math.ceil(totalMovimentosEstimados * 1.2)

local fuelAtual = turtle.getFuelLevel()
local fuelTexto = (fuelAtual == "unlimited") and "ilimitado" or tostring(fuelAtual)

print("")
print("=== DADOS DA MINERACAO ===")
print(string.format("Dimensoes: %d x %d x %d (X x Z x Y)", largura, profundidade, altura))
print(string.format("Total de blocos na area: %d", totalBlocos))
print(string.format("Movimentos estimados: %d", totalMovimentosEstimados))
print(string.format("Combustivel necessario (estimado): %d", combustivelEstimado))
print(string.format("Combustivel atual da turtle: %s", fuelTexto))
print(string.format("Slots de inventario disponiveis: 16 (recomendado ter chest no ponto inicial)"))
print("")

if fuelAtual ~= "unlimited" and fuelAtual < combustivelEstimado then
    print("AVISO: combustivel pode ser insuficiente!")
    print("Tentando reabastecer automaticamente com itens do inventario...")
    tentarReabastecer()
    fuelAtual = turtle.getFuelLevel()
    print(string.format("Combustivel apos tentativa de reabastecimento: %s",
        (fuelAtual == "unlimited") and "ilimitado" or tostring(fuelAtual)))
    if fuelAtual ~= "unlimited" and fuelAtual < combustivelEstimado then
        print("Ainda pode faltar combustivel. Recomenda-se abastecer mais antes de continuar.")
    end
    print("")
end

------------------------------------------------------------
-- CONFIRMACAO
------------------------------------------------------------

if not lerSimNao("Deseja iniciar a mineracao agora?") then
    print("Mineracao cancelada pelo usuario.")
    return
end

------------------------------------------------------------
-- MINERACAO EM PADRAO "COBRA" (BOUSTROPHEDON)
------------------------------------------------------------

print("Iniciando mineracao...")

local blocosMineradosEstimados = 0

for camada = 1, altura do
    for linha = 1, profundidade do
        -- Cava a linha (largura - 1 movimentos, largura blocos cavados no total
        -- pois o bloco de baixo/cima ja e tratado pelas funcoes de movimento)
        for passo = 1, largura - 1 do
            mover_frente()
            cavarCimaSeNecessario()
            cavarBaixoSeNecessario()
            blocosMineradosEstimados = blocosMineradosEstimados + 1
            verificarEDescarregar()
        end

        -- Se nao for a ultima linha da camada, vira para trocar de fileira
        if linha < profundidade then
            if facing == 0 or facing == 2 then
                -- Alterna a direcao da "cobra"
                if (linha % 2) == 1 then
                    virar_direita()
                    mover_frente()
                    virar_direita()
                else
                    virar_esquerda()
                    mover_frente()
                    virar_esquerda()
                end
            end
        end
    end

    -- Vira de volta para a direcao original antes de descer (facilita logica)
    virarPara(0)

    -- Desce para a proxima camada, se houver
    if camada < altura then
        mover_baixo()
        cavarCimaSeNecessario()
    end
end

------------------------------------------------------------
-- RETORNO AO PONTO INICIAL E DESCARGA FINAL
------------------------------------------------------------

print("Mineracao concluida! Retornando ao ponto inicial...")
irParaCoordenada(0, 0, 0)
virarPara(0)
descarregarNaChestInicial()

print("")
print("=== MINERACAO FINALIZADA ===")
print(string.format("Area minerada: %d x %d x %d", largura, profundidade, altura))
print(string.format("Blocos processados (estimado): %d", blocosMineradosEstimados))
print("A turtle esta de volta ao ponto inicial.")
