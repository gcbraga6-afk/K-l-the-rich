# Protótipo 0.1 — The Dry Kingdom

`0.1` é a primeira versão jogável: **uma fase única**, sem mapa e sem menu, só para
provar que o Reino funciona. Depois vem 0.2, 0.3, e `1.0` é o jogo com campanha.
Quando este documento diz "fora do 0.1", significa "não agora, entra numa versão
seguinte" — nunca "cancelado". A visão completa está em `GAME_DESIGN.md`.

**Objetivo:** provar que um Reino lateral pequeno funciona como brinquedo sistêmico,
sem objetivo imposto, antes de existir campanha, mapa do mundo ou economia entre
Reinos.

## Critérios de aprovação

O protótipo está aprovado quando:

- Depois de 5 minutos, **dois jogadores produzem histórias diferentes** usando só o
  canhão.
- **10 partidas de 10 minutos geram histórias distintas:** o Influencer tomou o poder;
  matei o Rei e nada aconteceu; os soldados se amotinaram; destruí tanto a vila que o
  Rei ficou mais forte; a Revolução morreu sozinha.
- **Teste Run A × Run B:** quebrar o reservatório sem Pigeon e com Pigeon ao vivo gera
  consequências sociais claramente diferentes, sem roteiros diferentes.
- **Teste do Reino vivo:** abrir o jogo e não fazer nada por 5 minutos e ainda ver vida
  — rotinas, luzes à noite, propaganda mudando, conversas.
- O ciclo fecha: mirar → BOOM → algo quebra → pessoas percebem → conversam → mudam de
  comportamento → Rei reage → nova oportunidade.

## Situação do Reino

**Escassez de água.** A vila está quase seca. O reservatório e as fontes estão dentro
do castelo. A fábrica consome água. O Rei diz que a seca afeta todos. Soldados protegem
a infraestrutura. A população ainda está calma.

Em nenhum lugar está escrito "libere a água". A informação está no cenário: fonte seca
fora, fontes cheias dentro.

## Layout

Cena 2D horizontal única, 4–5 larguras de tela. Cavaleiro sempre no extremo esquerdo,
castelo à direita.

```text
CAVALEIRO → vila → escola → fábrica → Espelho → muralha → castelo
                                                              |
                                                     reservatório, bomba,
                                                     quartel, prisão, Rei
```

População de referência: ~20 trabalhadores, ~5 burgueses, ~3 nobres, ~8 soldados,
1 Influencer, 1 Rei. Entre 30 e 40 NPCs.

## Controles

- Mouse mira o canhão; arrastar para trás junto ao canhão e soltar dispara (a força vem
  do tamanho do arraste).
- A câmera percorre o Reino independente do Cavaleiro.
- Zoom pequeno.
- Seleção de munição entre as famílias ativas.
- Sem WASD no Cavaleiro: ele não se move.

## Ritmo

**Decisão fechada:** o ritmo **não** é imposto por recarga lenta nem por travas.
Cadência de tiro curta. O que faz o jogador parar entre tiros é ter o que olhar:

- micro-diálogos em balão;
- pessoas correndo com animação de verdade;
- soldados que gritam e apontam, chamando atenção;
- bandeirinhas subindo nas janelas;
- propaganda mudando no Espelho.

Quem quiser esvaziar o canhão em dez segundos consegue, e perde o jogo que estava
acontecendo. Isso é escolha do jogador, não bloqueio do sistema.

Sem cronômetro. Esperar custa Frenesi decaindo, não tempo de relógio.

## Munição

O Cavaleiro chega com **8 rounds** e consegue mais dentro do Reino. Gasta-se munição
para conseguir munição: errar é o que esvazia o canhão, não um relógio.

| Fonte | Rende | Risco |
| --- | --- | --- |
| **Paiol real** | 6–8 | Detona com as caixas dentro: medo enorme e dano em volta |
| **Carroça da Fairy Defense** | 2–3 | Alvo em movimento; a boleia leva um carreteiro |
| **Arsenal fixo** | 1 por caixa visível | Guardado; o Rei pode fechá-lo |

A munição tomada **entra direto na conta**, sem recolher — o Cavaleiro não sai do
lugar. O HUD mostra só quantos rounds ele tem, sem denominador: depois do primeiro
paiol não existe tamanho de carregador.

A carroça atravessa o Reino da ponta da vila até o portão, então o tiro fácil é cedo,
numa rua cheia de gente, e o difícil é tarde, longe e sob guarda.

**A Intervenção não acaba com um round no ar.** Munição zerada só encerra depois que
o céu está limpo e passa a carência — o último tiro é justamente o mais provável de
estar mirando numa carroça, e encerrar no instante em que a conta zera tirava o
reabastecimento antes dele pousar.

## Janelas de oportunidade

Três no 0.1, criadas pela rotina e nunca anunciadas na tela:

1. **Saída da fábrica / escola** — rua cheia, muitas testemunhas.
2. **Troca de turno no quartel** — soldados juntos; um Flash desarma vários.
3. **Discurso do Rei ao pôr do sol** — anunciado por sinos e pelo Espelho ("ROYAL
   ADDRESS AT SUNSET"); Rei exposto na varanda, com guardas e muitas testemunhas.

## Legibilidade

Nenhum número aparece ao jogador. Nenhum medidor, e isso inclui o painel atual
"População: apreensiva · Guardas: desorganizados", que **sai do HUD** e passa para o
debug overlay.

No 0.1 entram dois canais, nesta ordem:

1. **Micro-diálogos.** Balão estilo história em quadrinhos sobre 2–3 personagens
   próximos. Letra bem maior que a atual. Poucos por vez, para não confundir. Banco
   classificado por contexto (seca, propaganda, medo, revolta, repressão).
2. **Bandeirinhas do Rei nas janelas.** Surgem e desaparecem a qualquer momento, sem
   esperar "turno" do jogador: a bala pode estar no ar quando a primeira sobe.

Os demais canais (ruas vazias, mais guardas, transformação de estrutura) vêm depois.

## Fim da Intervenção

Três motivos:

1. **Munição zerada** → começa a **Resolução**: o HUD desaparece e o jogador fica
   15–30 s apenas assistindo, com a câmera livre e sem poder atirar. É quando as coisas
   grandes acontecem — a multidão chega ao portão, a casa rachada termina de cair, o
   Espelho muda a mensagem, o Influencer fala.
2. **Expulsão física** — soldados avançam até a posição do Cavaleiro e o empurram para
   fora ("LEAVE OUR KINGDOM!"). Nunca barra de hostilidade e tela preta.
3. **Retirada voluntária**, a qualquer momento.

O Cavaleiro não morre. Nada termina a Intervenção porque o Rei morreu, a Revolução
aconteceu ou o castelo caiu.

## Etapas

### Etapa A — Física · em grande parte pronta

| Item | Estado |
| --- | --- |
| Câmera lateral percorrendo o Reino | pronto |
| Cavaleiro à esquerda, canhão, mira por arraste, prévia de trajetória | pronto |
| Basic e Flash | pronto (Flash desarma soldado, com recuperação ligada à Coesão) |
| Casas, comércio, casas nobres, escola, fábrica, Espelho, muralha, castelo | pronto |
| Destruição recortada com entulho persistente | pronto |
| Civis e soldados com rotina simples | parcial — rotina de trajeto existe, sem animação e sem comportamento de soldado |
| Event Bus | parcial — existe e carrega severidade e Valor Narrativo |
| Ciclo diário | pronto (4 min/dia; duração a validar) |
| Reservatório, bomba, prisão, Rei no castelo | **falta** |

### Etapa B — O Reino reage · o foco agora

- ~~**Soldados de verdade**~~ — **feito.** [garrison.gd](scripts/systems/garrison.gd)
  comanda quatro soldados em três graus, conforme o quanto o Reino já levou:
  **perceber** (param, viram-se e gritam, num raio de 1000), **investigar** (vão até
  onde aconteceu) e **avançar** (acima de 6 de provocação a guarnição larga a ronda e
  caminha sobre o Cavaleiro; chegar a 150 dele encerra a Intervenção por expulsão).
  Munição tomada conta em dobro: carroça arrombada na rua é o Cavaleiro se servindo
  na frente de quem guardava.
  **A Coesão é o portão:** abaixo de 32 ninguém se forma, por mais estrago que haja —
  é aí que o Flash e o banquete do Rei passam a ter peso mecânico. Segundo Flash num
  soldado ainda desarmado e ele **deserta**: larga capacete e posto.
  Falta: reprimir a população, e Motim.
- **Rei dentro do castelo**, se deslocando entre salas e **aparecendo pelas janelas**,
  mais a varanda do discurso. Sem barra de vida: a dificuldade é achá-lo e ter linha de
  tiro.
- **Influencer como voz**, não como vida: Prestígio próprio e falas no Espelho
  disputando o mesmo fato com o Rei. Sem casa, sem rotina, sem oficina — isso vem
  depois. Duas vozes sobre o mesmo tiro é o que faz "informação não é verdade" existir.
- **Água como puzzle:** reservatório → bomba → fontes, mais o cano da vila com válvula
  fechada. Três alvos, três resultados diferentes.
- **Prisão:** abrir liberta presos que andam pelo Reino como testemunhas materiais.
- **Modelo de conhecimento mínimo:** cada NPC guarda apenas **viu / ouviu no Espelho /
  não sabe**. Nada além disso. É o mínimo para o teste Run A × Run B significar algo.
- **Mobilização mínima:** gente converge para um ponto quando Frenesi alto e Medo
  baixo; com Coesão no chão, a multidão anda até o portão. Revolução completa com
  tochas e foices não entra agora.
- **Micro-diálogos e bandeirinhas** (ver Legibilidade).
- **Resolução** depois do último tiro.
- **Debug overlay** com todos os números.
- **Estado do Reino serializável** desde já: população, recursos, dano por estrutura,
  prestígios, Coesão, Confiança, memória. Sem mapa e sem anos ainda — só a capacidade
  de salvar e reconstruir.

### Etapa C — Pigeon e propaganda

Fluxo completo do Pigeon (marcar targets → pousar dormente → CONNECT → LIVE → guardas
espantam → cooldown) e propaganda reagindo a fatos. O Pigeon entra no 0.1, por último,
e é o critério de aprovação — não um extra.

Hoje `scripts/systems/pigeon.gd` existe com 243 linhas e **nada no projeto o
instancia**.

## Fora do 0.1

Tudo isto é parte do jogo e está em `GAME_DESIGN.md`; só não entra nesta versão:

- mapa do mundo, 12 anos de campanha, viagens, evolução fora de tela, censo final;
- clima, migração, interdependência entre Reinos;
- riqueza como soma real de patrimônios das famílias;
- Impact Bomb, Incendiária e **Mechanical Falcon** (o Falcon fica no design e é
  implementado mais à frente, reaproveitando a nuvem de visão do Pigeon);
- castelo procedural por módulos recombinados;
- **população itinerante** (goblins ou criatura própria) — exige segunda espécie com
  arte, acampamento e rotina próprias;
- Fairy Defense Industries como presença no mapa;
- jogo online;
- Revolução completa, sucessões políticas complexas, simulação detalhada de famílias.

## Pontos em aberto do protótipo

- [ ] Quantidade de munição e se há seleção de loadout.
- [ ] Duração do dia (4 min hoje; o design sugere 8–10).
- [ ] Duração da Resolução dentro da faixa 15–30 s.
- [ ] Cooldown, velocidade e percepção dos guardas que deixam o Pigeon "não tão fácil".
- [ ] Thresholds de Frenesi, Medo, Confiança, Prestígio e Coesão.
- [ ] Quantos micro-diálogos simultâneos antes de virar confusão.
- [ ] Mapa físico exato do Dry Kingdom: o que fica entre Cavaleiro e castelo, e onde.
