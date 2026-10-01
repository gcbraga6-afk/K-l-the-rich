# Relatório consolidado: K**l the Rich

Documento de continuidade do projeto a partir da conversa "Reformular Castle Siege" e da releitura do material de Castle Siege enviado na conversa.

Nota de continuidade em 1 de outubro de 2026: as decisoes fechadas posteriormente foram consolidadas em `GAME_DESIGN.md` e `PROTOTYPE_01.md`. Este relatorio permanece como historico e contexto; os novos documentos funcionam como referencia operacional mais direta para o design atual e para o Prototype 0.1.

## 1. Conceito central

K**l the Rich evolui a partir de Castle Siege, mas deixa de ser apenas uma fase com objetivo fechado e passa a ser um jogo sistêmico sobre sociedades em transformação.

O jogador controla um Cavaleiro de conto de fadas, uma figura externa ao Reino, armado principalmente com um canhão. Essa escolha é parte da crítica: o "herói salvador" entra em sociedades complexas acreditando que pode resolver tudo com ações físicas, precisas ou violentas. O jogo não precisa explicar essa contradição em texto; ela deve aparecer nas consequências.

Princípio central:

> O jogador não escolhe resultados políticos em menus. Ele escolhe ações físicas. O sistema produz consequências sociais.

Exemplos:

- O jogador não aperta "apoiar revolução"; ele destrói a porta de um depósito de comida, abre um reservatório de água, derruba uma barricada ou desarma soldados.
- O jogador não aperta "instaurar autoritarismo"; ele pode gerar medo, atacar moradores, deixar a propaganda funcionando, proteger estruturas do Rei ou destruir formas de organização coletiva.
- O jogo não diz se o jogador ganhou ou perdeu; mostra o mundo que suas ações ajudaram a produzir.

Outro princípio fechado:

> Não existem finais dentro dos Reinos. Existem consequências.

O único encerramento real acontece no fim da campanha, quando o jogo mostra um censo/crônica do mundo.

## 2. Relação com Castle Siege

### Herdado de Castle Siege

A releitura do Castle Siege confirmou que o projeto antigo já possuía um motor social importante e que ele deve ser reaproveitado antes de inventar sistemas novos.

Elementos já documentados no Castle Siege:

- Excitação/Frenesi com decaimento ao longo do tempo.
- Progressão social: civis se agrupam, formam Multidão, podem evoluir para Revolta e Revolução.
- Progressão reversível: Revolta e Revolução perdem força com o tempo, especialmente sob repressão.
- Soldados armados produzem repressão física e ajudam a reduzir agitação.
- Medo como força social relevante.
- Motim de soldados.
- Caos como resultado de combinação de acontecimentos, não como consequência automática de um único evento.
- Possibilidade de o cenário ficar sem líder.
- Ausência do Rei não gera Caos automaticamente.
- Fuga/morte/remoção do Rei eram elementos compatíveis com o motor.
- No Castle Siege original, a fase tendia a encerrar quando o objetivo era atingido.

### Novo em K**l the Rich

K**l the Rich não deve substituir esse motor por um sistema completamente novo de muitas barras. A decisão tomada foi adaptar o que já existe e acrescentar apenas o necessário:

- Persistência dos Reinos depois da intervenção do jogador.
- Campanha com vários Reinos conectados por mapa.
- Tempo avançando quando o Cavaleiro viaja/intervém.
- Riqueza persistente por famílias/classes.
- Prestígio de personagens que disputam liderança.
- Influencer/Voz do Reino como figura física e narrativa.
- Torre dos Espelhos como infraestrutura de propaganda.
- Propaganda que enquadra acontecimentos reais, em vez de controlar magicamente a população.
- Deserção de soldados como adição nova, distinta de Motim.
- Possibilidade de sociedade continuar funcionando sem Rei.
- Possibilidade de o jogador continuar interferindo depois da morte/fuga do Rei.

## 3. Estrutura do mundo e campanha

O jogo deve ter uma campanha finita, casual e legível, com algo como 8 a 10 Reinos. O número inicial recomendado é 8, para que cada Reino tenha identidade econômica, visual e social clara.

Estrutura definida:

- Mapa do mundo inspirado em Mario/Alex Kidd.
- O jogador começa em um Reino e vai liberando caminhos.
- Depois de descoberto, um Reino pode ser revisitado.
- Viajar consome tempo.
- Reinos continuam evoluindo enquanto o jogador está em outros lugares, por simulação abstrata/eventos, não por simulação contínua em tempo real.
- A campanha deve ter duração explícita, possivelmente 12 anos/ciclos.
- O jogador deve ver algo como `YEAR 3 / 12`.
- No fim, há um último olhar sobre o mundo e depois um censo/crônica factual.

Cada Reino começa com diferenças materiais pequenas ou moderadas, não com ideologias prontas. Exemplos de diferenças iniciais:

- água abundante ou escassa;
- agricultura fértil;
- minas;
- indústria;
- comércio;
- população maior;
- castelo muito rico;
- desigualdade inicial maior;
- propaganda mais forte;
- organização coletiva mais frágil ou mais forte.

Decisão importante: evitar Reinos já definidos como "fascista", "comunal", "capitalista" etc. O objetivo é que pequenas diferenças materiais, somadas às ações do jogador e à passagem do tempo, produzam trajetórias diferentes.

## 4. Cavaleiro e gameplay

O jogador é um Cavaleiro de conto de fadas.

Função conceitual:

- representa o salvador externo;
- contrasta com a figura do monarca/salvador autoritário;
- não governa, não legisla e não escolhe políticas;
- interfere no mundo físico.

Decisões fechadas:

- Não haverá dois modos separados de "andar pela vila" e "atacar com o canhão".
- O gameplay principal permanece concentrado no canhão/tiro/interferência física.
- A exploração acontece pela observação do cenário, movendo a câmera por um Reino grande em visão lateral.
- O jogador observa pessoas, propaganda, soldados, água, trabalho, riqueza e conflitos acontecendo antes de atirar.
- A limitação "só atirar/interferir fisicamente" é uma força do jogo, não uma limitação a ser corrigida.

Loop sugerido:

1. Mirar.
2. Atirar.
3. Impacto físico.
4. O Reino reage por alguns segundos.
5. Pessoas conversam, correm, se agrupam, fogem, aderem, resistem.
6. O Rei/propaganda/repressão respondem.
7. O jogador lê a nova situação e decide o próximo tiro.

Foi sugerido um ritmo de 8 a 15 segundos de reação entre tiros, preservando o DNA de Castle Siege.

Possibilidades físicas:

- destruir propaganda;
- abrir reservatório;
- liberar depósito;
- destruir barricada;
- libertar pessoas presas;
- atacar soldados;
- atingir casas;
- matar o Rei;
- matar o Influencer;
- quebrar espelhos;
- destruir ou tomar a Torre dos Espelhos;
- causar incêndio ou dano ambiental se agir de forma descuidada.

Reinos autoritários podem expulsar o Cavaleiro. Isso não é Game Over. O Reino continua no mapa, e para alterá-lo depois o jogador precisará de ações mais cirúrgicas.

## 5. Persistência dos Reinos

A unidade básica deixa de ser "fase" e passa a ser "Reino".

Um Reino não tem vitória definitiva. Ele tem estado histórico.

Possíveis estados visuais/sistêmicos:

- fartura;
- Revolta;
- Revolução;
- monarquia estável;
- oligarquia;
- autoritarismo;
- vácuo de poder;
- colapso climático/econômico;
- abandono;
- sociedade sem Rei;
- castelo transformado em espaço público;
- castelo ocupado por outro líder;
- reino empobrecido mas funcionando;
- reino aparentemente seguro, mas repressivo.

O mapa deve refletir isso visualmente. Exemplo: um Reino autoritário pode ficar escuro/preto, com bandeiras pretas e um X vermelho, checkpoints e soldados de preto.

Quando o jogador volta a um Reino, ele deve reconhecer o mesmo lugar, mas transformado.

Princípio visual:

> O mundo não troca de cenário quando a sociedade muda. O próprio cenário se transforma.

## 6. Classes sociais e riqueza

O jogo deve ter classes sociais fisicamente identificáveis, mas sem comportamento político fixo programado.

Classes/posições definidas:

- Rei: único; controla inicialmente castelo, repressão, recursos e poder institucional.
- Nobreza: poucas famílias; mansões/pequenos castelos, roupas distintas, riqueza concentrada, proximidade física do castelo.
- Burguesia: comerciantes, donos de oficina, pequenos proprietários; casas um pouco melhores que as dos trabalhadores, elementos visuais imitando a nobreza.
- Trabalhadores: agricultores, operários, mineiros, construtores etc.; maior parte da população.

Decisão conceitual:

> Não programar "burguesia = apoia Rei" ou "trabalhador = Revolução".

A posição econômica cria vulnerabilidades e incentivos. O comportamento emerge de riqueza, medo, propaganda, repressão, experiência vivida e organização coletiva.

Ideia importante:

- A burguesia deve parecer visualmente mais próxima da nobreza no desejo/símbolo, mas materialmente mais próxima dos trabalhadores.
- Em crise, a nobreza se isola atrás das muralhas.
- A pequena oficina fecha.
- A casa burguesa deteriora.
- O personagem ainda pode manter uma bandeira real na janela por medo, conveniência ou autoimagem.

Riqueza deve ser real e circulante:

- trabalhadores produzem;
- oficinas/indústrias/comércio processam;
- comerciantes acumulam;
- impostos e extração levam recursos ao castelo;
- nobres possuem terra/indústria/patrimônio;
- Rei extrai impostos/recursos;
- famílias enriquecem, empobrecem, migram ou abandonam casas.

Isso permite que o censo final diga algo como:

- "75% da riqueza está nas mãos de 3 famílias."
- "61% das reservas de água estão atrás de muralhas."

Esses números devem ser calculados da campanha, não frases decorativas pré-escritas.

## 7. Motor social herdado/adaptado

### Excitação/Frenesi

Origem: Castle Siege.

No novo jogo, Frenesi continua sendo energia social momentânea:

- sobe rápido com acontecimentos;
- decai naturalmente com o tempo;
- não equivale automaticamente a Revolução;
- é combustível social disponível.

Eventos que podem aumentar Frenesi:

- casa destruída;
- repressão;
- depósito aberto;
- Rei foge;
- transmissão revoltante;
- incêndio;
- Cavaleiro liberta presos;
- soldado entra em Motim;
- água/comida do castelo é revelada à população.

Nova leitura:

> Frenesi alto não diz para onde a raiva vai. A propaganda, o medo, o prestígio e a experiência coletiva ajudam a direcionar essa energia.

### Multidão

Origem: Castle Siege.

Multidão é o primeiro comportamento coletivo. Não significa automaticamente que as pessoas estão contra o Rei. Significa que estão mobilizadas.

Uma Multidão pode inclusive gritar:

> "PROTEJAM O REI!"

Ela surge quando acontecimentos fazem pessoas saírem de casa e se agruparem.

### Revolta

Origem: Castle Siege, com adaptação.

Para Multidão virar Revolta, a proposta atual é:

> Frenesi alto + alvo percebido.

O alvo pode variar:

- Rei;
- nobreza;
- Cavaleiro;
- trabalhadores de fora;
- soldados;
- Influencer;
- "inimigos" definidos pela propaganda;
- estruturas de riqueza/repressão.

Propaganda entra justamente aqui, tentando enquadrar quem é o culpado.

Exemplo:

- O Cavaleiro destrói uma mansão da nobreza.
- Sem propaganda forte, moradores podem concluir: "Eles têm tudo e nós não temos água."
- Com propaganda forte, a Torre dos Espelhos pode dizer: "O Cavaleiro está destruindo nosso Reino."
- A raiva continua alta, mas pode ser redirecionada contra o Cavaleiro.

### Revolução

Origem: Castle Siege, com adaptação.

Revolução deve continuar difícil de sustentar. Quanto mais avançado o estado social, mais difícil manter sua força.

Condição proposta:

> Frenesi alto + bastante gente mobilizada + repressão enfraquecida + alvo comum.

A Revolução não precisa significar automaticamente "povo contra Rei". Ela é um estado de mobilização social extrema.

Possibilidades:

- Revolução contra o Rei;
- mobilização popular a favor do Rei;
- Revolução contra um Influencer que tomou o poder;
- Revolução que derruba um regime autoritário;
- Revolução que é capturada por outro salvador.

Ações autônomas possíveis em Revolução:

- atacar checkpoint;
- libertar presos;
- derrubar portão;
- ocupar depósito;
- avançar para o castelo;
- provocar Motim entre soldados;
- tomar a Torre dos Espelhos;
- transformar estruturas do Reino.

### Medo

Origem: Castle Siege.

Medo continua sendo um freio/desvio central.

Soldados produzem medo fisicamente:

- patrulham;
- revistam;
- cercam casas;
- prendem revoltosos;
- reprimem multidões;
- fecham ruas;
- protegem depósitos;
- intimidam a população.

Combinações importantes:

- Frenesi alto + Medo baixo: pessoas ficam na rua e se mobilizam.
- Frenesi alto + Medo alto: pessoas querem mudança, mas podem voltar para casa, procurar proteção ou aderir ao "salve-se quem puder".
- Medo alto + propaganda forte + prestígio alto do Rei: o Rei pode endurecer o regime.
- Medo alto + propaganda forte + prestígio do Influencer maior que o do Rei: Alternative for the Kingdom pode crescer.

### Repressão

Origem: Castle Siege.

Repressão é física. Ela aparece como soldados, prisões, checkpoints, muralhas, barricadas, patrulhas e casas cercadas.

O jogador pode interferir fisicamente na repressão:

- quebrar barricadas;
- desarmar soldados;
- libertar pessoas cercadas;
- destruir checkpoint;
- bloquear patrulha.

Mas atacar indiscriminadamente pode aumentar medo e fortalecer narrativas autoritárias.

### Motim

Origem: Castle Siege.

Motim já estava documentado. Soldados podem se voltar contra a autoridade.

Em K**l the Rich, Motim deve continuar como possibilidade distinta de deserção.

### Deserção

Novo em K**l the Rich.

Correção importante feita na conversa: deserção não estava documentada no Castle Siege. Motim estava.

Deserção deve significar:

- soldado abandona o posto;
- vai embora;
- desaparece;
- deixa de participar da repressão.

Não precisa simular família ou psicologia profunda de soldados. A decisão foi não complicar esse ponto.

Estados possíveis do soldado:

- permanece leal;
- deserta;
- entra em Motim.

### Caos

Origem: Castle Siege.

Caos não é consequência automática da ausência do Rei. Surge de combinação de acontecimentos.

No novo jogo, isso permite:

- Rei morre → vácuo → caos;
- Rei morre → Influencer ganha prestígio → toma poder;
- Rei morre → Motim → Revolução;
- Rei morre → ninguém assume → pessoas continuam vivendo;
- Rei foge → nobreza disputa recursos;
- Rei foge → soldados ficam sem comando;
- Rei foge → sociedade reorganiza estruturas;
- Rei foge → outro grupo toma a Torre dos Espelhos.

## 8. Prestígio

Novo em K**l the Rich.

Prestígio é uma variável interna invisível para personagens capazes de disputar liderança, principalmente:

- Rei;
- Influencer;
- talvez futuras lideranças, ainda não decididas.

Definição proposta:

> Prestígio = Visibilidade + Credibilidade + Apoio + Acesso ao poder.

O Rei começa com muito poder institucional e prestígio tradicional.

O Influencer começa com visibilidade/audiência, mas menos poder institucional.

Prestígio não é apenas popularidade. É capacidade de aparecer como resposta legítima à crise.

Como sobe:

- personagem "acerta" narrativas que depois parecem verdadeiras;
- promete segurança e consegue entregar segurança;
- denuncia crise antes que ela piore;
- aparece como figura forte em momento de medo;
- usa infraestrutura de propaganda com eficácia;
- ocupa símbolos de poder.

Como cai:

- promete prosperidade enquanto a vila deteriora;
- promete ordem enquanto o Reino entra em caos;
- propaganda contradiz a experiência física da população;
- estruturas que sustentavam sua imagem são destruídas;
- outro ator passa a interpretar melhor a crise.

Caminhos importantes:

- Rei forte + medo alto + propaganda forte → o próprio Rei endurece o regime.
- Rei enfraquecido + Influencer com prestígio alto + medo alto + coletividade baixa → Influencer pode romper com o Rei e ocupar o poder.
- Rei fraco + Influencer fraco + coletividade alta → população pode tomar o castelo sem surgir salvador individual.

Decisão conceitual:

> Autoritarismo não deve ser um personagem. É um estado possível do Reino.

O ditador pode ser o Rei, o Influencer ou outro ocupante futuro do poder.

## 9. Influencer, Torre dos Espelhos e propaganda

### Influencer

Novo em K**l the Rich.

A ideia nasceu de um espelho mágico de conto de fadas usado como meio de propaganda. Em vez de televisão/celular/internet, o Reino possui espelhos mágicos.

O Influencer:

- é uma figura física do Reino, não apenas uma imagem;
- pode morar numa casa comum ou burguesa;
- talvez tenha roupas melhores e símbolos que imitam a nobreza;
- aparece nos espelhos como "Voz do Reino";
- pode defender meritocracia, ordem, trabalho duro, crítica a apoios sociais etc.;
- não é ideólogo fixo;
- amplifica o estado social do Reino.

Decisão: retirar a ideia literal de "Royal Bread" como programa central nomeado. A conversa concluiu que referências reais ou literais demais podem envelhecer o jogo. Melhor usar equivalentes do mundo ficcional quando necessário.

O Influencer pode começar defendendo o Rei:

- "Quem trabalha consegue."
- "O Reino está prosperando."
- "Precisamos trabalhar, não reclamar."

Mas, se for atingido pela crise, pode virar "raivoso":

- perde oficina;
- soldados revistam sua casa;
- perde patrimônio;
- alguém próximo é preso;
- nobreza fecha portões;
- ele é censurado.

Então pode passar a dizer:

- "FORA REI!"
- "Eles mentiram para nós!"
- "Precisamos recuperar nosso Reino."

Isso não significa que virou revolucionário. Dependendo do estado do Reino:

- raiva + confiança coletiva alta → pode apoiar Revolta/população;
- raiva + medo alto + confiança coletiva baixa → pode procurar culpados e ajudar a Alternative for the Kingdom;
- prestígio alto + vácuo de poder → pode tomar o castelo.

### Torre dos Espelhos

Novo em K**l the Rich.

Infraestrutura proposta:

> Torre dos Espelhos → transmite magia → espelhos espalhados pelo Reino → população.

Camadas:

- Influencer = mensagem/rosto;
- espelhos = distribuição local;
- Torre dos Espelhos = infraestrutura central.

O jogador pode:

- quebrar um espelho e silenciar uma região temporariamente;
- destruir a Torre e derrubar a transmissão central;
- atingir o Influencer;
- deixar a Torre intacta e ver outra pessoa ocupá-la depois.

Decisão importante:

> Destruir a infraestrutura do Rei não destrói automaticamente pessoas, ideias ou organizações.

Depois de uma Revolução, a população pode tomar a Torre:

- "A assembleia começa ao pôr do sol."

Ou, anos depois, outro grupo pode tomar a mesma Torre e iniciar nova propaganda.

### Propaganda

Novo sistema/adaptação em K**l the Rich.

Propaganda não deve funcionar como "população burra +10".

Ela muda a percepção dos acontecimentos, enquadrando fatos reais.

Exemplo:

- O Cavaleiro destrói uma casa.
- O fato físico é real.
- A propaganda pode dizer: "O Cavaleiro ataca nossas famílias."
- Medo aumenta.
- Apoio ao Rei ou ao autoritarismo pode subir.

Propaganda captura acontecimentos. Ela não cria medo do nada; trabalha junto com medo, recursos, repressão, conveniência, individualismo e experiência material.

Formas de propaganda:

- dragão carregando faixa;
- bandeiras;
- cartazes;
- espelhos mágicos;
- Torre dos Espelhos;
- Influencer/Voz do Reino;
- símbolos autoritários;
- slogans de fronteira/proteção.

Exemplo definido:

- O jogador destrói uma casa.
- Em seguida aparece um dragão com faixa: "THE KING MEANS SECURITY."
- Isso aumenta medo e pode levar a endurecimento autoritário.
- Se o jogador atinge o dragão ou a faixa, essa narrativa perde força.

Princípio:

> O Rei joga contra o jogador através da narrativa. O jogador joga contra o Rei através da física.

## 10. Organizações concorrentes e Alternative for the Kingdom

Novo em K**l the Rich.

Pode existir mais de uma organização política/social simultaneamente.

Decisão fechada:

- Revolta popular e Alternative for the Kingdom podem coexistir.
- A crise não deve ser uma barra simples indo de Rei para Revolução.
- O Influencer pode ajudar a criar ou fortalecer a Alternative for the Kingdom.
- A Alternative pode crescer em medo alto, confiança coletiva baixa e propaganda forte.

Possível trajetória:

1. Reino em crise.
2. Influencer ganha audiência.
3. Rei perde prestígio.
4. Influencer rompe: "FORA REI!"
5. População apoia queda do Rei.
6. Influencer diz: "Agora precisamos restaurar a ordem."
7. Alternative for the Kingdom aparece.
8. Parte da multidão aceita: "Ele estava conosco desde o começo."
9. O mesmo Frenesi que derrubou o Rei ajuda a colocar outro salvador no poder.

Isso preserva a crítica ao príncipe salvador e à troca superficial de ocupante do poder.

## 11. Sociedade sem Rei e vácuo de poder

Novo em K**l the Rich, compatível com Castle Siege.

Decisão forte:

> O Rei pode morrer/fugir e ninguém precisa substituí-lo imediatamente.

Vácuo de poder não significa automaticamente caos.

Possibilidades:

- caos;
- disputa da nobreza;
- soldados sem comando;
- Influencer tentando ocupar o vazio;
- Revolta avançando;
- população tomando o castelo;
- sociedade simplesmente continuando a viver;
- padaria abrindo, trabalhadores trabalhando, pessoas vivendo sem Rei.

Isso é importante para produzir a sensação:

> Talvez não precise ter Rei.

O jogador pode aproveitar o vácuo fisicamente, por exemplo usando flash bombs contra soldados ou atacando estruturas de repressão enquanto o comando está desorganizado.

## 12. Clima, migração e interdependência

Novo em K**l the Rich.

Os Reinos devem afetar uns aos outros, mas com complexidade controlada.

Fluxos sugeridos:

- comida;
- água;
- matéria-prima;
- energia;
- pessoas/migração.

Exemplos:

- Reino A entra em colapso e pessoas migram para B.
- Reino B produz comida e abastece parcialmente A.
- Reino C fecha fronteiras.
- Reino D polui e contribui para pressão climática global.
- Um Reino expulsa trabalhadores de fora e depois sofre falta de mão de obra.

Clima:

- Deve ser predominantemente local, para preservar relação entre ação e consequência.
- A ideia discutida foi algo como 90% local / 10% global, não como número fechado.
- Incêndio industrial em um Reino causa impacto forte naquele Reino e pequena pressão climática mundial.
- Muitos eventos locais acumulados podem gerar mudanças globais.

Isso permite que um Reino quase não responsável pela crise também sofra consequências, sem quebrar completamente a legibilidade.

Migração:

- Pessoas podem deixar Reinos de origem.
- Reinos podem receber migrantes.
- Propaganda pode culpar recém-chegados por escassez.
- Fechar fronteiras pode parecer solução de curto prazo, mas causar colapsos materiais.

## 13. Transformação física do cenário

Novo em K**l the Rich.

As mesmas estruturas devem mudar de função ao longo do tempo.

Exemplos:

Castelo:

- palácio real;
- fortaleza autoritária;
- escola;
- oficinas;
- biblioteca;
- hospital;
- armazém coletivo;
- ruína;
- sede de novo ditador.

Casa:

- moradia;
- casa melhorada;
- cela padronizada;
- casa com bandeira real;
- casa abandonada;
- casa deteriorada;
- casa cercada por soldados.

Muralha:

- defesa;
- fronteira militarizada;
- checkpoint;
- estrutura desmontada e reaproveitada;
- símbolo de isolamento.

Praça:

- mercado;
- encontro;
- manifestação;
- espaço coletivo;
- palco de propaganda;
- local reprimido.

Indústria:

- exploração;
- produção;
- poluição;
- abandonada;
- transformada;
- intensificada até degradar ambiente.

Bandeiras:

- decoração real;
- propaganda;
- símbolo autoritário;
- removidas;
- reutilizadas.

Exemplo forte:

- Reino A: população toma o castelo; anos depois, salão do trono vira sala de aula, fonte abastece a vila, depósitos viram armazéns.
- Reino B: propaganda domina; casas ganham grades, depois ficam menores e padronizadas; pessoas trabalham, produzem e sustentam o castelo em troca de segurança.

## 14. Diálogos

Os diálogos devem mostrar contradições sociais sem explicar a tese do jogo.

Exemplos já surgidos:

- "A fonte secou outra vez."
- "A do Rei não."
- "Pelo menos estamos seguros."
- "Seguros de quê?"
- "Você anda fazendo perguntas demais."
- "Eu não concordo com tudo."
- "Então por que colocou a bandeira?"
- "Tenho filhos."
- "Eles vão nos proteger."
- "Eles fecharam o portão."
- "É temporário."
- "Quem trabalha consegue."
- "O Reino está prosperando."
- "Precisamos trabalhar, não reclamar."
- "FORA REI!"
- "Precisamos recuperar nosso Reino."
- "Precisamos de ordem."
- "Eu posso consertar isso."

Slogans/propaganda:

- "THE KING MEANS SECURITY."
- "PROTECT OUR BORDERS."
- "THE KNIGHT ATTACKS OUR FAMILIES."
- "THE KINGDOM HAS NEVER BEEN RICHER."
- "Alternative for the Kingdom."

O diálogo deve ser curto, observável e situado fisicamente. O jogador vê a propaganda, a casa, o soldado e a pessoa ao mesmo tempo.

## 15. Final e censo

Decisão fechada:

> O encerramento é um censo do mundo, não uma pontuação.

O jogo não deve declarar "bom final" ou "mau final".

Ele deve mostrar fatos calculados pela simulação:

- população inicial e final;
- migração;
- riqueza concentrada;
- acesso à água;
- Reinos abandonados;
- Reinos sob regimes autoritários;
- monarquias restantes;
- castelos transformados em espaços públicos;
- reservas atrás de muralhas;
- temperatura média;
- famílias mais ricas;
- casas abandonadas;
- produção;
- fome/escassez;
- fronteiras fechadas.

Exemplos:

- "75% da riqueza está nas mãos de 3 famílias."
- "61% das reservas de água estão atrás de muralhas."
- "1.840 pessoas deixaram seus Reinos de origem."
- "4 Reinos fecharam suas fronteiras."
- "2 castelos foram transformados em espaços públicos."
- "3 Reinos estão sob regimes autoritários."
- "1 Reino foi completamente abandonado."
- "A população caiu de 8.420 para 6.917."
- "A temperatura média aumentou 1,7 °C."

O último tom pode ser provocativo, mas não julgador. Foi sugerida a frase:

> WHAT DID YOU SAVE?

Ainda não foi decidido se essa frase entra no jogo.

## 16. Primeira fase/protótipo: The Thirsty Kingdom

Foi proposta uma fase vertical slice chamada The Thirsty Kingdom.

Situação:

- calor extremo;
- fonte seca fora da muralha;
- água, vegetação e luxo dentro da muralha;
- castelo rico;
- indústria poluente;
- propaganda no céu;
- trabalhadores de outro Reino trabalhando na muralha;
- moradores sofrendo escassez.

Objetos atingíveis:

- reservatório real;
- dragão/faixa de propaganda;
- indústria/Royal Oil;
- quartel/soldados;
- depósito de riqueza/comida;
- casas;
- Rei;
- barricadas/checkpoints.

Cadeias de consequência:

- Quebrar reservatório → água chega à vila → população percebe → confiança coletiva sobe.
- Derrubar propaganda → influência narrativa cai.
- Derrubar propaganda sobre uma casa → propaganda ganha munição contra o Cavaleiro.
- Abrir depósito → recursos aparecem → narrativa de escassez perde força.
- Atingir casa → medo sobe → propaganda contra o Cavaleiro ganha força.
- Revolta fraca + medo + propaganda → "salve-se quem puder" → bandeiras reais nas casas.
- Muitas adesões individuais + propaganda + Revolta fracassando → Alternative for the Kingdom.
- Calor extremo → pessoas mais lentas, fogo mais perigoso, organização mais difícil.
- Destruir indústria sem cuidado → incêndio/poluição/desastre ambiental.

Observação: essa fase foi proposta como protótipo, não como decisão final de campanha.

## 17. Decisões já fechadas

- Reaproveitar o motor de Castle Siege antes de criar um motor novo.
- Frenesi/Excitação continua existindo e decai com o tempo.
- Multidão, Revolta e Revolução continuam como estados sociais, mas não são alinhamentos políticos fixos.
- Medo e repressão continuam centrais.
- Motim já existia em Castle Siege.
- Deserção é adição nova em K**l the Rich.
- Soldados não precisam ter família/psicologia profunda para o sistema funcionar.
- Soldado pode permanecer leal, desertar ou entrar em Motim.
- O Cavaleiro é o personagem do jogador.
- O gameplay principal é observar e interferir fisicamente, principalmente com canhão/tiro.
- Não haverá modo separado obrigatório de andar pela vila e conversar.
- O jogo não deve ter objetivo político imposto do tipo "faça a Revolução".
- Reinos persistem e continuam mudando.
- O mapa/campanha terá vários Reinos.
- Viajar consome tempo.
- A campanha deve ter fim explícito.
- O final é um censo/crônica, não uma pontuação.
- Reinos devem poder afetar uns aos outros, mas sem simulação econômica excessivamente pesada.
- Clima deve ser principalmente local, com algum componente global.
- Classes sociais devem ser visíveis.
- Riqueza deve ser real/calculável.
- A burguesia deve aparecer materialmente mais próxima dos trabalhadores do que da nobreza, apesar de símbolos/aspirações.
- Propaganda enquadra acontecimentos reais.
- Influencer é uma possibilidade forte do sistema, conectado à Torre dos Espelhos.
- O Influencer não precisa ser obrigatório em todas as campanhas.
- Se o Influencer morrer, a propaganda pode continuar porque a estrutura permanece.
- Pode surgir outro Influencer.
- Qualquer personagem pode morrer.
- A nobreza pode abandonar o Rei.
- Revolta popular e Alternative for the Kingdom podem coexistir.
- O Rei pode morrer/fugir sem substituto imediato.
- Vácuo de poder não significa Caos automático.
- A sociedade pode continuar funcionando sem Rei.
- O jogador pode continuar interferindo depois da morte/fuga do Rei.
- O castelo pode virar escola/espaço público, ruína, fortaleza autoritária ou sede de novo poder.

## 18. Pontos ainda em aberto

### Escopo exato do protótipo

Foi sugerido começar por The Thirsty Kingdom como vertical slice, mas ainda falta fechar:

- tamanho da fase;
- quantidade de tiros;
- número de NPCs/agentes;
- quais cadeias entram primeiro;
- quais sistemas ficam fora da primeira versão.

### Quantidade final de Reinos

A conversa favoreceu 8 Reinos inicialmente, com possibilidade de 10. Ainda não é decisão técnica final.

### Duração exata da campanha

Foi sugerido 12 anos/ciclos. Ainda falta decidir:

- se cada viagem consome estação, mês ou ano;
- se cada intervenção também consome tempo;
- se quatro estações formam um ano;
- quantas ações cabem por ano.

### Interface de informação

Ainda não foi decidido quanto o jogador vê numericamente.

Provável direção:

- números internos invisíveis;
- estado lido pelo cenário, diálogos e censo final;
- talvez indicadores mínimos de ano/mapa.

Mas ainda está aberto se haverá barras, ícones ou painel simplificado.

### Prestígio

A fórmula conceitual foi definida, mas não os pesos:

- Visibilidade;
- Credibilidade;
- Apoio;
- Acesso ao poder.

Ainda falta transformar em modelo jogável.

### Propaganda

Foi decidido que propaganda enquadra acontecimentos. Ainda falta definir:

- alcance local dos espelhos;
- frequência de mensagens;
- como a Torre repara/substitui espelhos;
- quanto tempo uma narrativa dura;
- como narrativas competem entre si.

### Influencer

Ainda em aberto:

- se todo Reino tem um Influencer potencial;
- se o Influencer sempre começa na burguesia;
- como surgem substitutos;
- como o jogador reconhece mudanças de prestígio;
- quantas "Vozes do Reino" podem existir ao mesmo tempo.

### Organizações concorrentes

Alternative for the Kingdom foi definida conceitualmente. Falta decidir:

- símbolos finais;
- comportamento no mapa;
- como recruta;
- como disputa a Torre;
- como difere visualmente de monarquia autoritária.

### Sociedade sem Rei

Foi definida como possibilidade. Falta desenhar:

- como funciona a rotina visual sem Rei;
- quem mantém recursos;
- como conflitos aparecem;
- como evitar que sempre vire utopia ou caos.

### Clima e economia entre Reinos

Direção definida: interdependência leve.

Aberto:

- quais recursos entram no protótipo;
- como migração é calculada;
- como escassez local vira efeito global;
- como fronteiras aparecem no mapa.

### Diálogos

Há tom e exemplos, mas ainda falta:

- banco de falas por classe;
- falas por estado social;
- falas por propaganda;
- falas por medo/repressão;
- falas por retorno após anos.

### Objetivo visível

A conversa migrou de um possível objetivo "MAKE THE KING LEAVE" para uma estrutura sem objetivo imposto, mas com campanha finita e censo final.

Estado atual:

- não impor "mate o Rei" ou "faça Revolução";
- manter direção pelo mundo persistente, tempo finito e consequências.

Ainda falta decidir se algum objetivo inicial mínimo aparece no tutorial/protótipo.

## 19. Síntese para retomada

K**l the Rich deve ser um sandbox/campanha sistêmica em pixel art, herdando de Castle Siege o motor de Frenesi, Multidão, Revolta, Revolução, Medo, repressão, Motim e Caos, mas expandindo isso para Reinos persistentes, classes sociais, riqueza real, propaganda, Prestígio, Influencer, Torre dos Espelhos, migração, clima e transformação física do cenário.

O coração do jogo não é escolher uma ideologia vencedora. É interferir fisicamente em sociedades vivas e depois encarar as consequências.

O Rei pode cair e o mundo melhorar. Ou outro salvador pode ocupar a Torre. Ou a população pode transformar o castelo. Ou o Reino pode continuar sem Rei. Ou pode entrar em medo, fronteiras, propaganda e autoritarismo. O sistema deve permitir esses caminhos sem tratá-los como cutscenes obrigatórias.

Frase-guia:

> Você não escolhe o resultado. Você escolhe ações. O sistema produz o resultado.
