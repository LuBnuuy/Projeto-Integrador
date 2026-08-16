DELIMITER $$

CREATE TRIGGER trg_atualiza_km
AFTER INSERT ON consumo_combustivel
FOR EACH ROW
BEGIN
    UPDATE frota
    SET km = km + NEW.km_percorrido
    WHERE id_veiculo = NEW.id_veiculo;
END $$
DELIMITER ;

-- valida_motorista_entrega
-- Regra: só pode ser registrada uma entrega se o funcionário
-- vinculado tiver o cargo de 'Motorista'. Caso contrário, a
-- inserção é bloqueada com uma mensagem de erro.

DELIMITER $$
CREATE TRIGGER trg_valida_motorista_entrega
BEFORE INSERT ON entregas
FOR EACH ROW
BEGIN
    DECLARE v_cargo VARCHAR(255);
 
    SELECT cargo INTO v_cargo
    FROM funcionarios
    WHERE id_funcionario = NEW.id_funcionario;
 
    IF v_cargo IS NULL OR v_cargo <> 'Motorista' THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'O funcionário informado não é um motorista e não pode ser vinculado a uma entrega.';
    END IF;
END $$
DELIMITER ;

--  trg_data_entrega_automatica
-- Regra: sempre que o status de uma entrega for atualizado
-- para 'Entregue' e a data_entrega ainda não tiver sido
-- preenchida, o sistema grava automaticamente a data atual.

DELIMITER $$
CREATE TRIGGER trg_data_entrega_automatica
BEFORE UPDATE ON entregas
FOR EACH ROW
BEGIN
    IF NEW.status = 'Entregue' AND NEW.data_entrega IS NULL THEN
        SET NEW.data_entrega = CURDATE();
    END IF;
END $$
DELIMITER ;
