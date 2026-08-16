-- ECOSTYLE_DB - TRIGGERS

USE ecostyle_db;

DELIMITER //

-- TRIGGER 1 - Tabela: PEDIDO_ITENS (AFTER INSERT)
-- REGRA DE NEGÓCIO: o ValorTotal do pedido precisa refletir sempre a
-- soma dos itens lançados, mesmo que o item seja inserido diretamente
-- (fora da procedure sp_AdicionarItemPedido). O trigger garante essa
-- consistência automaticamente em qualquer caminho de inserção.

CREATE TRIGGER trg_pedido_itens_after_insert
AFTER INSERT ON PEDIDO_ITENS
FOR EACH ROW
BEGIN
    UPDATE PEDIDOS
       SET ValorTotal = ValorTotal + (NEW.Quantidade * NEW.PrecoUnitario)
     WHERE IDPedido = NEW.IDPedido;
END//


-- TRIGGER 2 - Tabela: ESTOQUE (BEFORE INSERT)
-- REGRA DE NEGÓCIO: nenhum movimento de SAÍDA pode deixar o estoque
-- do produto negativo. O trigger valida a quantidade disponível antes
-- de aceitar o registro, protegendo a integridade mesmo se alguém
-- inserir diretamente na tabela ESTOQUE, sem passar pela procedure.

CREATE TRIGGER trg_estoque_before_insert
BEFORE INSERT ON ESTOQUE
FOR EACH ROW
BEGIN
    DECLARE v_EstoqueAtual INT;

    SELECT Quantidade INTO v_EstoqueAtual
    FROM PRODUTOS
    WHERE IDProdutos = NEW.IDProduto;

    IF NEW.Tipo = 'SAIDA' AND v_EstoqueAtual < NEW.Quantidade THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Movimento de saída maior que o estoque disponível do produto.';
    END IF;
END//


-- TRIGGER 3 - Tabela: ESTOQUE (AFTER INSERT)
-- REGRA DE NEGÓCIO: toda movimentação registrada em ESTOQUE precisa
-- refletir imediatamente na quantidade disponível do produto
-- (PRODUTOS.Quantidade), sem depender de lógica externa na aplicação.

CREATE TRIGGER trg_estoque_after_insert
AFTER INSERT ON ESTOQUE
FOR EACH ROW
BEGIN
    IF NEW.Tipo = 'ENTRADA' THEN
        UPDATE PRODUTOS SET Quantidade = Quantidade + NEW.Quantidade WHERE IDProdutos = NEW.IDProduto;
    ELSE
        UPDATE PRODUTOS SET Quantidade = Quantidade - NEW.Quantidade WHERE IDProdutos = NEW.IDProduto;
    END IF;
END//


-- TRIGGER 4 (extra) - Tabela: CLIENTE (BEFORE INSERT)
-- REGRA DE NEGÓCIO: o CPF do cliente deve ser armazenado sempre em
-- formato numérico puro (sem pontos/traços), garantindo padronização
-- do dado independentemente de como o valor chegou até o banco.

CREATE TRIGGER trg_cliente_before_insert
BEFORE INSERT ON CLIENTE
FOR EACH ROW
BEGIN
    SET NEW.CPF = REPLACE(REPLACE(NEW.CPF, '.', ''), '-', '');

    IF LENGTH(NEW.CPF) <> 11 OR NEW.CPF NOT REGEXP '^[0-9]{11}$' THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'CPF do cliente deve conter exatamente 11 dígitos numéricos.';
    END IF;
END//

DELIMITER ;
