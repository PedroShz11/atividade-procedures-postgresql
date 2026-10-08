-- Estrutura do sistema de reservas de hotel.
CREATE TABLE IF NOT EXISTS hospedes (
    id_hospede SERIAL PRIMARY KEY,
    nome VARCHAR(100) NOT NULL,
    email VARCHAR(150) UNIQUE NOT NULL,
    telefone VARCHAR(20)
);

CREATE TABLE IF NOT EXISTS reservas (
    id_reserva SERIAL PRIMARY KEY,
    id_hospede INTEGER NOT NULL REFERENCES hospedes(id_hospede),
    data_checkin DATE NOT NULL,
    data_checkout DATE NOT NULL,
    valor_diaria NUMERIC(10,2) NOT NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'ATIVA'
);

INSERT INTO hospedes (nome, email, telefone) VALUES
    ('Ana Oliveira', 'ana@email.com', '86999990001'),
    ('Bruno Santos', 'bruno@email.com', '86999990002'),
    ('Carla Mendes', 'carla@email.com', '86999990003'),
    ('Daniel Costa', 'daniel@email.com', '86999990004')
ON CONFLICT (email) DO NOTHING;

-- Garante IDs de hóspede corretos mesmo se o banco já possuía dados.
INSERT INTO reservas (id_hospede, data_checkin, data_checkout, valor_diaria, status)
SELECT h.id_hospede, v.data_checkin, v.data_checkout, v.valor_diaria, 'ATIVA'
FROM (VALUES
    ('ana@email.com', DATE '2026-10-10', DATE '2026-10-13', 250.00::numeric),
    ('bruno@email.com', DATE '2026-10-15', DATE '2026-10-18', 300.00::numeric),
    ('carla@email.com', DATE '2026-11-05', DATE '2026-11-07', 200.00::numeric)
) AS v(email, data_checkin, data_checkout, valor_diaria)
JOIN hospedes h USING (email)
WHERE NOT EXISTS (
    SELECT 1 FROM reservas r
    WHERE r.id_hospede = h.id_hospede
      AND r.data_checkin = v.data_checkin
      AND r.data_checkout = v.data_checkout
);
