-- Script Logger usando Orion Hub UI V3
-- Monitora e exibe scripts executados no servidor

local OrionLib = loadstring(game:HttpGet('https://raw.githubusercontent.com/VerbalHubz/Verbal-Hub/refs/heads/main/Orion%20Hub%20Ui%20V3'))()

-- Configuração da janela principal
local Window = OrionLib:MakeWindow({
    Name = "Script Logger - Monitor de Atividades",
    HidePremium = false,
    SaveConfig = true,
    ConfigFolder = "ScriptLogger",
    IntroEnabled = true,
    IntroText = "Script Logger Carregado"
})

-- Variáveis globais
local scriptLogs = {}
local maxLogs = 100
local isLogging = true
local logCount = 0
local detectSystemScripts = true
local detectLocalScripts = true

-- Função para formatar timestamp
local function getTimestamp()
    return os.date("[%H:%M:%S]")
end

-- Função para adicionar log
local function addLog(playerName, scriptInfo, scriptType)
    if not isLogging then return end
    
    logCount = logCount + 1
    local logEntry = {
        id = logCount,
        timestamp = getTimestamp(),
        player = playerName or "Desconhecido",
        script = scriptInfo or "Script Desconhecido",
        type = scriptType or "Executado",
        time = tick()
    }
    
    table.insert(scriptLogs, 1, logEntry)
    
    -- Limita o número de logs
    if #scriptLogs > maxLogs then
        table.remove(scriptLogs, #scriptLogs)
    end
    
    -- Atualiza a interface se existir
    if logListBox then
        updateLogDisplay()
    end
end

-- Função para detectar scripts
local function detectScripts()
    -- Monitor de novos scripts criados
    local function onChildAdded(child)
        if (child:IsA("LocalScript") and detectLocalScripts) or (child:IsA("Script") and detectSystemScripts then
            local player = game.Players:GetPlayerFromCharacter(child.Parent) or 
                          game.Players:FindFirstChild(child.Parent.Name)
            local playerName = player and player.Name or "Sistema"
            
            addLog(playerName, child.Name, child:IsA("LocalScript") and "LocalScript" or "Script")
        end
    end
    
    -- Monitora workspace
    workspace.ChildAdded:Connect(onChildAdded)
    workspace.DescendantAdded:Connect(function(descendant)
        if (descendant:IsA("LocalScript") and detectLocalScripts) or (descendant:IsA("Script") and detectSystemScripts) then
            local player = game.Players:GetPlayerFromCharacter(descendant.Parent) or 
                          game.Players:FindFirstChild(descendant.Parent.Name)
            local playerName = player and player.Name or "Sistema"
            
            addLog(playerName, descendant.Name, descendant:IsA("LocalScript") and "LocalScript" or "Script")
        end
    end)
    
    -- Monitora players
    for _, player in pairs(game.Players:GetPlayers()) do
        if player.Character then
            player.Character.ChildAdded:Connect(onChildAdded)
            player.Character.DescendantAdded:Connect(function(descendant)
                if (descendant:IsA("LocalScript") and detectLocalScripts) or (descendant:IsA("Script") and detectSystemScripts) then
                    addLog(player.Name, descendant.Name, "Script no Character")
                end
            end)
        end
        
        player.CharacterAdded:Connect(function(character)
            character.ChildAdded:Connect(onChildAdded)
            character.DescendantAdded:Connect(function(descendant)
                if (descendant:IsA("LocalScript") and detectLocalScripts) or (descendant:IsA("Script") and detectSystemScripts) then
                    addLog(player.Name, descendant.Name, "Script no Character")
                end
            end)
        end)
    end
    
    -- Monitora novos players
    game.Players.PlayerAdded:Connect(function(player)
        player.CharacterAdded:Connect(function(character)
            character.ChildAdded:Connect(onChildAdded)
            character.DescendantAdded:Connect(function(descendant)
                if (descendant:IsA("LocalScript") and detectLocalScripts) or (descendant:IsA("Script") and detectSystemScripts) then
                    addLog(player.Name, descendant.Name, "Script no Character")
                end
            end)
        end)
    end)
end

-- Tab principal - Logs
local LogTab = Window:MakeTab({
    Name = "📋 Logs de Scripts",
    Icon = "rbxassetid://4483345998",
    PremiumOnly = false
})

-- Seção de status
LogTab:AddSection({
    Name = "Status do Logger"
})

local statusLabel = LogTab:AddLabel("Status: Ativo - Logs: 0")

-- Toggle para ativar/desativar logging
LogTab:AddToggle({
    Name = "Ativar Logger",
    Default = true,
    Callback = function(Value)
        isLogging = Value
        statusLabel:Set(string.format("Status: %s - Logs: %d", 
            isLogging and "Ativo" or "Inativo", #scriptLogs))
    end    
})

-- Seção de logs
LogTab:AddSection({
    Name = "Logs Recentes"
})

-- Display dos logs
local logDisplay = LogTab:AddParagraph("Logs", "Aguardando detecção de scripts...")

-- Função para atualizar o display periodicamente
spawn(function()
    while true do
        wait(1)
        if isLogging then
            local displayText = ""
            for i = 1, math.min(10, #scriptLogs) do
                local log = scriptLogs[i]
                displayText = displayText .. string.format(
                    "%s %s: %s\n",
                    log.timestamp,
                    log.player,
                    log.script
                )
            end
            
            if displayText == "" then
                displayText = "Nenhum script detectado..."
            end
            
            logDisplay:Set("Logs", displayText)
            statusLabel:Set(string.format("Status: %s - Logs: %d", 
                isLogging and "Ativo" or "Inativo", #scriptLogs))
        end
    end
end)

-- Botão para limpar logs
LogTab:AddButton({
    Name = "Limpar Logs",
    Callback = function()
        scriptLogs = {}
        logCount = 0
        logDisplay:Set("Logs", "Logs limpos!")
        statusLabel:Set(string.format("Status: %s - Logs: 0", 
            isLogging and "Ativo" or "Inativo"))
    end    
})

-- Tab de Jogo
local GameTab = Window:MakeTab({
    Name = "🎮 Jogo",
    Icon = "rbxassetid://4483345998",
    PremiumOnly = false
})

-- Função para obter informações do jogo
local function getGameInfo()
    local gameInfo = {
        name = game:GetService("MarketplaceService"):GetProductInfo(game.PlaceId).Name or "Nome não disponível",
        gameId = game.GameId,
        placeId = game.PlaceId,
        jobId = game.JobId,
        creatorType = "",
        creatorName = "",
        creatorId = 0,
        created = "",
        updated = "",
        gameLink = "",
        creatorLink = "",
        maxPlayers = game.Players.MaxPlayers,
        currentPlayers = #game.Players:GetPlayers()
    }
    
    -- Determina o tipo de criador e links
    if game:GetService("MarketplaceService"):GetProductInfo(game.PlaceId).Creator.CreatorType == Enum.CreatorType.User then
        gameInfo.creatorType = "Usuário"
        gameInfo.creatorName = game:GetService("MarketplaceService"):GetProductInfo(game.PlaceId).Creator.Name or "Desconhecido"
        gameInfo.creatorId = game:GetService("MarketplaceService"):GetProductInfo(game.PlaceId).Creator.CreatorTargetId
        gameInfo.creatorLink = "https://www.roblox.com/users/" .. gameInfo.creatorId .. "/profile"
    else
        gameInfo.creatorType = "Grupo"
        gameInfo.creatorName = game:GetService("MarketplaceService"):GetProductInfo(game.PlaceId).Creator.Name or "Desconhecido"
        gameInfo.creatorId = game:GetService("MarketplaceService"):GetProductInfo(game.PlaceId).Creator.CreatorTargetId
        gameInfo.creatorLink = "https://www.roblox.com/groups/" .. gameInfo.creatorId
    end
    
    -- Links do jogo
    gameInfo.gameLink = "https://www.roblox.com/games/" .. game.PlaceId
    
    return gameInfo
end

-- Função para formatar informações do jogo
local function formatGameInfo(info)
    local formattedInfo = string.format([[
🎮 Nome do Jogo: %s
🆔 Place ID: %d
🎯 Game ID: %d
🔗 Job ID: %s

👤 Criado por: %s (%s)
🆔 ID do Criador: %d
🔗 Link do Criador: %s

🔗 Link do Jogo: %s

👥 Players: %d/%d
🌐 Servidor: %s
]], 
        info.name,
        info.placeId,
        info.gameId,
        info.jobId,
        info.creatorName,
        info.creatorType,
        info.creatorId,
        info.creatorLink,
        info.gameLink,
        info.currentPlayers,
        info.maxPlayers,
        info.jobId:sub(1, 8) .. "..."
    )
    
    return formattedInfo
end

-- Seção principal de informações do jogo
GameTab:AddSection({
    Name = "Informações do Jogo Atual"
})

-- Obtém e exibe informações do jogo
local gameInfo = getGameInfo()
local gameInfoDisplay = GameTab:AddParagraph("Informações do Jogo", formatGameInfo(gameInfo))

-- Seção de ações rápidas
GameTab:AddSection({
    Name = "Ações Rápidas"
})

-- Botão para atualizar informações
GameTab:AddButton({
    Name = "🔄 Atualizar Informações",
    Callback = function()
        gameInfo = getGameInfo()
        gameInfoDisplay:Set("Informações do Jogo", formatGameInfo(gameInfo))
        
        OrionLib:MakeNotification({
            Name = "Informações Atualizadas",
            Content = "Dados do jogo foram atualizados!",
            Image = "rbxassetid://4483345998",
            Time = 3
        })
    end    
})

-- Botão para copiar Place ID
GameTab:AddButton({
    Name = "📋 Copiar Place ID",
    Callback = function()
        local placeId = tostring(game.PlaceId)
        if setclipboard then
            setclipboard(placeId)
            OrionLib:MakeNotification({
                Name = "Place ID Copiado",
                Content = "Place ID " .. placeId .. " copiado!",
                Image = "rbxassetid://4483345998",
                Time = 3
            })
        else
            print("Place ID: " .. placeId)
            OrionLib:MakeNotification({
                Name = "Place ID no Console",
                Content = "Place ID exibido no console!",
                Image = "rbxassetid://4483345998",
                Time = 3
            })
        end
    end    
})

-- Tab de Players
local PlayerTab = Window:MakeTab({
    Name = "👥 Players",
    Icon = "rbxassetid://4483345998",
    PremiumOnly = false
})

-- Variáveis para player info
local selectedPlayer = nil
local playerInfoDisplay = nil

-- Função para obter informações do player
local function getPlayerInfo(player)
    if not player then return nil end
    
    local info = {
        name = player.Name,
        displayName = player.DisplayName,
        userId = player.UserId,
        accountAge = player.AccountAge,
        membershipType = tostring(player.MembershipType),
        joinDate = "",
        profileLink = "https://www.roblox.com/users/" .. player.UserId .. "/profile"
    }
    
    -- Calcula data de criação da conta
    local currentDate = os.time()
    local accountCreationDate = currentDate - (player.AccountAge * 24 * 60 * 60)
    info.joinDate = os.date("%d/%m/%Y", accountCreationDate)
    
    return info
end

-- Função para atualizar display de informações do player
local function updatePlayerInfo(playerInfo)
    if not playerInfo or not playerInfoDisplay then return end
    
    local infoText = string.format([[
🎮 Nome: %s
📝 Nome de Exibição: %s
🆔 ID da Conta: %d
📅 Criada em: %s
⏰ Idade da Conta: %d dias
💎 Membership: %s
🔗 Link do Perfil: %s
]], 
        playerInfo.name,
        playerInfo.displayName,
        playerInfo.userId,
        playerInfo.joinDate,
        playerInfo.accountAge,
        playerInfo.membershipType,
        playerInfo.profileLink
    )
    
    playerInfoDisplay:Set("Informações do Player", infoText)
end

-- Seção de pesquisa
PlayerTab:AddSection({
    Name = "Pesquisar Player"
})

-- Lista de players online para dropdown
local function getOnlinePlayerNames()
    local players = {}
    for _, player in pairs(game.Players:GetPlayers()) do
        table.insert(players, player.Name)
    end
    return players
end

-- Dropdown para selecionar player
local playerDropdown = PlayerTab:AddDropdown({
    Name = "Selecionar Player Online",
    Default = "",
    Options = getOnlinePlayerNames(),
    Callback = function(Value)
        local player = game.Players:FindFirstChild(Value)
        if player then
            selectedPlayer = player
            local info = getPlayerInfo(player)
            updatePlayerInfo(info)
            
            OrionLib:MakeNotification({
                Name = "Player Selecionado",
                Content = "Informações carregadas para " .. Value,
                Image = "rbxassetid://4483345998",
                Time = 3
            })
        end
    end    
})

-- Display das informações
playerInfoDisplay = PlayerTab:AddParagraph("Informações do Player", "Selecione um player para ver as informações...")

-- Botão para copiar ID
PlayerTab:AddButton({
    Name = "📋 Copiar ID do Player",
    Callback = function()
        if selectedPlayer then
            local playerId = tostring(selectedPlayer.UserId)
            if setclipboard then
                setclipboard(playerId)
                OrionLib:MakeNotification({
                    Name = "ID Copiado",
                    Content = "ID " .. playerId .. " copiado!",
                    Image = "rbxassetid://4483345998",
                    Time = 3
                })
            else
                print("Player ID: " .. playerId)
                OrionLib:MakeNotification({
                    Name = "ID no Console",
                    Content = "ID exibido no console!",
                    Image = "rbxassetid://4483345998",
                    Time = 3
                })
            end
        else
            OrionLib:MakeNotification({
                Name = "Erro",
                Content = "Nenhum player selecionado!",
                Image = "rbxassetid://4483345998",
                Time = 3
            })
        end
    end    
})

-- Tab de configurações
local ConfigTab = Window:MakeTab({
    Name = "⚙️ Configurações",
    Icon = "rbxassetid://4483345998",
    PremiumOnly = false
})

ConfigTab:AddSection({
    Name = "Configurações do Logger"
})

-- Slider para máximo de logs
ConfigTab:AddSlider({
    Name = "Máximo de Logs",
    Min = 10,
    Max = 500,
    Default = 100,
    Color = Color3.fromRGB(255,255,255),
    Increment = 10,
    ValueName = "logs",
    Callback = function(Value)
        maxLogs = Value
        -- Remove logs extras se necessário
        while #scriptLogs > maxLogs do
            table.remove(scriptLogs, #scriptLogs)
        end
    end    
})

-- Toggle para diferentes tipos de detecção
ConfigTab:AddToggle({
    Name = "Detectar Scripts do Sistema",
    Default = true,
    Callback = function(Value)
        detectSystemScripts = Value
    end    
})

ConfigTab:AddToggle({
    Name = "Detectar LocalScripts",
    Default = true,
    Callback = function(Value)
        detectLocalScripts = Value
    end    
})

-- Inicia a detecção de scripts
detectScripts()

-- Inicializa a UI
OrionLib:Init()