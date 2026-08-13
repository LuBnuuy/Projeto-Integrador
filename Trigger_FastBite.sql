-- =========================================================
-- TRIGGERS
-- TOTAL: 3
-- =========================================================

DELIMITER $$


-- =========================================================
-- TRIGGER 1
-- HISTORICO DE SENHA
--
-- Quando a senha do cliente for alterada,
-- a senha anterior será armazenada automaticamente.
-- =========================================================

CREATE TRIGGER trg_cliente_alteracao_senha
BEFORE UPDATE ON Cliente
FOR EACH ROW
BEGIN

    IF NOT (OLD.senha <=> NEW.senha) THEN

        INSERT INTO Historico_Senha (
            cliente_id,
            senha_antiga,
            data_alteracao
        )
        VALUES (
            OLD.cliente_id,
            OLD.senha,
            NOW()
        );

        SET NEW.data_alteracao_senha = NOW();

    END IF;

END$$


-- =========================================================
-- TRIGGER 2
-- INSERCAO DE ITEM NO PEDIDO
--
-- Calcula automaticamente o subtotal do item.
-- Depois recalcula subtotal e total do pedido.
-- =========================================================

CREATE TRIGGER trg_item_pedido_insercao
AFTER INSERT ON Item_pedido
FOR EACH ROW
BEGIN

    UPDATE Item_pedido
    SET subtotal = NEW.quantidade * NEW.preco_unitario
    WHERE item_pedido_id = NEW.item_pedido_id;

    UPDATE Pedido
    SET
        subtotal = (
            SELECT COALESCE(
                SUM(ip.quantidade * ip.preco_unitario),
                0
            )
            FROM Item_pedido ip
            WHERE ip.pedido_id = NEW.pedido_id
        ),

        total = GREATEST(
            (
                SELECT COALESCE(
                    SUM(ip.quantidade * ip.preco_unitario),
                    0
                )
                FROM Item_pedido ip
                WHERE ip.pedido_id = NEW.pedido_id
            )
            + taxa_entrega
            - valor_desconto,
            0
        )

    WHERE pedido_id = NEW.pedido_id;

END$$


-- =========================================================
-- TRIGGER 3
-- ALTERACAO DE ITEM DO PEDIDO
--
-- Recalcula o subtotal do item e os valores do pedido.
-- =========================================================

CREATE TRIGGER trg_item_pedido_atualizacao
AFTER UPDATE ON Item_pedido
FOR EACH ROW
BEGIN

    UPDATE Item_pedido
    SET subtotal = NEW.quantidade * NEW.preco_unitario
    WHERE item_pedido_id = NEW.item_pedido_id;

    UPDATE Pedido
    SET
        subtotal = (
            SELECT COALESCE(
                SUM(ip.quantidade * ip.preco_unitario),
                0
            )
            FROM Item_pedido ip
            WHERE ip.pedido_id = NEW.pedido_id
        ),

        total = GREATEST(
            (
                SELECT COALESCE(
                    SUM(ip.quantidade * ip.preco_unitario),
                    0
                )
                FROM Item_pedido ip
                WHERE ip.pedido_id = NEW.pedido_id
            )
            + taxa_entrega
            - valor_desconto,
            0
        )

    WHERE pedido_id = NEW.pedido_id;

END$$


DELIMITER ;