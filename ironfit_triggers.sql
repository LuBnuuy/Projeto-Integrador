-- IRON_FIT - TRIGGERS

USE iron_fit;

DELIMITER //

-- TRIGGER 1 - Tabela: assinaturas (AFTER UPDATE)
-- REGRA DE NEGÓCIO: quando a assinatura de um membro é cancelada, ele
-- não pode continuar frequentando aulas em grupo. O trigger cancela
-- automaticamente todas as matrículas ativas desse membro assim que a
-- assinatura muda para 'cancelada'.

CREATE TRIGGER trg_assinaturas_after_update
AFTER UPDATE ON assinaturas
FOR EACH ROW
BEGIN
    IF OLD.status <> 'cancelada' AND NEW.status = 'cancelada' THEN
        UPDATE matricula_aulas
           SET status = 'cancelada'
         WHERE IDMembro = NEW.IDMembro
           AND status = 'ativa';
    END IF;
END//


-- TRIGGER 2 - Tabela: avaliacoes_fisicas (BEFORE INSERT)
-- REGRA DE NEGÓCIO: o IMC do membro deve ser calculado automaticamente
-- pela fórmula peso / altura², a cada nova avaliação física, evitando
-- que o trainer precise calcular (e possivelmente errar) esse valor
-- manualmente.

CREATE TRIGGER trg_avaliacoes_fisicas_before_insert
BEFORE INSERT ON avaliacoes_fisicas
FOR EACH ROW
BEGIN
    SET NEW.IMC = ROUND(NEW.PesoKg / (NEW.AlturaM * NEW.AlturaM), 2);
END//


-- TRIGGER 3 - Tabela: matricula_aulas (BEFORE INSERT)
-- REGRA DE NEGÓCIO: uma aula em grupo não pode receber mais matrículas
-- ativas do que sua CapacidadeMaxima. O trigger funciona como uma
-- segunda camada de proteção (além da procedure sp_MatricularMembroAula),
-- bloqueando também inserções feitas diretamente na tabela.

CREATE TRIGGER trg_matricula_aulas_before_insert
BEFORE INSERT ON matricula_aulas
FOR EACH ROW
BEGIN
    DECLARE v_CapacidadeMaxima   INT;
    DECLARE v_MatriculadosAtivos INT;

    SELECT CapacidadeMaxima INTO v_CapacidadeMaxima
    FROM aulas_grupo
    WHERE IDAula = NEW.IDAula;

    SELECT COUNT(*) INTO v_MatriculadosAtivos
    FROM matricula_aulas
    WHERE IDAula = NEW.IDAula AND status = 'ativa';

    IF NEW.status = 'ativa' AND v_MatriculadosAtivos >= v_CapacidadeMaxima THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Capacidade máxima da aula já foi atingida.';
    END IF;
END//

DELIMITER ;
