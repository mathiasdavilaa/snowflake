--!strict

-- ModuleScript disponível ao servidor e ao cliente através de require.
local Mensagem = {}

function Mensagem.saudacao(nome: string): string
    return "Ola, " .. nome
end

return Mensagem
