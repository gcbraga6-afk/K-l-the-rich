# Mapas de materiais

Um PNG por casa, do mesmo tamanho da região da casa no atlas, nomeado pelo índice
do catálogo: `house_02.png` é `house_catalog.house(2)`.

A cor diz do que a parte é feita, e cada material falha de um jeito:

| cor            | material | como falha                                        |
|----------------|----------|---------------------------------------------------|
| vermelho       | telhado  | o vão desaba e as telhas caem para dentro         |
| branco/cinza   | parede   | buraco rasgado, a casa continua de pé             |
| azul           | janela   | a abertura inteira arrebenta, a parede em volta fica |
| marrom         | madeira  | porta, postes e lenha                             |
| transparente   | nada     | fora da casa                                      |

Uma janela é achada como uma mancha ligada de pixels azuis, e falha como uma peça
só — é essa a diferença entre uma bomba levar a janela e uma bomba cortar a janela
pela metade junto com a parede.

Pinte a janela **com as venezianas**: elas vão junto.

Casa sem mapa continua funcionando: tudo vira alvenaria e o telhado é deduzido da
silhueta. Então dá para mapear as casas aos poucos.
