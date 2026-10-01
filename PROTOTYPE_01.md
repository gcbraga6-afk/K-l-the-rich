# Prototype 0.1 - The Dry Kingdom

Objetivo: provar que um Reino lateral pequeno funciona como brinquedo sistemico antes de expandir para campanha, mapa do mundo ou economia entre Reinos.

## Escopo

The Dry Kingdom e uma unica cena 2D horizontal no Godot 4.

Nao inclui:

- world map;
- multiplos Reinos;
- objetivos ou missoes;
- final de fase tradicional;
- campanha de anos completa;
- todas as familias de armas;
- toda a simulacao politica final.

Inclui o suficiente para testar:

- Cavaleiro fixo a esquerda;
- castelo a direita;
- camera horizontal;
- mira e tiro;
- trajetoria de projetil;
- dano/destruicao basica;
- rotina autonoma;
- Event Bus;
- social minimo;
- propaganda;
- Pigeon em milestones.

## Layout

Mapa pequeno, cerca de 4 a 5 larguras de tela:

```text
KNIGHT -> village -> school -> factory -> mirror -> wall -> castle
                                                        |
                                                        reservoir
                                                        barracks
                                                        king
                                                        prison
```

Elementos iniciais:

- vila;
- escola;
- fabrica;
- Espelho;
- muralha;
- castelo;
- reservatorio;
- quartel;
- prisao;
- Rei;
- soldados;
- civis de grupos diferentes.

## Controle

Direcao inicial:

- mouse mira o canhao;
- clique dispara;
- camera move horizontalmente;
- zoom pequeno pode existir;
- selecao de municao quando houver mais de uma familia ativa.

O Cavaleiro permanece sempre na esquerda. A camera pode viajar pelo Reino independentemente dele.

## Tempo

- Sem limite de tempo de intervencao.
- Ciclo diario acelerado.
- NPCs seguem rotinas simples.
- A intervencao termina por municao 0, expulsao fisica ou retirada voluntaria.
- O Cavaleiro nao morre.

## Municao

O prototipo comeca com:

- Basic;
- Flash.

A quantidade de municao, composicao do loadout e ritmo entre disparos ainda sao perguntas do prototipo. O objetivo e descobrir qual limite produz leitura, tensao e consequencia sem transformar o jogo em puzzle fechado.

## Rotina autonoma minima

NPCs devem ter rotina simples, visivel e interrompivel:

- trabalhadores vao entre casa, fabrica e vila;
- crianças podem aparecer perto da escola ou casas;
- soldados patrulham, guardam muralha, quartel, reservatorio e castelo;
- nobres ou burgueses circulam em zonas mais protegidas;
- Rei permanece associado ao castelo;
- Espelho transmite propaganda normal quando nao ha LIVE.

Crianças podem estar em risco, mas sem gore.

## Event Bus

Primeira arquitetura a provar:

```text
tiro -> impacto -> evento -> reacao fisica/social/narrativa
```

Eventos iniciais sugeridos:

- PROJECTILE_FIRED;
- STRUCTURE_HIT;
- STRUCTURE_DESTROYED;
- PERSON_HIT;
- SOLDIER_DISARMED;
- RESERVOIR_OPENED;
- MIRROR_DAMAGED;
- PROPAGANDA_BROADCAST;
- PIGEON_TARGET_MARKED;
- PIGEON_CONNECTED;
- LIVE_STARTED;
- LIVE_ENDED;
- PIGEON_SCARED_AWAY.

Campos importantes:

- tipo;
- alvo;
- causa;
- local;
- severidade;
- testemunhas;
- Valor Narrativo.

## Social minimo

O prototipo deve testar uma versao pequena de:

- Frenesi;
- Medo;
- Prestigio do Rei por grupo;
- Prestigio do Influencer por grupo, se o Influencer entrar neste milestone;
- Coesao dos soldados;
- repressao;
- deserção;
- Motim.

Nao precisa provar a campanha inteira. Precisa mostrar que eventos fisicos alteram comportamento e percepcao de forma legivel.

## Propaganda e Espelho

O Espelho tem apenas dois estados:

- PROPAGANDA normal;
- LIVE do Cavaleiro.

Nao ha canais.

Nao ha gravacao, captura ou replay. LIVE e ao vivo.

Propaganda reage a fatos:

- casa atingida pode virar narrativa contra o Cavaleiro;
- reservatorio aberto pode enfraquecer narrativa do Rei;
- soldados desorganizados podem reduzir percepcao de ordem;
- escola ou crianças em risco podem ter alto Valor Narrativo.

## Pigeon milestone

Implementar depois do tiro/camera/dano/eventos basicos.

Regras definitivas para validar:

- voo semiautonomo;
- targets podem ser pessoas ou estruturas;
- Pigeon pousa dormente no Espelho sem ser percebido;
- jogador prepara ou espera uma acao;
- CONNECT inicia LIVE;
- guardas percebem apenas quando LIVE comeca;
- durante LIVE, alternar apenas entre targets previamente marcados;
- guardas espantam o Pigeon;
- Pigeon retorna ao Cavaleiro;
- targets, percepcao e conexao zeram;
- cooldown antes de novo uso.

Pergunta do prototipo: a preparacao/espera antes do CONNECT gera tensao interessante?

## Milestones sugeridos

1. Cena lateral: camera, Cavaleiro, canhao, trajetoria e impactos.
2. Destruicao basica: estruturas civis persistem danificadas/destruidas.
3. Rotina autonoma: civis, soldados e ciclo diario acelerado.
4. Event Bus: eventos fisicos alimentam sistemas simples.
5. Social minimo: Frenesi, Medo, Coesao e primeiras respostas coletivas.
6. Propaganda: Espelho em PROPAGANDA normal reagindo a fatos.
7. Pigeon: marcar targets, CONNECT, LIVE, expulsao e cooldown.
8. Fechamento de intervencao: municao 0, expulsao fisica ou retirada.

## Fora do 0.1

- campanha com varios Reinos;
- mapa do mundo;
- Fairy Defense Industries completa;
- Incendiary, Impact completo e Mechanical Falcon;
- censo final;
- economia inter-Reinos;
- clima global;
- sucessoes politicas complexas;
- simulacao detalhada de familias.

## Frase-guia

> There are no missions. There are kingdoms. You don't complete them. You change them.

