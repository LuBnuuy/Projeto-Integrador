-- MEDPET_DB - STORED PROCEDURES

USE medpet_db;

DELIMITER //


-- 1) DONO
-- REGRA DE NEGÓCIO: não permite cadastrar dois donos com o mesmo CPF,
-- evitando cadastros duplicados de tutores.

CREATE PROCEDURE sp_CadastrarDono (
    IN p_nome     VARCHAR(150),
    IN p_cpf      VARCHAR(11),
    IN p_telefone VARCHAR(20),
    IN p_email    VARCHAR(150),
    IN p_endereco VARCHAR(255)
)
BEGIN
    IF EXISTS (SELECT 1 FROM DONO WHERE cpf = p_cpf) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Já existe um dono cadastrado com este CPF.';
    END IF;

    INSERT INTO DONO (nome, cpf, telefone, email, endereco)
    VALUES (p_nome, p_cpf, p_telefone, p_email, p_endereco);
END//



-- 2) PET
-- REGRA DE NEGÓCIO: um pet só pode ser cadastrado vinculado a um dono
-- já existente, e o peso, quando informado, precisa ser maior que
-- zero (reforça a regra que já existe via CHECK, com mensagem clara).

CREATE PROCEDURE sp_CadastrarPet (
    IN p_IDDono          INT,
    IN p_nome            VARCHAR(100),
    IN p_especie         VARCHAR(50),
    IN p_raca            VARCHAR(80),
    IN p_DataNascimento  DATE,
    IN p_peso            DECIMAL(6,2)
)
BEGIN
    IF NOT EXISTS (SELECT 1 FROM DONO WHERE IDDono = p_IDDono) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Dono informado não existe.';
    END IF;

    IF p_peso IS NOT NULL AND p_peso <= 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Peso do pet deve ser maior que zero.';
    END IF;

    INSERT INTO PET (IDDono, nome, especie, raca, DataNascimento, peso)
    VALUES (p_IDDono, p_nome, p_especie, p_raca, p_DataNascimento, p_peso);
END//



-- 3) VETERINARIO
-- REGRA DE NEGÓCIO: impede o cadastro de veterinários com CRMV
-- duplicado, garantindo que cada registro profissional seja único.

CREATE PROCEDURE sp_CadastrarVeterinario (
    IN p_nome          VARCHAR(150),
    IN p_crmv          VARCHAR(20),
    IN p_especialidade VARCHAR(100),
    IN p_telefone      VARCHAR(20)
)
BEGIN
    IF EXISTS (SELECT 1 FROM VETERINARIO WHERE crmv = p_crmv) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Já existe um veterinário cadastrado com este CRMV.';
    END IF;

    INSERT INTO VETERINARIO (nome, crmv, especialidade, telefone)
    VALUES (p_nome, p_crmv, p_especialidade, p_telefone);
END//



-- 4) VACINA
-- REGRA DE NEGÓCIO: evita cadastrar o mesmo lote de vacina mais de
-- uma vez, prevenindo duplicidade no controle de lotes.

CREATE PROCEDURE sp_CadastrarVacina (
    IN p_nome          VARCHAR(100),
    IN p_fabricante    VARCHAR(100),
    IN p_ValidadeMeses INT,
    IN p_lote          VARCHAR(50)
)
BEGIN
    IF p_lote IS NOT NULL AND EXISTS (SELECT 1 FROM VACINA WHERE lote = p_lote) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Já existe uma vacina cadastrada com este lote.';
    END IF;

    INSERT INTO VACINA (nome, fabricante, ValidadeMeses, lote)
    VALUES (p_nome, p_fabricante, p_ValidadeMeses, p_lote);
END//



-- 5) ALERGIA
-- REGRA DE NEGÓCIO: só permite cadastrar a alergia se o grau de
-- severidade informado for um dos valores aceitos pela clínica
-- (LEVE, MODERADA, GRAVE), com mensagem de erro amigável.

CREATE PROCEDURE sp_CadastrarAlergia (
    IN p_descricao      VARCHAR(150),
    IN p_GrauSeveridade VARCHAR(20)
)
BEGIN
    IF p_GrauSeveridade NOT IN ('LEVE','MODERADA','GRAVE') THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Grau de severidade inválido. Use LEVE, MODERADA ou GRAVE.';
    END IF;

    INSERT INTO ALERGIA (descricao, GrauSeveridade)
    VALUES (p_descricao, p_GrauSeveridade);
END//



-- 6) CONSULTA
-- REGRA DE NEGÓCIO: um mesmo pet não pode ter duas consultas
-- marcadas para a mesma data, evitando agendamento duplicado.

CREATE PROCEDURE sp_RegistrarConsulta (
    IN p_IDPet         INT,
    IN p_IDVeterinario INT,
    IN p_DataConsulta  DATE,
    IN p_motivo        VARCHAR(255),
    IN p_diagnostico   VARCHAR(255),
    IN p_valor         DECIMAL(10,2)
)
BEGIN
    IF EXISTS (
        SELECT 1 FROM CONSULTA
        WHERE IDPet = p_IDPet AND DataConsulta = p_DataConsulta
    ) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Este pet já possui consulta marcada para esta data.';
    END IF;

    INSERT INTO CONSULTA (IDPet, IDVeterinario, DataConsulta, motivo, diagnostico, valor)
    VALUES (p_IDPet, p_IDVeterinario, p_DataConsulta, p_motivo, p_diagnostico, p_valor);
END//



-- 7) INTERNAMENTO
-- REGRA DE NEGÓCIO: um pet não pode ter dois internamentos ativos ao
-- mesmo tempo (ou seja, com DataSaida em aberto), evitando registros
-- inconsistentes de ocupação de leito/baia.

CREATE PROCEDURE sp_RegistrarInternamento (
    IN p_IDPet         INT,
    IN p_IDVeterinario INT,
    IN p_DataEntrada   DATE,
    IN p_motivo        VARCHAR(255),
    IN p_ValorDiaria   DECIMAL(10,2)
)
BEGIN
    IF EXISTS (
        SELECT 1 FROM INTERNAMENTO
        WHERE IDPet = p_IDPet AND DataSaida IS NULL
    ) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Este pet já possui um internamento em andamento.';
    END IF;

    INSERT INTO INTERNAMENTO (IDPet, IDVeterinario, DataEntrada, DataSaida, motivo, ValorDiaria)
    VALUES (p_IDPet, p_IDVeterinario, p_DataEntrada, NULL, p_motivo, p_ValorDiaria);
END//



-- 8) FATURA
-- REGRA DE NEGÓCIO: toda fatura nasce com status 'PENDENTE' e valor
-- total zerado; o valor é consolidado conforme itens são lançados
-- (ver sp_AdicionarItemFatura), evitando faturas emitidas com total
-- incorreto.

CREATE PROCEDURE sp_EmitirFatura (
    IN p_IDDono INT,
    OUT p_IDFaturaGerada INT
)
BEGIN
    IF NOT EXISTS (SELECT 1 FROM DONO WHERE IDDono = p_IDDono) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Dono informado não existe.';
    END IF;

    INSERT INTO FATURA (IDDono, DataEmissao, ValorTotal, StatusPagamento)
    VALUES (p_IDDono, CURRENT_DATE, 0.00, 'PENDENTE');

    SET p_IDFaturaGerada = LAST_INSERT_ID();
END//



-- 9) PET_ALERGIA
-- REGRA DE NEGÓCIO: impede registrar a mesma alergia duas vezes para
-- o mesmo pet, mantendo o histórico clínico limpo (a UNIQUE já
-- protege no banco; aqui a mensagem fica amigável para a aplicação).

CREATE PROCEDURE sp_RegistrarAlergiaPet (
    IN p_IDPet           INT,
    IN p_IDAlergia       INT,
    IN p_DataDiagnostico DATE,
    IN p_Observacao      VARCHAR(255)
)
BEGIN
    IF EXISTS (SELECT 1 FROM PET_ALERGIA WHERE IDPet = p_IDPet AND IDAlergia = p_IDAlergia) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Esta alergia já está registrada para este pet.';
    END IF;

    INSERT INTO PET_ALERGIA (IDPet, IDAlergia, DataDiagnostico, Observacao)
    VALUES (p_IDPet, p_IDAlergia, p_DataDiagnostico, p_Observacao);
END//



-- 10) PET_VACINA
-- REGRA DE NEGÓCIO: ao aplicar uma vacina, a data da próxima dose é
-- calculada automaticamente a partir da validade (em meses) cadastrada
-- na vacina, evitando que a clínica esqueça de agendar o reforço.

CREATE PROCEDURE sp_RegistrarVacinacaoPet (
    IN p_IDPet         INT,
    IN p_IDVacina      INT,
    IN p_DataAplicacao DATE
)
BEGIN
    DECLARE v_ValidadeMeses INT;

    SELECT ValidadeMeses INTO v_ValidadeMeses
    FROM VACINA
    WHERE IDVacina = p_IDVacina;

    IF v_ValidadeMeses IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Vacina informada não existe.';
    END IF;

    INSERT INTO PET_VACINA (IDPet, IDVacina, DataAplicacao, DataProximaDose)
    VALUES (p_IDPet, p_IDVacina, p_DataAplicacao, DATE_ADD(p_DataAplicacao, INTERVAL v_ValidadeMeses MONTH));
END//



-- 11) ITEM_FATURA
-- REGRA DE NEGÓCIO: cada item de fatura deve estar vinculado a
-- exatamente uma origem (uma consulta OU um internamento, nunca os
-- dois nem nenhum), e ao ser lançado, atualiza automaticamente o
-- ValorTotal da fatura correspondente.

CREATE PROCEDURE sp_AdicionarItemFatura (
    IN p_IDFatura       INT,
    IN p_IDConsulta     INT,
    IN p_IDInternamento INT,
    IN p_descricao      VARCHAR(255),
    IN p_valor          DECIMAL(10,2)
)
BEGIN
    IF (p_IDConsulta IS NULL AND p_IDInternamento IS NULL)
       OR (p_IDConsulta IS NOT NULL AND p_IDInternamento IS NOT NULL) THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Informe exatamente uma origem para o item: consulta OU internamento.';
    END IF;

    INSERT INTO ITEM_FATURA (IDFatura, IDConsulta, IDInternamento, descricao, valor)
    VALUES (p_IDFatura, p_IDConsulta, p_IDInternamento, p_descricao, p_valor);

    UPDATE FATURA
       SET ValorTotal = ValorTotal + p_valor
     WHERE IDFatura = p_IDFatura;
END//

DELIMITER ;