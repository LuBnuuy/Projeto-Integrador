-- IRON FIT

CREATE DATABASE iron_fit;

USE iron_fit;

-- Tabela: academias

DROP TABLE IF EXISTS academias;
CREATE TABLE academias (
    IDAcademia   INT AUTO_INCREMENT PRIMARY KEY,
    NomeUnidade  VARCHAR(150) NOT NULL,
    Endereco     VARCHAR(255) NOT NULL,
    Cidade       VARCHAR(100) NOT NULL,
    Telefone     VARCHAR(20)
);


-- Tabela: membros

CREATE TABLE membros (
    IDMembro       INT AUTO_INCREMENT PRIMARY KEY,
    IDAcademia     INT NOT NULL,
    Nome           VARCHAR(150) NOT NULL,
    CPF            VARCHAR(11) NOT NULL UNIQUE,
    DataNascimento DATE NOT NULL,
    Email          VARCHAR(150) UNIQUE,
    Telefone       VARCHAR(20),
    DataCriacao    DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_membros_academia
        FOREIGN KEY (IDAcademia) REFERENCES academias (IDAcademia)
);


-- Tabela: personal_trainers

CREATE TABLE personal_trainers (
    IDTrainer     INT AUTO_INCREMENT PRIMARY KEY,
    IDAcademia    INT NOT NULL,
    Nome          VARCHAR(150) NOT NULL,
    CREF          VARCHAR(20) NOT NULL UNIQUE,
    Especialidade VARCHAR(100),
    Telefone      VARCHAR(20),
    StatusAtivo   BOOLEAN NOT NULL DEFAULT TRUE,
    CONSTRAINT fk_trainers_academia
        FOREIGN KEY (IDAcademia) REFERENCES academias (IDAcademia)
);


-- Tabela: planos_assinatura

CREATE TABLE planos_assinatura (
    IDPlano       INT AUTO_INCREMENT PRIMARY KEY,
    NomePlano     VARCHAR(100) NOT NULL,
    ValorMensal   DECIMAL(10,2) NOT NULL,
    DuracaoMeses  INT NOT NULL,
    Descricao     VARCHAR(255),
    Status_ativo  BOOLEAN NOT NULL DEFAULT TRUE
);


-- Tabela: assinaturas

CREATE TABLE assinaturas (
    IDAssinatura           INT AUTO_INCREMENT PRIMARY KEY,
    IDMembro               INT NOT NULL,
    IDPlano                INT NOT NULL,
    DataInicio             DATE NOT NULL,
    DataFim                DATE,
    status                  ENUM('ativa','cancelada','suspensa','expirada') NOT NULL DEFAULT 'ativa',
    usuario_ultima_alteracao VARCHAR(100),
    CONSTRAINT fk_assinaturas_membro
        FOREIGN KEY (IDMembro) REFERENCES membros (IDMembro),
    CONSTRAINT fk_assinaturas_plano
        FOREIGN KEY (IDPlano) REFERENCES planos_assinatura (IDPlano)
);


-- Tabela: avaliacoes_fisicas (trainer "realiza" em membro)

CREATE TABLE avaliacoes_fisicas (
    IDAvaliacao        INT AUTO_INCREMENT PRIMARY KEY,
    IDMembro           INT NOT NULL,
    IDTrainer          INT NOT NULL,
    DataAvaliacao      DATE NOT NULL,
    PesoKg             DECIMAL(5,2) NOT NULL,
    AlturaM            DECIMAL(3,2) NOT NULL,
    PercentualGordura  DECIMAL(4,2),
    ObservacoesInternas TEXT,
    CONSTRAINT fk_avaliacoes_membro
        FOREIGN KEY (IDMembro) REFERENCES membros (IDMembro),
    CONSTRAINT fk_avaliacoes_trainer
        FOREIGN KEY (IDTrainer) REFERENCES personal_trainers (IDTrainer)
);


-- Tabela: aulas_grupo (academia "oferece", trainer "ministra")

CREATE TABLE aulas_grupo (
    IDAula           INT AUTO_INCREMENT PRIMARY KEY,
    IDAcademia       INT NOT NULL,
    IDTrainer        INT NOT NULL,
    NomeAula         VARCHAR(100) NOT NULL,
    DiaSemana        ENUM('segunda','terca','quarta','quinta','sexta','sabado','domingo') NOT NULL,
    Horario           TIME NOT NULL,
    CapacidadeMaxima INT NOT NULL,
    DataCriacao      DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_aulas_academia
        FOREIGN KEY (IDAcademia) REFERENCES academias (IDAcademia),
    CONSTRAINT fk_aulas_trainer
        FOREIGN KEY (IDTrainer) REFERENCES personal_trainers (IDTrainer)
);


-- Tabela: matricula_aulas (membro "participa" de aula)

CREATE TABLE matricula_aulas (
    IDMatricula             INT AUTO_INCREMENT PRIMARY KEY,
    IDAula                  INT NOT NULL,
    IDMembro                INT NOT NULL,
    DataMatricula            DATE NOT NULL,
    status                    ENUM('ativa','cancelada','concluida') NOT NULL DEFAULT 'ativa',
    usuario_ultima_alteracao VARCHAR(100),
    CONSTRAINT fk_matricula_aula
        FOREIGN KEY (IDAula) REFERENCES aulas_grupo (IDAula),
    CONSTRAINT fk_matricula_membro
        FOREIGN KEY (IDMembro) REFERENCES membros (IDMembro)
        ON UPDATE CASCADE
        ON DELETE CASCADE,
    CONSTRAINT uq_matricula_aula_membro UNIQUE (IDAula, IDMembro)
);
