-- Triggers SkyLodge
-- 1)Trigger
-- Esse trigger será executado antes de inserir uma reserva.
-- Ele verifica a capacidade do quarto e impede a reserva caso
-- a quantidade de hóspedes seja maior.
DELIMITER $$
CREATE TRIGGER trg_validar_capacidade_reserva
BEFORE INSERT ON RESERVAS
FOR EACH ROW
BEGIN
    DECLARE v_capacidade INT;

    SELECT capacidade
    INTO v_capacidade
    FROM QUARTOS
    WHERE id_quarto = NEW.id_quarto;

    IF NEW.qtd_hospedes > v_capacidade THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Erro: quantidade de hospedes maior que a capacidade do quarto';
    END IF;
END$$
DELIMITER ;

-- 2)Trigger
-- Valida o cliente do pagamento.
DELIMITER $$
CREATE TRIGGER trg_validar_cliente_pagamento
BEFORE INSERT ON PAGAMENTO
FOR EACH ROW
BEGIN
    DECLARE v_cliente_reserva INT;

    SELECT id_cliente
    INTO v_cliente_reserva
    FROM RESERVAS
    WHERE id_reserva = NEW.id_reserva;

    IF v_cliente_reserva <> NEW.id_cliente THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Erro: cliente informado nao corresponde ao cliente da reserva';
    END IF;
END$$
DELIMITER ;

-- 3)Trigger
-- Libera automaticamente o quarto após a limpeza.
DELIMITER $$
CREATE TRIGGER trg_quarto_disponivel_apos_limpeza
AFTER UPDATE ON LIMPEZA
FOR EACH ROW
BEGIN

    IF NEW.status = 'concluida'
       AND OLD.status <> 'concluida' THEN

        UPDATE QUARTOS
        SET status = 'disponivel'
        WHERE id_quarto = NEW.id_quarto;

    END IF;

END$$

DELIMITER ;