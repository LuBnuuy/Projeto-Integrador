
-- Triggers - Banco tunestream
-- Trigger 1: calcula automaticamente a posição (Ordem) de uma
-- faixa ao ser adicionada em uma playlist, mesmo em inserts
-- feitos diretamente na tabela (sem passar pela procedure)
DELIMITER //
CREATE TRIGGER trg_playlist_faixas_ordem
BEFORE INSERT ON playlist_faixas
FOR EACH ROW
BEGIN
    DECLARE v_ProximaOrdem INT;
 
    SELECT IFNULL(MAX(Ordem), 0) + 1 INTO v_ProximaOrdem
    FROM playlist_faixas
    WHERE IDplaylist = NEW.IDplaylist;
 
    SET NEW.Ordem = v_ProximaOrdem;
END //
DELIMITER ;

-- Trigger 2: ao marcar um royalty como "Pago", preenche
-- automaticamente a DataPagamento com a data atual
DELIMITER //
CREATE TRIGGER trg_royalty_data_pagamento
BEFORE UPDATE ON royalties
FOR EACH ROW
BEGIN
    IF NEW.StatusPagamento = 'Pago' AND OLD.StatusPagamento <> 'Pago' THEN
        SET NEW.DataPagamento = CURDATE();
    END IF;
END //
DELIMITER ;

-- Trigger 3: impede que uma reprodução seja registrada no
-- histórico caso a conta do usuário esteja suspensa
DELIMITER //
CREATE TRIGGER trg_historico_valida_usuario
BEFORE INSERT ON historico
FOR EACH ROW
BEGIN
    DECLARE v_StatusConta VARCHAR(20);
 
    SELECT StatusConta INTO v_StatusConta
    FROM usuarios
    WHERE IDusuario = NEW.IDusuario;
 
    IF v_StatusConta = 'Suspenso' THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Usuário suspenso não pode reproduzir faixas';
    END IF;
END //
DELIMITER ;
