-- MEDPET

CREATE DATABASE medpet_db;

USE medpet_db;


-- TABELA: DONO

CREATE TABLE DONO (
    IDDono   INT AUTO_INCREMENT PRIMARY KEY,
    nome      VARCHAR(150)  NOT NULL,
    cpf       VARCHAR(11)   NOT NULL UNIQUE,
    telefone  VARCHAR(20),
    email     VARCHAR(150),
    endereco  VARCHAR(255)
);


-- TABELA: PET

CREATE TABLE PET (
    IDPet            INT AUTO_INCREMENT PRIMARY KEY,
    IDDono           INT NOT NULL,
    nome             VARCHAR(100)  NOT NULL,
    especie          VARCHAR(50)   NOT NULL,
    raca             VARCHAR(80),
    DataNascimento  DATE,
    peso             DECIMAL(6,2),
    CONSTRAINT fk_pet_dono
        FOREIGN KEY (IDDono) REFERENCES DONO(IDDono),
    CONSTRAINT chk_pet_peso CHECK (peso IS NULL OR peso > 0)
);


-- TABELA: VETERINARIO

CREATE TABLE VETERINARIO (
    IDVeterinario   INT AUTO_INCREMENT PRIMARY KEY,
    nome            VARCHAR(150) NOT NULL,
    crmv            VARCHAR(20) NOT NULL UNIQUE,
    especialidade   VARCHAR(100),
    telefone        VARCHAR(20)
);


-- TABELA: VACINA

CREATE TABLE VACINA (
    IDVacina         INT AUTO_INCREMENT PRIMARY KEY,
    nome             VARCHAR(100) NOT NULL,
    fabricante       VARCHAR(100),
    ValidadeMeses    INT NOT NULL,
    lote             VARCHAR(50),
    CONSTRAINT chk_vacina_validade CHECK (ValidadeMeses > 0)
);


-- TABELA: ALERGIA

CREATE TABLE ALERGIA (
    IDAlergia        INT AUTO_INCREMENT PRIMARY KEY,
    descricao        VARCHAR(150) NOT NULL,
    GrauSeveridade   VARCHAR(20) NOT NULL,
    CONSTRAINT chk_alergia_grau
        CHECK (GrauSeveridade IN ('LEVE','MODERADA','GRAVE'))
);


-- TABELA: CONSULTA

CREATE TABLE CONSULTA (
    IDConsulta       INT AUTO_INCREMENT PRIMARY KEY,
    IDPet            INT NOT NULL,
    IDVeterinario    INT NOT NULL,
    DataConsulta     DATE NOT NULL,
    motivo           VARCHAR(255),
    diagnostico      VARCHAR(255),
    valor            DECIMAL(10,2) NOT NULL DEFAULT 0.00,
    CONSTRAINT fk_consulta_pet
        FOREIGN KEY (IDPet) REFERENCES PET(IDPet),
    CONSTRAINT fk_consulta_veterinario
        FOREIGN KEY (IDVeterinario) REFERENCES VETERINARIO(IDVeterinario),
    CONSTRAINT chk_consulta_valor CHECK (valor >= 0)
);


-- TABELA: INTERNAMENTO

CREATE TABLE INTERNAMENTO (
    IDInternamento   INT AUTO_INCREMENT PRIMARY KEY,
    IDPet            INT NOT NULL,
    IDVeterinario    INT NOT NULL,
    DataEntrada      DATE NOT NULL,
    DataSaida        DATE NULL,
    motivo           VARCHAR(255),
    ValorDiaria      DECIMAL(10,2) NOT NULL DEFAULT 0.00,
    CONSTRAINT fk_internamento_pet
        FOREIGN KEY (IDPet) REFERENCES PET(IDPet),
    CONSTRAINT fk_internamento_veterinario
        FOREIGN KEY (IDVeterinario) REFERENCES VETERINARIO(IDVeterinario),
    CONSTRAINT chk_internamento_datas
        CHECK (DataSaida IS NULL OR DataSaida >= DataEntrada),
    CONSTRAINT chk_internamento_valor CHECK (ValorDiaria >= 0)
);


-- TABELA: FATURA

CREATE TABLE FATURA (
    IDFatura          INT AUTO_INCREMENT PRIMARY KEY,
    IDDono            INT NOT NULL,
    DataEmissao       DATE NOT NULL DEFAULT (CURRENT_DATE),
    ValorTotal        DECIMAL(10,2) NOT NULL DEFAULT 0.00,
    StatusPagamento   VARCHAR(20) NOT NULL DEFAULT 'PENDENTE',
    CONSTRAINT fk_fatura_dono
        FOREIGN KEY (IDDono) REFERENCES DONO(IDDono),
    CONSTRAINT chk_fatura_status
        CHECK (StatusPagamento IN ('PENDENTE','PAGA','ATRASADA','CANCELADA'))
);


-- TABELA: PET_ALERGIA

CREATE TABLE PET_ALERGIA (
    IDPetAlergia       INT AUTO_INCREMENT PRIMARY KEY,
    IDPet              INT NOT NULL,
    IDAlergia          INT NOT NULL,
    DataDiagnostico    DATE NOT NULL,
    Observacao         VARCHAR(255),
    CONSTRAINT fk_petalergia_pet
        FOREIGN KEY (IDPet) REFERENCES PET(IDPet),
    CONSTRAINT fk_petalergia_alergia
        FOREIGN KEY (IDAlergia) REFERENCES ALERGIA(IDAlergia),
    CONSTRAINT uq_pet_alergia UNIQUE (IDPet, IDAlergia)
);


-- TABELA: PET_VACINA

CREATE TABLE PET_VACINA (
    IDPetVacina         INT AUTO_INCREMENT PRIMARY KEY,
    IDPet               INT NOT NULL,
    IDVacina            INT NOT NULL,
    DataAplicacao       DATE NOT NULL,
    DataProximaDose     DATE  NULL,
    CONSTRAINT fk_petvacina_pet
        FOREIGN KEY (IDPet) REFERENCES PET(IDPet),
    CONSTRAINT fk_petvacina_vacina
        FOREIGN KEY (IDVacina) REFERENCES VACINA(IDVacina),
    CONSTRAINT chk_petvacina_datas
        CHECK (DataProximaDose IS NULL OR DataProximaDose > DataAplicacao)
);


-- TABELA: ITEM_FATURA

CREATE TABLE ITEM_FATURA (
    IDItemFatura     INT AUTO_INCREMENT PRIMARY KEY,
    IDFatura         INT NOT NULL,
    IDconsulta       INT NULL,
    IDInternamento   INT NULL,
    descricao        VARCHAR(255)  NOT NULL,
    valor            DECIMAL(10,2) NOT NULL,
    CONSTRAINT fk_item_fatura
        FOREIGN KEY (IDFatura) REFERENCES FATURA(IDFatura),
    CONSTRAINT fk_item_consulta
        FOREIGN KEY (IDconsulta) REFERENCES CONSULTA(IDConsulta),
    CONSTRAINT fk_item_internamento
        FOREIGN KEY (IDInternamento) REFERENCES INTERNAMENTO(IDInternamento),
    CONSTRAINT chk_item_origem
        CHECK (
            (IDconsulta IS NOT NULL AND IDInternamento IS NULL)
            OR (IDconsulta IS NULL AND IDInternamento IS NOT NULL)
        ),
    CONSTRAINT chk_item_valor CHECK (valor >= 0)
);