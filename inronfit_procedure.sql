-- IRON_FIT - STORED PROCEDURES

USE iron_fit;

DELIMITER //


-- 1) academias
-- REGRA DE NEGÓCIO: não permite cadastrar duas unidades com o mesmo
-- nome na mesma cidade, evitando unidades duplicadas na rede.

CREATE PROCEDURE sp_CadastrarAcademia (
    IN p_NomeUnidade VARCHAR(150),
    IN p_Endereco    VARCHAR(255),
    IN p_Cidade      VARCHAR(100),
    IN p_Telefone    VARCHAR(20)
)
BEGIN
    IF EXISTS (SELECT 1 FROM academias WHERE NomeUnidade = p_NomeUnidade AND Cidade = p_Cidade) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Já existe uma unidade com este nome nesta cidade.';
    END IF;

    INSERT INTO academias (NomeUnidade, Endereco, Cidade, Telefone)
    VALUES (p_NomeUnidade, p_Endereco, p_Cidade, p_Telefone);
END//


-- 2) membros
-- REGRA DE NEGÓCIO: a academia exige idade mínima de 16 anos para
-- matrícula (menores de 16 não podem ser cadastrados como membros),
-- além de impedir CPF duplicado.

CREATE PROCEDURE sp_CadastrarMembro (
    IN p_IDAcademia     INT,
    IN p_Nome           VARCHAR(150),
    IN p_CPF            VARCHAR(11),
    IN p_DataNascimento DATE,
    IN p_Email          VARCHAR(150),
    IN p_Telefone       VARCHAR(20)
)
BEGIN
    IF NOT EXISTS (SELECT 1 FROM academias WHERE IDAcademia = p_IDAcademia) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Academia informada não existe.';
    END IF;

    IF EXISTS (SELECT 1 FROM membros WHERE CPF = p_CPF) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Já existe um membro cadastrado com este CPF.';
    END IF;

    IF TIMESTAMPDIFF(YEAR, p_DataNascimento, CURDATE()) < 16 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Membro deve ter no mínimo 16 anos para se matricular.';
    END IF;

    INSERT INTO membros (IDAcademia, Nome, CPF, DataNascimento, Email, Telefone)
    VALUES (p_IDAcademia, p_Nome, p_CPF, p_DataNascimento, p_Email, p_Telefone);
END//


-- 3) personal_trainers
-- REGRA DE NEGÓCIO: impede o cadastro de personal trainers com CREF
-- duplicado e garante que o trainer esteja vinculado a uma academia
-- existente, já entrando como ativo por padrão.

CREATE PROCEDURE sp_CadastrarTrainer (
    IN p_IDAcademia    INT,
    IN p_Nome          VARCHAR(150),
    IN p_CREF          VARCHAR(20),
    IN p_Especialidade VARCHAR(100),
    IN p_Telefone      VARCHAR(20)
)
BEGIN
    IF NOT EXISTS (SELECT 1 FROM academias WHERE IDAcademia = p_IDAcademia) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Academia informada não existe.';
    END IF;

    IF EXISTS (SELECT 1 FROM personal_trainers WHERE CREF = p_CREF) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Já existe um trainer cadastrado com este CREF.';
    END IF;

    INSERT INTO personal_trainers (IDAcademia, Nome, CREF, Especialidade, Telefone, StatusAtivo)
    VALUES (p_IDAcademia, p_Nome, p_CREF, p_Especialidade, p_Telefone, TRUE);
END//


-- 4) planos_assinatura
-- REGRA DE NEGÓCIO: um plano precisa ter valor mensal e duração
-- válidos (maiores que zero) para ser comercializado.

CREATE PROCEDURE sp_CadastrarPlano (
    IN p_NomePlano    VARCHAR(100),
    IN p_ValorMensal  DECIMAL(10,2),
    IN p_DuracaoMeses INT,
    IN p_Descricao    VARCHAR(255)
)
BEGIN
    IF p_ValorMensal <= 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Valor mensal do plano deve ser maior que zero.';
    END IF;

    IF p_DuracaoMeses <= 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Duração do plano deve ser maior que zero meses.';
    END IF;

    INSERT INTO planos_assinatura (NomePlano, ValorMensal, DuracaoMeses, Descricao, Status_ativo)
    VALUES (p_NomePlano, p_ValorMensal, p_DuracaoMeses, p_Descricao, TRUE);
END//


-- 5) assinaturas
-- REGRA DE NEGÓCIO: um membro não pode ter duas assinaturas ativas ao
-- mesmo tempo, e a data de término é calculada automaticamente a
-- partir da duração (em meses) do plano contratado.

CREATE PROCEDURE sp_CriarAssinatura (
    IN p_IDMembro INT,
    IN p_IDPlano  INT,
    IN p_DataInicio DATE,
    IN p_usuario  VARCHAR(100)
)
BEGIN
    DECLARE v_DuracaoMeses INT;

    IF EXISTS (SELECT 1 FROM assinaturas WHERE IDMembro = p_IDMembro AND status = 'ativa') THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Este membro já possui uma assinatura ativa.';
    END IF;

    SELECT DuracaoMeses INTO v_DuracaoMeses
    FROM planos_assinatura
    WHERE IDPlano = p_IDPlano;

    IF v_DuracaoMeses IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Plano informado não existe.';
    END IF;

    INSERT INTO assinaturas (IDMembro, IDPlano, DataInicio, DataFim, status, usuario_ultima_alteracao)
    VALUES (p_IDMembro, p_IDPlano, p_DataInicio, DATE_ADD(p_DataInicio, INTERVAL v_DuracaoMeses MONTH), 'ativa', p_usuario);
END//


-- 6) avaliacoes_fisicas
-- REGRA DE NEGÓCIO: o IMC do membro é calculado automaticamente pela
-- fórmula peso / altura², padronizando o indicador em toda avaliação
-- e evitando cálculo manual sujeito a erro.

CREATE PROCEDURE sp_RegistrarAvaliacaoFisica (
    IN p_IDMembro            INT,
    IN p_IDTrainer           INT,
    IN p_DataAvaliacao       DATE,
    IN p_PesoKg              DECIMAL(5,2),
    IN p_AlturaM             DECIMAL(3,2),
    IN p_PercentualGordura   DECIMAL(4,2),
    IN p_ObservacoesInternas TEXT
)
BEGIN
    DECLARE v_IMC DECIMAL(4,2);

    SET v_IMC = p_PesoKg / (p_AlturaM * p_AlturaM);

    INSERT INTO avaliacoes_fisicas (IDMembro, IDTrainer, DataAvaliacao, PesoKg, AlturaM, PercentualGordura, ObservacoesInternas)
    VALUES (p_IDMembro, p_IDTrainer, p_DataAvaliacao, p_PesoKg, p_AlturaM, p_PercentualGordura, p_ObservacoesInternas);

    -- Observação: caso a coluna IMC (do ALTER TABLE) exista em avaliacoes_fisicas,
    -- pode-se persistir o valor calculado com um UPDATE logo após o INSERT:
    -- UPDATE avaliacoes_fisicas SET IMC = v_IMC WHERE IDAvaliacao = LAST_INSERT_ID();

    SELECT v_IMC AS IMC_Calculado;
END//


-- 7) aulas_grupo
-- REGRA DE NEGÓCIO: o trainer só pode ministrar aulas na mesma
-- academia em que atua, evitando escalar um profissional de outra
-- unidade para dar aula em um local que ele não atende.

CREATE PROCEDURE sp_CriarAulaGrupo (
    IN p_IDAcademia       INT,
    IN p_IDTrainer        INT,
    IN p_NomeAula         VARCHAR(100),
    IN p_DiaSemana        VARCHAR(10),
    IN p_Horario          TIME,
    IN p_CapacidadeMaxima INT
)
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM personal_trainers
        WHERE IDTrainer = p_IDTrainer AND IDAcademia = p_IDAcademia
    ) THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'O trainer informado não pertence a esta academia.';
    END IF;

    INSERT INTO aulas_grupo (IDAcademia, IDTrainer, NomeAula, DiaSemana, Horario, CapacidadeMaxima)
    VALUES (p_IDAcademia, p_IDTrainer, p_NomeAula, p_DiaSemana, p_Horario, p_CapacidadeMaxima);
END//


-- 8) matricula_aulas
-- REGRA DE NEGÓCIO: um membro só pode se matricular em uma aula se
-- ainda houver vaga disponível, respeitando a CapacidadeMaxima
-- definida para a turma.

CREATE PROCEDURE sp_MatricularMembroAula (
    IN p_IDAula        INT,
    IN p_IDMembro      INT,
    IN p_DataMatricula DATE,
    IN p_usuario       VARCHAR(100)
)
BEGIN
    DECLARE v_CapacidadeMaxima INT;
    DECLARE v_MatriculadosAtivos INT;

    SELECT CapacidadeMaxima INTO v_CapacidadeMaxima
    FROM aulas_grupo
    WHERE IDAula = p_IDAula;

    IF v_CapacidadeMaxima IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Aula informada não existe.';
    END IF;

    SELECT COUNT(*) INTO v_MatriculadosAtivos
    FROM matricula_aulas
    WHERE IDAula = p_IDAula AND status = 'ativa';

    IF v_MatriculadosAtivos >= v_CapacidadeMaxima THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Capacidade máxima da aula já foi atingida.';
    END IF;

    INSERT INTO matricula_aulas (IDAula, IDMembro, DataMatricula, status, usuario_ultima_alteracao)
    VALUES (p_IDAula, p_IDMembro, p_DataMatricula, 'ativa', p_usuario);
END

DELIMITER ;