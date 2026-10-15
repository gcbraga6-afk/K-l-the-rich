# Props e personagens recortados do sheet

Recortados de um sheet 1254×1254 gerado com fundo **já transparente**, por
componentes conectados, e depois aparados na própria caixa.

| arquivo | tamanho | usado por |
| --- | --- | --- |
| `props/supply_cart.png` | 512×307 | [supply_cart.gd](../../scripts/world/supply_cart.gd), desenhado com 230 de largura |
| `props/powder_pile.png` | 264×238 | [powder_store.gd](../../scripts/world/powder_store.gd), 210 de largura |
| `props/supply_balloon.png` | 307×586 | ainda não ligado — segunda fonte de munição, aérea |
| `props/royal_banner.png` | 178×396 | ainda não ligado — a bandeirinha nas janelas |
| `characters/guard_shout.png` | 331×415 | ainda não ligado — soldado que grita e aponta |
| `characters/guard_advance.png` | 386×326 | ainda não ligado — soldado avançando |
| `characters/guard_broken.png` | 147×324 | ainda não ligado — desarmado, sem capacete |
| `ui/speech_01..04.png` | ~600×370 | ainda não ligado — balões dos micro-diálogos |

Os quatro balões vieram num sheet separado, de 1536×1024, com **xadrez pintado** no
lugar de transparência (branco 253, cinza 215). Removido por preenchimento a partir
das bordas, aceitando só pixel neutro e claro: 55,5% da imagem era fundo.

**A carroça pintada não tem carreteiro.** Quem conduz é um trabalhador do próprio
`people_walk.png`, desenhado a 80 de altura ao lado da cabeça do cavalo — a mesma
altura em que a vila inteira anda. Era essa a intenção: acertar a boleia tem de
matar um trabalhador, não um boneco próprio do prop.
