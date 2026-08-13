DELIMITER $$

/* ============================================================
   TRIGGER 1

   Impede que a quantidade do estoque fique negativa
   ============================================================ */

CREATE TRIGGER trg_estoque_quantidade
BEFORE UPDATE ON estoque
FOR EACH ROW
BEGIN
    IF NEW.quantidade < 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'A quantidade do estoque não pode ser negativa';
    END IF;
END$$


/* ============================================================
   TRIGGER 2
   Registra automaticamente a entrada de um item no estoque
   ============================================================ */

CREATE TRIGGER trg_estoque_entrada
AFTER INSERT ON estoque
FOR EACH ROW
BEGIN
    IF NEW.id_funcionario IS NOT NULL THEN
        INSERT INTO log_acesso_estoque
        (
            id_funcionario,
            id_estoque,
            tipo_acesso,
            quantidade_movimentada,
            observacao
        )
        VALUES
        (
            NEW.id_funcionario,
            NEW.id_estoque,
            'ENTRADA',
            NEW.quantidade,
            'Entrada de item no estoque'
        );
    END IF;
END$$



  -- TRIGGER 3
 --  Registra alterações na quantidade do estoque


CREATE TRIGGER trg_estoque_movimentacao
AFTER UPDATE ON estoque
FOR EACH ROW
BEGIN
    IF OLD.quantidade <> NEW.quantidade
       AND NEW.id_funcionario IS NOT NULL THEN

        INSERT INTO log_acesso_estoque
        (
            id_funcionario,
            id_estoque,
            tipo_acesso,
            quantidade_movimentada,
            observacao
        )
        VALUES
        (
            NEW.id_funcionario,
            NEW.id_estoque,
            'MOVIMENTACAO',
            NEW.quantidade - OLD.quantidade,
            'Alteração automática da quantidade do estoque'
        );

    END IF;
END$$