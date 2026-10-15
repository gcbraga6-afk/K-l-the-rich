# Game Design — K\*\*l the Rich

Fonte viva das decisões fechadas de design. Consolidado a partir da conversa completa
de design (out/2026) mais as decisões tomadas depois dela. Os relatórios
(`relatorio-kill-the-rich.md`, `relatorio-castle-siege-kill-the-rich.md`) permanecem
como histórico; este documento é a direção atual. Escopo do primeiro protótipo
jogável fica em `PROTOTYPE_01.md`; o estado de implementação e as armadilhas de
engine ficam em `PROGRESSO_PROTOTIPO.md`.

> There are no missions. There are kingdoms. You don't complete them. You change them.

## Visão e premissa

Jogo 2D lateral herdeiro do Castle Siege: **tiro → física → evento → consequência →
nova oportunidade**. A diferença é que a consequência passa a ser física, social e
ambiental ao mesmo tempo.

- **Tema:** crítica ácida à concentração de renda, desigualdade, individualismo,
  propaganda, autoritarismo e crise climática.
- **Tom:** fábula política contemporânea com pano de fundo de conto de fadas, humor
  ácido e ironia escrachada. O Reino inteiro pegando fogo e o Rei inaugurando uma
  fonte nova.
- **Ideia maior:** o jogo não é destruir o castelo, é desestabilizar um sistema e
  lidar com o que nasce no lugar dele. Derrubar o castelo não melhora o Reino.
- **Formato:** sandbox sistêmico 2D, sem objetivo imposto, com campanha finita para
  provocar reflexão.
- **Crítica do salvador:** o jogador é um Cavaleiro de conto de fadas, o príncipe
  encantado externo que acredita resolver uma sociedade com atos heroicos — paralelo
  ao monarca autoritário. O jogo nunca diz isso. Demonstra.

## Princípios de design (fechados)

Funcionam como filtro para qualquer ideia nova.

1. **O Rei joga contra você pela narrativa; você joga contra o Rei pela física.**
2. **Toda força sistêmica importante tem manifestação física** que o jogador pode
   atingir, proteger, liberar ou transformar. Teste: "como isso aparece fisicamente e
   o que eu faço com um tiro?" Sem resposta, ainda não é mecânica.
3. **O jogador não escolhe consequências em menus.** Ele interfere no mundo e o mundo
   interpreta. Não existe botão "apoiar Revolução" nem "instaurar autoritarismo".
4. **O jogo não explica a contradição; ele a coloca na tela.**
5. **Nada de medidores no HUD.** Nunca FASCISMO 72% ou CLIMA 48%. O jogador vê o
   Reino mudando. A interface é o próprio Reino.
6. **Não existem finais dentro dos Reinos, só consequências.** O único final é o fim
   da campanha.
7. **O jogador não completa Reinos, ele os altera.** Sem objetivo, sem missão, sem
   briefing.
8. **O mundo não troca de cenário quando a sociedade muda; o próprio cenário se
   transforma.**
9. **O mundo produz fatos; o poder produz versões.** O jogador só interfere nos fatos
   físicos. Não existe botão "corrigir desinformação".
10. **Esperar também é uma ação.** O mundo continua enquanto você observa.
11. **Ninguém tem alinhamento político permanente.** Pessoas, famílias, Influencer e
    nobres mudam de lado várias vezes. Isso é o core do jogo.
12. **Sem pontuação moral e sem personagens protegidos.** Qualquer um pode ser
    atingido; a consequência é o que importa. Não há bônus por matar rico nem arma
    correta.
13. **A intenção do jogador não entra no cálculo.** Contam ação, testemunhas,
    consequências e narrativa.
14. **O Reino também produz problemas sozinho**, para que o Cavaleiro não seja
    automaticamente o culpado de tudo.

## Legibilidade: como o jogador percebe o sistema

Corolário do princípio 5, e condição de existência do motor social: **uma variável
que não tem manifestação física não existe para o jogador.** O motor pode ser
sofisticado; se Prestígio cair e nada mudar na tela, não caiu.

Canais de leitura, em ordem de prioridade:

1. **Micro-diálogos.** Balões estilo história em quadrinhos sobre 2–3 personagens
   próximos, por poucos segundos, sorteados de um banco classificado por contexto
   (riqueza, clima, propaganda, medo, revolta, repressão, migração). Letra grande e
   legível. Poucos por vez — muitos ao mesmo tempo confundem. É o canal mais barato e
   mais forte do jogo.
2. **Bandeirinhas do Rei nas janelas.** Individualismo e Prestígio virando pixel.
   Aparecem e desaparecem a qualquer momento, sem esperar "turno" do jogador: a bala
   pode estar no ar quando a primeira sobe.
3. **O Espelho mudando de mensagem** diante de um fato novo.
4. **Comportamento de rua:** ruas vazias ou cheias, mais ou menos guardas, patrulhas
   diferentes, soldados que gritam e apontam, multidões se formando.
5. **Transformação permanente do cenário:** ruínas que ficam, fonte seca, checkpoints,
   casas-cela, bandeiras padronizadas.

Nenhum número aparece ao jogador. Todos os números ficam num **debug overlay**
(tecla dedicada), para desenvolvimento e balanceamento.

## Estrutura macro: mapa, Reinos e campanha

A unidade básica não é a fase, é o **Reino**: uma pequena sociedade sistêmica
persistente. O mapa conecta os Reinos e o Cavaleiro circula entre eles.

**Loop macro:** Mapa → escolher Reino → Intervenção → Resolução → Mapa → tempo passa
→ consequências → próxima escolha.

### Mapa do mundo

- Estilo mapa de Mario Bros / Alex Kidd, com 8–12 Reinos.
- A miniatura de cada Reino muda conforme seu estado. Autoritarismo deixa o Reino
  preto, com bandeiras pretas de X vermelho.
- Ao selecionar, apenas informações factuais simples: nome, ano, população,
  governante, fronteiras abertas ou fechadas. Nunca "Democracia 82%".
- Ao fundo, o castelo-fábrica soltando fumaça: **Fairy Defense Industries**.

### Estados possíveis de um Reino

Vistos, nunca escritos como "ENDING".

- **Fartura:** recursos circulam, muralha perde importância, pouca repressão.
- **Revolução:** Rei perdeu poder, população organizada, ainda instável.
- **Autoritarismo:** Reino escuro, bandeiras pretas com X vermelho, checkpoints,
  soldados de preto, Alternative for the Kingdom consolidada.
- **Oligarquia:** castelo absurdamente rico, vila empobrecida, propaganda forte,
  aparentemente estável.
- **Colapso climático/econômico:** seca → falta comida → êxodo → casas vazias →
  indústria para → castelo deteriora.
- **Reino morto:** quase ninguém, fonte seca, castelo abandonado, silêncio. O regime
  protegeu o Reino até não sobrar Reino.

Nenhum estado congela. Um Reino próspero pode sofrer seca global, receber refugiados
e virar alvo de propaganda ("THEY ARE TAKING OUR RESOURCES"). Um Reino autoritário
pode ruir sozinho, por deserção e motim, e voltar a ficar acessível.

### Reinos afetam uns aos outros

- Colapso em A → migração para B; B exporta comida para A; A autoritário fecha a
  fronteira; enchente em B → refugiados em C; C culpa os recém-chegados; a indústria
  de D aumenta a pressão climática global.
- O clima não respeita fronteiras, o que deixa "PROTECT OUR BORDERS" ainda mais
  absurdo.
- **Memória:** cada Reino tem a sua, e eventos enormes circulam entre Reinos. Se você
  matou três Reis, os outros já sabem quem você é.

### Tempo e campanha

- Campanha finita de **12 anos** (YEAR I → YEAR XII). Ter fim é decisão fechada:
  evita o jogo virar abstração infinita e é o que produz reflexão.
- O tempo avança com intervenções e viagens, não com relógio real. Ninguém é punido
  por ficar dias sem jogar. A proporção exata é balanceamento.
- Você não consegue cuidar de todos os Reinos: escolher onde interferir é escolher
  onde não interferir. O mundo não espera o jogador.
- **Fora de tela não se simula NPC por NPC.** Salva-se o **estado do Reino**
  (população, recursos, riqueza, repressão, propaganda, organização coletiva, clima,
  infraestrutura, dano em cada estrutura, prestígios, memória, migração, estado
  político) e calcula-se a evolução a cada passagem de tempo. Ao voltar, o cenário é
  reconstruído desse estado — "essa é a casa que eu destruí".

**Decisão de arquitetura:** o Reino é modelado como estado serializável desde o
primeiro protótipo, mesmo sem mapa e sem anos. Custa pouco cedo e é o que permite
plugar campanha, viagens e evolução fora de tela depois sem reescrever o jogo.

### Final da campanha

- Uma última visita livre ao mapa que você produziu, sem pontuação.
- Um **censo**/crônica factual do mundo: pessoas que permanecem, quantas deixaram
  seus Reinos, quantas monarquias e regimes autoritários, Reinos abandonados, % da
  água concentrada num só Reino, aumento de temperatura, "75% da riqueza está nas
  mãos de 3 famílias" — calculado pela soma real dos patrimônios.
- Última tela: **WHAT DID YOU SAVE?**

## Intervenção: a visita a um Reino

"Fase" chama-se **Intervenção**. O Reino é persistente; a Intervenção começa e termina.

### Chegada

- O jogador escolhe o Reino no mapa, a câmera aproxima, o Cavaleiro entra pela
  lateral esquerda e para. Aparece no máximo o nome do Reino e o ano.
- Sem objetivo, sem missão, sem briefing. O Reino já está funcionando — trabalho,
  escola, patrulha, propaganda, mercado — e não precisa estar em crise.
- Não existe fase de reconhecimento separada: antes do primeiro tiro você já está
  jogando, movendo a câmera pelo Reino inteiro. A informação está no cenário (fonte
  seca fora, fontes cheias dentro).
- O jogador deduz a planta do castelo observando comportamento: soldados entram
  sempre por uma porta (quartel), caixas da Fairy Defense entram numa ala (arsenal),
  canos na parte de baixo (água), pessoas escoltadas que não saem (prisão).
- **O primeiro tiro inicia a Intervenção ativa:** Rei, soldados, propaganda e civis
  passam a reagir diretamente ao Cavaleiro. Sem troca de modo.

### Ritmo dentro da Intervenção

- O ritmo **não** é imposto por recarga lenta nem por travas. Cadência de tiro é
  curta. O que faz o jogador parar entre tiros é ter o que olhar: diálogos, pessoas
  correndo, soldados que gritam e apontam, bandeirinhas subindo, propaganda mudando.
  Quem quiser esvaziar o canhão em dez segundos consegue — e perde o jogo que estava
  acontecendo. Isso é escolha do jogador, não bloqueio do sistema.
- O mundo evolui devagar; o Cavaleiro é a perturbação violenta.
- **Sem cronômetro.** Pode-se observar vários dias. O custo de esperar é o mundo
  seguir mudando e o Frenesi decair sozinho — não se congela uma Revolução esperando
  o Rei aparecer.
- Virar o dia muda a rotina, mas não reseta o tabuleiro: dano, mortes e perdas
  permanecem.

### Ciclo diário acelerado

Um dia do Reino dura alguns minutos reais, mostrado de forma medieval pela posição do
sol: manhã → dia → entardecer → noite.

- **Manhã:** crianças vão à escola, trabalhadores à fábrica/mina/campo, troca da
  guarda, Rei toma café e reúne, primeiro boletim, mercado abre.
- **Meio do dia:** Reino mais ativo, ruas e escola cheias, mais testemunhas. Um tiro
  às 13h e um às 3h têm consequências sociais muito diferentes.
- **Discurso do Rei:** anunciado por sinos e Espelhos ("ROYAL ADDRESS AT SUNSET").
  Rei exposto na varanda, com guardas e muitas testemunhas.
- **Final da tarde:** escola e fábrica esvaziam, ruas cheias; melhor momento para
  informação circular — ex-presos contando o que viram, por exemplo.
- **Noite:** vila vazia, patrulhas diferentes, rotina privada do Rei. Salas acesas no
  castelo viram informação: "ele está naquela sala".

O jogo cria **janelas de oportunidade** pela rotina: Rei na janela, troca de turno no
quartel, escola vazia, presos no pátio, saída da fábrica, discurso, Influencer na
praça. O jogador nunca recebe "OPPORTUNITY AVAILABLE"; percebe olhando. Esperar a
escola esvaziar é seguro, mas o Frenesi cai enquanto isso — segurança × oportunidade
× tempo.

### Como a Intervenção termina

Três motivos, nunca outros:

1. **Munição acabou.** Começa a **Resolução**: o HUD desaparece e o jogador fica
   15–30 s apenas assistindo às consequências, com a câmera livre e sem poder atirar.
   Coisas enormes podem acontecer depois do último tiro. É o "agora olha o que você
   fez".
2. **Cavaleiro expulso.** Tem de ser físico: soldados avançam até a posição do
   Cavaleiro, tomam o canhão ou o empurram para fora ("LEAVE OUR KINGDOM!"). Nunca
   uma barra de hostilidade e tela preta. O Reino pode ficar temporariamente
   inacessível, o que torna o autoritarismo mecanicamente relevante.
3. **O jogador decide partir**, a qualquer momento.

Nunca termina porque o Rei morreu, a Revolução aconteceu, o Influencer tomou o poder,
começou uma ditadura ou o castelo caiu. Isso são acontecimentos, não finais. Depois,
volta ao mapa e o estado é salvo.

## O Cavaleiro e o arsenal

### O Cavaleiro

- Cavaleiro de conto de fadas, fixo no extremo esquerdo com o canhão. Um único modo de
  jogo: a câmera percorre horizontalmente o Reino. A "exploração" é observar o sistema
  funcionar.
- **Só atira.** Não conversa, não carrega, não constrói, não governa. Quer ajudar? Não
  tem botão AJUDAR, tem um canhão.
- **Não morre.** Pode ser repelido ou expulso. A ameaça é perder a oportunidade de
  interferir, não o personagem.
- **Sem RPG:** sem XP, nível, árvore de habilidades, armadura ou dinheiro. O que muda
  na campanha é o mundo, não ele. Recursos do Cavaleiro: munição, informação e
  oportunidade.
- Carrega reputação histórica sem barra: "Da última vez que ele veio, morreram sete."
- Controles: mouse mira, clique dispara, câmera percorre o Reino independente dele,
  zoom pequeno. Sem WASD no Cavaleiro.

### Munição

- Limitada por Intervenção. Munição restante **não** passa para a próxima: cada
  entrada é uma nova operação. Evita acumular munição e evita grind.
- **A munição vem do mundo, e é ela que dá ritmo ao jogo.** O Cavaleiro gasta
  munição para conseguir munição: quem atira sem ler o Reino fica sem, quem lê
  continua jogando. O fim por munição zerada deixa de ser arbitrário e vira
  resultado da própria pontaria.
- Três fontes, com riscos diferentes:
  - **Paiol / arsenal no castelo** — o prêmio grande, e o mais barulhento. Vai aos
    ares com as caixas dentro: medo enorme, dano em volta, e há funcionários civis
    no castelo. Munição comprada com Valor Narrativo contra o Cavaleiro.
  - **Carroça ou balão em movimento** — janela de tempo e acerto difícil. O
    condutor é um trabalhador: acertar a carga é ouro, acertar a boleia é um
    carreteiro morto, e o Espelho fala disso pelo resto da Intervenção. A carroça é
    da **Fairy Defense Industries** entregando ao Rei — a munição dos dois lados sai
    da mesma fábrica, e a fumaça continua igual.
  - **Arsenal fixo** — estoque finito e visível antes do ataque: dá para contar as
    caixas pela janela e decidir se vale.
- Toda fonte é finita e visível antes de ser atacada. O Rei responde protegendo o
  paiol, escoltando a carroça ou fechando o arsenal: quanto mais o Cavaleiro se
  abastece, mais caro fica se abastecer.
- A munição tomada entra direto na conta, sem recolher — o Cavaleiro não sai do
  lugar. O que ele chegou carregando é ponto de partida, não tamanho de carregador.
- Sistema de seleção (loadout) é pergunta do protótipo.
- Novas armas surgem ao longo dos anos como lançamentos da Fairy Defense Industries,
  não como upgrade por XP.

### Arsenal (cinco armas, nenhuma correta)

| Arma | Função |
| --- | --- |
| **Basic Bomb** | Destruição geral, a mais abundante e neutra. Pode libertar ou causar desastre: muralha, casa, reservatório, Rei, trabalhador, Espelho. |
| **Impact Bomb** | Deslocamento (herdada do Castle Siege): empurra grupos, quebra barricadas, abre depósitos, tira lanças. Pouca destruição estrutural. |
| **Flash** | Não letal. 1º acerto desarma o soldado (a arma cai). 2º acerto enquanto ainda desarmado: ele tira capacete e equipamento e abandona o posto (repressão ↓ permanente). Se esperar demais, ele recupera a arma. Também causa Medo, dispersa multidões — inclusive uma Revolução — e evacua lugares. |
| **Incendiária** | Muito eficaz contra estruturas, mas gera incêndio, dano ambiental, risco às casas próximas e Medo enorme. |
| **Mechanical Falcon** | Precisão, rara. Ver abaixo. |

**Mechanical Falcon:** pássaro mecânico de madeira, metal e engrenagens. O Cavaleiro
põe um capacete FPV de madeira enorme e ridículo, e aparece uma nuvem de visão (tipo
balão de pensamento) com a câmera do pássaro. Ele segue a trajetória do lançamento e o
jogador só corrige um pouco com as setas — trajetória mais correção, não voo livre.
Serve para atingir o Rei por uma janela, componentes da Torre, mecanismos, Espelhos
sem derrubar o prédio. Exige linha visual ou abertura. Exagerar na correção pode
acertar a mesa do banquete. Reaproveita a nuvem de visão do Pigeon.

### Scout Pigeon (reconhecimento)

Substituiu a luneta. Pombo lento, sem ataque, com a mesma nuvem de visão. Não pode ser
fácil demais nem virar câmera livre. Fluxo fechado:

1. Lançar; voo semiautônomo.
2. Marcar targets no caminho.
3. Pousar num Espelho e ficar dormente, sem ser percebido.
4. Esperar ou preparar um acontecimento.
5. **CONNECT:** a propaganda daquele Espelho é interrompida e passa a transmitir o
   target ao vivo. Dá para alternar apenas entre targets já marcados.
6. Guardas percebem **só quando a LIVE começa**, chegam e espantam o pombo, que volta
   ao Cavaleiro.
7. Targets e conexão zeram; o Pigeon entra em cooldown.

Função sistêmica: com o Pigeon ao vivo, quem assiste pelos Espelhos vira testemunha do
evento. A mesma ação — abrir a prisão, por exemplo — gera histórias diferentes com ou
sem transmissão. **O Pigeon não cria fatos; ele muda quem presencia fatos.**

### A ironia também atinge o Cavaleiro

- As armas vêm da **Fairy Defense Industries**, com slogans: "PRECISION PEACE™ —
  Protecting civilians through accuracy", "HUMANE FLASH™ — Because every life
  matters", "GREEN FIRE™ — Carbon-neutral destruction", "MECHANICAL FALCON™ — Zero
  civilian harm technology".
- Se o jogador erra o Falcon, o Influencer usa o slogan contra ele: "ZERO CIVILIAN
  HARM?"
- No mapa, a fábrica da Fairy Defense troca só o subtítulo conforme o regime:
  "Protecting the Kingdom™" → depois de uma revolução "Protecting Good Citizens from
  Tyranny™" → "Protecting Freedom / Stability / Peace™". A fumaça continua igual: o
  fabricante só quer lucro. Não é loja nem economia — é piada recorrente e origem da
  munição.

## Motor social

Nada de scripts tipo `if agua_destruida: start_revolution()`. Resultados emergem de
condições se encontrando. Reaproveita o motor do Castle Siege (Frenesi com
decaimento, Multidão → Revolta → Revolução reversível, Medo por raio, Motim, fuga do
Rei, Caos) e acrescenta uma camada social entre reação e consequência.

**Cadeia do motor:** evento físico → quem viu? → que narrativa foi transmitida? → quem
ganhou ou perdeu Prestígio? → Frenesi / Medo / Confiança → comportamento → novo evento
físico.

### Variáveis (invisíveis ao jogador; só no debug overlay)

- **Do Reino:** **Frenesi** (energia momentânea, sobe rápido e decai sozinha, sem
  ideologia), **Medo** (bloqueia ou desvia ação coletiva e empurra para busca de
  proteção), **Confiança coletiva** (memória lenta de "quando agimos juntos,
  funcionou").
- **Das figuras de poder (Rei e Influencer):** **Prestígio** (0–100) e **Alcance**.
- **Dos soldados:** **Coesão**.
- **De cada NPC/família:** medo pessoal, posição social, condição material, confiança
  no Rei, confiança no Influencer, estado atual e uma inclinação momentânea (Rei /
  Influencer / coletivo / neutro) que muda.
- **Do mundo físico:** poder institucional, repressão, infraestrutura narrativa,
  recursos.

População: vemos indivíduos, mas as decisões são tomadas por grupos locais e famílias.
Classe não define lado — a posição econômica só muda **como** os eventos são sentidos.

### Prestígio, Alcance e mobilização

- **Prestígio** = "quando eu falo, quantos me escutam ou seguem?". **Frenesi** =
  "quanto potencial de mobilização existe agora?". Prestígio não cria Frenesi: com
  Frenesi 8, um Influencer com Prestígio 95 gritando "FORA REI!" faz duas pessoas
  olharem.
- **Prestígio não é poder**, é capacidade de obter adesão. Rei com prestígio alto passa
  pela praça sob "Viva o Rei!" com poucos guardas; com prestígio baixo, ruas vazias,
  muitos guardas, propaganda constante.
- Prestígio muda quando a narrativa bate (ou não) com o que as pessoas veem. Cada
  evento tem uma ficha (tipo, causa, vítimas, resposta do Rei, soldados presentes,
  impacto); cada narrativa tem condições — "THE KING CANNOT PROTECT YOU" ganha força
  se houve dano civil e a resposta do Rei foi baixa. O sistema escolhe a narrativa mais
  conveniente e plausível.
- Variação = força do evento × credibilidade × alcance, com curva suave que desacelera
  nos extremos: +8 com Prestígio 20, +5 com 60, +1 com 92.
- Prestígio é parcialmente global e parcialmente local: cada NPC guarda apenas
  confiança no Rei e no Influencer. Sem matriz por personagem.
- **Alcance** vem da Torre dos Espelhos. Influência efetiva = Prestígio × Alcance:
  80 × 100% = 80; com a Torre destruída, 80 × 10% = 8.
- Modelo mental, não fórmula final: **Mobilização = Frenesi × Prestígio × Alcance ×
  (1 − Medo)**. Com Medo alto, parte da energia vira busca por proteção em vez de
  sumir.
- Duas narrativas podem disputar o mesmo Frenesi: parte vai para "FORA REI!", parte
  para "DEFEND THE KINGDOM!", parte volta para casa com medo.

### Três formas de responder a uma crise

- **Rei** — autoridade institucional: soldados, castelo, recursos, acesso à Torre,
  Prestígio.
- **Influencer** — autoridade narrativa: Prestígio e audiência, sem exército nem
  castelo. Precisa converter narrativa em poder físico: audiência → símbolos →
  mobilizações → apoio de nobres → soldados mudando de lado → disputa do castelo.
- **População** — poder coletivo: com Confiança coletiva alta, age sem líder
  carismático. Isso evita o sistema afirmar que toda ação política precisa de um
  salvador.

### Estados de mobilização

- **Multidão** = agrupamento. Não significa ser contra o Rei; pode gritar "PROTEJAM O
  REI!".
- **Revolta** = rompe com uma autoridade ou alvo local. Precisa de Frenesi alto mais um
  alvo percebido — e a propaganda disputa qual é o alvo, podendo ser o Cavaleiro.
- **Revolução** = tentativa coletiva de mudar a estrutura de poder. Precisa de Frenesi
  alto, muita gente, repressão enfraquecida e alvo comum. Visual herdado: tochas →
  foices e martelos; ações autônomas (atacar checkpoint, libertar presos, derrubar
  portão, ocupar depósito, avançar ao castelo). É difícil de sustentar e pode morrer
  sozinha.
- **Mobilização** = população organizada em defesa de uma autoridade ou movimento,
  inclusive pró-Rei.
- Uma Revolução não precisa ser contra o Rei: pode ser contra um Influencer-ditador
  anos depois.
- Revolução fracassada não reseta: casas destruídas, mortos, desertores e prestígios
  alterados ficam, e podem gerar outra coisa anos depois.

Combinações-chave:

- Frenesi alto + Confiança alta + Medo baixo → **Revolução**.
- Frenesi alto + Medo alto + Confiança baixa + propaganda forte → **terreno
  autoritário**.
- Frenesi alto + Medo alto + Rei com prestígio alto → **Rei endurece o regime** (vira
  ditador sem golpe).
- Frenesi alto + Medo alto + Influencer com mais prestígio que o Rei → **Alternative
  for the Kingdom cresce**.
- Frenesi alto + Rei e Influencer com prestígio baixo + Confiança alta → **população
  toma o castelo sem novo salvador**.
- Repressão violenta não é determinística: Medo alto + Confiança baixa → dispersão;
  Frenesi alto + Confiança alta → radicalização.

### "Salve-se quem puder" e a escalada autoritária

Estado anterior ao autoritarismo, feito de decisões individuais acumuladas:

1. A Revolta demora, fracassa ou gera caos: "Isso não vai mudar nada." "Eu só quero
   proteger minha casa."
2. Casas perto da muralha põem uma bandeirinha do Rei na janela. Soldados não as
   reprimem; talvez recebam água ou comida. A recompensa de curto prazo é real —
   essas pessoas **não** são mostradas como idiotas ou vilãs.
3. Outras copiam. Feedback: medo → abandono do coletivo → proteção individual →
   coletivo mais fraco → poder mais forte → mais medo.
4. A propaganda oferece a narrativa: "PROTEJA SUA FAMÍLIA." "ORDEM É SEGURANÇA." "NÃO
   ARRISQUE O QUE VOCÊ CONQUISTOU."
5. Surge **Alternative for the Kingdom**: começa como faixa improvisada nas casas e
   vira identidade oficial padronizada — janelas, muralha, torres, checkpoints. O Rei
   inicialmente tolera e usa o movimento porque ele enfraquece a Revolta; depois vira
   parte do aparato.
6. Transformação extrema: uniformes pretos, símbolos, checkpoints, perseguição aos "de
   fora", vizinhos denunciando vizinhos. A Intervenção fica mais difícil — mais
   soldados, mais repressão, Rei mais protegido, expulsão mais fácil.

Individualismo é uma das grandes forças invisíveis do jogo. A bandeira pode sair da
janela de novo se a realidade mudar: comida escondida cai para fora da muralha e
algumas bandeiras somem.

### Informação não é verdade

- O jogo guarda o **evento real**: o quê, quem causou, onde, testemunhas, gravidade,
  quando. As pessoas conhecem por **experiência direta** (viu) ou **narrativa
  recebida** (Torre, Rei, Influencer, boca a boca).
- NPCs só sabem a autoria se viram, estavam perto ou ouviram. A propaganda pode
  distorcer a autoria.
- **Experiência direta vence informação recebida:** quem viu presos saindo pode
  acreditar que eram assassinos, mas não que a prisão estava vazia.
- Posição importa: libertar presos atrás do castelo tem pouco efeito; na praça, efeito
  enorme.
- Rei e Influencer podem mentir descaradamente. Se testemunhas virem a contradição, o
  Prestígio cai. O motor não simula se eles sabem que mentem.
- **Memória:** eventos grandes duram anos, pequenos somem aos poucos.
- **Valor Narrativo:** cada evento tem um valor temporário — muralha 20, soldado morto
  35, casa 60, Rei morto no discurso 90, escola atingida 100. Rei e Influencer escolhem
  o fato recente mais útil à narrativa deles, a partir das tags do evento, e podem
  omitir partes ("sem mortes"). A mentira é, muitas vezes, uma verdade incompleta.

### Reação a eventos-chave

| Evento | Reação |
| --- | --- |
| **Casa destruída pelo Cavaleiro** | Frenesi ↑, Medo ↑↑. O Rei ganha prestígio só se responder fisicamente; se ninguém aparece, o Influencer raivoso usa "E onde estavam os soldados do Rei?". O mesmo tiro pode favorecer Rei ou Influencer. |
| **Trabalhador morto** | Frenesi ↑↑, Medo ↑↑, reação forte dos próximos; entra na memória do Cavaleiro. |
| **Nobre morto** | Nobreza com medo e pró-repressão; a população reage conforme a relação material com aquele nobre. Sem bônus por matar rico. |
| **Rei morto** | Frenesi ↑↑↑, mas **não** dispara Revolução. Abre um vácuo: caos, Influencer assume, Revolução — ou nada de extraordinário (a padaria continua, ninguém senta no trono). No vácuo o jogador pode, por exemplo, usar Flash em soldados sem comando. |
| **Influencer morto** | A Torre continua; surge outro Influencer com Prestígio próprio baixo, mas com o Alcance da Torre. |
| **Torre destruída** | Alcance despenca; crenças, prestígios e movimentos continuam. O Influencer pode falar na praça; o Rei pode reconstruir. |
| **Água liberada** | Confiança coletiva pode ↑, narrativa de escassez ↓. Ambíguo: pode ter destruído o reservatório do próximo verão. |
| **Presos libertados** | Frenesi ↑↑, Confiança ↑, repressão local ↓. Ex-presos são testemunhas materiais e espalham informação andando pelo Reino. O Rei responde "KNIGHT RELEASES DANGEROUS CRIMINALS". Grande estratégia de desestabilização. |
| **Flash nos soldados** | Sem mobilização, eles se recuperam; com Frenesi alto e multidão presente, abre uma janela que a população pode aproveitar. |
| **Repressão violenta** | Intimida ou incendeia, conforme Medo, Frenesi e Confiança. |

## Personagens

### Rei

- É um agente do sistema e também joga: reage periodicamente ao estado do Reino — mais
  guardas, muralhas, propaganda, repressão, soldados especiais, fechar o portão,
  proteger o depósito, distribuir um pouco de comida, fugir com parte da riqueza para
  outro Reino.
- **Pão e circo:** portões abrem, comida e artistas, "A CELEBRAÇÃO REAL COMEÇOU!".
  Parte da multidão sai, Frenesi cai, soldados se recuperam. Dilema para o jogador:
  bombardear a comida sendo entregue, atingir a Torre ou atingir o Rei na cerimônia —
  o que interrompe o evento.
- Vive **dentro do castelo** e se desloca entre salas (quarto, corredor, escritório,
  salão, varanda). **Aparece pelas janelas.** Faz discursos periódicos pela varanda,
  retransmitidos pelos Espelhos: mais em crise, ou desaparece se estiver com medo.
- Sem barra de vida e sem boss fight. A dificuldade é encontrá-lo e ter linha de tiro.
  Três oportunidades: **janela** (Falcon), **discurso** (exposto, mas com guardas e
  muitas testemunhas) e **caos no castelo** (parede derrubada revela o Rei).
- Matar o Rei no discurso: centenas veem ao vivo, e a propaganda ainda pode tentar
  "KING DIES PEACEFULLY DURING KNIGHT TERROR ATTACK".
- **Personalidade:** 2–3 tendências escondidas, nunca rotuladas na tela; o jogador
  descobre observando. Rotina parcialmente previsível, não idêntica todo dia.
  - *Hedonista:* festas privadas frequentes, banquetes, aparece muito nas janelas,
    mais fácil de matar; "A FAMÍLIA É O MAIS IMPORTANTE". Castelo com salão de festas,
    adega, cozinha, quartel menor.
  - *Paranoico:* aparece pouco, muitos guardas, poucas janelas, checkpoints cedo,
    prisão maior; "WE HAVE NOTHING TO FEAR". Repressão alta pode aumentar o Frenesi.
  - *Populista:* discursos, festas públicas, distribuição; prestígio inicial alto, mas
    mais exposto.
  - *Empresário:* produção e riqueza altas, condições ruins, ligado à Fairy Defense;
    "A RICH KINGDOM MAKES RICH CITIZENS". Castelo com mecanismos, tesouro grande, sala
    de contratos.
  - *Administrador:* trabalha até tarde, janela do escritório acesa.

### Influencer ("Vozes do Reino")

- **Um Influencer principal por Reino** — não um mundial, para não virar vilão
  principal. O antagonista é o sistema. Pode morrer (surge sucessor), migrar, virar
  governante ou perder tudo.
- Aparece nos Espelhos Mágicos, referência ao espelho dos contos de fadas. É crítica
  aos influenciadores que defendem os ricos, pregam meritocracia e atacam apoio social
  sendo eles próprios pobres ou beneficiados.
- Existe fisicamente como NPC: mora numa casa só um pouco melhor que a dos
  trabalhadores, mas no Espelho se apresenta como quase nobre — "Eu comecei sem nada.
  Qualquer um consegue." Pertence à burguesia.
- **Amplificador oportunista, não ideólogo fixo.** Com o Rei forte: "Quem trabalha
  consegue." Quando algo o atinge pessoalmente (oficina fecha, casa revistada, alguém
  preso) ou quando seu prestígio supera o do Rei, vira **raivoso**: "FORA REI!",
  gerando pico de Frenesi.
- Raiva + Confiança coletiva alta → defende a população. Raiva + Medo alto +
  Confiança baixa → procura culpados ("Precisamos de alguém forte!") e alimenta a
  Alternative for the Kingdom.
- **Plot twist:** ele pode virar o ditador. Rei com prestígio 18 cai, Influencer com 82
  grita "FORA REI!", o povo invade o castelo, e logo depois ele diz "AGORA PRECISAMOS
  RESTAURAR A ORDEM."
- Um traço escondido de oportunismo, sorteado, define se ele rompe rápido ou demora.
- Fala conforme a posição atual: pró-Rei ("Mais uma família vítima do Cavaleiro"),
  contra o Rei ("E onde estavam os soldados do Rei?"), buscando poder ("Este Reino
  precisa de liderança"). O Rei fala pouco, em pronunciamentos; o Influencer comenta
  tudo.

### Classes sociais

Quatro posições visíveis, sem rótulo escrito. Cada família tem riqueza e recursos
próprios.

- **Rei:** único, controla castelo, repressão e boa parte dos recursos.
- **Nobreza:** poucas famílias, roupas muito distintas, casas parecendo pequenos
  castelos, terras e indústria, perto do castelo. Pode abandonar o Rei — continuar com
  ele, apoiar o Influencer ou fugir com a riqueza.
- **Burguesia:** comerciantes e donos de oficina; casas parecidas com as dos
  trabalhadores, só um pouco melhores, imitando a nobreza com brasãozinho e
  torrezinhas ridículas.
- **Trabalhadores:** agricultores, operários, mineiros, construtores. A maioria.

Objetivo crítico: mostrar que a burguesia está mais perto dos trabalhadores que da
nobreza, e retratar o pobre de direita que defende o patrão por ter um pouco mais. Na
crise a nobreza fecha os portões e o burguês empobrece, ainda com a bandeirinha do Rei
na janela — "Eles vão nos proteger." "Eles fecharam o portão." "É temporário." Ele
pode mudar de lado depois. Nada de "burguesia = direita" codificado.

### Soldados

- Soldado é soldado: sem família nem psicologia individual simulada.
- Contingente físico finito com rotina: patrulha, castelo, quartel, troca de turno.
  Comportamentos: patrulhar, investigar, reprimir, perseguir o Cavaleiro ou o pombo.
  São produtores físicos de Medo — patrulha, revista, fechar uma casa com revoltosos
  dentro, prender.
- **Coesão** é a única variável do grupo. Cai com salário e comida ruins, quartel
  destruído, companheiros mortos, Rei festejando enquanto eles passam mal, uso repetido
  contra a população, prestígio do Rei caindo, Revolta forte, ver deserções. Sobe com
  recursos, Rei prestigiado, quartel funcionando, vitórias, propaganda convincente,
  medo da punição, comando funcionando. A propaganda também mira neles: "DESERTERS ARE
  TRAITORS TO THEIR FAMILIES".
- Resultados: Coesão alta → continua reprimindo; baixa → **deserção** (larga o posto e
  some); baixa + Frenesi alto + ruptura coletiva → **Motim** (vira a arma contra a
  autoridade). Desarmado ou desertor pelo Flash é um caminho separado.

### População itinerante (campanha, não protótipo)

- Uma espécie fantástica — goblins ou criatura própria — em vez de outra cor de pele,
  para evitar associação racial direta.
- Trabalham, carregam mercadorias, constroem muralhas, cuidam de jardins, minas e
  indústria; vivem em acampamentos, sem casa fixa.
- Viram bode expiatório quando falta recurso ("THEY ARE THE PROBLEM"): são evitados,
  revistados, barreiras aparecem, alguns fogem → falta mão de obra → infraestrutura
  piora → a propaganda culpa os mesmos de novo.
- Não são inerentemente pobres nem criminosos. "Estrangeiro" é construção do Reino: em
  outro Reino os humanos podem ser os estrangeiros.
- **Fora do protótipo.** Exige segunda espécie com arte, acampamento e rotina próprias;
  a mecânica é boa e barata depois, cara agora.

## Propaganda e narrativa

A disputa entre realidade física e narrativa é a chave da graça do jogo, de
preferência escrachada e irônica. Propaganda não fabrica medo do nada: ela captura
acontecimentos e muda quem a população acha que é o problema.

### Formas físicas da propaganda

- **Faixas aéreas** puxadas por dragãozinho, grifo ou balão medieval, com flâmula.
- **Bandeiras, cartazes, arautos.** Cartazes do Cavaleiro como monstro — dentes
  enormes, esmagando uma família, segurando uma bomba — que a própria população pode
  pichar ou rasgar quando percebe as contradições.
- **Espelho Real / Torre dos Espelhos:** uma Torre por Reino e vários espelhos
  receptores. Quebrar um espelho silencia aquela região; destruir a Torre derruba quase
  toda a rede. Dentro do castelo há uma **sala de controle da propaganda** —
  engrenagens, cristais, operadores, painéis satíricos tipo "TRUTH CONTROL [MORE FEAR
  +] [MORE KING +] [LESS RIOT −]", cenário, não usável. Destruí-la deixa os espelhos
  em "NO ROYAL SIGNAL".
- Comercial e político dividem a mesma infraestrutura: o Espelho alterna Royal Oil,
  notícia, discurso do Rei, Influencer e anúncio de arma humanitária.
- Hierarquia: Influencer (mensagem) → Espelho (distribuição) → Torre (infraestrutura).
  Destruir infraestrutura não destrói pessoas nem ideias.
- Destruir propaganda nem sempre resolve propaganda: "Viram? O Cavaleiro quer nos
  silenciar!"
- Depois de uma Revolução a população pode tomar a Torre — "A assembleia começa ao pôr
  do sol" — e anos depois outro grupo pode se apropriar dela. A tecnologia é a mesma;
  muda quem controla.

### Narrativa × realidade

- A propaganda ataca o Cavaleiro ("ELE VEIO DESTRUIR NOSSAS CASAS", "O CAVALEIRO QUER
  SEU EMPREGO", "O CAVALEIRO NÃO É DAQUI") e ganha credibilidade se ele estiver
  destruindo casas pobres. A população pode não aderir à Revolta, fugir, proteger
  estruturas, avisar soldados, jogar coisas nele, bloquear tiros e rotas. **Povo não é
  aliado automático.**
- Se o tiro libera a água escondida, a faixa passa, a população olha a água, olha a
  faixa e rasga a propaganda.
- O jogador desmente propaganda com física: "Não existe falta de água" mais uma parede
  quebrada revelando reservatório gigante → prestígio ↓↓.
- O Reino também gera eventos sozinho — poluição, prisões, despejos, acidentes,
  incêndio na fábrica, soldado matando civil, fronteira fechando — e a propaganda culpa
  o Cavaleiro de todo jeito: "KNIGHT ATTACK DESTROYS ROYAL FACTORY" antes do primeiro
  tiro. "Ele nem disparou." "Foi o que disseram no Espelho."
- Prisão: "THERE ARE NO POLITICAL PRISONERS IN THE KINGDOM" enquanto a prisão está
  visível; ao libertá-los, "DANGEROUS CRIMINALS RELEASED BY KNIGHT".
- **Escola:** usar Flash para evacuar antes de atingir o arsenal atrás dela salva as
  crianças, mas os Espelhos mostram em loop "KNIGHT ATTACKS SCHOOL" — tecnicamente
  verdade. O inverso também vale: criança ferida por soldados vira "THIS IS THE KING'S
  ORDER" na boca de um Influencer contrário ao Rei.
- **Hipocrisia procedural:** o sistema conhece os fatos — Rei festeiro, fome, poluição,
  riqueza concentrada, repressão — e escolhe um valor que os contradiz ou mascara:
  "FAMILY ABOVE ALL", "THE GREENEST KINGDOM IN HISTORY", "FREEDOM IS OUR GREATEST
  TREASURE", "PROSPERITY FOR EVERYONE", "NO ONE IS PERSECUTED FOR THEIR OPINIONS",
  "PEACE THROUGH STRENGTH". Às vezes diz algo verdadeiro, o que torna a mentira mais
  eficaz.
- Mensagens dos Espelhos vêm de **templates** ligados a eventos e estado. Sem IA
  generativa.

### Banco de slogans e imagens satíricas

- **Royal Oil & Dragon Co.:** torre-refinaria medieval dentro da muralha, brasão verde
  com folhas. "Energia para um Reino mais verde", "Carbon Neutral Dragon Fire™",
  "ROYAL OIL™ — Taking care of the environment" com um golfinho segurando um tonel de
  petróleo, rio preto, peixe morto e um trabalhador jogando barril no rio atrás do
  outdoor.
- **Políticos** (sátira de AfD/VOX sem copiar logos nem identidade visual): "TIME FOR
  THE KINGDOM" (o Rei na piscina, sem água fora), "THE KINGDOM. ALWAYS.", "OUR KINGDOM
  FIRST", "TAKE BACK OUR KINGDOM", "PROTECT OUR BORDERS" (trabalhadores de outros
  reinos construindo a muralha), "OUR GOLD FOR OUR PEOPLE" (carroças de ouro entrando
  no castelo), "THEY ARE TAKING OUR RESOURCES", "THE KING MEANS SECURITY", "WE WARNED
  YOU", **ALTERNATIVE FOR THE KINGDOM**.
- **Outros alvos** — greenwashing, meritocracia, austeridade, nacionalismo, culto à
  riqueza, individualismo: "O Reino Nunca Esteve Tão Próspero!", "O Calor É Uma
  Oportunidade", "ROYAL BANK — Your prosperity is our priority" (com despejo atrás),
  "HARD WORK SETS YOU FREE" (homem rico e trabalhadores entrando em fábrica cercada),
  "EVERY DROP MATTERS" (com fontes jorrando no castelo), "A HOME FOR EVERY FAMILY" (ao
  lado de barracas), "PROTECT OUR WAY OF LIFE".
- **Escola:** "WORK HARD. OBEY THE KING. DREAM BIG."; depois de uma Revolução
  "QUESTION EVERYTHING"; anos depois "QUESTION EVERYTHING EXCEPT THE KINGDOM".

### Conversas do Reino (micro-diálogos)

Balões curtos estilo história em quadrinhos, sobre 2–3 personagens próximos, por
poucos segundos, sorteados de centenas classificados por contexto: riqueza, clima,
propaganda, medo, revolta, repressão, migração, guerra, vitória. Letra grande. Poucos
por vez. O jogador escuta a sociedade mudando.

- — A fonte secou de novo. — Dentro do castelo tem três.
- — Dizem que o Cavaleiro veio roubar nosso ouro. — Que ouro?
- — Trabalhei vinte anos naquela torre. — É sua? — Não.
- — Quarenta graus outra vez. — O Rei inaugurou uma piscina.
- — Agora a fumaça tem selo verde. — Ah. Então tudo bem.
- — Ouvi dizer que ele come crianças. — Quem disse? — A faixa.
- — Dizem que falta pão porque chegaram pessoas de outro reino. — O celeiro está
  cheio. — É, mas está atrás da muralha.
- — Dizem que eles estão tomando nossos empregos. — Ele construiu sua casa.
- — Estamos construindo outra muralha. — Contra quem? — Nós, aparentemente.
- — O preço do pão subiu outra vez. — Mas meu salário não.
- **Sinal de perigo:** — Ele não é daqui. — Nenhum deles é. / — Talvez o Rei tenha
  razão. — Sobre o quê? — Não sei. Mas alguma coisa precisa ser feita.
- **Reino autoritário:** — Pelo menos estamos seguros. — Seguros de quê? — Você anda
  fazendo perguntas demais. / — Eu não concordo com tudo. — Então por que colocou a
  bandeira? — Tenho filhos.
- **Revolução:** — O portão abriu! — Então anda! / — Quem é o líder? — Achei que fosse
  você.

## Riqueza, clima e migração

### Riqueza como elemento físico

- Não é moedinha para comprar upgrade. O Rei e os ricos acumulam **coisas físicas** no
  castelo: ouro, comida, água, energia, terras, até árvores particulares enquanto o
  resto do Reino seca.
- **Dentro × fora da muralha** é a camada visual mais forte do jogo. Quanto maior a
  concentração:
  - Fora: casas deterioram → fonte seca → menos comida → barracas → abandono.
  - Dentro: jardins → fontes → banquetes → estátuas → piscinas → ouro → torres maiores
    → luxos absurdos.
- Riqueza circula de verdade: produção → comércio → imposto → castelo. Nobres têm
  terra e indústria, burgueses oficinas e comércio, trabalhadores recebem parte, o Rei
  extrai impostos. Concentração é a soma real dos patrimônios das famílias.
- O jogador altera a distribuição com física: abrir o depósito faz comida cair e
  escorrer para fora; quebrar o cano faz a água sair. "Então tinha água." "Sempre teve."

### Clima como mecânica, não decoração

- Não é punição arbitrária. Existe uma **dívida ambiental invisível**: incêndios
  gigantes, indústria, destruição indiscriminada e exploração de recursos aumentam a
  pressão climática, inclusive global entre Reinos.
- **Tempo ≠ clima:** pode chover naturalmente, mas com a crise os extremos ficam mais
  frequentes e violentos.
- Efeitos físicos:
  - *Calor extremo:* projéteis e ações mais lentos, pessoas e soldados mais lentos,
    Revolução demora a ganhar força, vegetação inflamável, reservatórios secam.
  - *Chuva:* trajetória mais difícil, visibilidade pior, chão e estruturas instáveis,
    fogo enfraquece.
  - *Vento forte:* altera muito a trajetória e espalha incêndios.
  - *Enchente:* elimina caminhos baixos, desloca personagens e destroços, isola partes
    do mapa.
  - *Seca:* fogo se propaga violentamente, água escassa.
- Destruir a indústria poluente não é automaticamente bom: explodir a Royal Oil pode
  gerar incêndio, fumaça e piora ambiental. Evita botões moralmente óbvios.

### Migração

- Pessoas deixam Reinos em colapso e chegam a outros, pressionando comida e moradia; a
  propaganda as culpa.
- Expulsar trabalhadores estrangeiros → agricultura perde mão de obra → comida escassa
  → preço sobe → o Rei culpa os estrangeiros de novo.
- Consequências atravessam regiões: destruir a mina para a indústria; incêndio na
  floresta piora a seca e o castelo passa a proteger reservatórios.

## Castelo e transformação do cenário

### O castelo como máquina

- Visto em corte lateral, parcialmente escondido. Algumas salas são vistas pelas
  janelas; outras só aparecem ao derrubar paredes. Explorar o castelo para achar coisas
  escondidas é parte do jogo.
- **Cada sistema externo tem uma infraestrutura física interna:** repressão → quartel;
  propaganda → sala de controle; água → bombas e reservatório; riqueza → tesouro;
  repressão política → prisão; autoridade → Rei. O jogador descobre que talvez nem
  precise tocar no Rei.
- Módulos: aposentos, varanda, quartel, prisão, propaganda, água, tesouro, arsenal,
  cozinha, salão de festas e, conforme o Reino, escola, enfermaria, biblioteca.
- **Híbrido procedural:** módulos desenhados à mão, recombinados em layouts diferentes
  por Reino. A personalidade do Rei muda o layout.
- Salas descobertas continuam abertas quando você volta, a menos que o Reino tenha
  reconstruído.
- Existem funcionários civis no castelo — cozinheiros, operadores, criados.
  Bombardear às cegas mata quem não é Rei nem soldado.
- **Quartel:** pegar a troca de turno e desarmar todos com um Flash.
- **Água como puzzle:** reservatório → bomba → fontes, e um cano para a vila com
  válvula fechada. Destruir o reservatório libera tudo de uma vez e perde a reserva;
  destruir a bomba para as fontes do castelo sem mandar água à vila; acertar a válvula
  talvez redirecione.
- **Escola e dilemas de trajetória:** escola encostada na muralha ou na frente de algo
  estratégico (sala do Rei, arsenal). Opções: atirar e destruir a escola; Flash para
  evacuar e depois atirar (crianças salvas, mas "KNIGHT ATTACKS SCHOOL"); esperar a
  aula acabar (perde Frenesi e janelas). Crianças existem e podem estar em perigo, mas
  **sem gore**: comunicado por ausência, ruína, reação social e memória. Escola,
  hospital, casas e mercado têm peso simbólico muito maior que uma muralha vazia.
- Soldados no quartel podem ver a contradição: comida ruim embaixo, banquete em cima →
  Coesão ↓.

### Estruturas mudam de função ao longo dos anos

O castelo não desaparece quando o Rei cai; ele muda de função. Voltar a um Reino e
reconhecer o mesmo lugar transformado é um dos momentos centrais do jogo.

| Estrutura | Caminhos possíveis |
| --- | --- |
| **Castelo** | palácio → fortaleza autoritária, espaço coletivo (escola, oficinas, biblioteca, hospital; sala do trono vira sala de aula, torre de arqueiros vira observatório, depósito vira armazém, fonte passa a abastecer a vila) ou ruína |
| **Casa** | melhora, vira cela padronizada (grades → menores → idênticas) ou abandono |
| **Muralha** | checkpoint e fronteira militarizada, ou desmontada e reaproveitada |
| **Praça** | mercado e encontro → manifestação → espaço coletivo ou palco de propaganda |
| **Indústria** | abandonada, transformada ou intensificada até degradar o ambiente |
| **Bandeiras** | decoração real → propaganda → símbolo autoritário, ou removidas e reutilizadas |

Nenhum caminho é utopia garantida: o Reino coletivo pode ter seca, falta de recursos,
disputas, chegada de refugiados, gente acumulando e pedindo alguém forte. No Reino de
propaganda forte, a população vive em casas-cela e sustenta o castelo aceitando por
medo, conveniência e incentivos — comida primeiro para quem aceita, sem revista para
quem põe a bandeira.

### Mundo do Reino

- Mundo lateral contínuo com regiões: floresta — vila — castelo e muralha — distrito
  rico — indústria — minas — porto.
- Reino com pouca autoridade central é mais fácil de interferir, mas mais imprevisível
  e com mais gente exposta. Reino autoritário tem mais bandeiras, patrulhas,
  checkpoints, Torre protegida, casas fechadas e ruas vazias.

## Produção

### Ordem geral

Parar de expandir o universo e provar que **um único Reino é divertido sem objetivo**.

1. Um Reino vertical slice (`PROTOTYPE_01.md`).
2. Implementar o Castle Siege dentro dele: canhão, física, destruição, Medo,
   soldados e desarme, Frenesi com decaimento, Multidão → Revolta → Revolução, Motim,
   Rei fugir ou morrer, Caos.
3. Persistência: matar o Rei não encerra nada; o jogo continua.
4. Prestígio e Influencer: Torre, Espelhos, sucessor, ocupar o vácuo.
5. Riqueza e classes com poucas famílias e recursos mudando de mão.
6. Só então: mapa com 8–12 Reinos, anos, viagens, evolução fora de tela, migração,
   clima, interdependência, censo final.

A campanha não é opcional nem adiada por desinteresse: ela **multiplica** o que o
Reino vale, para cima ou para baixo. Se um Reino não segura dez minutos, dez Reinos são
dez vezes o tédio. Por isso o Reino vem primeiro — mas modelado como estado
serializável desde já, para que a campanha depois seja plugar, não reescrever.

### Arquitetura

- **Godot 4 + GDScript, 2D puro.** Sem C#, sem C++ por agora. Nada de destruição estilo
  Noita.
- Sistemas pequenos conversando: Mundo (prédios, água, fogo, destruição), Personagens
  (Rei, soldados, civis, Influencer), SocialSystem (Frenesi, Medo, Confiança,
  Prestígio, Coesão), **EventSystem**, PropagandaSystem (Espelhos, Pigeon), Cavaleiro
  (canhão, munição), PersistenceSystem (estado do Reino).
- **Event Bus é a peça central.** A bomba só publica um fato: `EXPLOSION` com posição,
  raio e fonte; depois `STRUCTURE_DAMAGED` com prédio, causa, local, testemunhas,
  severidade, Valor Narrativo. Cada sistema reage ao fato. Nada de chamada direta tipo
  `casa_atingida → populacao_irritada`.
- O Pigeon não é sistema paralelo: conectado, ele só aumenta quem testemunha o evento
  daquele target.
- Reino em cenas e componentes (vila, escola, fábrica, mercado, muralha, castelo);
  castelo em módulos recombináveis.

### Repositório

- Repo oficial: `github.com/gcbraga6-afk/K-l-the-rich` (privado, branch `main`). O
  Castle Siege antigo serve apenas como referência de mecânicas.
- Documentos: **GAME_DESIGN.md** (este, visão e regras fechadas), **PROTOTYPE_01.md**
  (escopo do Dry Kingdom 0.1), **PROGRESSO_PROTOTIPO.md** (diário de implementação e
  armadilhas de engine), **ESPELHO.md** (sistema do Espelho em detalhe).

## Ideias descartadas ou substituídas

| Ideia anterior | Ficou assim |
| --- | --- |
| Objetivo visível "MAKE THE KING LEAVE" | Sem objetivo; o estado do Reino é o resultado |
| Fases como puzzle "destruir X"; unidade básica = fase | Reino persistente; a visita se chama Intervenção |
| Mundo aberto sem fim, só "NEW KINGDOM" / nova seed | Campanha finita de 12 anos com censo final |
| Relatório numérico ao sair de cada Reino | Miniatura muda no mapa + poucas infos factuais; números só no censo final |
| Simulação contínua real de NPCs fora de tela | Estado salvo + evolução por passagem de tempo |
| 1 Intervenção = 1 estação (48 ciclos) | Tempo avança com intervenções e viagens; proporção no balanceamento |
| Viajar no mapa para reabastecer munição | Munição básica por Intervenção + arsenais dentro do Reino |
| Loadout de 10 slots | Adiado para o protótipo |
| Dois momentos: andar pela vila e depois usar o canhão | Só o canhão, com câmera percorrendo o Reino |
| Ações além do tiro (conversar, carregar, construir) | Só atirar |
| Soldados vindos da população, com família na vila | Soldado é soldado; só Coesão, deserção e motim |
| Luneta de observação | Scout Pigeon |
| Avião moderno com faixa | Dragãozinho, grifo ou balão medieval |
| Royal Bread e referências literais | Removidos; sátira com equivalentes do próprio universo |
| Presos libertados mentindo ou exagerando | Descartado; são testemunhas materiais |
| Influencer único no mundo inteiro | Um Influencer principal por Reino |
| Barra de autoritarismo / fascismo / apoio popular / reputação | Emerge de variáveis, memória e sinais físicos |
| Qualquer grande multidão chamada de Revolução | Multidão, Revolta, Revolução e Mobilização separadas |
| Equação gigante de Prestígio | Algoritmo de credibilidade + curva suave |
| Cinco sistemas iniciais (Riqueza, Coletividade, Propaganda, Clima, Poder) | Frenesi, Medo, Confiança coletiva, Prestígio, Alcance, Coesão + riqueza e clima físicos |
| Matriz de 15–20 ações causa → consequência | Teste dos eventos-chave contra o motor social |
| Nome "The Thirsty Kingdom" | "The Dry Kingdom" |
| Arquivos CORE / SYSTEMS / WORLD / GAMEPLAY / IDEAS.md | GAME_DESIGN.md + PROTOTYPE_01.md |
| Fim da Intervenção por vitória ou derrota | Só por munição zerada, expulsão ou retirada |
| Ritmo imposto por recarga lenta entre tiros | Ritmo vem do mundo ter o que olhar: diálogos, animação, soldados chamando atenção |
| Munição só como contador que esvazia | Munição vem do mundo: paiol, carroça e arsenal. Gasta-se munição para conseguir munição |

## Pontos em aberto

- [ ] Quantidade de munição e sistema de seleção (loadout) — decidir jogando.
- [ ] Quanto tempo do mundo cada Intervenção ou viagem consome, e quantos Reinos o mapa
      terá.
- [ ] Números de ritmo: duração do dia, duração da Resolução.
- [ ] Como deixar o Scout Pigeon não tão fácil na prática: cooldown, velocidade,
      guardas.
- [ ] Equação real e thresholds de mobilização, Prestígio e Coesão.
- [ ] Por quanto tempo um Reino fica inacessível após a expulsão.
- [ ] Espécie da população itinerante: goblins ou criatura própria.
- [ ] Nome final do "Pão e circo" do Rei.
- [ ] Lideranças que surgem organicamente da população.
- [ ] Jogo online — hipótese levantada, não decidida.
- [ ] Desenhar o mapa físico exato do Dry Kingdom.
