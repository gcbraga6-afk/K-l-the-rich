# Relatório da conversa — Castle Siege e K**l the Rich

Data de elaboração: 30 de setembro de 2026.  
Base: conversa de reformulação e inspeção documental realizada nesta tarefa em 18 de setembro de 2026.  
Escopo: recuperar motores e regras do Castle Siege e compará-los com as decisões de K**l the Rich.

> Este relatório registra o conteúdo discutido e verificado nesta conversa. Não representa uma nova inspeção do repositório em 30 de setembro nem uma especificação de implementação aprovada integralmente.

## 1. Objetivo e método

O pedido original foi inspecionar o projeto Castle Siege sem modificar arquivos, identificar os sistemas reutilizáveis e separar regras existentes de novidades ou adaptações.

Foram lidos os cinco documentos da branch `main` do repositório privado `gcbraga6-afk/CastleSiege`, na revisão `ac49b45048fc2233c136b0d1ca80d3b98ad79b30`:

- [README.md](https://github.com/gcbraga6-afk/CastleSiege/blob/ac49b45048fc2233c136b0d1ca80d3b98ad79b30/README.md)
- [PROJECT_CONTEXT.md](https://github.com/gcbraga6-afk/CastleSiege/blob/ac49b45048fc2233c136b0d1ca80d3b98ad79b30/PROJECT_CONTEXT.md)
- [GAME_DESIGN.md](https://github.com/gcbraga6-afk/CastleSiege/blob/ac49b45048fc2233c136b0d1ca80d3b98ad79b30/GAME_DESIGN.md)
- [DECISIONS.md](https://github.com/gcbraga6-afk/CastleSiege/blob/ac49b45048fc2233c136b0d1ca80d3b98ad79b30/DECISIONS.md)
- [gameplay/PHASE_SCHEMA.md](https://github.com/gcbraga6-afk/CastleSiege/blob/ac49b45048fc2233c136b0d1ca80d3b98ad79b30/gameplay/PHASE_SCHEMA.md)

Também foi consultada a conversa referenciada, **Reformular Castle Siege**.

O repositório inspecionado continha documentação, sem código-fonte executável. Neste relatório, **existente** significa **documentado**, e não implementação comprovada. A inspeção não alterou arquivos locais de referência nem o repositório remoto.

## 2. Decisões atuais de K**l the Rich

As seguintes decisões foram explicitamente confirmadas pelo usuário na conversa:

1. Soldados não precisam de famílias simuladas ou de aprofundamento desnecessário de sua vida individual.
2. Soldados podem desertar — ir embora ou desaparecer — ou fazer motim, revoltando-se contra a autoridade.
3. A nobreza pode abandonar o Rei.
4. Há um influencer principal por vez; outro pode substituí-lo se morrer.
5. Qualquer personagem pode ser atingido e morrer.
6. Organizações políticas ou sociais concorrentes podem coexistir.
7. A morte ou saída do Rei pode deixar um vácuo de poder, sem substituição imediata obrigatória.
8. Esse vácuo pode gerar caos, oferecer oportunidades ao jogador ou permitir que a vida continue, transmitindo a sensação de que não é necessário haver Rei.
9. O jogador pode aproveitar o vácuo usando flash bombs nos soldados.

Essas decisões devem orientar a adaptação, mesmo quando o jogo antigo possuía outra estrutura.

## 3. Motores já documentados no Castle Siege

### 3.1. Excitação e decaimento

O nome registrado é **Excitação**, apresentado como estado temporal da sequência e camada de ritmo do jogador.

- Aumenta com boas ações, consequências, combos e eventos.
- Decai naturalmente com o tempo.
- Disparos sem consequência relevante reduzem a Excitação ou deixam de sustentá-la.
- Não possui barra visível; áudio e pequenas mudanças de comportamento comunicam seu estado.
- Excitação alta representa uma janela de oportunidade, sem concluir automaticamente a fase.
- Se chega a zero antes do objetivo, a tentativa termina.
- O documento associa seu reset à mudança de Reino.

Sequência conceitual registrada:

```text
baixa → tensão → agitação/Revolta → Revolução → Caos
```

O mesmo documento distingue **Excitação**, **Caos** e **pontuação** como sistemas independentes e também descreve agitação social. Assim, transformar tudo numa única variável social chamada **Frenesi** seria uma adaptação, não uma reprodução literal.

Escala, limiares e tempos de decaimento permanecem em aberto.

Fonte: `PROJECT_CONTEXT.md`, §§6 e 18.

### 3.2. População, Multidão, Revolta e Revolução

A progressão social pode ser resumida conceitualmente como:

```text
civis se agrupam → Multidão → Revolta → Revolução
```

| Estado | Regra documentada |
|---|---|
| Civil | Pode se agrupar e mudar visualmente de roupa/estado para indicar participação. |
| Multidão | Estado social formado por civis agrupados. |
| Revolta | Identificada por tochas; reversível; com o tempo, as tochas diminuem e pode voltar a Multidão. |
| Revolução | Identificada por tochas, foices e martelos; estado mais avançado, reversível e sujeito à regressão temporal. |

Regras adicionais:

- Dano, ações e combos podem alimentar a agitação.
- Quanto mais avançado o estado, mais difícil mantê-lo.
- Soldados com lanças aumentam a repressão e aceleram a perda de agitação.
- A Revolução pode matar o Rei ou destruir estruturas, dependendo da situação.
- O jogador deve continuar agindo para sustentar a cadeia; não é uma sequência automática.
- Revolta pode ser objetivo principal de fase.
- Revolução é evento extraordinário/bônus, e não objetivo principal normal.

Os gatilhos exatos das transições não estão fechados. O encadeamento acima é uma síntese do design, não uma máquina de estados implementada e verificada.

Fonte: `PROJECT_CONTEXT.md`, §§7 e 10; `gameplay/PHASE_SCHEMA.md`.

### 3.3. Soldados e repressão

O ciclo documentado é:

```text
soldado armado
→ sofre dano suficiente
→ perde a lança
→ fica desorganizado
→ recupera HP com o tempo
→ recupera a lança
→ repressão aumenta automaticamente
```

A lança comunica visualmente a capacidade de repressão. Recuperar essa capacidade acelera novamente a regressão social.

Não há exigência documentada de simular famílias ou parentesco dos soldados.

As armas têm efeitos distintos:

| Arma | Efeito relevante |
|---|---|
| Flash Bang | Pequeno dano localizado, clarão, som e pressão; provoca Medo e pode desorganizar soldados. |
| Bomba de Impacto | Desloca objetos/personagens e possui raio específico para remover várias lanças. |
| Bomba Básica | Pode remover lanças quando causa dano suficiente, em raio menor. |

Flash Bang não está documentada como equivalente a um desarme coletivo garantido pela Bomba de Impacto.

Fonte: `PROJECT_CONTEXT.md`, §§8 e 10.

### 3.4. Motim e deserção

**Motim já está documentado** como evento extraordinário de ruptura da autoridade dos soldados. Tem valor elevado na pontuação e peso muito alto no Caos. O esquema de fases reconhece o objetivo `cause_mutiny`.

Não estão definidos em detalhe:

- gatilhos;
- duração;
- alvos dos amotinados;
- relação precisa com Revolta/Revolução;
- comportamento posterior dos soldados envolvidos.

**Deserção de soldados**, no sentido de abandonar o posto e ir embora/desaparecer, **não foi encontrada nos documentos inspecionados**. É uma decisão atual aprovada, mas não deve ser atribuída ao material antigo recuperado.

Fonte: `PROJECT_CONTEXT.md`, §10; `gameplay/PHASE_SCHEMA.md`.

### 3.5. Medo

Medo e dano são efeitos distintos:

```text
raio de impacto → dano
raio maior ao redor → Medo, mesmo sem contato
```

Explosões e destroços que passam perto podem provocar Medo sem atingir diretamente um personagem.

O Castle Siege não define a transformação desse Medo em apoio político, autoritarismo ou procura por liderança. Essas relações pertencem à reformulação.

Fonte: `PROJECT_CONTEXT.md`, §§13–14.

### 3.6. Caos

Caos é descrito como estado temporário do mundo e também como categoria de objetivo/pontuação. Resulta da combinação de sistemas ativos, com pesos diferentes.

| Elemento | Peso qualitativo |
|---|---|
| Fogo | Menor |
| Destruição/colapso | Médio/alto |
| Soldados desorganizados | Médio |
| Multidão | Baixo/médio |
| Revolta | Médio |
| Revolução | Alto |
| Autoridade em fuga | Alto |
| Destroços | Baixo/médio |
| Medo | Baixo |
| Motim | Muito alto |

Não é necessário que todos estejam presentes. Exemplos documentados:

```text
Rei fugiu + Revolução + fogo → Caos
Motim + colapso + destroços → Caos
```

O estado regride quando os eventos terminam. Pesos numéricos e limiar continuam em aberto. A ausência de Rei, isoladamente, não está definida como Caos automático.

Fonte: `PROJECT_CONTEXT.md`, §§17–18.

### 3.7. Rei, fuga, morte e ausência de autoridade

O Rei possui HP interno, sem barra numérica. Mudanças simples no olhar e no corpo comunicam deterioração.

```text
dano → HP diminui → HP crítico pode provocar fuga
HP zero → morte
impacto direto apropriado → pode produzir Headshot
```

HP exato e limiar de fuga não estão definidos.

Existe também um **Primeiro-ministro**:

- nunca aparece junto com o Rei;
- pode aparecer depois da morte do Rei ou em fases posteriores;
- tende a fugir com saúde baixa;
- ao fugir, deixa de atuar como autoridade;
- pode aparecer, desaparecer ou deixar o cenário sem líder.

A possibilidade de ausência de autoridade já existia. Não estavam definidos uma sociedade persistente continuando sem monarca ou um sistema detalhado de disputa pela sucessão.

Fonte: `PROJECT_CONTEXT.md`, §10.

### 3.8. Propaganda e apaziguamento

Não foram encontrados sistemas de propaganda narrativa, influencer, prestígio ou organizações políticas concorrentes.

O antecedente mais próximo é **PAN Y CIRCO**, poder periódico do Rei Final baseado na oferta de comida/entretenimento. Seus efeitos possíveis incluem:

- reduzir Excitação e agitação social;
- acelerar a regressão de Revolta/Revolução;
- acelerar recuperação de soldados/lanças;
- enfraquecer ou apagar fogo em condições definidas.

O jogador pode interromper a preparação atingindo o Rei. A proposta técnica é simples, baseada em timer/variável, sem IA complexa.

Trata-se de um mecanismo documentado de apaziguamento. A infraestrutura de propaganda e a disputa de narrativas são ampliações novas.

Fonte: `PROJECT_CONTEXT.md`, §25.

### 3.9. Cadeias físicas e sociais reutilizáveis

O princípio central do Castle Siege já era:

```text
tiro → dano → estado → reação → consequência → nova oportunidade
```

Outros encadeamentos documentados:

- Fogo → deterioração → perda de resistência → explosão posterior remove mais material.
- Remoção de sustentação → colapso → destroços → dano/Medo.
- Dano a soldado especializado → liberação única de munição.
- Dano a depósito → liberação progressiva de estoque finito.
- Uma ação com várias consequências conectadas → combo.

No documento de contexto, fogo sempre tende a regredir e normalmente não se espalha sozinho. Deterioração prepara estruturas, mas não causa automaticamente sua destruição completa ou colapso. O jogador continua alimentando a cadeia.

Fonte: `PROJECT_CONTEXT.md`, §§9–15 e 31.

## 4. Comparação com K**l the Rich

| Decisão atual | Classificação diante do Castle Siege inspecionado |
|---|---|
| Soldados sem famílias simuladas | Compatível com o modelo simples existente. |
| Soldados podem fazer motim | Reutiliza evento existente; gatilhos e comportamento precisam de definição. |
| Soldados podem desertar e desaparecer | Regra adicional aprovada na conversa atual. |
| Nobreza pode abandonar o Rei | Nova camada de atores e lealdades. |
| Um influencer principal por vez, substituível se morrer | Novo; o Primeiro-ministro é antecedente de substituição de autoridade, não de propaganda. |
| Qualquer personagem pode morrer | Generalização nova; morte do Rei e dano a personagens já existem, mas a regra universal não está explicitada. |
| Organizações concorrentes coexistem | Novo; os estados sociais antigos não constituem organizações independentes. |
| Morte/saída do Rei pode deixar vácuo | Reutiliza a possibilidade de cenário sem líder. |
| Vida pode continuar sem Rei | Ampliação para uma sociedade persistente. |
| Flash bombs em soldados durante o vácuo | Combinação coerente de mecanismos existentes; interação específica não documentada anteriormente. |
| Medo e propaganda podem favorecer autoritarismo | Nova relação política construída sobre Medo já existente. |

## 5. Propostas da reformulação que não devem ser confundidas com regras antigas

Na conversa referenciada, o assistente propôs cinco forças internas: **Frenesi, Medo, Confiança coletiva, Propaganda e Repressão**, além de **Prestígio** para personagens que disputam liderança.

Foram discutidas relações conceituais como:

- Frenesi alto + confiança coletiva alta + medo baixo → mobilização popular.
- Frenesi alto + medo alto + confiança coletiva baixa → procura por autoridade.
- Medo alto + propaganda forte + prestígio do Rei → endurecimento do regime pelo próprio Rei.
- Influencer com audiência/prestígio pode romper com o Rei e disputar poder.
- Destruir a infraestrutura de transmissão reduz seu alcance, mas não elimina automaticamente pessoas ou ideias.

Essas relações são **propostas conceituais da reformulação**, não fórmulas recuperadas do Castle Siege nem parâmetros finais validados. O usuário pediu uma equação de prestígio, mas os componentes sugeridos pelo assistente não constituem uma fórmula fechada.

A principal cautela é preservar a distinção entre **ritmo da intervenção do jogador** e **estado social da população**, em vez de fundi-los automaticamente no Frenesi.

## 6. Mudança estrutural necessária: fase versus Reino persistente

O Castle Siege documentado encerra a fase quando o objetivo é cumprido:

```text
objetivo concluído
→ controle do jogador é retirado
→ curta resolução de consequências já iniciadas
→ pontuação/estrelas/Caos
→ mapa
```

O estado físico detalhado da fase não é salvo; uma nova entrada reinicia a situação.

K**l the Rich pretende permitir:

```text
Rei morre ou foge
→ pode surgir vácuo de poder
→ jogador ainda pode interferir
→ sociedade continua evoluindo
→ consequências permanecem relevantes em visitas futuras
```

Isso exige adaptar a estrutura de encerramento e persistência. A morte do Rei deixa de precisar funcionar como conclusão da experiência naquele lugar.

Da mesma forma, a regressão da agitação não precisa significar que todas as mudanças sociais ou materiais sejam desfeitas. Essa separação é uma questão de adaptação a resolver, não uma regra já fechada nesta conversa.

Fonte do funcionamento antigo: `PROJECT_CONTEXT.md`, §§23–24 e 30.

## 7. Divergências e lacunas do material original

Os documentos não estão completamente harmonizados:

- `GAME_DESIGN.md` e `DECISIONS.md` registram três vidas e estrelas baseadas em tiros.
- `PROJECT_CONTEXT.md` remove vidas, define dez bombas por tentativa e estrelas por desempenho.
- `PHASE_SCHEMA.md` confirma dez bombas para uma tentativa normal.
- Há divergência sobre fogo destruir completamente estruturas: o contexto determina deterioração sem destruição completa pelo fogo sozinho, enquanto o design registra desaparecimento do bloco de madeira após queimar.
- O contexto admite “Causar Caos” como objetivo, mas esse tipo não consta da lista de IDs do esquema de fases inspecionado.

Não se deve resolver silenciosamente essas diferenças por inferência ou tratar o conjunto como especificação única já consolidada.

Continuam em aberto, entre outros:

- HP e limiares de fuga;
- tempos de recuperação dos soldados;
- tempos de regressão de Fogo, Revolta, Revolução e Caos;
- pesos e limiares numéricos de Caos;
- condições exatas para motim e transições sociais;
- relação operacional entre Excitação e agitação social;
- comportamento detalhado durante a ausência de autoridade.

## 8. Resultado da conversa

Foi recuperada uma base documental suficiente para reutilizar:

1. Agitação social reversível, alimentada por acontecimentos.
2. Repressão física visível e recuperável por soldados com lanças.
3. Motim como ruptura extraordinária da autoridade.
4. Medo por proximidade, separado de dano.
5. Caos produzido pela combinação de sistemas.
6. Rei que pode fugir ou morrer e cenário que pode ficar sem líder.
7. Cadeias físicas que criam novas oportunidades de intervenção.

Deserção, nobreza com lealdade variável, influencer substituível, organizações concorrentes, propaganda política e continuidade da vida sem Rei pertencem à reformulação atual. Confiança coletiva e a formalização de prestígio permanecem propostas a consolidar.

Nenhuma implementação foi realizada. Este arquivo é apenas o relatório solicitado da conversa e de seus achados.
