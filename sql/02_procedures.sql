-- 1. Cadastra um hóspede.
CREATE OR REPLACE PROCEDURE cadastrar_hospede(p_nome VARCHAR, p_email VARCHAR, p_telefone VARCHAR)
LANGUAGE plpgsql AS $$
BEGIN
    INSERT INTO hospedes (nome, email, telefone) VALUES (p_nome, p_email, p_telefone);
    RAISE INFO 'Hóspede % cadastrado com sucesso.', p_nome;
END; $$;

-- 2. Atualiza o telefone de um hóspede existente.
CREATE OR REPLACE PROCEDURE atualizar_telefone_hospede(p_id_hospede INTEGER, p_novo_telefone VARCHAR)
LANGUAGE plpgsql AS $$
BEGIN
    UPDATE hospedes SET telefone = p_novo_telefone WHERE id_hospede = p_id_hospede;
    IF NOT FOUND THEN RAISE EXCEPTION 'Hóspede % não encontrado.', p_id_hospede; END IF;
    RAISE INFO 'Telefone do hóspede % atualizado.', p_id_hospede;
END; $$;

-- 3 e 4. Consulta o hóspede e informa se não existir.
CREATE OR REPLACE PROCEDURE consultar_hospede(p_id_hospede INTEGER)
LANGUAGE plpgsql AS $$
DECLARE v_hospede hospedes%ROWTYPE;
BEGIN
    SELECT * INTO v_hospede FROM hospedes WHERE id_hospede = p_id_hospede;
    IF NOT FOUND THEN RAISE EXCEPTION 'Hóspede % não encontrado.', p_id_hospede; END IF;
    RAISE INFO 'Nome: % | E-mail: % | Telefone: %', v_hospede.nome, v_hospede.email, COALESCE(v_hospede.telefone, 'não informado');
END; $$;

-- 5, 6 e 7. Cria reserva após validar hóspede, datas e diária.
CREATE OR REPLACE PROCEDURE criar_reserva(p_id_hospede INTEGER, p_data_checkin DATE, p_data_checkout DATE, p_valor_diaria NUMERIC(10,2))
LANGUAGE plpgsql AS $$
DECLARE v_id_hospede INTEGER;
BEGIN
    SELECT id_hospede INTO v_id_hospede FROM hospedes WHERE id_hospede = p_id_hospede;
    IF NOT FOUND THEN RAISE EXCEPTION 'Hóspede % não encontrado; reserva não criada.', p_id_hospede; END IF;
    IF p_data_checkout <= p_data_checkin THEN RAISE EXCEPTION 'O check-out deve ser posterior ao check-in.'; END IF;
    IF p_valor_diaria <= 0 THEN RAISE EXCEPTION 'O valor da diária deve ser maior que zero.'; END IF;
    INSERT INTO reservas (id_hospede, data_checkin, data_checkout, valor_diaria, status) VALUES (v_id_hospede, p_data_checkin, p_data_checkout, p_valor_diaria, 'ATIVA');
    RAISE INFO 'Reserva criada com sucesso para o hóspede %.', p_id_hospede;
END; $$;

-- 8 e 9. Cancela somente reservas existentes e ainda não canceladas.
CREATE OR REPLACE PROCEDURE cancelar_reserva(p_id_reserva INTEGER)
LANGUAGE plpgsql AS $$
DECLARE v_status reservas.status%TYPE;
BEGIN
    SELECT status INTO v_status FROM reservas WHERE id_reserva = p_id_reserva;
    IF NOT FOUND THEN RAISE EXCEPTION 'Reserva % não encontrada.', p_id_reserva; END IF;
    IF v_status = 'CANCELADA' THEN RAISE EXCEPTION 'A reserva % já está cancelada.', p_id_reserva; END IF;
    UPDATE reservas SET status = 'CANCELADA' WHERE id_reserva = p_id_reserva;
    RAISE INFO 'Reserva % cancelada.', p_id_reserva;
END; $$;

-- 10. Calcula o valor total (número de noites * diária).
CREATE OR REPLACE PROCEDURE calcular_valor_reserva(p_id_reserva INTEGER)
LANGUAGE plpgsql AS $$
DECLARE v_checkin DATE; v_checkout DATE; v_diaria NUMERIC(10,2); v_total NUMERIC(12,2);
BEGIN
    SELECT data_checkin, data_checkout, valor_diaria INTO v_checkin, v_checkout, v_diaria FROM reservas WHERE id_reserva = p_id_reserva;
    IF NOT FOUND THEN RAISE EXCEPTION 'Reserva % não encontrada.', p_id_reserva; END IF;
    v_total := (v_checkout - v_checkin) * v_diaria;
    RAISE INFO 'Valor total da reserva %: R$ %', p_id_reserva, to_char(v_total, 'FM999999990.00');
END; $$;

-- 11. Calcula o total após aplicar desconto entre 0 e 100 por cento.
CREATE OR REPLACE PROCEDURE calcular_valor_com_desconto(p_id_reserva INTEGER, p_percentual_desconto NUMERIC(5,2))
LANGUAGE plpgsql AS $$
DECLARE v_checkin DATE; v_checkout DATE; v_diaria NUMERIC(10,2); v_total NUMERIC(12,2); v_com_desconto NUMERIC(12,2);
BEGIN
    IF p_percentual_desconto < 0 OR p_percentual_desconto > 100 THEN RAISE EXCEPTION 'O desconto deve estar entre 0 e 100.'; END IF;
    SELECT data_checkin, data_checkout, valor_diaria INTO v_checkin, v_checkout, v_diaria FROM reservas WHERE id_reserva = p_id_reserva;
    IF NOT FOUND THEN RAISE EXCEPTION 'Reserva % não encontrada.', p_id_reserva; END IF;
    v_total := (v_checkout - v_checkin) * v_diaria;
    v_com_desconto := round(v_total * (1 - p_percentual_desconto / 100), 2);
    RAISE INFO 'Reserva %: total R$ %, desconto %%%, com desconto R$ %', p_id_reserva, to_char(v_total, 'FM999999990.00'), to_char(p_percentual_desconto, 'FM990.00'), to_char(v_com_desconto, 'FM999999990.00');
END; $$;

-- 12. Finaliza reserva ativa e apresenta valor.
CREATE OR REPLACE PROCEDURE finalizar_reserva(p_id_reserva INTEGER)
LANGUAGE plpgsql AS $$
DECLARE v_checkin DATE; v_checkout DATE; v_diaria NUMERIC(10,2); v_status reservas.status%TYPE; v_total NUMERIC(12,2);
BEGIN
    SELECT data_checkin, data_checkout, valor_diaria, status INTO v_checkin, v_checkout, v_diaria, v_status FROM reservas WHERE id_reserva = p_id_reserva;
    IF NOT FOUND THEN RAISE EXCEPTION 'Reserva % não encontrada.', p_id_reserva; END IF;
    IF v_status <> 'ATIVA' THEN RAISE EXCEPTION 'A reserva % precisa estar ATIVA para ser finalizada (status atual: %).', p_id_reserva, v_status; END IF;
    v_total := (v_checkout - v_checkin) * v_diaria;
    UPDATE reservas SET status = 'FINALIZADA' WHERE id_reserva = p_id_reserva;
    RAISE INFO 'Reserva % finalizada. Valor total: R$ %', p_id_reserva, to_char(v_total, 'FM999999990.00');
END; $$;

-- 13. Altera a diária somente em reserva ativa e para valor positivo.
CREATE OR REPLACE PROCEDURE alterar_valor_diaria(p_id_reserva INTEGER, p_novo_valor_diaria NUMERIC(10,2))
LANGUAGE plpgsql AS $$
DECLARE v_status reservas.status%TYPE;
BEGIN
    SELECT status INTO v_status FROM reservas WHERE id_reserva = p_id_reserva;
    IF NOT FOUND THEN RAISE EXCEPTION 'Reserva % não encontrada.', p_id_reserva; END IF;
    IF v_status <> 'ATIVA' THEN RAISE EXCEPTION 'A reserva % não está ATIVA.', p_id_reserva; END IF;
    IF p_novo_valor_diaria <= 0 THEN RAISE EXCEPTION 'O novo valor da diária deve ser maior que zero.'; END IF;
    UPDATE reservas SET valor_diaria = p_novo_valor_diaria WHERE id_reserva = p_id_reserva;
    RAISE INFO 'Diária da reserva % alterada para R$ %.', p_id_reserva, to_char(p_novo_valor_diaria, 'FM999999990.00');
END; $$;

-- 14. Reabre apenas reservas canceladas.
CREATE OR REPLACE PROCEDURE reabrir_reserva(p_id_reserva INTEGER)
LANGUAGE plpgsql AS $$
DECLARE v_status reservas.status%TYPE;
BEGIN
    SELECT status INTO v_status FROM reservas WHERE id_reserva = p_id_reserva;
    IF NOT FOUND THEN RAISE EXCEPTION 'Reserva % não encontrada.', p_id_reserva; END IF;
    IF v_status <> 'CANCELADA' THEN RAISE EXCEPTION 'A reserva % não pode ser reaberta; status atual: %.', p_id_reserva, v_status; END IF;
    UPDATE reservas SET status = 'ATIVA' WHERE id_reserva = p_id_reserva;
    RAISE INFO 'Reserva % reaberta e marcada como ATIVA.', p_id_reserva;
END; $$;

-- 15. Valida e apresenta os dados da reserva e seu valor total.
CREATE OR REPLACE PROCEDURE confirmar_reserva(p_id_reserva INTEGER)
LANGUAGE plpgsql AS $$
DECLARE v_reserva reservas%ROWTYPE; v_nome hospedes.nome%TYPE; v_email hospedes.email%TYPE; v_telefone hospedes.telefone%TYPE; v_total NUMERIC(12,2);
BEGIN
    SELECT * INTO v_reserva FROM reservas WHERE id_reserva = p_id_reserva;
    IF NOT FOUND THEN RAISE EXCEPTION 'Reserva % não encontrada.', p_id_reserva; END IF;
    SELECT nome, email, telefone INTO v_nome, v_email, v_telefone FROM hospedes WHERE id_hospede = v_reserva.id_hospede;
    IF NOT FOUND THEN RAISE EXCEPTION 'Hóspede associado à reserva % não encontrado.', p_id_reserva; END IF;
    IF v_reserva.status <> 'ATIVA' THEN RAISE EXCEPTION 'A reserva % precisa estar ATIVA (status atual: %).', p_id_reserva, v_reserva.status; END IF;
    IF v_reserva.data_checkout <= v_reserva.data_checkin THEN RAISE EXCEPTION 'O check-out deve ser posterior ao check-in.'; END IF;
    IF v_reserva.valor_diaria <= 0 THEN RAISE EXCEPTION 'O valor da diária deve ser maior que zero.'; END IF;
    v_total := (v_reserva.data_checkout - v_reserva.data_checkin) * v_reserva.valor_diaria;
    RAISE INFO 'Reserva: % | Status: % | Check-in: % | Check-out: % | Diária: R$ %', v_reserva.id_reserva, v_reserva.status, v_reserva.data_checkin, v_reserva.data_checkout, to_char(v_reserva.valor_diaria, 'FM999999990.00');
    RAISE INFO 'Hóspede: % | E-mail: % | Telefone: %', v_nome, v_email, COALESCE(v_telefone, 'não informado');
    RAISE INFO 'Noites: % | Valor total: R$ %', (v_reserva.data_checkout - v_reserva.data_checkin), to_char(v_total, 'FM999999990.00');
END; $$;
