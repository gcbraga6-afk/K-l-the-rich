# Espelho e propaganda

> **Estado deste documento.** A decisão ainda está sendo construída. Isto registra
> a direção conversada, não cânone fechado. O que já está decidido aparece como
> decidido; o resto aparece como pendente, com o nome de quem decide: o Gabriel.
>
> O `GAME_DESIGN.md` continua valendo. Este documento detalha a seção
> "Espelhos e propaganda" sem substituí-la.

## O que o Espelho é

O Espelho é o **meio de comunicação de massa do Reino**. Ele não informa: ele diz
à população o que os acontecimentos significam.

A regra que governa tudo vem do `GAME_DESIGN.md` e não muda:

> Propaganda nao cria realidade do nada. Ela enquadra acontecimentos reais,
> explorando medo, conveniencia, experiencia material, Prestigio e contradicoes
> visiveis.

Ou seja: o Espelho **nunca nega o fato**. Ele admite e reatribui a culpa. É daí
que vem a piada e o desconforto — a casa cai no primeiro plano enquanto a placa
explica por que a culpa é de quem atirou.

## Quem fala

**Decidido — primeira etapa:** o Espelho carrega a voz do **Reino**. Propaganda
institucional, pronunciamentos, instruções, emergência.

**Decidido:** o **Cavaleiro invade o canal com o Pigeon**. O pombo pousa dormente
sem ser percebido; os guardas só notam quando a transmissão começa. É a LIVE
descrita no `GAME_DESIGN.md` — ao vivo, sem gravação nem replay.

**Segunda etapa:** o **Influencer**. Uma pessoa, não o sistema — o Espelho é o
meio, ele é um dos conteúdos. Começa legitimando o regime e pode virar contra ele
por oportunismo, não por conversão moral. Fica para depois.

**Em aberto:** outras vozes do relatório — Ministério, Exército, noticiário,
publicidade, Alternative for the Kingdom, rebeldes.

## O totalitarismo já está no começo

A ideia mais forte do relatório, e a que mais muda o tom do jogo: a propaganda
**não vira** autoritária quando a crise chega. Ela já era, embalada como cuidado.

A linguagem endurece sem trocar de identidade. A mesma promessa de proteção,
levada passo a passo até a vigilância:

```
THE KING CARES FOR YOU.
THE KING PROTECTS YOU.
HELP THE KING PROTECT YOU.
REPORT SUSPICIOUS ACTIVITY.
NOTHING TO HIDE, NOTHING TO FEAR.
```

E a mesma ideia de unidade, levada até a ameaça:

```
TOGETHER UNDER THE CROWN.
NOW MORE THAN EVER: TOGETHER UNDER THE CROWN.
TO DIVIDE THE KINGDOM IS TO HELP THE ENEMY.
WHOEVER IS NOT WITH THE KINGDOM IS AGAINST IT.
```

O jogador não assiste o regime virar fascista. Ele percebe, pela crise, que a
linguagem paternalista do início já continha isso.

## Biblioteca de mensagens

Em inglês, como aparecem na tela. **Nenhuma destas está implementada** — o tom
ainda não foi aprovado. Ficam aqui como matéria-prima.

### NORMAL — antes de qualquer ataque

```
STRONG KING. KIND HAND.
ONE KINGDOM. ONE PEOPLE. ONE KING.
A SAFE KINGDOM IS A HAPPY KINGDOM.
ORDER BRINGS PROSPERITY.
WORK. ORDER. PROSPERITY.
EVERY SUBJECT HAS THEIR PLACE.
THE KING SEES. THE KING HEARS. THE KING PROTECTS.
THE CROWN UNITES WHAT CHAOS DIVIDES.
```

O banal entra junto, e é essencial: se tudo no Espelho for política explícita,
ele vira painel de slogan em vez de mídia.

```
ROYAL LOTTERY — YOUR CASTLE COULD BE NEXT!
BUY LOCAL. BUY ROYAL.
THE NEW CARRIAGE. NOW WITH 12% MORE HORSE.
```

### ATAQUE — a programação é interrompida

```
BREAKING: THE CASTLE IS UNDER ATTACK.
AN ATTACK ON THE KING IS AN ATTACK ON ALL OF US.
THE SITUATION IS UNDER CONTROL.
THERE IS NO REASON TO PANIC.
```

A graça está na contradição com o que o jogador vê atrás da placa. Prédio
desabando: `THE KINGDOM REMAINS STRONG.` Soldados fugindo: `OUR BRAVE TROOPS ARE
ADVANCING.` Metade da cidade em chamas: `MINOR DISTURBANCES REPORTED.`

### MEDO — o discurso troca de "está tudo bem" para "estamos ameaçados"

```
THE KINGDOM IS UNDER ATTACK.
REPORT SUSPICIOUS BEHAVIOUR.
YOUR NEIGHBOUR COULD BE A REBEL.
ORDER IS FREEDOM.
SECURITY REQUIRES SACRIFICE.
LOYAL CITIZENS HAVE NOTHING TO FEAR.
```

Aqui aparece a dinâmica mais cruel do sistema: **quanto mais caos o jogador
produz, mais material o Reino tem para justificar autoritarismo.**

### COLAPSO e VÁCUO

Pendentes, e dependem do Influencer e da disputa de Prestígio.

## Quando o Cavaleiro toma o canal

A LIVE do Pigeon não torna o Cavaleiro "o lado certo". A mesma infraestrutura
serve a quem a controla — e isso é o ponto político, não um detalhe técnico:

```
👑 caiu.
🪞 continuou.
```

## O que o jogador pode atacar

| alvo | efeito | estado |
|---|---|---|
| Espelho | silencia a propaganda **naquela região** | **feito** — 3 tiros, com teste |
| Torre de Transmissão | derruba a rede inteira de Espelhos | não existe |
| Dragão de propaganda | leva a mensagem até o jogador, e pode ser abatido | não existe |

Destruir a Torre **não mata o Influencer**. Ele é pessoa, não infraestrutura:
pode aparecer na praça e continuar falando. Destruir mídia não é destruir ideia.

## Dragão de propaganda

Ideia do Gabriel, fora do escopo original. Um dragão com faixa atravessa o céu ao
fundo, com névoa de profundidade, e pode ser abatido.

Vale porque hoje a propaganda é **estática e num ponto fixo** — o jogador pode
simplesmente não ir até lá. O dragão leva a propaganda até ele, e abater vira
escolha.

Pendente, e é o que decide se isso é mecânica ou enfeite: **o que acontece
quando ele cai.** Se não mexe em medo, raiva ou prestígio, é alvo bonito. Se
mexe, é a primeira vez que o jogador ataca a narrativa em vez dos tijolos.

Arte em `assets/propaganda/`: cinco poses, faixa vazia de propósito.

## Pendências

1. **Tom das frases.** O Gabriel não aprovou as atuais. Registros de direção:
   ordem seca, paternal, culpa invertida, burocrática fria.
2. **O que acontece ao abater o dragão.**
3. **Prestígio** como disputa entre Rei e Influencer — segunda etapa.
4. **Torre de Transmissão.**
