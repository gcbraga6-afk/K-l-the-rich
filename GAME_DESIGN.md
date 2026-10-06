# Game Design - K**l the Rich

Fonte viva das decisoes fechadas de design. Os relatorios existentes permanecem como historico e contexto; este documento consolida a direcao atual para evitar contradicoes durante o prototipo.

## Principio central

> There are no missions. There are kingdoms. You don't complete them. You change them.

K**l the Rich nao e um jogo de cumprir objetivos politicos. O jogador interfere fisicamente em Reinos persistentes, observa as consequencias e deixa marcas materiais, sociais e narrativas.

O jogador nao escolhe "revolucao", "autoritarismo" ou "final bom" em menus. Ele mira, dispara, liberta, quebra, revela, assusta, protege ou destrói. O sistema social interpreta esses acontecimentos.

## Direcao tecnica

- Engine: Godot 4.
- Linguagem principal: GDScript.
- Formato: 2D lateral.
- Camera: navegacao horizontal pelo Reino.
- Estrutura: sistemas pequenos conectados por eventos, nao uma IA monolitica do Reino.
- Peca central tecnica: Event Bus/Event System.

Eventos devem registrar fatos do mundo, por exemplo:

```text
BUILDING_HIT
target: house
cause: knight
location: village
witnesses: 7
severity: 0.6
narrative_value: 0.4
```

Os sistemas de medo, propaganda, Prestigio, Frenesi, rotina, repressao e transformacao fisica reagem aos fatos.

## Reino e intervencao

A unidade basica nao e a fase: e o Reino.

- Cada Reino persiste depois da intervencao.
- Nao ha objetivo ou missao obrigatoria dentro de um Reino.
- O Cavaleiro pode interferir, observar as consequencias e sair.
- O Reino continua existindo, mudando e carregando marcas permanentes.
- Estruturas civis podem ser destruidas de forma permanente e persistente.
- Crianças podem existir e estar em risco, mas o jogo nao deve usar gore.

Layout base:

- Cavaleiro sempre no extremo esquerdo.
- Castelo sempre a direita.
- O jogador observa o Reino deslocando a camera.
- O Cavaleiro nao e personagem de plataforma; ele e a origem externa da intervencao.

## Tempo e fim da intervencao

- A intervencao nao tem limite de tempo fixo.
- O Reino possui ciclo diario acelerado durante a intervencao.
- Rotinas de trabalho, deslocamento, propaganda, patrulha e descanso devem continuar acontecendo.
- A municao e limitada.
- A quantidade de municao e o loadout exato ainda precisam ser validados no prototipo.

A intervencao termina quando:

- municao chega a 0;
- o Cavaleiro e expulso fisicamente;
- o jogador decide se retirar.

O Cavaleiro nao morre. Expulsao nao e Game Over; e consequencia historica daquele Reino.

## Cavaleiro

O Cavaleiro representa o salvador externo de conto de fadas. Ele nao governa, nao legisla e nao recebe mandato politico.

Decisoes fechadas:

- Sem Prestigio do Cavaleiro.
- Sem modo principal de andar pela vila e conversar.
- O gameplay principal e observar e interferir fisicamente.
- As consequencias sociais pertencem ao Reino, nao a uma arvore de missoes do Cavaleiro.

## Prestigio

Prestigio mede quem aparece como resposta legitima para diferentes grupos sociais.

O Cavaleiro nao tem Prestigio.

Prestigio existe, no minimo, para:

- Rei;
- Influencer.

O Prestigio deve ser segmentado por grupo:

- Workers;
- Bourgeoisie;
- Nobility;
- Soldiers.

O mesmo personagem pode ter Prestigio alto entre Soldiers e baixo entre Workers. Isso permite que uma autoridade permaneca forte pela repressao mesmo perdendo legitimidade popular.

## Grupos sociais

Grupos relevantes:

- Workers;
- Bourgeoisie;
- Nobility;
- Soldiers.

Esses grupos nao devem ter comportamento politico fixo programado. Posicao material, medo, propaganda, experiencia direta, riqueza, repressao e Prestigio moldam suas respostas.

## Eventos e Valor Narrativo

Eventos devem ter Valor Narrativo alem de efeito fisico.

Valor Narrativo representa o quanto um acontecimento e facil de interpretar, capturar, propagar ou transformar em simbolo.

Exemplos:

- destruir uma casa civil tem alto Valor Narrativo contra o Cavaleiro;
- abrir um reservatorio real para a vila tem alto Valor Narrativo contra o Rei;
- derrubar uma muralha diante de trabalhadores pode ter Valor Narrativo coletivo;
- dano sem testemunhas pode ter efeito fisico alto e Valor Narrativo baixo.

Propaganda, LIVE do Cavaleiro, Prestigio e Frenesi devem reagir a esse valor.

## Soldados e Coesao

Soldados continuam sendo uma forca fisica de repressao.

Variavel-chave: Coesao.

A Coesao dos soldados deve influenciar:

- capacidade de repressao;
- obediencia;
- recuperacao de formacao;
- risco de deserção;
- risco de Motim.

Estados possiveis:

- leal;
- desorganizado;
- desertor;
- amotinado.

Motim e deserção sao coisas diferentes:

- deserção: soldado abandona o posto e desaparece/para de reprimir;
- Motim: soldado se volta contra a autoridade.

## Espelhos e propaganda

O Espelho nao possui canais.

Estados do Espelho:

- PROPAGANDA normal do Reino;
- LIVE do Cavaleiro.

LIVE e ao vivo. Nao ha captura, replay, gravacao ou arquivo de video. O poder da LIVE esta em transmitir um acontecimento enquanto ele acontece.

Propaganda nao cria realidade do nada. Ela enquadra acontecimentos reais, explorando medo, conveniencia, experiencia material, Prestigio e contradicoes visiveis.

O sistema detalhado do Espelho esta em `ESPELHO.md`: quem ocupa o canal, a progressao da linguagem institucional, a biblioteca de mensagens e o que ainda esta em aberto.

## Pigeon

O Pigeon e definitivo no design atual.

Funcao: permitir que o jogador transmita uma acao ao vivo pelos Espelhos sem transformar o jogo em sistema de canais ou gravacoes.

Comportamento:

- voo semiautonomo;
- pode marcar targets de pessoas ou estruturas;
- pode pousar dormente no Espelho sem ser percebido;
- enquanto dormente, o jogador prepara ou espera a acao certa;
- CONNECT inicia a LIVE;
- os guardas so percebem o Pigeon quando a LIVE comeca;
- durante a LIVE, o jogador pode alternar apenas entre targets previamente marcados;
- guardas tentam espantar o Pigeon;
- quando espantado, o Pigeon retorna ao Cavaleiro;
- targets, percepcao e conexao zeram;
- o Pigeon entra em cooldown.

O Pigeon nao cria fatos. Ele muda quem presencia fatos.

## Armas e tecnologia

Novas armas nao surgem por XP.

Tecnologia e novas armas aparecem ao longo dos anos via Fairy Defense Industries, como parte do mundo e da historia material da campanha.

Familias planejadas:

- Basic;
- Impact;
- Flash;
- Incendiary;
- Mechanical Falcon.

O prototipo deve comecar com:

- Basic;
- Flash.

Loadout, quantidade de municao e cadencia ainda devem ser validados no Prototype 0.1.

## Persistencia fisica

Estruturas civis sao permanentemente destrutiveis/persistentes.

Casas, escola, fabrica, espelhos, muralhas, reservatorio, prisoes, oficinas e outros elementos devem carregar consequencias ao longo do tempo quando fizer sentido.

O mundo nao troca de cenario quando a sociedade muda. O proprio cenario se transforma.

## Campanha

A campanha maior ainda pode ter mapa do mundo, varios Reinos, anos e censo final. Isso nao entra no Prototype 0.1.

Decisoes preservadas:

- Reinos podem continuar evoluindo apos a intervencao.
- Viagens e anos importam na campanha completa.
- O final deve ser um censo/cronica do mundo, nao uma pontuacao moral.

