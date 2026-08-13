-- MEDPET_DB - TRIGGERS

USE medpet_db;

DELIMITER //

-- TRIGGER 1 - Tabela: ITEM_FATURA (AFTER INSERT)
-- REGRA DE NEGÓCIO: o ValorTotal da fatura precisa refletir sempre a
-- soma dos itens lançados, independentemente de o item ter sido
-- inserido pela procedure sp_AdicionarItemFatura ou diretamente na
-- tabela.

CREATE TRIGGER trg_item_fatura_after_insert
AFTER INSERT ON ITEM_FATURA
FOR EACH ROW
BEGIN
    UPDATE FATURA
       SET ValorTotal = ValorTotal + NEW.valor
     WHERE IDFatura = NEW.IDFatura;
END//


-- TRIGGER 2 - Tabela: PET_VACINA (BEFORE INSERT)
-- REGRA DE NEGÓCIO: se a clínica não informar a data da próxima dose,
-- ela deve ser calculada automaticamente a partir da validade (em
-- meses) cadastrada na vacina aplicada — garante que nenhum reforço
-- fique sem previsão de agendamento.

CREATE TRIGGER trg_pet_vacina_before_insert
BEFORE INSERT ON PET_VACINA
FOR EACH ROW
BEGIN
    DECLARE v_ValidadeMeses INT;

    IF NEW.DataProximaDose IS NULL THEN
        SELECT ValidadeMeses INTO v_ValidadeMeses
        FROM VACINA
        WHERE IDVacina = NEW.IDVacina;

        SET NEW.DataProximaDose = DATE_ADD(NEW.DataAplicacao, INTERVAL v_ValidadeMeses MONTH);
    END IF;
END//


-- TRIGGER 3 - Tabela: INTERNAMENTO (AFTER UPDATE)
-- REGRA DE NEGÓCIO: quando o pet recebe alta (DataSaida deixa de ser
-- NULL), o sistema deve gerar automaticamente a cobrança do
-- internamento — cria uma FATURA para o dono do pet e lança o item
-- correspondente (diárias x valor da diária) — sem depender de um
-- funcionário lançar isso manualmente.

CREATE TRIGGER trg_internamento_after_update
AFTER UPDATE ON INTERNAMENTO
FOR EACH ROW
BEGIN
    DECLARE v_IDDono   INT;
    DECLARE v_Dias      INT;
    DECLARE v_ValorItem DECIMAL(10,2);
    DECLARE v_IDFatura  INT;

    IF OLD.DataSaida IS NULL AND NEW.DataSaida IS NOT NULL THEN

        SELECT IDDono INTO v_IDDono
        FROM PET
        WHERE IDPet = NEW.IDPet;

        SET v_Dias = GREATEST(DATEDIFF(NEW.DataSaida, NEW.DataEntrada), 1);
        SET v_ValorItem = v_Dias * NEW.ValorDiaria;

        INSERT INTO FATURA (IDDono, DataEmissao, ValorTotal, StatusPagamento)
        VALUES (v_IDDono, CURRENT_DATE, 0.00, 'PENDENTE');

        SET v_IDFatura = LAST_INSERT_ID();

        INSERT INTO ITEM_FATURA (IDFatura, IDConsulta, IDInternamento, descricao, valor)
        VALUES (v_IDFatura, NULL, NEW.IDInternamento, CONCAT('Internamento (', v_Dias, ' diária(s))'), v_ValorItem);

        -- Observação: o TRIGGER 1 (trg_item_fatura_after_insert) já cuida
        -- de atualizar o ValorTotal da FATURA automaticamente ao inserir
        -- este ITEM_FATURA, então não é necessário repetir esse UPDATE aqui.
    END IF;
END//

DELIMITER ;
