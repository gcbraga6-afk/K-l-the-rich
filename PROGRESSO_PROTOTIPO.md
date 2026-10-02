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
