
-- Triggers - Banco bibliotech
-- Trigger 1: ao registrar a devolução real de um empréstimo,
-- o exemplar volta automaticamente a ficar "Disponivel" e o
-- empréstimo muda para "Concluido"
DELIMITER //
CREATE TRIGGER trg_atualiza_exemplar_devolucao
BEFORE UPDATE ON emprestimos
FOR EACH ROW
BEGIN
    IF NEW.DevoluçaoReal IS NOT NULL AND OLD.DevoluçaoReal IS NULL THEN
        SET NEW.Status = 'Concluido';
 
        UPDATE exemplares
        SET Status = 'Disponivel'
        WHERE IDexemplar = NEW.IDexemplar;
    END IF;
END //
DELIMITER ;

-- Trigger 2: impede o cadastro de um empréstimo cuja data de
-- devolução prevista seja anterior (ou igual) à data do empréstimo
DELIMITER //
CREATE TRIGGER trg_valida_datas_emprestimo
BEFORE INSERT ON emprestimos
FOR EACH ROW
BEGIN
    IF NEW.DevoluçaoPrevista <= NEW.DataDeEmprestimo THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'A data de devolução prevista deve ser posterior à data do empréstimo';
    END IF;
END //
DELIMITER ;

-- Trigger 3: quando um pagamento é confirmado, a multa
-- correspondente é automaticamente marcada como "Paga"
DELIMITER //
CREATE TRIGGER trg_pagamento_atualiza_multa
AFTER UPDATE ON pagamentos
FOR EACH ROW
BEGIN
    IF NEW.Status = 'Confirmado' AND OLD.Status <> 'Confirmado' THEN
        UPDATE multas
        SET StatusMulta = 'Paga'
        WHERE IDmulta = NEW.IDmulta;
    END IF;
END //
DELIMITER ;