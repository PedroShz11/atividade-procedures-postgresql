-- Consulte os dados iniciais.
SELECT * FROM hospedes ORDER BY id_hospede;
SELECT * FROM reservas ORDER BY id_reserva;

-- Questão 1: cadastro. Use um e-mail ainda não cadastrado.
CALL cadastrar_hospede('Eva Lima', 'eva@email.com', '86999990005');

-- Questões 2 a 4: atualização e consulta.
CALL atualizar_telefone_hospede(1, '86988880001');
CALL consultar_hospede(1);
-- CALL consultar_hospede(99999); -- Esperado: erro de hóspede inexistente.

-- Questões 5 a 7: criação de reserva.
CALL criar_reserva(1, DATE '2026-12-01', DATE '2026-12-04', 275.00);
-- CALL criar_reserva(99999, DATE '2026-12-01', DATE '2026-12-04', 275.00); -- hóspede inexistente
-- CALL criar_reserva(1, DATE '2026-12-04', DATE '2026-12-04', 275.00); -- datas inválidas

-- Questões 8 e 9: cancelar reserva.
CALL cancelar_reserva(1);
-- CALL cancelar_reserva(1); -- Esperado: erro, já cancelada.

-- Questões 10 e 11: cálculo.
CALL calcular_valor_reserva(2);
CALL calcular_valor_com_desconto(2, 10.00);

-- Questão 12: finaliza uma reserva ativa.
CALL finalizar_reserva(2);

-- Questão 13: altere o ID se a reserva 3 já tiver sido modificada/finalizada.
CALL alterar_valor_diaria(3, 225.00);
-- CALL alterar_valor_diaria(3, 0); -- Esperado: diária precisa ser positiva.

-- Questão 14: a reserva 1 foi cancelada acima.
CALL reabrir_reserva(1);

-- Questão 15: confirma uma reserva ativa.
CALL confirmar_reserva(1);

SELECT * FROM hospedes ORDER BY id_hospede;
SELECT * FROM reservas ORDER BY id_reserva;
