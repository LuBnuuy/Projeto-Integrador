
-- Triggers - Banco edugest
-- Trigger 1: ao preencher a Data_Pagamento de uma mensalidade,
-- o Estado_Pagamento é automaticamente atualizado para "Pago"
DELIMITER //
CREATE TRIGGER trg_mensalidade_baixa_automatica
BEFORE UPDATE ON mensalidade
FOR EACH ROW
BEGIN
    IF NEW.Data_Pagamento IS NOT NULL AND OLD.Data_Pagamento IS NULL THEN
        SET NEW.Estado_Pagamento = 'Pago';
    END IF;
END //
DELIMITER ;

-- Trigger 2: impede matricular um aluno em uma turma que já
-- atingiu o limite de vagas, mesmo em inserts diretos na tabela
DELIMITER //
CREATE TRIGGER trg_matricula_valida_vagas
BEFORE INSERT ON matricula
FOR EACH ROW
BEGIN
    DECLARE v_Vagas INT;
    DECLARE v_MatriculasAtivas INT;
 
    SELECT Vagas INTO v_Vagas
    FROM turma
    WHERE IDturma = NEW.IDturma;
 
    SELECT COUNT(*) INTO v_MatriculasAtivas
    FROM matricula
    WHERE IDturma = NEW.IDturma AND Estado = 'Ativa';
 
    IF v_MatriculasAtivas >= v_Vagas THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Turma sem vagas disponíveis';
    END IF;
END //
DELIMITER ;

-- Trigger 3: garante que nenhuma nota fora do intervalo de
-- 0 a 10 seja gravada na tabela
DELIMITER //
CREATE TRIGGER trg_nota_valida_valor
BEFORE INSERT ON nota
FOR EACH ROW
BEGIN
    IF NEW.Valor < 0 OR NEW.Valor > 10 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Valor da nota deve estar entre 0 e 10';
    END IF;
END //
DELIMITER ;
