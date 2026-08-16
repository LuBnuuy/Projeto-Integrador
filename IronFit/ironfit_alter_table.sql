-- ACADEMIAS

ALTER TABLE academias
    ADD COLUMN HorarioFuncionamento VARCHAR(100);

-- MEMBROS

ALTER TABLE membros
    ADD COLUMN Sexo VARCHAR(10);

-- PERSONAL_TRAINERS

ALTER TABLE personal_trainers
    ADD COLUMN DataContratacao DATE;

-- PLANOS_ASSINATURA

ALTER TABLE planos_assinatura
    ADD COLUMN AcessosSemanais INT;

-- ASSINATURAS

ALTER TABLE assinaturas
    ADD COLUMN FormaPagamento VARCHAR(50);

-- AVALIACOES_FISICAS

ALTER TABLE avaliacoes_fisicas
    ADD COLUMN IMC DECIMAL(4,2);

-- AULAS_GRUPO

ALTER TABLE aulas_grupo
    ADD COLUMN NivelAula VARCHAR(20);

-- MATRICULA_AULAS

ALTER TABLE matricula_aulas
    ADD COLUMN DataCancelamento DATE NULL;
