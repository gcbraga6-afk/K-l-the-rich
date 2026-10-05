# Avanço do protótipo — 1 de outubro de 2026

Implementado sobre a cena existente:

- Câmera acompanha a bala nos dois eixos, inclusive em arcos altos. Após o impacto, mantém a posição horizontal e retorna à altura do Reino. A/D interrompe o acompanhamento; Home retorna ao canhão.
- Teclas 1 e 2 selecionam Basic e Flash, compartilhando as oito munições de teste.
- Basic danifica estruturas por proximidade da superfície. Removido o dano direto duplicado antes da explosão.
- Flash assusta moradores e desorganiza soldados por sete segundos, sem destruir estruturas. Este primeiro recorte ainda não aplica dano em pessoas.
- Moradores fogem temporariamente e retomam o percurso; soldados recuperam a formação.
- Ruínas escondem elementos intactos e deixam de bloquear projéteis. Persistem durante a sessão; ainda não há salvamento entre sessões.
- Esc encerra a intervenção sem interromper a simulação. O último disparo continua voando após acabar a munição.
- Registro dos cinco acontecimentos mais recentes e instruções na tela.
- Alcance máximo ampliado para permitir tiros até o castelo; ponto de arraste estabilizado; projéteis perdidos são removidos.

Validação automática no Godot 4.7.2: Flash sem dano estrutural, fuga, desorganização/recuperação, dano por superfície, ruínas sem colisão, último disparo e acompanhamento/retorno da câmera. Cena de teste: `tests/prototype_smoke.tscn`.

Ainda pendentes: avaliação visual e ajuste de sensação dos controles, persistência em disco, ciclo diário, social por grupo, propaganda e Pigeon. Os valores deste avanço são parâmetros experimentais de protótipo.

## Cenário e direção visual

- Fundo de vale aberto, rio e escarpa à direita; removido o paredão próximo à esquerda.
- Planos independentes: paisagem distante (35% do deslocamento), vegetação transparente (72%) e chão/objetos (100%). Céu e montanhas ainda estão juntos na imagem distante.
- Overlay atmosférico azul-acinzentado a 26% aplicado somente ao fundo distante, antes de desenhar vegetação, construções e personagens. Cor e intensidade ajustáveis no script do cenário.
- Prancha de seis concepts de casas salva em `assets/concepts/village_houses.png`; ainda não convertida em sprites individuais.
- Imagens criadas com a ferramenta integrada de geração. Direção dos prompts: vale aberto sem paredão à esquerda, preservar rio e platô à direita; camada transparente de vegetação baixa; seis casas de vila em vista frontal com materiais e silhuetas diferentes.

### Separação na marca vermelha

Vale/encostas agora são um PNG transparente separado, seguindo aproximadamente o contorno marcado. O fundo foi reconstruído sem duplicar essas encostas. Velocidades do fundo e vale: 0,35 e 0,40 (diferença de 5 pixels a cada 100 pixels de câmera), mantendo parallax sutil. Névoa aplicada apenas ao fundo, a 16%. Renderização conferida no Godot.

## Vila, comércio e oficinas — 2 de outubro de 2026

Implementado na cena principal:

- 20 modelos de casas em cinco atlas transparentes: oito na rua principal com colisão/dano e doze cenográficas numa rua recuada. As casas ao fundo têm menor escala, leve névoa e 95% da velocidade de deslocamento da rua principal.
- Padaria, taverna, mercado e alfaiataria com arte própria.
- Moinho, ferraria, olaria e serraria medievais com arte própria. O moinho substitui a representação anterior de fábrica.
- Reino ampliado para 7.600 unidades; escola, oficinas, Espelho, muralha e castelo reposicionados. Alcance do canhão e limites do projétil ajustados para o novo tamanho.
- Moradores têm rotas entre casa, atividade e comércio, com pausas. Medo interrompe a rotina. Destinos destruídos são ignorados; estabelecimentos exibem fechamento e geram um evento.
- Personagens ainda usam desenhos provisórios simples com movimento das pernas. A prancha de conceitos de pessoas está salva; ainda não é um conjunto de animações.
- Tecla V vai à vila; Home volta ao canhão. Instruções no rodapé e painel de munição com fundo legível.
- Fundo distante e vale agora se movem a 20% e 25% para cobrir o Reino ampliado mantendo a diferença sutil de cinco pontos percentuais.

Verificação: testes `prototype_smoke.tscn` e `village_integration.tscn` passaram. Renderizações de vila, mercado, oficinas e castelo conferidas. Comércio e produção são locais com rotinas e reação a dano; ainda não simulam estoques, preços ou economia. Escola, castelo, muralha, Espelho e personagens permanecem com arte provisória.

Arquivos de arte:

- `assets/houses/houses_01.png` até `houses_05.png`: vinte modelos.
- `assets/businesses/shops.png`: quatro comércios; `industry.png`: quatro oficinas.
- `assets/concepts/people.png`: proposta visual de doze personagens.
- `assets/backgrounds/preview_village.png`, `preview_market.png`, `preview_industry.png`, `preview_castle.png`: capturas renderizadas pelo Godot.

Geração: ferramenta integrada de imagens, usando a prancha original das casas como referência. Prompts pediram vista frontal para jogo lateral, pixel art pictórico, materiais medievais de conto de fadas, peças inteiras e fundo transparente. Casas foram divididas em cinco famílias: casas básicas, moradias simples, casas-oficinas, variações de volume e casas com manutenção melhor. Comércio: padaria/taverna/mercado/alfaiataria; indústria: moinho/ferraria/olaria/serraria, sem eletricidade ou arquitetura industrial moderna. Os recortes usados pelo Godot são regiões de atlas; pixels das imagens originais foram preservados.

### Comércio com tendas

Os quatro comércios agora usam `assets/businesses/shops_tents.png`, com tendas largas cobrindo toda a fachada, balcões abertos e mercadorias expostas. Prompt de edição pela ferramenta integrada: substituir aparência residencial por pavilhões comerciais frontais; toldos ocre, vinho, verde e azul; preservar pixel art medieval e separar com alpha. Atlas atualizado; rotinas e destruição verificadas novamente. Prévia do mercado renderizada no Godot.

### Comércio misto e Cavaleiro

Padaria e taverna usam as fachadas construídas originais; mercado e alfaiataria mantêm tendas largas. Catálogo atualizado e teste de integração aprovado.

Concept `assets/concepts/knight_cannon_abc.png` criado pela ferramenta integrada. Prompt: três pares de Cavaleiro/canhão de perfil, pixel art medieval no estilo da vila; A viajante clássico com ferro e carvalho, B salvador pomposo com ornamentos de latão, C veterano com canhão longo e baixo. Comparação conceitual, ainda não aplicada ao personagem do jogo.

## Indústrias compactas — biblioteca e cenário
- Biblioteca visual em assets/concepts/industries/index.html com as 16 variações A1–D4 aprovadas.
- Quatro adaptações transparentes em assets/businesses/factories_v2.png: A1 Tecelagem Real, B1 Fundição, C2 Manufatura, D3 Destilaria.
- Integradas aos quatro locais industriais existentes, mantendo dano, fechamento e rotinas de trabalhadores. Originais preservados.
- Importação concluída; teste village_integration passou; preview_industry.png conferido visualmente no Godot.
- Próxima etapa solicitada: castelo.

## Composição experimental — rejeitada visualmente
Alteração no Godot adicionou platôs, redução de escala, duas fábricas, seis casas nobres, castelo aprovado e cavaleiro. Teste prototype_smoke passou, mas o usuário rejeitou o resultado visual (chão artificial/composição solta). Não tratar esta implementação como aprovada. A pedido, gerado concept panorâmico em assets/concepts/composition/kingdom_panorama_v1.png para estudar composição antes de continuar implementação.

## Composição jogável baseada no panorama
- Terreno ilustrado com alpha em assets/composition/terrain.png substitui o chão procedural rejeitado; prédios continuam nós separados com colisão e dano. Fundo atmosférico independente e parallax sutil preservado.
- Mapa de 7600 unidades: platô inicial, 20 casas da vila em duas camadas, quatro comércios, quatro fábricas, intervalo verde, seis residências nobres (quatro interativas + duas de fundo), castelo sobre platô final.
- Castelo com largura 850 e altura aproximada 1113; enquadramento local ajustado para mostrar suas torres. Escala em relação ao panorama é uma adaptação ao mapa amplo, não reprodução pixel a pixel.
- Canhão A2 preparado em peças alpha separadas: tubo acompanha direção do tiro; carro recua e retorna, roda gira, clarão, fumaça e poeira. Funciona inclusive no último tiro.
- Testes prototype_smoke, village_integration e composition_check passaram. Prévia real renderizada pelo Godot: assets/backgrounds/playable_panorama.png.
- Terreno é camada visual única com colisão simplificada por contorno; personagens ainda usam arte procedural e moradores desenhados nas janelas não são agentes independentes.

## Correção aprovada da composição — 2 de outubro
A montagem anterior acima foi rejeitada: terreno esticado, vila espalhada, parallax excessivo, zoom automático e apoio inadequado do castelo.

- Removido o zoom automático lateral e o modo Tab que alterava a ampliação. Tiro e navegação preservam o zoom; câmera continua seguindo a bala nos dois eixos.
- Terreno reorganizado em quatro regiões de atlas sobrepostas, todas com escala uniforme 2×. Extensão atual de 5648 unidades; trechos centrais acrescentam espaço para indústria, sem alargar as pedras. Imagem original preservada. Transições usam máscara de borda; a repetição de vegetação ainda é perceptível no distrito industrial.
- Vila condensada em cerca de 1600 unidades, com 40 unidades entre as bases das duas fileiras. Parallax da segunda fileira limitado a ±6 unidades em todo o mapa.
- Platô inicial mais curto; cavaleiro aumentado e ajustado ao piso. Quatro fábricas agrupadas, intervalo de terreno antes das casas nobres.
- Castelo com largura 950 e proporções preservadas, reposicionado sobre a parte ampla do platô. Com zoom fixo, as torres ultrapassam o enquadramento próximo: não há redução automática para caber na janela.
- Validação: prototype_smoke, village_integration, composition_check e camera_traversal aprovados. Este último simula percurso completo de ida e volta e disparo para verificar zoom fixo e limite de parallax. Cinco enquadramentos renderizados e inspecionados no Godot.
- Colisão do chão continua sendo um contorno simplificado. Esta revisão implementa a direção aprovada; a aprovação visual final pertence ao usuário.

## Substituição integral do chão rejeitado e trava de câmera
A revisão com recortes do terreno antigo também foi rejeitada pelo usuário por definição incompatível. Ela foi substituída, não deve ser recuperada.

- Três artes inéditas em assets/composition/terrain_long_v2, geradas usando apenas as casas e o castelo como referência de estilo. 2172×724 pixels por arquivo, escala 1:1 no jogo, 6260 de extensão total. Sem recortes/repetições do terreno antigo. Prompts completos e proveniência no README da pasta.
- Novo platô do cavaleiro, vila condensada, pátio industrial com quatro fábricas, intervalo de campo, terraço nobre e base ampla do castelo. Posições e contorno de colisão ajustados aos novos pisos.
- Fundo distante agora em escala uniforme 1.5, com parallax de 0.16. Removida a ampliação do fundo até a largura de todo o mapa.
- Zoom explicitamente travado em Vector2.ONE a cada quadro e no disparo. Removido retorno vertical automático ao fim do voo. Desativado stretch do viewport para que redimensionar a janela altere a área visível, não a escala. W/S navega verticalmente; A/D horizontalmente; Home/V reposicionam sem alterar escala.
- Testes prototype_smoke, village_integration, composition_check e camera_traversal passaram. O último também disparou um projétil físico até impacto em VillageHouse03, verificando escala durante voo e imobilidade do enquadramento após impacto. A composição testa três texturas novas distintas em escala nativa.
- Cinco capturas reais do Godot conferidas. Limitações: colisão de terreno ainda aproximada e extensão inferior do solo simplificada fora do enquadramento habitual. A imagem geral playable_panorama anterior não representa a revisão atual do fundo; consultar preview_launch/village/industry/nobles/castle.

## Platô profundo, indústria compacta e camadas restauradas
- Vila aprovada preservada. Quatro fábricas aumentadas de 275 para 330 unidades (+20%) e centros separados por 270 unidades, criando sobreposição leve e conjunto mais compacto.
- Recuperadas as camadas valley_midground e near_vegetation, com névoa atmosférica e velocidades de parallax de 0.20 e 0.24; montanhas mantidas em 0.16. Camadas em escala uniforme e contínuas, sem espelhamento de cachoeiras ou árvores.
- Nova extensão castle_plateau.png em escala nativa; mundo ampliado para 6927 unidades. Castelo transferido para o centro da superfície profunda, com piso atrás e sob todos os contrafortes. Prompt e referência em CASTLE_PLATEAU.md.
- composition_check agora amostra a borda inferior da imagem do castelo a cada 8 pixels, conferindo terreno opaco sob cada ponto. Teste passou, e a prévia real confirma apoio nas laterais antes marcadas pelo usuário.
- camera_traversal passou novamente com voo físico e impacto: zoom em 1×, sem reenquadramento após impacto.

## Continuação — 3 de outubro: navegação e alcance
- Limites laterais da câmera passam a acompanhar a largura real da janela. Redimensionar revela mais/menos cenário sem alterar o zoom nem ultrapassar a borda do mundo em janelas usuais.
- Teste window_bounds verifica larguras 1280, 1600 e 1920; também mede o deslocamento horizontal das duas camadas restauradas, sem deriva vertical.
- Teste long_shot usa velocidade (1900,-2200), abaixo do máximo e correspondente a arrasto possível na janela inicial. O tiro físico atinge Castle em aproximadamente (6086,-565); câmera acompanha em 1×. Captura real em assets/backgrounds/preview_castle_impact.png.
- camera_traversal adaptado para calcular a duração da travessia pela largura visível, em vez de presumir 500 quadros. Passou com tiro, impacto e preservação de enquadramento. composition_check e village_integration também passaram.
- Layout da vila, tamanho das fábricas, platô e arte preservados nesta etapa.
- Conferência visual do tiro revelou o ColorRect antigo da explosão, visível como quadrado sobre o castelo. Aplicado shader de pulso radial com borda suave; partículas e cálculo de dano preservados. Impacto renderizado novamente e prototype_smoke aprovado após a mudança.

## Janela Full HD e câmera mais solta — pedido de 3 de outubro
Este pedido substitui explicitamente a exigência anterior de zoom sempre travado durante tiros longos.
- Janela configurada de 1600×900 para 1920×1080; escala normal 1× e sem stretch da cena.
- Seguimento horizontal suavizado; vertical com zona livre e influência reduzida, mantendo a bala dentro da margem superior.
- Apenas durante trajetórias longas: zoom suave de 1.0 até 0.88, entrando entre 3000 e 5500 unidades percorridas. Enquadramento mantido após impacto.
- Clique esquerdo após disparar retorna suavemente ao cavaleiro e restaura 1×; o clique é bloqueado para mira/disparo. Funciona durante voo e após impacto. Home também retorna; W/S e A/D continuam disponíveis.
- Testes atualizados para o comportamento novo: câmera suave/retorno, limites de janela, tiro físico até o castelo e regressão de dano aprovados.

## Marco aprovado pelo usuário
Cenário e dinâmica de tiro aprovados em 3 de outubro de 2026. Estado solicitado para commit antes da próxima etapa de desenvolvimento do jogo: janela Full HD, câmera suave com afastamento discreto nos tiros longos, retorno por clique, vila/indústria/nobreza e castelo sobre terreno próprio, camadas de parallax restauradas.

## 2026-10-03 — personagens e corte implementados
- Checkpoint aprovado 3c77300 enviado ao GitHub/main.
- Novos sprites transparentes de aldeão, aldeã, soldados e rei, seguindo people.png; animações em atlas, orientação pela caminhada e corrida quando assustados.
- Mantidas rotinas entre casas e comércios, desorganização dos soldados com Flash; acrescentadas patrulhas na indústria e no castelo.
- Rei passeia e faz pausas no platô, junto do espelho real; espelho possui colisão, dano e estilhaços. A quebra assusta o rei se estiver próximo.
- Assets e prompts em assets/characters/README.md. Novas alterações locais posteriores ao checkpoint enviado.
- Validados royal_court_check, prototype_smoke, village_integration, composition_check e camera_traversal; previews do jogo atualizados.
- Cenário e dinâmica de câmera/tiro aprovados preservados. Ainda não há sistema de vitória ou combate de soldados nesta etapa.

### Correção do Espelho — modelo de propaganda aprovado
O espelho doméstico foi substituído pelo painel público de propaganda: perspectiva 3/4 voltada à vila/cavaleiro, colunas finas, tela ampla vazia, base de pedra. Largura 340 no mesmo platô próximo ao castelo. PNG transparente em assets/characters/propaganda_mirror.png; colisão e destruição preservadas. Renderização conferida e royal_court_check passou. Sistema de mensagens/PROPAGANDA/LIVE permanece pendente; esta alteração implementa o modelo visual solicitado.

## 2026-10-03 — primeira ligação social e propaganda
Consultados diretamente no GitHub GAME_DESIGN.md e PROTOTYPE_01.md (main). Implementada uma primeira fatia dos milestones 5/6:
- Testemunhas a até 600 unidades reagem a dano, registram alarme, medo e Frenesi; civis próximos fogem. Dano sem testemunhas não altera essas variáveis globais.
- Prestígio do Rei separado por grupo no modelo; grupos ativos atualmente Workers, Soldiers e King/Nobility. Bourgeoisie ainda não tem população própria. Não há Prestígio do Cavaleiro.
- Flash reduz coesão e torna a recuperação dos guardas mais lenta; há recuperação gradual. Deserção, repressão e Motim ainda pendentes. Frenesi ainda é uma variável inicial, sem revolta coletiva implementada.
- Espelho exibe texto em perspectiva sobre o vidro aprovado, reage a casas, estruturas e guardas atingidos. Fila limitada, mensagens iguais agrupadas, duração de 12 segundos. Ruína interrompe a transmissão.
- Propaganda afeta modestamente o Prestígio dos grupos presentes no raio de 800; experiência recente de perigo reduz credibilidade. Slogan padrão não acumula Prestígio.
- HUD resume população e guardas; tecla M enquadra o Espelho. Mecânica de tiro/câmera preservada.
- Testes: propaganda_check (inclui dano sem testemunhas, mensagens, deduplicação, silêncio após ruína), prototype_smoke atualizado para recuperação dependente da coesão, royal_court_check, village_integration, camera_traversal. Renderização da tela conferida.
Próximas partes: completar respostas sociais e ciclo diário; depois Pigeon com marcação, pouso dormente, CONNECT/LIVE, expulsão e cooldown. Nenhum sistema de LIVE/canais/gravação foi introduzido nesta etapa. Persistência entre sessões ainda não implementada.

### Casa física integrada à vila — 2026-10-03

- A primeira casa à direita do canhão usa a geometria de apoio do laboratório aprovado, com escala uniforme e arte própria para pedra, viga e telhado; porta independente mais leve.
- São 14 corpos presentes desde o início. O projétil Basic transmite momento por colisão e permanece no mundo após atingir essa casa. Não há explosão, tremor ou troca por sprite de ruína nesse impacto.
- A perda real de suporte/rotação da viga informa o colapso aos moradores e à propaganda. Explosões próximas aplicam impulso às peças existentes.
- Demais casas e castelo ainda não foram convertidos para esse novo sistema. O laboratório original permanece disponível em `scenes/physics_lab/house.tscn`.
- Verificação: estabilidade antes do tiro; disparo do canhão real; queda do telhado por gravidade; destroços persistentes e apoiados no terreno; evento social de colapso. Disparo longo até o castelo preservado.

### Ampliação da destruição física — 2026-10-04

- As oito casas da primeira camada agora têm corpos físicos desde a criação do cenário. As sete casas adicionais preservam seus desenhos originais, aplicados às peças móveis; telhados têm contornos de colisão e apoio nas vigas.
- A torre alta da esquerda do castelo agora tem sete peças físicas empilhadas. Impactos deslocam a alvenaria e a cobertura; o restante do castelo permanece como apoio estático. A perda da torre registra dano parcial, não a destruição do castelo inteiro.
- A bala pode registrar impactos em mais de uma construção durante seu percurso. Flash usa um detector separado e não empurra as peças.
- Corrigida a colisão residual do chão antigo invisível, que interceptava tiros baixos acima do terreno atual.
- Validação: estabilidade das oito casas e da torre antes do impacto; deslocamento de telhado; dois impactos na torre com destroços persistentes; disparo real na primeira casa; disparo longo; Flash sem dano estrutural; câmera e reações básicas.
- Escopo restante: casas de fundo são decorativas; comércio, fábricas, casas nobres e o restante do castelo ainda precisam de conversão para o novo sistema físico.

### Destruição por energia local e fratura sob demanda — 2026-10-04

Substitui a transferência de momento pelo solver, que o usuário rejeitou por
parecer sinuca. A bala agora detona no contato.

- Energia local: a peça dentro do núcleo do estouro é arrancada; fora dele a
  tensão acumula entre tiros até a fiada ceder; além do raio nada acontece.
  Direção radial misturada com a linha do tiro, e nunca para dentro do chão.
- Grafo de apoio montado da geometria autorada. Alvenaria intocada fica
  congelada como colisão estática, e entulho assentado volta a ser cenário.
  O desabamento vem da gravidade, não do empurrão da bala.
- Fratura sob demanda (`fracture.gd`): a peça com energia suficiente é trocada
  por lascas de Voronoi cortadas do próprio polígono de colisão, cada uma
  carregando a fatia da fachada pintada. Semente derivada da geometria, então a
  quebra é reproduzível. Teto de 160 lascas vivas e no máximo 2 gerações.
- Alvenaria que desaba de altura quebra ao aterrissar; entulho atingido acorda,
  é empurrado, solta poeira e quebra de novo. Lasca rápida danifica a construção
  que acertar, então destroços atingem casas vizinhas.
- Poeira desenhada à mão (`dust_puff.gd`), sem textura nem addon.

Decisão de design aprovada pelo usuário: **um tiro abre um buraco e deixa a casa
de pé cedendo**; só tiros repetidos a derrubam. O modelo anterior achatava a casa
inteira num tiro.

Avaliação visual: o usuário aprovou a fratura no laboratório ("está muito
melhor"), comparando com o modo de peças inteiras pela tecla F.

Pendências e problemas conhecidos:
- `village_physics_check` e `destruction_check` estão vermelhos. Não é apenas
  expectativa antiga: existe um travamento real de corpo. Com a coluna esquerda
  removida, a peça do topo fica encravada entre a viga e a porta, acumulando
  velocidade (mais de 1600 px/s) sem se deslocar. A tentativa de fazer pedra
  encravada ceder não resolveu o caso. É o artefato de blocos grandes e retos
  (lascas irregulares travam, caixas deslizam ou encravam).
- Realimentação de entulho foi encontrada e cortada: lasca que acertava casa
  disparava estouro que remexia entulho, gerando mais impactos. Dano causado por
  destroços agora não remexe entulho (`cascade=false`).
- Itens não feitos: peças originais continuam 14 por casa (retângulos), massa das
  peças não foi reequilibrada, e falta cascalho espirrando e miolo de pedra na
  face partida.
- Só o laboratório e as casas da frente/torre usam o sistema. Comércio, fábricas,
  casas nobres e o restante do castelo seguem pendentes.

### Peças irregulares — tentada e desligada — 2026-10-04

Objetivo: resolver o bloco que fica encravado no ar, trocando as 14 peças
retangulares por pedras irregulares desde a criação.

Implementado e funcionando: corte de Voronoi das regiões autoradas, com a fatia
certa da fachada pintada em cada pedra; grafo de apoio reescrito para achar
vizinho por contato, não por fiada alinhada (forma irregular não alinha);
API de regiões (`region`, `region_centre`) para que colapso seja julgado por
grupo, e nenhuma peça individual precise sobreviver à intervenção.

**Desligado.** Com as regiões divididas, o solver de contato 2D do Godot diverge:
posições chegam a 1e15 e além em segundos depois do primeiro impacto. Tentativas
que não resolveram: descartar lascas abaixo de área mínima, descartar lascas
finas (menor lado do retângulo envolvente), e subdividir só regiões grandes
deixando fiadas pequenas inteiras. `_stone_count` e `count` agora retornam 1; a
API de regiões ficou, então religar é uma linha quando a estabilidade for
resolvida.

Caminhos prováveis, não testados: dar faces irregulares às peças no tamanho atual
(em vez de pedras menores), ou trocar o backend de física por Rapier 2D, que
existe como GDExtension e é recomendado justamente para muitos corpos.

Consertado no caminho, e isso era o que impedia de jogar:
- A bala que caía curto perguntava a um `Array[RigidBody2D]` se o chão estava
  nele. Erro do motor, e o editor para o jogo rodando.
- Quatro lugares assumiam que peça não morre. O pior lia o nome da coroa da torre
  destruída a cada quadro. Eram 297 erros em 8 tiros; agora são zero.
- Realimentação de entulho: lasca acertando casa disparava estouro que remexia
  entulho, gerando mais impactos sem fim. Dano de destroço não remexe mais.

Pendência real, documentada por teste vermelho: o telhado não desce mesmo com a
casa quase toda destruída. `village_physics_check` cobra isso e falha. O teste
NÃO foi afrouxado para passar: ele documenta o defeito.

### Modelo de recorte, interior modular e desempenho — 2026-10-05

Visual aprovado pelo usuário na bancada `scenes/physics_lab/carve.tscn`.

- Fachada como máscara: a bala rasga buraco e a casa fica de pé. A estrutura de pé
  nunca vira corpo dinâmico, então o solver não diverge como no modelo de blocos.
- Telhado e parede falham diferente. A linha do beiral é deduzida da própria arte.
- Nada sai em linha reta: distância ao impacto mais ruído, com os limites também
  ondulando. O telhado antes era um retângulo de pixels.
- Telhado destruído **abre para o céu**, não vira mancha no formato do telhado.
  O cômodo tem alpha próprio: parede tem cômodo atrás, acima do teto tem céu.
- Interior montado de 12 módulos pintados (`assets/interiors/`), recortados da
  prancha gerada pelo ChatGPT. Cada casa sorteia uma combinação; colunas alternadas
  são espelhadas para a repetição não ler como papel de parede.
- Escombro carrega a textura de onde quebrou, e assenta: amortecimento cresce com
  o tempo solto, com prazo final. Tiro novo quebra entulho já caído.
- A explosão **arremessa**: cada peça sai na direção oposta ao ponto do estouro,
  com força caindo pela distância e com elevação somada, para arcar em vez de
  raspar a parede. A gravidade assume depois. Entulho já no chão também é jogado
  para cima e para fora, não empurrado rente ao solo.

DESEMPENHO — resolvido. Cada tiro caiu de ~170 ms para ~23 ms, abaixo de dois
quadros. O que rendeu, em ordem: contagem incremental em vez de varrer a imagem;
ruído pré-calculado em tabela no lugar de sin() por pixel; máscara trabalhada como
PackedByteArray em vez de get_pixel/set_pixel; decisão por bloco de 3x3 em vez de
pixel a pixel; a máscara nascendo vazia onde a arte é transparente, para o recorte
pular céu e chão sem avaliar nada; silhueta calculada uma vez por tiro em vez de
duas, com os polígonos que caíram apenas saindo da lista.

A colisão passou a ser por segmentos do contorno em vez de decomposição convexa.
Um contorno de silhueta bombardeada pode se auto-intersectar, e o decompositor
reporta isso como erro de motor — que no editor para o jogo rodando.

MAPA DE MATERIAIS — feito, com uma casa mapeada. Um PNG por casa diz do que cada
parte é feita (telhado, parede, janela, madeira). Janela é achada como mancha
ligada de pixels e **falha como abertura inteira**: um tiro de raspão no canto leva
a janela toda e deixa a parede em volta de pé, verificado em teste. O telhado passa
a vir do mapa em vez do palpite pela linha do beiral. Formato documentado em
`assets/houses/materials/README.md`. Só `house_02.png` existe; as outras 19 casas
continuam funcionando sem mapa, tratadas como alvenaria.

NO JOGO — as casas do reino passaram para o modelo de recorte. `carved_house.gd`
ocupa o lugar do antigo `PhysicalHouse`, responde `damage_near` e `closest_point`,
e a integridade do prédio passa a seguir **quanto da casa ainda está de pé** em vez
de contar tiros. O acerto é reportado na hora, porque o jogo lê dano no instante do
impacto, e o quanto sobrou só pode ser medido depois do recorte, que é adiado para
fora do flush da física. Casa cai quando resta menos de 60% da alvenaria.

Bugs encontrados ao integrar: um estouro ao lado da casa recortava o ar em vez da
parede mais próxima; e o teste de limites do ponto de recorte só olhava o índice no
array, então um x maior que a largura enrolava para outra linha e passava como
válido, fazendo o recorte acontecer fora de alcance.

Os 15 testes passam com zero erros. Testes que cobravam peças por nome foram
reescritos para cobrar o comportamento: a casa perde material, continua de pé com
um tiro, e as vizinhas não perdem nada — a garantia anti-sinuca agora em escala de
reino (7 de 7 casas vizinhas intocadas).

Ajustes depois de ver no jogo:
- Estilhaço **não dispara mais estouro**. Destroço voando machuca a construção que
  acerta, mas não abre buraco nela — senão cada desabamento acendia uma cadeia de
  desabamentos em volta. A marca `cascade=false` já existia e passou a ser honrada.
- Poeira e destroço do telhado estavam dimensionados em unidades de mundo,
  calibrados na bancada, onde a casa tem 430 de largura. No jogo a casa tem 225, e
  tudo saía com o dobro do tamanho relativo: a nuvem engolia a própria casa. Agora
  a poeira escala com a mordida que a levantou, e as peças de telhado são lascas
  irregulares em vez de lajes retangulares.
- `fire_burst.gd`: a bala Basic agora explode com fogo — corpo escuro, meio
  alaranjado e miolo claro, cada um irregular e com seu próprio tempo, mais
  fagulhas arremessadas e fumaça que sobrevive à chama. Desenhado por código, sem
  arte nova. Flash continua sendo luz, não fogo.

PENDÊNCIAS: a torre do castelo e o espelho continuam no modelo de blocos, a pedido
do usuário, e serão feitos com atenção própria. Só `house_02.png` tem mapa de
materiais; as outras 19 casas funcionam sem mapa, como alvenaria.

Composição: Mercado e Alfaiataria foram **removidos** a pedido do usuário. Eram os
dois comércios com tenda larga de fachada, e as tendas se espalhavam pela rua,
apertavam as casas dos dois lados e escondiam o estrago. As duas lojas restantes
ocupam o espaço que era das tendas. Rotinas dos moradores passaram a escolher
destino por posição no que resta, não por índice fixo, e a composição decide altura
e névoa pela marca `industry` em vez de contar índices.

A bala soltava, além do entulho de verdade, 14 retângulos de cor chapada — resto do
modelo antigo de explosão. Era isso que aparecia como "destroço cinza" no jogo e não
na bancada: a bancada chama o recorte direto, sem passar pela cena de explosão.
Removidos; o recorte já produz entulho com a textura de onde quebrou.

Sobrava ainda uma franja cinza: em dois lugares a lasca ganhava pintura mas seguia
desenhando a silhueta lisa por baixo, e essa silhueta é o **casco convexo**, mais
larga que a pintura. Resultado: cada peça com uma borda cinza-azulada em volta.
Corrigido nas ilhas que desabam e nas lascas que quebram de novo; e a cor de
reserva, para peça sem pintura nenhuma, passou de azul-ardósia para pedra.

Mesmo assim o usuário continuou vendo cinza. Medido: **zero** entulho chapado, 146
pintados — não era entulho. Era o desenho antigo de ruína do `house_art.gd`, que
pinta retângulos cinza-oliva no nível da rua, e que **lojas e fábricas** ainda
usavam por estarem no modelo antigo. Comércio e indústria passaram para o recorte
também, então a rua inteira quebra do mesmo jeito.

A bala detonava no ar, por **duas** causas somadas:
1. a camada de entulho estava na máscara de colisão dela, então explodia nos
   destroços do tiro anterior ainda caindo. Removida — o estouro já sacode o
   entulho dentro do raio, nada se perde;
2. a bala **não tinha camada própria**, ficando na camada 1, a mesma do terreno
   que ela deve acertar. Com a máscara incluindo a camada 1, **duas balas em voo
   colidiam uma com a outra** e as duas detonavam em céu aberto. Agora a bala tem
   camada 2. Guardado por `tests/crossfire_check.tscn`, que dispara uma rasante
   atrás de uma alta e exige que nenhuma detone acima da linha dos telhados nem
   contra outra bala. O Flash também só enxerga o chão; quem acha alvenaria é o
   sensor dele.
