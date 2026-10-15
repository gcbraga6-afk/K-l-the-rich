# Castelo — fachada e interior

Duas imagens de **1111 × 1416**, na mesma tela e alinhadas pixel a pixel.

- `castle_facade.png` — elevação lateral chapada, fechada e opaca, fundo transparente,
  sem chão nem sombra. É a silhueta que o `carved_facade` recorta.
- `castle_interior.png` — o mesmo castelo com a parede da frente removida. Fica
  **atrás** da fachada e só aparece onde a bomba abre buraco.

A fachada chegou do gerador com um **quadriculado pintado** no lugar de transparência
(branco 253 e cinza 215, quadrados de ~10 px). Foi removido por preenchimento a partir
das bordas, aceitando só pixel neutro e claro — a pedra do castelo é creme, com R > B,
então nada dela foi comido. 31,2% da imagem era fundo.

As silhuetas batem em 98%: a fachada é inteiramente coberta pelo interior, e só 1% do
interior sobra para fora dela. Ou seja, buraco em qualquer parede encontra arte atrás.

**O que não bate:** o arranjo de torres do interior não é o mesmo da fachada, então as
salas não ficam exatamente atrás das janelas correspondentes. Para o recorte isso não
importa. Para "o Rei aparece naquela janela", as zonas de janela e de sala são
definidas à mão sobre a fachada, não deduzidas do desenho.

Salas presentes no interior: observatório, aposentos reais, escritório, salão de
banquete, quartel com beliches e lanças, prisão com celas gradeadas, cozinha com
fornalha, tesouro, sala de água com cisterna, bomba e canos, e paiol com barris e
balas. É a lista inteira que a Etapa B precisa.
