$ErrorActionPreference = "Stop"

$workspace = Split-Path -Parent $MyInvocation.MyCommand.Path
$arquivoEntrada = Join-Path $workspace "Artigo RP2.txt"
$arquivoSaida = Join-Path $workspace "dados_avaliacao.json"
$pastaQuestoes = Join-Path $workspace "questões"
if (-not (Test-Path -LiteralPath $pastaQuestoes)) {
    $dirQuestoes = Get-ChildItem -LiteralPath $workspace -Directory | Where-Object { $_.Name -like "quest*" } | Select-Object -First 1
    if ($null -ne $dirQuestoes) {
        $pastaQuestoes = $dirQuestoes.FullName
    }
}

if (-not (Test-Path -LiteralPath $arquivoEntrada)) {
    throw "Arquivo de entrada não encontrado: $arquivoEntrada"
}

$gabarito = @{
    "2019-42" = "A"
    "2019-44" = "C"
    "2019-53" = "E"
    "2019-68" = "E"
    "2019-70" = "D"
    "2022-42" = "B"
    "2022-43" = "D"
    "2022-44" = "D"
    "2022-56" = "B"
    "2023-29" = "C"
    "2023-37" = "D"
    "2024-37" = "E"
}

$linhas = Get-Content -LiteralPath $arquivoEntrada -Encoding UTF8
if (($linhas -join "`n") -match "Ã") {
    # Fallback para arquivos em codificação ANSI/Windows-1252.
    $linhas = Get-Content -LiteralPath $arquivoEntrada -Encoding Default
}

$resultado = @()
$contador = 0
$blocoAtual = @()

function Add-ItemFromBlock {
    param(
        [string[]]$BlocoLinhas,
        [ref]$Resultado,
        [ref]$Contador,
        [hashtable]$Gabarito,
        [string]$PastaQuestoes
    )

    if (-not $BlocoLinhas -or $BlocoLinhas.Count -eq 0) {
        return
    }

    $blocoTexto = ($BlocoLinhas -join "`n")
    $ia = ([regex]::Match($blocoTexto, '(?m)^IA:\s*(.+)$')).Groups[1].Value.Trim()
    $ano = ([regex]::Match($blocoTexto, '(?m)^Ano:\s*(\d+)$')).Groups[1].Value.Trim()
    $cenario = ([regex]::Match($blocoTexto, '(?m)^Cenario:\s*(.+)$')).Groups[1].Value.Trim()
    $questao = ([regex]::Match($blocoTexto, '(?m)^Questao:\s*(\d+)$')).Groups[1].Value.Trim()

    if ([string]::IsNullOrWhiteSpace($ia) -or [string]::IsNullOrWhiteSpace($ano) -or [string]::IsNullOrWhiteSpace($cenario) -or [string]::IsNullOrWhiteSpace($questao)) {
        return
    }

    $resposta = ""
    $respostaMatch = [regex]::Match($blocoTexto, '(?s)--- RESPOSTA ---\s*(.*)$')
    if ($respostaMatch.Success) {
        $resposta = $respostaMatch.Groups[1].Value.Trim()
        $resposta = [regex]::Replace($resposta, '(?ms)(?:\r?\n)*(?:\d{4}:?|prompt\s*\d+:?)\s*$', '').Trim()
    }

    $chave = "$ano-$questao"
    $imagemNome = "${questao}_${ano}.png"
    $imagemCaminhoAbsoluto = Join-Path $PastaQuestoes $imagemNome
    $imagemQuestao = ""
    if (Test-Path -LiteralPath $imagemCaminhoAbsoluto) {
        $imagemQuestao = "questões/$imagemNome"
    }

    $gabaritoValor = ""
    if ($Gabarito.ContainsKey($chave)) {
        $gabaritoValor = $Gabarito[$chave]
    }

    $Contador.Value += 1
    $id = "item-{0:d3}" -f $Contador.Value

    $item = [ordered]@{
        id = $id
        ano = [int]$ano
        questao = [int]$questao
        cenario = $cenario
        ia = $ia
        enunciado = "Enunciado original não disponível em texto no arquivo fonte; consulte a imagem da questão."
        imagemQuestao = $imagemQuestao
        resposta = $resposta
        gabarito = $gabaritoValor
    }

    $Resultado.Value += [pscustomobject]$item
}

foreach ($linha in $linhas) {
    if ($linha.Trim() -eq "### INICIO_AVALIACAO") {
        Add-ItemFromBlock -BlocoLinhas $blocoAtual -Resultado ([ref]$resultado) -Contador ([ref]$contador) -Gabarito $gabarito -PastaQuestoes $pastaQuestoes
        $blocoAtual = @()
        $blocoAtual += $linha
        continue
    }

    if ($blocoAtual.Count -gt 0) {
        $blocoAtual += $linha
    }
}

Add-ItemFromBlock -BlocoLinhas $blocoAtual -Resultado ([ref]$resultado) -Contador ([ref]$contador) -Gabarito $gabarito -PastaQuestoes $pastaQuestoes

$resultado | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath $arquivoSaida -Encoding UTF8

Write-Host "Arquivo gerado com sucesso: $arquivoSaida"
Write-Host "Total de itens extraídos: $($resultado.Count)"
