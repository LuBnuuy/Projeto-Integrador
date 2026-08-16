CREATE DATABASE autoprime;
USE autoprime;


CREATE TABLE funcionario (
    id_funcionario INT AUTO_INCREMENT,
    nome VARCHAR(100) NOT NULL,
    endereco VARCHAR(150),
    cargo VARCHAR(50) NOT NULL,
    cpf VARCHAR(11) NOT NULL UNIQUE,
    email VARCHAR(100) UNIQUE,
    telefone VARCHAR(15),
    PRIMARY KEY (id_funcionario)
);


CREATE TABLE clientes (
    id_cliente INT AUTO_INCREMENT,
    nome VARCHAR(100) NOT NULL,
    endereco VARCHAR(150),
    email VARCHAR(100) UNIQUE,
    cpf VARCHAR(11) NOT NULL UNIQUE,
    telefone VARCHAR(15),
    PRIMARY KEY (id_cliente)
);

ALTER TABLE clientes
ADD COLUMN observacao VARCHAR(200);


CREATE TABLE fornecedor (
    id_fornecedor INT AUTO_INCREMENT,
    nome VARCHAR(100) NOT NULL,
    endereco VARCHAR(150),
    tipo_produto VARCHAR(50),
    cnpj VARCHAR(14) NOT NULL UNIQUE,
    telefone VARCHAR(15),
    cidade VARCHAR(50),
    uf CHAR(2),
    PRIMARY KEY (id_fornecedor)
);

ALTER TABLE fornecedor
ADD COLUMN email VARCHAR(100) UNIQUE;

CREATE TABLE veiculos_venda (
    id_veiculo_venda INT AUTO_INCREMENT,
    marca VARCHAR(50) NOT NULL,
    modelo VARCHAR(50) NOT NULL,
    ano INT NOT NULL,
    cor VARCHAR(30),
    placa VARCHAR(7) UNIQUE,
    chassi VARCHAR(17) UNIQUE,
    quilometragem INT,
    tipo VARCHAR(10) NOT NULL,
    preco DECIMAL(10,2) NOT NULL,
    status VARCHAR(20) NOT NULL,
    PRIMARY KEY (id_veiculo_venda)
);

ALTER TABLE veiculos_venda
ADD COLUMN data_cadastro DATE;

-- 5. VEÍCULOS DOS CLIENTES (OFICINA)
CREATE TABLE veiculo (
    id_veiculo INT AUTO_INCREMENT,
    placa VARCHAR(7) NOT NULL UNIQUE,
    id_cliente INT NOT NULL,
    modelo VARCHAR(50) NOT NULL,
    cor VARCHAR(30),
    quilometragem INT,
    motorizacao VARCHAR(20),
    PRIMARY KEY (id_veiculo),
    FOREIGN KEY (id_cliente)
        REFERENCES clientes(id_cliente)
        ON DELETE CASCADE
);

ALTER TABLE veiculo
ADD COLUMN ano_fabricacao INT;

CREATE TABLE estoque (
    id_estoque INT AUTO_INCREMENT,
    nome_peca VARCHAR(100) NOT NULL,
    tipo VARCHAR(50),
    fabricante VARCHAR(50),
    quantidade INT DEFAULT 0,
    id_fornecedor INT,
    id_funcionario INT,
    PRIMARY KEY (id_estoque),
    FOREIGN KEY (id_fornecedor)
        REFERENCES fornecedor(id_fornecedor)
        ON DELETE SET NULL,
    FOREIGN KEY (id_funcionario)
        REFERENCES funcionario(id_funcionario)
        ON DELETE SET NULL
);

ALTER TABLE estoque
ADD COLUMN data_entrada DATE;

CREATE TABLE servicos (
    id_servico INT AUTO_INCREMENT,
    id_funcionario INT NOT NULL,
    id_veiculo INT NOT NULL,
    tipo_servico VARCHAR(100) NOT NULL,
    tempo_estimado VARCHAR(20),
    status_servico VARCHAR(30) NOT NULL,
    PRIMARY KEY (id_servico),
    FOREIGN KEY (id_funcionario)
        REFERENCES funcionario(id_funcionario),
    FOREIGN KEY (id_veiculo)
        REFERENCES veiculo(id_veiculo)
);

CREATE TABLE servicos_pecas (
    id_servico INT,
    id_estoque INT,
    quantidade_usada INT NOT NULL,
    PRIMARY KEY (id_servico, id_estoque),
    FOREIGN KEY (id_servico)
        REFERENCES servicos(id_servico)
        ON DELETE CASCADE,
    FOREIGN KEY (id_estoque)
        REFERENCES estoque(id_estoque)
);

ALTER TABLE servicos
ADD COLUMN valor_servico DECIMAL(10,2);

CREATE TABLE pagamento (
    id_pagamento INT AUTO_INCREMENT,
    id_servico INT NOT NULL,
    id_cliente INT NOT NULL,
    id_funcionario INT NOT NULL,
    tipo_pagamento VARCHAR(30) NOT NULL,
    status_pagamento VARCHAR(30) NOT NULL,
   
   PRIMARY KEY (id_pagamento),
   
   FOREIGN KEY (id_servico)
        REFERENCES servicos(id_servico),

    FOREIGN KEY (id_cliente)
        REFERENCES clientes(id_cliente),

    FOREIGN KEY (id_funcionario)
        REFERENCES funcionario(id_funcionario)
);

ALTER TABLE servicos_pecas
ADD COLUMN valor_unitario DECIMAL(10,2);

CREATE TABLE venda (
    id_venda INT AUTO_INCREMENT,
    id_cliente INT NOT NULL,
    id_funcionario INT NOT NULL,
    id_veiculo_venda INT NOT NULL,
    data_venda DATE NOT NULL,
    valor DECIMAL(10,2) NOT NULL,
    PRIMARY KEY (id_venda),
    FOREIGN KEY (id_cliente)
        REFERENCES clientes(id_cliente),
    FOREIGN KEY (id_funcionario)
        REFERENCES funcionario(id_funcionario),
    FOREIGN KEY (id_veiculo_venda)
        REFERENCES veiculos_venda(id_veiculo_venda)
);

ALTER TABLE pagamento
ADD COLUMN data_pagamento DATE;

CREATE TABLE test_drive (
    id_test_drive INT AUTO_INCREMENT,
    id_cliente INT NOT NULL,
    id_funcionario INT NOT NULL,
    id_veiculo_venda INT NOT NULL,
    data_test DATE NOT NULL,
    horario TIME NOT NULL,
    observacao VARCHAR(200),
    PRIMARY KEY (id_test_drive),
    FOREIGN KEY (id_cliente)
        REFERENCES clientes(id_cliente),
    FOREIGN KEY (id_funcionario)
        REFERENCES funcionario(id_funcionario),
    FOREIGN KEY (id_veiculo_venda)
        REFERENCES veiculos_venda(id_veiculo_venda)
);

ALTER TABLE venda
ADD COLUMN forma_pagamento VARCHAR(30);

ALTER TABLE test_drive
ADD COLUMN status_test VARCHAR(30);

CREATE TABLE log_acesso_estoque (
    id_log INT AUTO_INCREMENT,
    id_funcionario INT NOT NULL,
    id_estoque INT NULL,       -- item específico acessado 
    tipo_acesso VARCHAR(30) NOT NULL,   -- ex: 'CONSULTA', 'RETIRADA', 'ENTRADA'
    data_hora DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    quantidade_movimentada INT NULL,
    observacao VARCHAR(200),
    PRIMARY KEY (id_log),
    FOREIGN KEY (id_funcionario)
        REFERENCES funcionario(id_funcionario),
    FOREIGN KEY (id_estoque)
        REFERENCES estoque(id_estoque)
        ON DELETE SET NULL
);

ALTER TABLE log_acesso_estoque
ADD COLUMN ip_acesso VARCHAR(45);


ALTER TABLE funcionario
   ADD COLUMN senha_acesso VARCHAR(255) NOT NULL DEFAULT '';
   

/* ============================================================
   3 TRIGGERS
   ============================================================ */

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


  -- STORED PROCEDURES
  -- PROCEDURE PARA CADA TABELA
   
CREATE PROCEDURE sp_inserir_funcionario(
    IN p_nome VARCHAR(100),
    IN p_endereco VARCHAR(150),
    IN p_cargo VARCHAR(50),
    IN p_cpf VARCHAR(11),
    IN p_email VARCHAR(100),
    IN p_telefone VARCHAR(15),
    IN p_senha_acesso VARCHAR(255)
)
BEGIN
    INSERT INTO funcionario
    (
        nome,
        endereco,
        cargo,
        cpf,
        email,
        telefone,
        senha_acesso
    )
    VALUES
    (
        p_nome,
        p_endereco,
        p_cargo,
        p_cpf,
        p_email,
        p_telefone,
        p_senha_acesso
    );
END$$



   -- 2. CLIENTES

CREATE PROCEDURE sp_inserir_cliente(
    IN p_nome VARCHAR(100),
    IN p_endereco VARCHAR(150),
    IN p_email VARCHAR(100),
    IN p_cpf VARCHAR(11),
    IN p_telefone VARCHAR(15),
    IN p_observacao VARCHAR(200)
)
BEGIN
    INSERT INTO clientes
    (
        nome,
        endereco,
        email,
        cpf,
        telefone,
        observacao
    )
    VALUES
    (
        p_nome,
        p_endereco,
        p_email,
        p_cpf,
        p_telefone,
        p_observacao
    );
END$$


/* ============================================================
   3. FORNECEDOR
   ============================================================ */

CREATE PROCEDURE sp_inserir_fornecedor(
    IN p_nome VARCHAR(100),
    IN p_endereco VARCHAR(150),
    IN p_tipo_produto VARCHAR(50),
    IN p_cnpj VARCHAR(14),
    IN p_telefone VARCHAR(15),
    IN p_cidade VARCHAR(50),
    IN p_uf CHAR(2),
    IN p_email VARCHAR(100)
)
BEGIN
    INSERT INTO fornecedor
    (
        nome,
        endereco,
        tipo_produto,
        cnpj,
        telefone,
        cidade,
        uf,
        email
    )
    VALUES
    (
        p_nome,
        p_endereco,
        p_tipo_produto,
        p_cnpj,
        p_telefone,
        p_cidade,
        p_uf,
        p_email
    );
END$$


/* ============================================================
   4. VEICULOS_VENDA
   ============================================================ */

CREATE PROCEDURE sp_inserir_veiculo_venda(
    IN p_marca VARCHAR(50),
    IN p_modelo VARCHAR(50),
    IN p_ano INT,
    IN p_cor VARCHAR(30),
    IN p_placa VARCHAR(7),
    IN p_chassi VARCHAR(17),
    IN p_quilometragem INT,
    IN p_tipo VARCHAR(10),
    IN p_preco DECIMAL(10,2),
    IN p_status VARCHAR(20),
    IN p_data_cadastro DATE
)
BEGIN
    INSERT INTO veiculos_venda
    (
        marca,
        modelo,
        ano,
        cor,
        placa,
        chassi,
        quilometragem,
        tipo,
        preco,
        status,
        data_cadastro
    )
    VALUES
    (
        p_marca,
        p_modelo,
        p_ano,
        p_cor,
        p_placa,
        p_chassi,
        p_quilometragem,
        p_tipo,
        p_preco,
        p_status,
        p_data_cadastro
    );
END$$


/* ============================================================
   5. VEICULO
   ============================================================ */

CREATE PROCEDURE sp_inserir_veiculo(
    IN p_placa VARCHAR(7),
    IN p_id_cliente INT,
    IN p_modelo VARCHAR(50),
    IN p_cor VARCHAR(30),
    IN p_quilometragem INT,
    IN p_motorizacao VARCHAR(20),
    IN p_ano_fabricacao INT
)
BEGIN
    INSERT INTO veiculo
    (
        placa,
        id_cliente,
        modelo,
        cor,
        quilometragem,
        motorizacao,
        ano_fabricacao
    )
    VALUES
    (
        p_placa,
        p_id_cliente,
        p_modelo,
        p_cor,
        p_quilometragem,
        p_motorizacao,
        p_ano_fabricacao
    );
END$$


/* ============================================================
   6. ESTOQUE
   ============================================================ */

CREATE PROCEDURE sp_inserir_estoque(
    IN p_nome_peca VARCHAR(100),
    IN p_tipo VARCHAR(50),
    IN p_fabricante VARCHAR(50),
    IN p_quantidade INT,
    IN p_id_fornecedor INT,
    IN p_id_funcionario INT,
    IN p_data_entrada DATE
)
BEGIN
    INSERT INTO estoque
    (
        nome_peca,
        tipo,
        fabricante,
        quantidade,
        id_fornecedor,
        id_funcionario,
        data_entrada
    )
    VALUES
    (
        p_nome_peca,
        p_tipo,
        p_fabricante,
        p_quantidade,
        p_id_fornecedor,
        p_id_funcionario,
        p_data_entrada
    );
END$$


/* ============================================================
   7. SERVICOS
   ============================================================ */

CREATE PROCEDURE sp_inserir_servico(
    IN p_id_funcionario INT,
    IN p_id_veiculo INT,
    IN p_tipo_servico VARCHAR(100),
    IN p_tempo_estimado VARCHAR(20),
    IN p_status_servico VARCHAR(30),
    IN p_valor_servico DECIMAL(10,2)
)
BEGIN
    INSERT INTO servicos
    (
        id_funcionario,
        id_veiculo,
        tipo_servico,
        tempo_estimado,
        status_servico,
        valor_servico
    )
    VALUES
    (
        p_id_funcionario,
        p_id_veiculo,
        p_tipo_servico,
        p_tempo_estimado,
        p_status_servico,
        p_valor_servico
    );
END$$


/* ============================================================
   8. SERVICOS_PECAS
   ============================================================ */

CREATE PROCEDURE sp_inserir_servico_peca(
    IN p_id_servico INT,
    IN p_id_estoque INT,
    IN p_quantidade_usada INT,
    IN p_valor_unitario DECIMAL(10,2)
)
BEGIN
    INSERT INTO servicos_pecas
    (
        id_servico,
        id_estoque,
        quantidade_usada,
        valor_unitario
    )
    VALUES
    (
        p_id_servico,
        p_id_estoque,
        p_quantidade_usada,
        p_valor_unitario
    );
END$$


/* ============================================================
   9. PAGAMENTO
   ============================================================ */

CREATE PROCEDURE sp_inserir_pagamento(
    IN p_id_servico INT,
    IN p_id_cliente INT,
    IN p_id_funcionario INT,
    IN p_tipo_pagamento VARCHAR(30),
    IN p_status_pagamento VARCHAR(30),
    IN p_data_pagamento DATE
)
BEGIN
    INSERT INTO pagamento
    (
        id_servico,
        id_cliente,
        id_funcionario,
        tipo_pagamento,
        status_pagamento,
        data_pagamento
    )
    VALUES
    (
        p_id_servico,
        p_id_cliente,
        p_id_funcionario,
        p_tipo_pagamento,
        p_status_pagamento,
        p_data_pagamento
    );
END$$


/* ============================================================
   10. VENDA
   ============================================================ */

CREATE PROCEDURE sp_inserir_venda(
    IN p_id_cliente INT,
    IN p_id_funcionario INT,
    IN p_id_veiculo_venda INT,
    IN p_data_venda DATE,
    IN p_valor DECIMAL(10,2),
    IN p_forma_pagamento VARCHAR(30)
)
BEGIN
    INSERT INTO venda
    (
        id_cliente,
        id_funcionario,
        id_veiculo_venda,
        data_venda,
        valor,
        forma_pagamento
    )
    VALUES
    (
        p_id_cliente,
        p_id_funcionario,
        p_id_veiculo_venda,
        p_data_venda,
        p_valor,
        p_forma_pagamento
    );
END$$


/* ============================================================
   11. TEST_DRIVE
   ============================================================ */

CREATE PROCEDURE sp_inserir_test_drive(
    IN p_id_cliente INT,
    IN p_id_funcionario INT,
    IN p_id_veiculo_venda INT,
    IN p_data_test DATE,
    IN p_horario TIME,
    IN p_observacao VARCHAR(200),
    IN p_status_test VARCHAR(30)
)
BEGIN
    INSERT INTO test_drive
    (
        id_cliente,
        id_funcionario,
        id_veiculo_venda,
        data_test,
        horario,
        observacao,
        status_test
    )
    VALUES
    (
        p_id_cliente,
        p_id_funcionario,
        p_id_veiculo_venda,
        p_data_test,
        p_horario,
        p_observacao,
        p_status_test
    );
END$$


/* ============================================================
   12. LOG_ACESSO_ESTOQUE
   ============================================================ */

CREATE PROCEDURE sp_inserir_log_estoque(
    IN p_id_funcionario INT,
    IN p_id_estoque INT,
    IN p_tipo_acesso VARCHAR(30),
    IN p_quantidade_movimentada INT,
    IN p_observacao VARCHAR(200),
    IN p_ip_acesso VARCHAR(45)
)
BEGIN
    INSERT INTO log_acesso_estoque
    (
        id_funcionario,
        id_estoque,
        tipo_acesso,
        quantidade_movimentada,
        observacao,
        ip_acesso
    )
    VALUES
    (
        p_id_funcionario,
        p_id_estoque,
        p_tipo_acesso,
        p_quantidade_movimentada,
        p_observacao,
        p_ip_acesso
    );
END$$


DELIMITER ;

INSERT INTO funcionario (nome, endereco, cargo, cpf, email, telefone, senha_acesso) VALUES
('Otavio Santos', 'Rua Sete de Setembro, 511 - Belo Horizonte/MG', 'Mecanico', '21819600133', 'otavio.santos0@autoprime.com', '31967827638', '$2b$12$hashDeExemplo000Senha'),
('Milena Silva', 'Av. Paulista, 1476 - Recife/PE', 'Financeiro', '86379402654', 'milena.silva1@autoprime.com', '31920868105', '$2b$12$hashDeExemplo001Senha'),
('Nathan Barbosa', 'Av. Brasil, 199 - Curitiba/PR', 'Recepcionista', '15594078161', 'nathan.barbosa2@autoprime.com', '31974093639', '$2b$12$hashDeExemplo002Senha'),
('Sabrina Moura', 'Rua Minas Gerais, 1192 - Uberlandia/MG', 'Mecanico', '10341316475', 'sabrina.moura3@autoprime.com', '31921831063', '$2b$12$hashDeExemplo003Senha'),
('Ximena Fernandes', 'Rua Sete de Setembro, 1447 - Sao Paulo/SP', 'Financeiro', '19283276483', 'ximena.fernandes4@autoprime.com', '31991887369', '$2b$12$hashDeExemplo004Senha'),
('Ursula Moura', 'Av. Paulista, 1693 - Belo Horizonte/MG', 'Vendedor', '56413953767', 'ursula.moura5@autoprime.com', '31919175900', '$2b$12$hashDeExemplo005Senha'),
('Quesia Pereira', 'Rua Rio de Janeiro, 1113 - Sao Paulo/SP', 'Gerente', '96965328710', 'quesia.pereira6@autoprime.com', '31914716857', '$2b$12$hashDeExemplo006Senha'),
('João Teixeira', 'Av. Getulio Vargas, 1231 - Contagem/MG', 'Vendedor', '66978480184', 'joão.teixeira7@autoprime.com', '31986028436', '$2b$12$hashDeExemplo007Senha'),
('Vitor Santos', 'Av. Getulio Vargas, 333 - Rio de Janeiro/RJ', 'Recepcionista', '04828148932', 'vitor.santos8@autoprime.com', '31950185867', '$2b$12$hashDeExemplo008Senha'),
('William Costa', 'Rua Rio de Janeiro, 1891 - Recife/PE', 'Vendedor', '95701543039', 'william.costa9@autoprime.com', '31910570592', '$2b$12$hashDeExemplo009Senha'),
('Felipe Freitas', 'Av. Brasil, 1567 - Salvador/BA', 'Estoquista', '22782489638', 'felipe.freitas10@autoprime.com', '31997969689', '$2b$12$hashDeExemplo010Senha'),
('Samuel Rodrigues', 'Av. Getulio Vargas, 1385 - Rio de Janeiro/RJ', 'Financeiro', '57871331509', 'samuel.rodrigues11@autoprime.com', '31974346088', '$2b$12$hashDeExemplo011Senha'),
('Olivia Monteiro', 'Rua das Flores, 155 - Sao Paulo/SP', 'Financeiro', '03105183473', 'olivia.monteiro12@autoprime.com', '31972374753', '$2b$12$hashDeExemplo012Senha'),
('Isabela Freitas', 'Av. Amazonas, 978 - Uberlandia/MG', 'Mecanico', '76311656670', 'isabela.freitas13@autoprime.com', '31990377459', '$2b$12$hashDeExemplo013Senha'),
('Paula Teixeira', 'Rua das Flores, 834 - Betim/MG', 'Financeiro', '51333872624', 'paula.teixeira14@autoprime.com', '31962092888', '$2b$12$hashDeExemplo014Senha'),
('Pedro Cavalcante', 'Rua Sao Paulo, 1664 - Betim/MG', 'Consultor Tecnico', '81080132677', 'pedro.cavalcante15@autoprime.com', '31928688676', '$2b$12$hashDeExemplo015Senha'),
('Zeca Dias', 'Rua XV de Novembro, 786 - Belo Horizonte/MG', 'Vendedor', '64746872343', 'zeca.dias16@autoprime.com', '31907849494', '$2b$12$hashDeExemplo016Senha'),
('Leandro Freitas', 'Rua das Flores, 1541 - Recife/PE', 'Gerente', '00978820812', 'leandro.freitas17@autoprime.com', '31909196777', '$2b$12$hashDeExemplo017Senha'),
('Milena Oliveira', 'Av. Getulio Vargas, 255 - Sao Paulo/SP', 'Estoquista', '39909169985', 'milena.oliveira18@autoprime.com', '31934999379', '$2b$12$hashDeExemplo018Senha'),
('Nathan Correia', 'Av. Paulista, 553 - Curitiba/PR', 'Recepcionista', '24751079911', 'nathan.correia19@autoprime.com', '31972160068', '$2b$12$hashDeExemplo019Senha'),
('Nathan Ribeiro', 'Rua XV de Novembro, 1921 - Rio de Janeiro/RJ', 'Gerente', '13542784980', 'nathan.ribeiro20@autoprime.com', '31989639081', '$2b$12$hashDeExemplo020Senha'),
('Jorge Lima', 'Rua XV de Novembro, 551 - Betim/MG', 'Vendedor', '18244935348', 'jorge.lima21@autoprime.com', '31965569635', '$2b$12$hashDeExemplo021Senha'),
('Quesia Dias', 'Av. Brasil, 1309 - Belo Horizonte/MG', 'Recepcionista', '40052427868', 'quesia.dias22@autoprime.com', '31901297845', '$2b$12$hashDeExemplo022Senha'),
('Henrique Oliveira', 'Rua Rio de Janeiro, 83 - Contagem/MG', 'Consultor Tecnico', '59826204505', 'henrique.oliveira23@autoprime.com', '31928195995', '$2b$12$hashDeExemplo023Senha'),
('Renata Almeida', 'Rua Minas Gerais, 1607 - Betim/MG', 'Estoquista', '69232260256', 'renata.almeida24@autoprime.com', '31989913412', '$2b$12$hashDeExemplo024Senha'),
('Valentina Pinto', 'Rua Sete de Setembro, 336 - Sao Paulo/SP', 'Consultor Tecnico', '16073375433', 'valentina.pinto25@autoprime.com', '31903176186', '$2b$12$hashDeExemplo025Senha'),
('Quintino Rodrigues', 'Rua Minas Gerais, 580 - Porto Alegre/RS', 'Consultor Tecnico', '14586850142', 'quintino.rodrigues26@autoprime.com', '31977925434', '$2b$12$hashDeExemplo026Senha'),
('Quesia Souza', 'Av. Amazonas, 899 - Betim/MG', 'Gerente', '56981693406', 'quesia.souza27@autoprime.com', '31900226999', '$2b$12$hashDeExemplo027Senha'),
('Hugo Castro', 'Av. Paulista, 755 - Recife/PE', 'Recepcionista', '15951484656', 'hugo.castro28@autoprime.com', '31993577729', '$2b$12$hashDeExemplo028Senha'),
('Sabrina Alves', 'Av. Paulista, 871 - Contagem/MG', 'Financeiro', '62994680443', 'sabrina.alves29@autoprime.com', '31957698610', '$2b$12$hashDeExemplo029Senha'),
('Leandro Cardoso', 'Rua Sao Paulo, 914 - Curitiba/PR', 'Recepcionista', '38721489513', 'leandro.cardoso30@autoprime.com', '31990301106', '$2b$12$hashDeExemplo030Senha'),
('Thiago Almeida', 'Rua XV de Novembro, 60 - Sao Paulo/SP', 'Vendedor', '37917693676', 'thiago.almeida31@autoprime.com', '31932747037', '$2b$12$hashDeExemplo031Senha'),
('João Teixeira', 'Av. Brasil, 1604 - Belo Horizonte/MG', 'Recepcionista', '32870831727', 'joão.teixeira32@autoprime.com', '31989600766', '$2b$12$hashDeExemplo032Senha'),
('Hugo Alves', 'Rua Minas Gerais, 1955 - Uberlandia/MG', 'Consultor Tecnico', '79868727743', 'hugo.alves33@autoprime.com', '31985585469', '$2b$12$hashDeExemplo033Senha'),
('Rafael Barbosa', 'Rua Sao Paulo, 1293 - Recife/PE', 'Mecanico', '47143455812', 'rafael.barbosa34@autoprime.com', '31920244148', '$2b$12$hashDeExemplo034Senha'),
('Olivia Carvalho', 'Av. Paulista, 141 - Contagem/MG', 'Recepcionista', '65876036690', 'olivia.carvalho35@autoprime.com', '31977267850', '$2b$12$hashDeExemplo035Senha'),
('Yara Rocha', 'Rua Minas Gerais, 621 - Belo Horizonte/MG', 'Consultor Tecnico', '66889373467', 'yara.rocha36@autoprime.com', '31903895645', '$2b$12$hashDeExemplo036Senha'),
('Yara Araujo', 'Rua XV de Novembro, 1731 - Porto Alegre/RS', 'Recepcionista', '29806990162', 'yara.araujo37@autoprime.com', '31961968116', '$2b$12$hashDeExemplo037Senha'),
('Lucas Souza', 'Av. Getulio Vargas, 680 - Rio de Janeiro/RJ', 'Mecanico', '75564641708', 'lucas.souza38@autoprime.com', '31906990811', '$2b$12$hashDeExemplo038Senha'),
('Wesley Almeida', 'Rua das Flores, 1554 - Betim/MG', 'Vendedor', '33092327193', 'wesley.almeida39@autoprime.com', '31962415804', '$2b$12$hashDeExemplo039Senha'),
('Samuel Nascimento', 'Rua XV de Novembro, 1250 - Curitiba/PR', 'Estoquista', '12419049663', 'samuel.nascimento40@autoprime.com', '31910200074', '$2b$12$hashDeExemplo040Senha'),
('Leandro Barros', 'Av. Brasil, 1437 - Sao Paulo/SP', 'Consultor Tecnico', '49190586518', 'leandro.barros41@autoprime.com', '31986911784', '$2b$12$hashDeExemplo041Senha'),
('Vitor Silva', 'Rua Sao Paulo, 226 - Porto Alegre/RS', 'Recepcionista', '57262849877', 'vitor.silva42@autoprime.com', '31958461818', '$2b$12$hashDeExemplo042Senha'),
('Ubirajara Monteiro', 'Rua Minas Gerais, 1754 - Rio de Janeiro/RJ', 'Mecanico', '14737996507', 'ubirajara.monteiro43@autoprime.com', '31943622663', '$2b$12$hashDeExemplo043Senha'),
('Lucas Rocha', 'Rua Minas Gerais, 1643 - Sao Paulo/SP', 'Gerente', '54948083136', 'lucas.rocha44@autoprime.com', '31965575808', '$2b$12$hashDeExemplo044Senha'),
('Jorge Barbosa', 'Rua Sao Paulo, 1332 - Sao Paulo/SP', 'Financeiro', '77014363495', 'jorge.barbosa45@autoprime.com', '31963519947', '$2b$12$hashDeExemplo045Senha'),
('Jorge Ribeiro', 'Av. Getulio Vargas, 1537 - Curitiba/PR', 'Estoquista', '55744431351', 'jorge.ribeiro46@autoprime.com', '31999707808', '$2b$12$hashDeExemplo046Senha'),
('Ingrid Barbosa', 'Av. Paulista, 453 - Contagem/MG', 'Financeiro', '74989413435', 'ingrid.barbosa47@autoprime.com', '31924084236', '$2b$12$hashDeExemplo047Senha'),
('Thiago Silva', 'Rua XV de Novembro, 571 - Recife/PE', 'Vendedor', '08427109477', 'thiago.silva48@autoprime.com', '31959118721', '$2b$12$hashDeExemplo048Senha'),
('Vitor Costa', 'Rua Sete de Setembro, 1937 - Belo Horizonte/MG', 'Consultor Tecnico', '71167190229', 'vitor.costa49@autoprime.com', '31940780112', '$2b$12$hashDeExemplo049Senha'),
('Felipe Almeida', 'Rua Rio de Janeiro, 1575 - Betim/MG', 'Recepcionista', '99938677496', 'felipe.almeida50@autoprime.com', '31940987442', '$2b$12$hashDeExemplo050Senha'),
('Katia Cardoso', 'Av. Amazonas, 1976 - Belo Horizonte/MG', 'Financeiro', '13341232812', 'katia.cardoso51@autoprime.com', '31900359129', '$2b$12$hashDeExemplo051Senha'),
('Amanda Martins', 'Rua Sao Paulo, 606 - Uberlandia/MG', 'Vendedor', '34471349361', 'amanda.martins52@autoprime.com', '31973089925', '$2b$12$hashDeExemplo052Senha'),
('Olivia Teixeira', 'Rua Sete de Setembro, 1702 - Contagem/MG', 'Mecanico', '10249947174', 'olivia.teixeira53@autoprime.com', '31993916665', '$2b$12$hashDeExemplo053Senha'),
('Zeca Nascimento', 'Rua Rio de Janeiro, 1021 - Recife/PE', 'Recepcionista', '19065940139', 'zeca.nascimento54@autoprime.com', '31978802305', '$2b$12$hashDeExemplo054Senha'),
('Bruno Barbosa', 'Av. Amazonas, 92 - Rio de Janeiro/RJ', 'Consultor Tecnico', '27874296717', 'bruno.barbosa55@autoprime.com', '31946702542', '$2b$12$hashDeExemplo055Senha'),
('Amanda Araujo', 'Av. Brasil, 1766 - Curitiba/PR', 'Mecanico', '56746807154', 'amanda.araujo56@autoprime.com', '31943389073', '$2b$12$hashDeExemplo056Senha'),
('Henrique Barbosa', 'Rua Rio de Janeiro, 1699 - Porto Alegre/RS', 'Vendedor', '87603859770', 'henrique.barbosa57@autoprime.com', '31927321124', '$2b$12$hashDeExemplo057Senha'),
('Rafael Alves', 'Rua Sete de Setembro, 907 - Contagem/MG', 'Financeiro', '71093248086', 'rafael.alves58@autoprime.com', '31912510327', '$2b$12$hashDeExemplo058Senha'),
('Olivia Moura', 'Rua Sao Paulo, 1949 - Betim/MG', 'Vendedor', '27484677378', 'olivia.moura59@autoprime.com', '31919413516', '$2b$12$hashDeExemplo059Senha'),
('Yara Rodrigues', 'Rua Rio de Janeiro, 1538 - Uberlandia/MG', 'Mecanico', '14658404499', 'yara.rodrigues60@autoprime.com', '31988575748', '$2b$12$hashDeExemplo060Senha'),
('Fabio Cavalcante', 'Rua Sao Paulo, 1113 - Contagem/MG', 'Recepcionista', '55886753396', 'fabio.cavalcante61@autoprime.com', '31931348220', '$2b$12$hashDeExemplo061Senha'),
('Yasmin Gomes', 'Rua Minas Gerais, 1535 - Belo Horizonte/MG', 'Recepcionista', '66270289517', 'yasmin.gomes62@autoprime.com', '31913383077', '$2b$12$hashDeExemplo062Senha'),
('Hugo Castro', 'Rua das Flores, 1489 - Salvador/BA', 'Mecanico', '62174596158', 'hugo.castro63@autoprime.com', '31951003997', '$2b$12$hashDeExemplo063Senha'),
('Ursula Teixeira', 'Rua Rio de Janeiro, 83 - Salvador/BA', 'Estoquista', '13431611724', 'ursula.teixeira64@autoprime.com', '31903885234', '$2b$12$hashDeExemplo064Senha'),
('Carla Araujo', 'Rua Sete de Setembro, 744 - Belo Horizonte/MG', 'Gerente', '62386922219', 'carla.araujo65@autoprime.com', '31951344226', '$2b$12$hashDeExemplo065Senha'),
('Nicolas Correia', 'Rua Sao Paulo, 1879 - Sao Paulo/SP', 'Estoquista', '23747407482', 'nicolas.correia66@autoprime.com', '31909913576', '$2b$12$hashDeExemplo066Senha'),
('Camila Fernandes', 'Rua Sete de Setembro, 1318 - Uberlandia/MG', 'Recepcionista', '47436713695', 'camila.fernandes67@autoprime.com', '31977149951', '$2b$12$hashDeExemplo067Senha'),
('Sabrina Barros', 'Rua das Flores, 1709 - Rio de Janeiro/RJ', 'Financeiro', '64090974395', 'sabrina.barros68@autoprime.com', '31929394291', '$2b$12$hashDeExemplo068Senha'),
('Otavio Rodrigues', 'Rua Sete de Setembro, 1398 - Uberlandia/MG', 'Consultor Tecnico', '21047095214', 'otavio.rodrigues69@autoprime.com', '31943851498', '$2b$12$hashDeExemplo069Senha'),
('Valentina Gomes', 'Av. Paulista, 280 - Contagem/MG', 'Consultor Tecnico', '85884247451', 'valentina.gomes70@autoprime.com', '31962858374', '$2b$12$hashDeExemplo070Senha'),
('Eduarda Pereira', 'Av. Getulio Vargas, 1990 - Sao Paulo/SP', 'Consultor Tecnico', '85160481754', 'eduarda.pereira71@autoprime.com', '31978458327', '$2b$12$hashDeExemplo071Senha'),
('Yara Moura', 'Av. Brasil, 1392 - Curitiba/PR', 'Mecanico', '70985931746', 'yara.moura72@autoprime.com', '31915659979', '$2b$12$hashDeExemplo072Senha'),
('Isabela Souza', 'Rua Sete de Setembro, 1018 - Belo Horizonte/MG', 'Vendedor', '13826758692', 'isabela.souza73@autoprime.com', '31955684858', '$2b$12$hashDeExemplo073Senha'),
('Paula Santos', 'Av. Amazonas, 845 - Salvador/BA', 'Gerente', '05377351585', 'paula.santos74@autoprime.com', '31908126895', '$2b$12$hashDeExemplo074Senha'),
('Zeca Nascimento', 'Av. Brasil, 1953 - Sao Paulo/SP', 'Consultor Tecnico', '71390053293', 'zeca.nascimento75@autoprime.com', '31909208698', '$2b$12$hashDeExemplo075Senha'),
('William Alves', 'Av. Amazonas, 452 - Sao Paulo/SP', 'Consultor Tecnico', '35290422842', 'william.alves76@autoprime.com', '31914754064', '$2b$12$hashDeExemplo076Senha'),
('Quintino Cavalcante', 'Rua XV de Novembro, 40 - Belo Horizonte/MG', 'Gerente', '39502402681', 'quintino.cavalcante77@autoprime.com', '31908530615', '$2b$12$hashDeExemplo077Senha'),
('Elisa Martins', 'Rua Rio de Janeiro, 1225 - Curitiba/PR', 'Vendedor', '78390847007', 'elisa.martins78@autoprime.com', '31953904155', '$2b$12$hashDeExemplo078Senha'),
('Breno Correia', 'Rua Sao Paulo, 1468 - Betim/MG', 'Recepcionista', '11592124998', 'breno.correia79@autoprime.com', '31995583530', '$2b$12$hashDeExemplo079Senha'),
('Ursula Carvalho', 'Rua Rio de Janeiro, 613 - Uberlandia/MG', 'Recepcionista', '89611836736', 'ursula.carvalho80@autoprime.com', '31945490631', '$2b$12$hashDeExemplo080Senha'),
('Danilo Carvalho', 'Av. Brasil, 650 - Porto Alegre/RS', 'Recepcionista', '54527111161', 'danilo.carvalho81@autoprime.com', '31999937039', '$2b$12$hashDeExemplo081Senha'),
('Valentina Fernandes', 'Rua Rio de Janeiro, 132 - Contagem/MG', 'Estoquista', '88516560494', 'valentina.fernandes82@autoprime.com', '31947197152', '$2b$12$hashDeExemplo082Senha'),
('Gabriela Monteiro', 'Av. Paulista, 326 - Recife/PE', 'Financeiro', '73158514936', 'gabriela.monteiro83@autoprime.com', '31975291541', '$2b$12$hashDeExemplo083Senha'),
('Yasmin Moura', 'Av. Amazonas, 1392 - Uberlandia/MG', 'Financeiro', '80940244550', 'yasmin.moura84@autoprime.com', '31924347841', '$2b$12$hashDeExemplo084Senha'),
('João Monteiro', 'Av. Brasil, 300 - Porto Alegre/RS', 'Financeiro', '01836675254', 'joão.monteiro85@autoprime.com', '31996850971', '$2b$12$hashDeExemplo085Senha'),
('Ursula Barbosa', 'Av. Amazonas, 183 - Uberlandia/MG', 'Vendedor', '22901476797', 'ursula.barbosa86@autoprime.com', '31955590800', '$2b$12$hashDeExemplo086Senha'),
('Rafael Rodrigues', 'Av. Brasil, 716 - Recife/PE', 'Recepcionista', '14978403690', 'rafael.rodrigues87@autoprime.com', '31901031743', '$2b$12$hashDeExemplo087Senha'),
('Nathan Lima', 'Rua XV de Novembro, 1575 - Sao Paulo/SP', 'Gerente', '45107622683', 'nathan.lima88@autoprime.com', '31967144075', '$2b$12$hashDeExemplo088Senha'),
('Jorge Moura', 'Av. Brasil, 823 - Curitiba/PR', 'Consultor Tecnico', '06071596966', 'jorge.moura89@autoprime.com', '31938858073', '$2b$12$hashDeExemplo089Senha'),
('Henrique Carvalho', 'Rua Minas Gerais, 361 - Belo Horizonte/MG', 'Consultor Tecnico', '97516136968', 'henrique.carvalho90@autoprime.com', '31910555833', '$2b$12$hashDeExemplo090Senha'),
('Zeca Cavalcante', 'Rua Minas Gerais, 463 - Rio de Janeiro/RJ', 'Gerente', '21818835523', 'zeca.cavalcante91@autoprime.com', '31913798190', '$2b$12$hashDeExemplo091Senha'),
('João Nascimento', 'Rua XV de Novembro, 1243 - Sao Paulo/SP', 'Mecanico', '12779979955', 'joão.nascimento92@autoprime.com', '31920261159', '$2b$12$hashDeExemplo092Senha'),
('Camila Oliveira', 'Rua Sao Paulo, 1303 - Salvador/BA', 'Gerente', '49058147700', 'camila.oliveira93@autoprime.com', '31949491122', '$2b$12$hashDeExemplo093Senha'),
('Sabrina Oliveira', 'Av. Amazonas, 1226 - Betim/MG', 'Estoquista', '67980793597', 'sabrina.oliveira94@autoprime.com', '31967292380', '$2b$12$hashDeExemplo094Senha'),
('João Souza', 'Av. Brasil, 1670 - Salvador/BA', 'Consultor Tecnico', '51820377889', 'joão.souza95@autoprime.com', '31921306555', '$2b$12$hashDeExemplo095Senha'),
('Ximena Fernandes', 'Av. Getulio Vargas, 847 - Rio de Janeiro/RJ', 'Consultor Tecnico', '59051518644', 'ximena.fernandes96@autoprime.com', '31997137886', '$2b$12$hashDeExemplo096Senha'),
('Quintino Castro', 'Rua XV de Novembro, 692 - Uberlandia/MG', 'Vendedor', '92546291486', 'quintino.castro97@autoprime.com', '31986368203', '$2b$12$hashDeExemplo097Senha'),
('Vitor Moura', 'Rua Rio de Janeiro, 201 - Contagem/MG', 'Financeiro', '68505423573', 'vitor.moura98@autoprime.com', '31930406092', '$2b$12$hashDeExemplo098Senha'),
('Isabela Pereira', 'Rua Sete de Setembro, 1739 - Betim/MG', 'Consultor Tecnico', '18880592962', 'isabela.pereira99@autoprime.com', '31921776452', '$2b$12$hashDeExemplo099Senha');

-- ===== CLIENTES =====
INSERT INTO clientes (nome, endereco, email, cpf, telefone) VALUES
('Lucas Moura', 'Rua XV de Novembro, 1486 - Uberlandia/MG', 'lucas.moura0@gmail.com', '70653794738', '31932100652'),
('Thiago Pinto', 'Av. Paulista, 763 - Salvador/BA', 'thiago.pinto1@gmail.com', '97746886239', '31918575536'),
('Quesia Souza', 'Rua Minas Gerais, 1145 - Salvador/BA', 'quesia.souza2@gmail.com', '18141247826', '31912309586'),
('Olivia Moura', 'Rua Minas Gerais, 1915 - Salvador/BA', 'olivia.moura3@gmail.com', '06068536153', '31903783268'),
('Ursula Castro', 'Rua Minas Gerais, 1630 - Betim/MG', 'ursula.castro4@gmail.com', '22047277901', '31902550658'),
('Quesia Rodrigues', 'Rua Rio de Janeiro, 1935 - Contagem/MG', 'quesia.rodrigues5@gmail.com', '98614341036', '31985758649'),
('Nicolas Martins', 'Av. Brasil, 1723 - Betim/MG', 'nicolas.martins6@gmail.com', '79808932460', '31982518345'),
('Wesley Almeida', 'Av. Getulio Vargas, 393 - Uberlandia/MG', 'wesley.almeida7@gmail.com', '18518888806', '31963100462'),
('Carla Teixeira', 'Rua Minas Gerais, 529 - Porto Alegre/RS', 'carla.teixeira8@gmail.com', '05153195205', '31973284724'),
('Vitor Moura', 'Rua Sao Paulo, 1434 - Contagem/MG', 'vitor.moura9@gmail.com', '72217043030', '31942358553'),
('Thiago Ribeiro', 'Rua Rio de Janeiro, 979 - Porto Alegre/RS', 'thiago.ribeiro10@gmail.com', '40345054156', '31953690013'),
('Valentina Martins', 'Rua Minas Gerais, 392 - Porto Alegre/RS', 'valentina.martins11@gmail.com', '77584161692', '31973212334'),
('Sabrina Araujo', 'Av. Brasil, 681 - Betim/MG', 'sabrina.araujo12@gmail.com', '44796275705', '31982523968'),
('Breno Nascimento', 'Av. Brasil, 1384 - Belo Horizonte/MG', 'breno.nascimento13@gmail.com', '65820297021', '31931674763'),
('Yasmin Teixeira', 'Rua Minas Gerais, 794 - Curitiba/PR', 'yasmin.teixeira14@gmail.com', '90927557192', '31971062902'),
('Ximena Carvalho', 'Rua Sete de Setembro, 521 - Curitiba/PR', 'ximena.carvalho15@gmail.com', '10278681447', '31928799154'),
('Nicolas Lima', 'Av. Paulista, 261 - Salvador/BA', 'nicolas.lima16@gmail.com', '21727155188', '31938971765'),
('Thiago Cavalcante', 'Rua XV de Novembro, 1635 - Contagem/MG', 'thiago.cavalcante17@gmail.com', '58313237058', '31976809773'),
('Ximena Martins', 'Rua XV de Novembro, 1263 - Recife/PE', 'ximena.martins18@gmail.com', '11467866912', '31942550733'),
('Paula Oliveira', 'Rua Sao Paulo, 1402 - Salvador/BA', 'paula.oliveira19@gmail.com', '85289226801', '31969538491'),
('João Lima', 'Rua XV de Novembro, 670 - Contagem/MG', 'joão.lima20@gmail.com', '35841438424', '31982467167'),
('Ingrid Oliveira', 'Rua XV de Novembro, 1222 - Recife/PE', 'ingrid.oliveira21@gmail.com', '92299590010', '31986094462'),
('Yasmin Monteiro', 'Av. Paulista, 1580 - Rio de Janeiro/RJ', 'yasmin.monteiro22@gmail.com', '96907844736', '31939920898'),
('Danilo Oliveira', 'Rua XV de Novembro, 910 - Belo Horizonte/MG', 'danilo.oliveira23@gmail.com', '67735925556', '31917551135'),
('William Fernandes', 'Rua Rio de Janeiro, 227 - Recife/PE', 'william.fernandes24@gmail.com', '53714732104', '31951559717'),
('Nicolas Gomes', 'Rua XV de Novembro, 1676 - Sao Paulo/SP', 'nicolas.gomes25@gmail.com', '59532787747', '31903110670'),
('Felipe Carvalho', 'Rua Sao Paulo, 1989 - Recife/PE', 'felipe.carvalho26@gmail.com', '33950047974', '31972033413'),
('Ana Cavalcante', 'Av. Getulio Vargas, 284 - Betim/MG', 'ana.cavalcante27@gmail.com', '45650609835', '31974252324'),
('Sabrina Oliveira', 'Rua Rio de Janeiro, 932 - Porto Alegre/RS', 'sabrina.oliveira28@gmail.com', '84991216558', '31949070856'),
('William Pereira', 'Av. Amazonas, 1052 - Sao Paulo/SP', 'william.pereira29@gmail.com', '68000257872', '31981370909'),
('Giovana Pereira', 'Av. Amazonas, 662 - Curitiba/PR', 'giovana.pereira30@gmail.com', '26949588879', '31940237208'),
('Elisa Moura', 'Rua Minas Gerais, 688 - Belo Horizonte/MG', 'elisa.moura31@gmail.com', '16940974993', '31996824684'),
('Diego Monteiro', 'Rua XV de Novembro, 1083 - Salvador/BA', 'diego.monteiro32@gmail.com', '96230913075', '31956207740'),
('João Gomes', 'Av. Getulio Vargas, 1037 - Sao Paulo/SP', 'joão.gomes33@gmail.com', '97028385786', '31942111160'),
('Lucas Martins', 'Rua Minas Gerais, 1128 - Recife/PE', 'lucas.martins34@gmail.com', '54973348434', '31938789478'),
('Tatiane Rodrigues', 'Rua Minas Gerais, 992 - Salvador/BA', 'tatiane.rodrigues35@gmail.com', '58441986652', '31938983895'),
('Carla Lima', 'Rua Minas Gerais, 1902 - Betim/MG', 'carla.lima36@gmail.com', '74733848421', '31982634772'),
('Valentina Monteiro', 'Av. Paulista, 113 - Sao Paulo/SP', 'valentina.monteiro37@gmail.com', '83301657120', '31973867070'),
('Karla Gomes', 'Rua Sao Paulo, 1342 - Salvador/BA', 'karla.gomes38@gmail.com', '34540193802', '31956087572'),
('Lucas Castro', 'Av. Getulio Vargas, 1623 - Belo Horizonte/MG', 'lucas.castro39@gmail.com', '72400499154', '31960981700'),
('Paula Alves', 'Rua Sao Paulo, 1831 - Recife/PE', 'paula.alves40@gmail.com', '28743152742', '31901890348'),
('Valentina Araujo', 'Av. Amazonas, 1391 - Rio de Janeiro/RJ', 'valentina.araujo41@gmail.com', '32966851612', '31918872606'),
('Elisa Araujo', 'Rua das Flores, 544 - Sao Paulo/SP', 'elisa.araujo42@gmail.com', '63745499045', '31992981826'),
('Pedro Souza', 'Rua Sao Paulo, 638 - Betim/MG', 'pedro.souza43@gmail.com', '26841459332', '31964180488'),
('João Martins', 'Rua Minas Gerais, 861 - Uberlandia/MG', 'joão.martins44@gmail.com', '87833918785', '31910482769'),
('Katia Santos', 'Rua Rio de Janeiro, 1859 - Belo Horizonte/MG', 'katia.santos45@gmail.com', '83982258713', '31996223100'),
('Leandro Rocha', 'Rua Rio de Janeiro, 922 - Betim/MG', 'leandro.rocha46@gmail.com', '07286790874', '31997077009'),
('Bruno Carvalho', 'Rua das Flores, 1537 - Rio de Janeiro/RJ', 'bruno.carvalho47@gmail.com', '39106518017', '31904259382'),
('Sabrina Gomes', 'Rua XV de Novembro, 1578 - Contagem/MG', 'sabrina.gomes48@gmail.com', '65676618251', '31923954324'),
('Ingrid Carvalho', 'Rua XV de Novembro, 1500 - Recife/PE', 'ingrid.carvalho49@gmail.com', '30047868633', '31961824078'),
('Wesley Pereira', 'Av. Paulista, 1929 - Rio de Janeiro/RJ', 'wesley.pereira50@gmail.com', '10690331190', '31959920305'),
('Milena Correia', 'Av. Paulista, 1526 - Belo Horizonte/MG', 'milena.correia51@gmail.com', '06738302843', '31998182614'),
('Katia Araujo', 'Av. Amazonas, 1592 - Uberlandia/MG', 'katia.araujo52@gmail.com', '53428364408', '31979412216'),
('Valentina Castro', 'Av. Getulio Vargas, 1148 - Contagem/MG', 'valentina.castro53@gmail.com', '70568566246', '31924679818'),
('William Alves', 'Av. Paulista, 1749 - Salvador/BA', 'william.alves54@gmail.com', '34270866882', '31952132722'),
('Pedro Nascimento', 'Rua Minas Gerais, 1334 - Sao Paulo/SP', 'pedro.nascimento55@gmail.com', '17518304699', '31905307982'),
('Eduarda Rodrigues', 'Rua Rio de Janeiro, 454 - Uberlandia/MG', 'eduarda.rodrigues56@gmail.com', '73540331739', '31994458220'),
('Nathan Carvalho', 'Rua Rio de Janeiro, 668 - Sao Paulo/SP', 'nathan.carvalho57@gmail.com', '46785445877', '31913234972'),
('Ubirajara Rocha', 'Av. Paulista, 769 - Curitiba/PR', 'ubirajara.rocha58@gmail.com', '56093204899', '31996638366'),
('Amanda Lima', 'Av. Paulista, 685 - Contagem/MG', 'amanda.lima59@gmail.com', '36937854777', '31922579937'),
('Ubirajara Pinto', 'Rua XV de Novembro, 296 - Curitiba/PR', 'ubirajara.pinto60@gmail.com', '87280801006', '31918453800'),
('Otavio Almeida', 'Rua XV de Novembro, 28 - Betim/MG', 'otavio.almeida61@gmail.com', '38750997700', '31971432350'),
('Jorge Gomes', 'Rua das Flores, 1094 - Belo Horizonte/MG', 'jorge.gomes62@gmail.com', '48408621182', '31932342289'),
('Mariana Cardoso', 'Rua Sete de Setembro, 1679 - Recife/PE', 'mariana.cardoso63@gmail.com', '54615679334', '31991810512'),
('Felipe Teixeira', 'Av. Brasil, 840 - Belo Horizonte/MG', 'felipe.teixeira64@gmail.com', '66870021765', '31975947990'),
('Gabriela Dias', 'Rua das Flores, 480 - Recife/PE', 'gabriela.dias65@gmail.com', '39740148902', '31942209421'),
('Bruno Rodrigues', 'Rua XV de Novembro, 1550 - Uberlandia/MG', 'bruno.rodrigues66@gmail.com', '61429396856', '31999286916'),
('Isabela Pinto', 'Rua Rio de Janeiro, 1536 - Betim/MG', 'isabela.pinto67@gmail.com', '50163159996', '31943805532'),
('Bruno Teixeira', 'Rua Sao Paulo, 1014 - Rio de Janeiro/RJ', 'bruno.teixeira68@gmail.com', '35866296194', '31933077929'),
('Tatiane Oliveira', 'Rua Sete de Setembro, 325 - Betim/MG', 'tatiane.oliveira69@gmail.com', '62655110475', '31936207439'),
('Gabriela Pereira', 'Rua XV de Novembro, 892 - Betim/MG', 'gabriela.pereira70@gmail.com', '78886101581', '31980117857'),
('Milena Pinto', 'Av. Getulio Vargas, 35 - Curitiba/PR', 'milena.pinto71@gmail.com', '46618398262', '31918634797'),
('Rafael Lima', 'Rua Sao Paulo, 308 - Rio de Janeiro/RJ', 'rafael.lima72@gmail.com', '12646471543', '31996757486'),
('Otavio Rocha', 'Av. Amazonas, 410 - Uberlandia/MG', 'otavio.rocha73@gmail.com', '71240659657', '31944927535'),
('Breno Moura', 'Rua XV de Novembro, 625 - Uberlandia/MG', 'breno.moura74@gmail.com', '59375265479', '31932537638'),
('Ursula Carvalho', 'Av. Getulio Vargas, 757 - Rio de Janeiro/RJ', 'ursula.carvalho75@gmail.com', '19398280737', '31939101812'),
('Samuel Oliveira', 'Rua Sao Paulo, 295 - Porto Alegre/RS', 'samuel.oliveira76@gmail.com', '43426617979', '31953795149'),
('Ingrid Ribeiro', 'Rua Rio de Janeiro, 85 - Porto Alegre/RS', 'ingrid.ribeiro77@gmail.com', '58911352909', '31986574622'),
('Renata Teixeira', 'Rua Minas Gerais, 1987 - Porto Alegre/RS', 'renata.teixeira78@gmail.com', '61014388899', '31929666377'),
('Camila Fernandes', 'Rua Sao Paulo, 1591 - Porto Alegre/RS', 'camila.fernandes79@gmail.com', '98250714611', '31997999171'),
('João Fernandes', 'Rua Minas Gerais, 942 - Rio de Janeiro/RJ', 'joão.fernandes80@gmail.com', '38757177514', '31905997257'),
('Tatiane Santos', 'Rua Minas Gerais, 1337 - Belo Horizonte/MG', 'tatiane.santos81@gmail.com', '12382825867', '31931119124'),
('Zeca Teixeira', 'Rua XV de Novembro, 1321 - Contagem/MG', 'zeca.teixeira82@gmail.com', '66093796603', '31927619925'),
('Rafael Barbosa', 'Av. Amazonas, 218 - Betim/MG', 'rafael.barbosa83@gmail.com', '82553714785', '31980124068'),
('Yara Cardoso', 'Av. Amazonas, 243 - Porto Alegre/RS', 'yara.cardoso84@gmail.com', '55792499125', '31915819123'),
('Pedro Lima', 'Rua XV de Novembro, 774 - Betim/MG', 'pedro.lima85@gmail.com', '28669296627', '31985295586'),
('Ingrid Barros', 'Rua Rio de Janeiro, 351 - Contagem/MG', 'ingrid.barros86@gmail.com', '74225790507', '31918325379'),
('Mariana Moura', 'Rua Rio de Janeiro, 1045 - Porto Alegre/RS', 'mariana.moura87@gmail.com', '76767721903', '31939203644'),
('Carla Nascimento', 'Rua Rio de Janeiro, 601 - Sao Paulo/SP', 'carla.nascimento88@gmail.com', '27978819148', '31949239353'),
('Ingrid Moura', 'Rua Sao Paulo, 1128 - Belo Horizonte/MG', 'ingrid.moura89@gmail.com', '36134074517', '31915755285'),
('Yasmin Pinto', 'Av. Paulista, 1670 - Sao Paulo/SP', 'yasmin.pinto90@gmail.com', '95962923309', '31947085656'),
('Ingrid Nascimento', 'Rua Rio de Janeiro, 354 - Uberlandia/MG', 'ingrid.nascimento91@gmail.com', '54494812604', '31988032908'),
('Isabela Barros', 'Av. Paulista, 309 - Contagem/MG', 'isabela.barros92@gmail.com', '53672946671', '31985044078'),
('Yasmin Oliveira', 'Rua Rio de Janeiro, 1545 - Porto Alegre/RS', 'yasmin.oliveira93@gmail.com', '45775901751', '31971729237'),
('Zeca Rodrigues', 'Av. Paulista, 1023 - Porto Alegre/RS', 'zeca.rodrigues94@gmail.com', '45458929750', '31906166355'),
('Gabriela Teixeira', 'Rua das Flores, 264 - Salvador/BA', 'gabriela.teixeira95@gmail.com', '27706324241', '31987857309'),
('Ximena Nascimento', 'Rua Minas Gerais, 1370 - Betim/MG', 'ximena.nascimento96@gmail.com', '20643611037', '31910460758'),
('Isabela Monteiro', 'Rua Rio de Janeiro, 1402 - Sao Paulo/SP', 'isabela.monteiro97@gmail.com', '70051627136', '31911989814'),
('Ubirajara Pinto', 'Av. Brasil, 651 - Betim/MG', 'ubirajara.pinto98@gmail.com', '54262218909', '31987244236'),
('Karla Martins', 'Av. Paulista, 1296 - Curitiba/PR', 'karla.martins99@gmail.com', '26973112196', '31947182314');

-- ===== FORNECEDOR =====
INSERT INTO fornecedor (nome, endereco, tipo_produto, cnpj, telefone, cidade, uf) VALUES
('Fornecedora Araujo 0 Ltda', 'Av. Paulista, 577 - Contagem/MG', 'Suspensao', '38999404389836', '31939666982', 'Porto Alegre', 'RS'),
('Fornecedora Pinto 1 Ltda', 'Rua Sao Paulo, 800 - Sao Paulo/SP', 'Suspensao', '37918055269658', '31991662930', 'Belo Horizonte', 'MG'),
('Fornecedora Barbosa 2 Ltda', 'Av. Brasil, 44 - Salvador/BA', 'Suspensao', '04300684866618', '31972162880', 'Contagem', 'MG'),
('Fornecedora Pereira 3 Ltda', 'Av. Brasil, 644 - Rio de Janeiro/RJ', 'Suspensao', '83285691463031', '31958315400', 'Uberlandia', 'MG'),
('Fornecedora Martins 4 Ltda', 'Av. Amazonas, 122 - Uberlandia/MG', 'Filtro', '21020275884252', '31936072958', 'Betim', 'MG'),
('Fornecedora Barbosa 5 Ltda', 'Rua Minas Gerais, 1662 - Belo Horizonte/MG', 'Carroceria', '48149177850792', '31949350218', 'Betim', 'MG'),
('Fornecedora Nascimento 6 Ltda', 'Av. Amazonas, 1390 - Betim/MG', 'Suspensao', '38000307562208', '31995834249', 'Contagem', 'MG'),
('Fornecedora Almeida 7 Ltda', 'Av. Paulista, 862 - Curitiba/PR', 'Pneu', '41951802380617', '31937890586', 'Porto Alegre', 'RS'),
('Fornecedora Araujo 8 Ltda', 'Rua Rio de Janeiro, 945 - Betim/MG', 'Freio', '53494937597383', '31920208677', 'Rio de Janeiro', 'RJ'),
('Fornecedora Castro 9 Ltda', 'Rua das Flores, 487 - Porto Alegre/RS', 'Pneu', '05064138367024', '31912485824', 'Belo Horizonte', 'MG'),
('Fornecedora Castro 10 Ltda', 'Rua Rio de Janeiro, 855 - Sao Paulo/SP', 'Pneu', '71918261990623', '31939148093', 'Belo Horizonte', 'MG'),
('Fornecedora Cavalcante 11 Ltda', 'Av. Getulio Vargas, 1445 - Curitiba/PR', 'Pneu', '57431329121277', '31942148834', 'Rio de Janeiro', 'RJ'),
('Fornecedora Santos 12 Ltda', 'Rua Minas Gerais, 1985 - Recife/PE', 'Eletrica', '74741124903521', '31995449930', 'Porto Alegre', 'RS'),
('Fornecedora Fernandes 13 Ltda', 'Rua Rio de Janeiro, 110 - Porto Alegre/RS', 'Filtro', '42067883171210', '31908277097', 'Sao Paulo', 'SP'),
('Fornecedora Pereira 14 Ltda', 'Av. Getulio Vargas, 772 - Sao Paulo/SP', 'Suspensao', '99410137215107', '31906796477', 'Sao Paulo', 'SP'),
('Fornecedora Castro 15 Ltda', 'Av. Getulio Vargas, 1692 - Uberlandia/MG', 'Carroceria', '70662532447209', '31983104469', 'Contagem', 'MG'),
('Fornecedora Almeida 16 Ltda', 'Rua Sao Paulo, 853 - Rio de Janeiro/RJ', 'Oleo/Lubrificante', '01462638380657', '31973083942', 'Uberlandia', 'MG'),
('Fornecedora Fernandes 17 Ltda', 'Rua Rio de Janeiro, 668 - Uberlandia/MG', 'Carroceria', '42059304078593', '31921424479', 'Salvador', 'BA'),
('Fornecedora Almeida 18 Ltda', 'Rua Sete de Setembro, 1102 - Sao Paulo/SP', 'Freio', '39652239559059', '31975645982', 'Betim', 'MG'),
('Fornecedora Monteiro 19 Ltda', 'Rua Sao Paulo, 1120 - Sao Paulo/SP', 'Filtro', '27010393087059', '31927040091', 'Contagem', 'MG'),
('Fornecedora Araujo 20 Ltda', 'Rua Minas Gerais, 131 - Contagem/MG', 'Freio', '29218515691545', '31918314232', 'Contagem', 'MG'),
('Fornecedora Freitas 21 Ltda', 'Rua Sao Paulo, 1339 - Porto Alegre/RS', 'Pneu', '28953926442209', '31952559853', 'Contagem', 'MG'),
('Fornecedora Souza 22 Ltda', 'Av. Amazonas, 661 - Contagem/MG', 'Eletrica', '91725135521570', '31935596211', 'Uberlandia', 'MG'),
('Fornecedora Almeida 23 Ltda', 'Rua Minas Gerais, 535 - Betim/MG', 'Suspensao', '00676267658617', '31977585294', 'Sao Paulo', 'SP'),
('Fornecedora Costa 24 Ltda', 'Av. Brasil, 1646 - Salvador/BA', 'Freio', '40541152621815', '31979729429', 'Sao Paulo', 'SP'),
('Fornecedora Dias 25 Ltda', 'Rua das Flores, 893 - Salvador/BA', 'Motor', '96201533688444', '31931883191', 'Uberlandia', 'MG'),
('Fornecedora Souza 26 Ltda', 'Av. Amazonas, 1135 - Porto Alegre/RS', 'Oleo/Lubrificante', '20506149731032', '31985656500', 'Betim', 'MG'),
('Fornecedora Oliveira 27 Ltda', 'Av. Brasil, 641 - Salvador/BA', 'Carroceria', '77418625652704', '31959020960', 'Rio de Janeiro', 'RJ'),
('Fornecedora Nascimento 28 Ltda', 'Rua Sete de Setembro, 1165 - Sao Paulo/SP', 'Freio', '21158693806868', '31992216696', 'Salvador', 'BA'),
('Fornecedora Monteiro 29 Ltda', 'Rua Sao Paulo, 622 - Sao Paulo/SP', 'Suspensao', '60898992172233', '31916936398', 'Salvador', 'BA'),
('Fornecedora Gomes 30 Ltda', 'Av. Getulio Vargas, 423 - Betim/MG', 'Motor', '94511686854870', '31994007723', 'Belo Horizonte', 'MG'),
('Fornecedora Monteiro 31 Ltda', 'Av. Getulio Vargas, 240 - Recife/PE', 'Carroceria', '22999119148564', '31951411224', 'Uberlandia', 'MG'),
('Fornecedora Monteiro 32 Ltda', 'Rua Sao Paulo, 86 - Uberlandia/MG', 'Motor', '46299606530745', '31902715612', 'Salvador', 'BA'),
('Fornecedora Moura 33 Ltda', 'Rua Sete de Setembro, 584 - Rio de Janeiro/RJ', 'Oleo/Lubrificante', '13247546913736', '31999447927', 'Curitiba', 'PR'),
('Fornecedora Barbosa 34 Ltda', 'Rua Minas Gerais, 1691 - Recife/PE', 'Freio', '82148628902330', '31933486016', 'Salvador', 'BA'),
('Fornecedora Martins 35 Ltda', 'Rua Minas Gerais, 1453 - Belo Horizonte/MG', 'Eletrica', '45786103579727', '31978769733', 'Belo Horizonte', 'MG'),
('Fornecedora Fernandes 36 Ltda', 'Rua XV de Novembro, 1725 - Curitiba/PR', 'Filtro', '14060293333468', '31902691381', 'Recife', 'PE'),
('Fornecedora Rocha 37 Ltda', 'Rua XV de Novembro, 1241 - Contagem/MG', 'Freio', '34944665743748', '31983698993', 'Belo Horizonte', 'MG'),
('Fornecedora Monteiro 38 Ltda', 'Rua das Flores, 1057 - Betim/MG', 'Pneu', '89944171545444', '31925281262', 'Porto Alegre', 'RS'),
('Fornecedora Ribeiro 39 Ltda', 'Rua das Flores, 1659 - Sao Paulo/SP', 'Carroceria', '52074466609935', '31997515873', 'Contagem', 'MG'),
('Fornecedora Correia 40 Ltda', 'Rua Sao Paulo, 1866 - Recife/PE', 'Pneu', '84282417248251', '31929830361', 'Sao Paulo', 'SP'),
('Fornecedora Almeida 41 Ltda', 'Av. Getulio Vargas, 1624 - Rio de Janeiro/RJ', 'Pneu', '54947170999173', '31967172936', 'Curitiba', 'PR'),
('Fornecedora Cavalcante 42 Ltda', 'Rua Rio de Janeiro, 621 - Porto Alegre/RS', 'Carroceria', '02235697252175', '31984695784', 'Betim', 'MG'),
('Fornecedora Araujo 43 Ltda', 'Rua das Flores, 935 - Belo Horizonte/MG', 'Filtro', '32927129666676', '31900626681', 'Contagem', 'MG'),
('Fornecedora Alves 44 Ltda', 'Rua Minas Gerais, 1955 - Sao Paulo/SP', 'Freio', '58300335421689', '31941086072', 'Belo Horizonte', 'MG'),
('Fornecedora Oliveira 45 Ltda', 'Rua Sete de Setembro, 1952 - Belo Horizonte/MG', 'Filtro', '78985625753260', '31930657783', 'Contagem', 'MG'),
('Fornecedora Freitas 46 Ltda', 'Av. Paulista, 1513 - Contagem/MG', 'Freio', '98215064890901', '31987720360', 'Sao Paulo', 'SP'),
('Fornecedora Souza 47 Ltda', 'Av. Getulio Vargas, 919 - Betim/MG', 'Carroceria', '18472304618499', '31994049898', 'Belo Horizonte', 'MG'),
('Fornecedora Gomes 48 Ltda', 'Rua Rio de Janeiro, 1482 - Betim/MG', 'Suspensao', '41173934835642', '31905288944', 'Contagem', 'MG'),
('Fornecedora Rocha 49 Ltda', 'Rua Sao Paulo, 687 - Sao Paulo/SP', 'Eletrica', '00119721811437', '31939731424', 'Recife', 'PE'),
('Fornecedora Martins 50 Ltda', 'Av. Brasil, 1675 - Belo Horizonte/MG', 'Motor', '04556110022557', '31983457527', 'Rio de Janeiro', 'RJ'),
('Fornecedora Dias 51 Ltda', 'Rua Minas Gerais, 1679 - Betim/MG', 'Pneu', '21667467621202', '31913920137', 'Rio de Janeiro', 'RJ'),
('Fornecedora Castro 52 Ltda', 'Rua Sao Paulo, 1653 - Uberlandia/MG', 'Oleo/Lubrificante', '29659027716701', '31935113084', 'Porto Alegre', 'RS'),
('Fornecedora Silva 53 Ltda', 'Av. Amazonas, 1492 - Recife/PE', 'Eletrica', '58891637562890', '31901562947', 'Curitiba', 'PR'),
('Fornecedora Ribeiro 54 Ltda', 'Rua Sao Paulo, 1790 - Salvador/BA', 'Motor', '17535408386631', '31961618633', 'Contagem', 'MG'),
('Fornecedora Pinto 55 Ltda', 'Rua Sao Paulo, 190 - Uberlandia/MG', 'Oleo/Lubrificante', '75170166088019', '31983089652', 'Salvador', 'BA'),
('Fornecedora Dias 56 Ltda', 'Rua Rio de Janeiro, 433 - Recife/PE', 'Oleo/Lubrificante', '55037589975711', '31988437437', 'Rio de Janeiro', 'RJ'),
('Fornecedora Silva 57 Ltda', 'Rua Minas Gerais, 1709 - Curitiba/PR', 'Filtro', '88510272614933', '31916206227', 'Sao Paulo', 'SP'),
('Fornecedora Rodrigues 58 Ltda', 'Av. Paulista, 1477 - Salvador/BA', 'Pneu', '16091779827080', '31974252780', 'Porto Alegre', 'RS'),
('Fornecedora Moura 59 Ltda', 'Rua Sao Paulo, 1903 - Uberlandia/MG', 'Motor', '92216995866934', '31953401206', 'Porto Alegre', 'RS'),
('Fornecedora Lima 60 Ltda', 'Rua XV de Novembro, 292 - Salvador/BA', 'Carroceria', '98485833394522', '31967631432', 'Curitiba', 'PR'),
('Fornecedora Barros 61 Ltda', 'Av. Brasil, 1568 - Curitiba/PR', 'Pneu', '87996846081062', '31907122263', 'Recife', 'PE'),
('Fornecedora Rodrigues 62 Ltda', 'Rua XV de Novembro, 596 - Rio de Janeiro/RJ', 'Filtro', '20438057198386', '31931889524', 'Belo Horizonte', 'MG'),
('Fornecedora Pinto 63 Ltda', 'Rua das Flores, 1907 - Rio de Janeiro/RJ', 'Carroceria', '66580043973598', '31999113085', 'Recife', 'PE'),
('Fornecedora Rodrigues 64 Ltda', 'Rua Sete de Setembro, 929 - Sao Paulo/SP', 'Motor', '12281606484229', '31934227688', 'Uberlandia', 'MG'),
('Fornecedora Araujo 65 Ltda', 'Rua XV de Novembro, 91 - Salvador/BA', 'Motor', '59094798515832', '31969874593', 'Belo Horizonte', 'MG'),
('Fornecedora Pinto 66 Ltda', 'Rua XV de Novembro, 861 - Recife/PE', 'Carroceria', '15335554398780', '31915397719', 'Betim', 'MG'),
('Fornecedora Martins 67 Ltda', 'Av. Amazonas, 1891 - Sao Paulo/SP', 'Eletrica', '05616484085887', '31965337822', 'Curitiba', 'PR'),
('Fornecedora Lima 68 Ltda', 'Rua Minas Gerais, 1062 - Sao Paulo/SP', 'Suspensao', '12880133613861', '31992079205', 'Belo Horizonte', 'MG'),
('Fornecedora Silva 69 Ltda', 'Rua Minas Gerais, 87 - Salvador/BA', 'Suspensao', '10248193466766', '31942467059', 'Contagem', 'MG'),
('Fornecedora Carvalho 70 Ltda', 'Rua Rio de Janeiro, 22 - Betim/MG', 'Suspensao', '90158144914766', '31988680762', 'Belo Horizonte', 'MG'),
('Fornecedora Rocha 71 Ltda', 'Rua Rio de Janeiro, 460 - Contagem/MG', 'Motor', '68424508821009', '31980081663', 'Belo Horizonte', 'MG'),
('Fornecedora Alves 72 Ltda', 'Av. Brasil, 634 - Recife/PE', 'Eletrica', '53682223943129', '31907299874', 'Porto Alegre', 'RS'),
('Fornecedora Martins 73 Ltda', 'Av. Brasil, 605 - Recife/PE', 'Suspensao', '41397552314913', '31942652506', 'Recife', 'PE'),
('Fornecedora Martins 74 Ltda', 'Av. Amazonas, 1360 - Curitiba/PR', 'Filtro', '92995562053364', '31948249394', 'Salvador', 'BA'),
('Fornecedora Correia 75 Ltda', 'Rua Sao Paulo, 957 - Curitiba/PR', 'Oleo/Lubrificante', '54781291428341', '31997633380', 'Contagem', 'MG'),
('Fornecedora Dias 76 Ltda', 'Rua Rio de Janeiro, 1303 - Belo Horizonte/MG', 'Freio', '99693084887256', '31929971710', 'Betim', 'MG'),
('Fornecedora Freitas 77 Ltda', 'Rua XV de Novembro, 961 - Rio de Janeiro/RJ', 'Suspensao', '65803928272299', '31988504955', 'Uberlandia', 'MG'),
('Fornecedora Freitas 78 Ltda', 'Rua Minas Gerais, 92 - Salvador/BA', 'Eletrica', '73145303856770', '31905355917', 'Contagem', 'MG'),
('Fornecedora Santos 79 Ltda', 'Rua Sete de Setembro, 1719 - Recife/PE', 'Filtro', '98926659184638', '31954471218', 'Curitiba', 'PR'),
('Fornecedora Moura 80 Ltda', 'Rua Sao Paulo, 1633 - Curitiba/PR', 'Oleo/Lubrificante', '90827231843222', '31948616740', 'Curitiba', 'PR'),
('Fornecedora Barros 81 Ltda', 'Av. Paulista, 859 - Betim/MG', 'Pneu', '17773926030299', '31921626387', 'Uberlandia', 'MG'),
('Fornecedora Teixeira 82 Ltda', 'Rua das Flores, 1834 - Recife/PE', 'Motor', '02428699041379', '31963272042', 'Contagem', 'MG'),
('Fornecedora Costa 83 Ltda', 'Av. Getulio Vargas, 1240 - Sao Paulo/SP', 'Motor', '92984257991366', '31917745355', 'Salvador', 'BA'),
('Fornecedora Silva 84 Ltda', 'Rua Rio de Janeiro, 1770 - Sao Paulo/SP', 'Carroceria', '29127990881172', '31980996996', 'Betim', 'MG'),
('Fornecedora Moura 85 Ltda', 'Av. Getulio Vargas, 1079 - Belo Horizonte/MG', 'Carroceria', '50863765991624', '31964040812', 'Recife', 'PE'),
('Fornecedora Castro 86 Ltda', 'Rua Sete de Setembro, 1235 - Betim/MG', 'Carroceria', '43009818063565', '31914305357', 'Sao Paulo', 'SP'),
('Fornecedora Gomes 87 Ltda', 'Rua Sete de Setembro, 545 - Uberlandia/MG', 'Carroceria', '95946368872588', '31964929189', 'Contagem', 'MG'),
('Fornecedora Lima 88 Ltda', 'Rua Minas Gerais, 1595 - Uberlandia/MG', 'Carroceria', '21372138658902', '31952224611', 'Rio de Janeiro', 'RJ'),
('Fornecedora Pinto 89 Ltda', 'Rua XV de Novembro, 975 - Betim/MG', 'Carroceria', '11435190669849', '31907712557', 'Belo Horizonte', 'MG'),
('Fornecedora Teixeira 90 Ltda', 'Rua Sao Paulo, 31 - Salvador/BA', 'Eletrica', '84309883920530', '31921131878', 'Contagem', 'MG'),
('Fornecedora Nascimento 91 Ltda', 'Rua Minas Gerais, 1381 - Porto Alegre/RS', 'Carroceria', '69380118489554', '31930372869', 'Betim', 'MG'),
('Fornecedora Rodrigues 92 Ltda', 'Av. Getulio Vargas, 1187 - Salvador/BA', 'Freio', '42681818451848', '31977160950', 'Uberlandia', 'MG'),
('Fornecedora Barros 93 Ltda', 'Av. Getulio Vargas, 1163 - Salvador/BA', 'Oleo/Lubrificante', '35779071416335', '31955354876', 'Rio de Janeiro', 'RJ'),
('Fornecedora Ribeiro 94 Ltda', 'Rua das Flores, 1445 - Recife/PE', 'Filtro', '34165182755394', '31924532913', 'Curitiba', 'PR'),
('Fornecedora Rocha 95 Ltda', 'Av. Paulista, 1516 - Sao Paulo/SP', 'Eletrica', '43333952111790', '31972675403', 'Sao Paulo', 'SP'),
('Fornecedora Cavalcante 96 Ltda', 'Rua Minas Gerais, 1281 - Salvador/BA', 'Pneu', '79472846392086', '31964199033', 'Belo Horizonte', 'MG'),
('Fornecedora Souza 97 Ltda', 'Rua Minas Gerais, 816 - Recife/PE', 'Motor', '71875003691559', '31934856447', 'Recife', 'PE'),
('Fornecedora Alves 98 Ltda', 'Av. Paulista, 561 - Rio de Janeiro/RJ', 'Oleo/Lubrificante', '95527636556472', '31976693314', 'Contagem', 'MG'),
('Fornecedora Monteiro 99 Ltda', 'Av. Brasil, 1486 - Sao Paulo/SP', 'Filtro', '38663227026728', '31971669929', 'Contagem', 'MG');

-- ===== VEICULOS_VENDA =====
INSERT INTO veiculos_venda (marca, modelo, ano, cor, placa, chassi, quilometragem, tipo, preco, status) VALUES
('Honda', 'HR-V', 2022, 'Vermelho', 'BMD2034', '7G5YT00TZB3HZNMVZ', 33895, 'Seminovo', 143374.23, 'Reservado'),
('Renault', 'Duster', 2022, 'Cinza', 'TJO2256', '2EFLYRXXVU2U5053L', 59580, 'Usado', 200685.68, 'Disponivel'),
('Chevrolet', 'Onix', 2017, 'Azul', 'WXC3261', 'GE7DB2FGTKF1WRSV5', 31753, 'Usado', 160853.95, 'Vendido'),
('Volkswagen', 'Gol', 2017, 'Branco', 'VLK7784', '5JM64WZ7RF5W03TKW', 110906, 'Usado', 74856.4, 'Disponivel'),
('Chevrolet', 'Onix', 2023, 'Cinza', 'RAW7740', '4VRA0N342SL11RTF4', 0, 'Novo', 105179.86, 'Vendido'),
('Ford', 'Ka', 2023, 'Prata', 'JUX8463', 'EMJVH65U8NXBKDBMG', 106850, 'Usado', 166436.8, 'Reservado'),
('Ford', 'EcoSport', 2017, 'Preto', 'CEA7356', 'W806CYFKDU2E7MNT1', 58464, 'Usado', 172243.74, 'Disponivel'),
('Fiat', 'Toro', 2026, 'Cinza', 'HXB3718', 'P71WXLCHT7WN0DPHS', 0, 'Novo', 112339.63, 'Vendido'),
('Hyundai', 'HB20', 2020, 'Prata', 'SDM3009', '7K0FSL8FYDDZKGJ8R', 0, 'Novo', 74288.06, 'Reservado'),
('Jeep', 'Renegade', 2025, 'Azul', 'GAW6524', 'C85V8NMZX6ULEK5VT', 106581, 'Seminovo', 201064.29, 'Vendido'),
('Toyota', 'Corolla', 2022, 'Vermelho', 'MXF0959', 'SXE1N8KVX3XHGECJM', 0, 'Novo', 180785.63, 'Disponivel'),
('Volkswagen', 'T-Cross', 2016, 'Vermelho', 'UMV7899', 'TD0REAP8F6D030DUC', 26115, 'Seminovo', 62281.88, 'Vendido'),
('Fiat', 'Argo', 2019, 'Vermelho', 'DDX3863', 'NSM3GZ64GLM29YL5Z', 0, 'Novo', 210305.61, 'Reservado'),
('Jeep', 'Renegade', 2020, 'Cinza', 'XKT3983', '1T0552ACVBJWAWRPX', 55046, 'Seminovo', 178732.26, 'Disponivel'),
('Ford', 'EcoSport', 2023, 'Vermelho', 'EDB7522', 'T0SRTWF2PEX7M8GWC', 73918, 'Usado', 144866.94, 'Vendido'),
('Jeep', 'Compass', 2021, 'Verde', 'KLN6139', 'A1DWCXKX9RKD259FR', 0, 'Novo', 181521.33, 'Reservado'),
('Honda', 'Civic', 2021, 'Branco', 'PSX0864', 'F294JJ7N82NSSEU4X', 0, 'Novo', 68133.08, 'Vendido'),
('Jeep', 'Compass', 2016, 'Cinza', 'LLG5590', 'WLZ5K5CRN0KFHDSKV', 0, 'Novo', 162555.82, 'Disponivel'),
('Honda', 'HR-V', 2026, 'Cinza', 'AKG8338', 'T7KB1CTLDVNUD6AE1', 0, 'Novo', 98395.66, 'Vendido'),
('Ford', 'EcoSport', 2025, 'Branco', 'JUM3681', 'X8FMN96BCSWY82LBZ', 48214, 'Usado', 196249.4, 'Vendido'),
('Toyota', 'Corolla', 2020, 'Vermelho', 'IZB4608', 'URKY2JF1R3SK4WY5J', 40626, 'Usado', 86335.83, 'Disponivel'),
('Volkswagen', 'Gol', 2024, 'Verde', 'EJW8262', 'LXEHMXKBX33W5UKNG', 90659, 'Usado', 185018.39, 'Disponivel'),
('Volkswagen', 'Polo', 2015, 'Vermelho', 'THT3305', 'F7J970M187JLNRC3A', 81864, 'Usado', 91700.96, 'Reservado'),
('Hyundai', 'HB20', 2018, 'Verde', 'GCF7975', '6S42C1X2CG56CS2C1', 88993, 'Usado', 217942.6, 'Vendido'),
('Chevrolet', 'Tracker', 2018, 'Prata', 'YJO2649', 'DK65F9HMJ23X5BM6N', 58613, 'Seminovo', 114656.98, 'Reservado'),
('Fiat', 'Argo', 2019, 'Azul', 'ZFW1117', '0F19L11CLYKLKMD3W', 91664, 'Seminovo', 158500.88, 'Reservado'),
('Hyundai', 'Creta', 2019, 'Preto', 'GAT4077', '8A8SP7635FASUPDMK', 24684, 'Usado', 65571.95, 'Disponivel'),
('Toyota', 'Corolla', 2015, 'Azul', 'STJ5101', '3MLVM60CFWX01E4EV', 0, 'Novo', 194420.13, 'Reservado'),
('Volkswagen', 'Gol', 2016, 'Vermelho', 'NQG3901', 'F7V4XTZJ888MRVNAH', 113644, 'Usado', 93023.24, 'Disponivel'),
('Hyundai', 'Creta', 2025, 'Preto', 'ZTN6055', 'PANVTEWW9XAHYY2BM', 0, 'Novo', 174056.97, 'Disponivel'),
('Honda', 'HR-V', 2020, 'Verde', 'BUE7278', 'Y63DWXBPYZEKUBY1L', 63797, 'Usado', 205328.53, 'Vendido'),
('Nissan', 'Kicks', 2021, 'Verde', 'ZYJ5046', 'F8S05WPWMH0CNF59B', 0, 'Novo', 149158.58, 'Reservado'),
('Renault', 'Duster', 2017, 'Cinza', 'XQJ5218', 'JPC61HAWCFY6CGWBW', 0, 'Novo', 104520.28, 'Vendido'),
('Volkswagen', 'T-Cross', 2020, 'Prata', 'RKY7142', 'LUHA9GPZXUKVSLEWY', 0, 'Novo', 78695.49, 'Vendido'),
('Hyundai', 'Creta', 2015, 'Azul', 'BDM0166', 'M5ZWYNF6JF6G6W67R', 0, 'Novo', 50073.72, 'Disponivel'),
('Volkswagen', 'Gol', 2024, 'Azul', 'VKZ5770', 'E7HZ76LVZJ9G2GXEW', 48638, 'Seminovo', 113613.46, 'Vendido'),
('Hyundai', 'Creta', 2021, 'Preto', 'RFP6153', '44YSME8H6XG5MW2EG', 55190, 'Usado', 86750.68, 'Vendido'),
('Nissan', 'Kicks', 2021, 'Branco', 'CGE9022', '5V15NPXWW4ZFA92JV', 65788, 'Seminovo', 157873.1, 'Disponivel'),
('Toyota', 'Corolla', 2023, 'Vermelho', 'LDJ0369', '2X1214PM7JN103KVJ', 0, 'Novo', 45147.58, 'Disponivel'),
('Chevrolet', 'Onix', 2016, 'Cinza', 'VNE1267', '4M69451ZRM4A8S9U3', 3058, 'Usado', 70199.28, 'Vendido'),
('Jeep', 'Compass', 2020, 'Vermelho', 'PWL1971', 'KU6FFS7EWDYA7697Y', 0, 'Novo', 216190.85, 'Reservado'),
('Toyota', 'Corolla', 2019, 'Vermelho', 'XJX9407', 'LDVBV8FJ9EUTJUUTA', 22955, 'Seminovo', 51182.09, 'Vendido'),
('Fiat', 'Toro', 2024, 'Azul', 'EVO5243', '8MCYFKK831S5LPZDT', 0, 'Novo', 204273.01, 'Disponivel'),
('Chevrolet', 'Tracker', 2017, 'Cinza', 'XYR3667', 'TK4AV51XCGZ4UYUUG', 53264, 'Seminovo', 128340.59, 'Reservado'),
('Jeep', 'Compass', 2021, 'Preto', 'XVS3852', 'XAAEA3GG5ZRVTNCBF', 102338, 'Seminovo', 163175.95, 'Disponivel'),
('Nissan', 'Kicks', 2025, 'Azul', 'DWD1926', 'MHMTV6E6U4XTLEUD1', 0, 'Novo', 211335.57, 'Reservado'),
('Honda', 'HR-V', 2015, 'Cinza', 'CPG9627', 'GK4PG5TGCEET5B8KA', 107535, 'Seminovo', 91316.35, 'Disponivel'),
('Toyota', 'Hilux', 2019, 'Cinza', 'SAQ7766', 'ERA17HZYW2DF0YF6V', 0, 'Novo', 167509.66, 'Vendido'),
('Volkswagen', 'T-Cross', 2017, 'Azul', 'GJW6157', 'F5NJCNBS81EW85BCY', 6155, 'Usado', 214314.77, 'Disponivel'),
('Honda', 'HR-V', 2026, 'Preto', 'ZUV8782', 'RECK8B7CSJAMDWG6L', 0, 'Novo', 115963.87, 'Vendido'),
('Fiat', 'Argo', 2016, 'Verde', 'THC3656', 'XHJXPCMYEHUK3L0L5', 0, 'Novo', 132000.11, 'Disponivel'),
('Jeep', 'Compass', 2015, 'Verde', 'UTM2071', 'AAMFV37JPKU53SMCM', 0, 'Novo', 62494.37, 'Vendido'),
('Renault', 'Kwid', 2024, 'Verde', 'JLN0833', 'HG09R6PUDNHK78MLC', 0, 'Novo', 154758.54, 'Disponivel'),
('Toyota', 'Corolla', 2019, 'Prata', 'TZY7010', 'MLB89HES5X3NXRHXR', 0, 'Novo', 121067.54, 'Disponivel'),
('Ford', 'Ka', 2026, 'Preto', 'CPS7062', 'P6M10J6NZUNYJCDUJ', 115017, 'Seminovo', 79992.27, 'Disponivel'),
('Hyundai', 'Creta', 2022, 'Preto', 'JTF9298', 'RF38P76UA4SSX4RKA', 23439, 'Seminovo', 178059.43, 'Reservado'),
('Chevrolet', 'Tracker', 2015, 'Branco', 'NQM7177', 'SFA3PJZVSFB7WL6B6', 97138, 'Seminovo', 179506.12, 'Reservado'),
('Volkswagen', 'Gol', 2026, 'Prata', 'UOW0165', 'CV4UPFYD90DH106C0', 25241, 'Seminovo', 183225.27, 'Reservado'),
('Volkswagen', 'Polo', 2025, 'Azul', 'YGE5381', '7PRXZU94UDE0Z589H', 93389, 'Usado', 56726.03, 'Reservado'),
('Jeep', 'Renegade', 2025, 'Vermelho', 'LZV1371', 'F2MVEGLUHK8KPBV3J', 118892, 'Usado', 96146.26, 'Reservado'),
('Toyota', 'Corolla', 2021, 'Prata', 'GCA3856', 'YX856WJWLTR70VDKZ', 97693, 'Seminovo', 157819.78, 'Reservado'),
('Hyundai', 'Creta', 2017, 'Prata', 'FFW2231', 'CXJ5T0MPCXZK05LWH', 22075, 'Usado', 169567.13, 'Disponivel'),
('Toyota', 'Hilux', 2022, 'Prata', 'EAX8854', '7VK5YH7CJHWB2R5ZF', 0, 'Novo', 210863.08, 'Reservado'),
('Chevrolet', 'Tracker', 2024, 'Preto', 'ZYI3018', '5F92N8X9D02K4010A', 26578, 'Usado', 147100.5, 'Reservado'),
('Toyota', 'Corolla', 2020, 'Branco', 'GXO6742', '43JFKPW7YE1FA3U3M', 59402, 'Seminovo', 198002.8, 'Vendido'),
('Hyundai', 'Creta', 2026, 'Preto', 'FMJ8704', 'W86RBAKTW7HV3M8SB', 99991, 'Usado', 205102.62, 'Disponivel'),
('Ford', 'EcoSport', 2022, 'Prata', 'SPS6471', '09BTLDKX6JZLDU03Z', 0, 'Novo', 149805.98, 'Disponivel'),
('Honda', 'Civic', 2019, 'Vermelho', 'GYU2192', 'XXWU0GZKAJV083YLG', 84747, 'Usado', 208855.48, 'Disponivel'),
('Volkswagen', 'Gol', 2023, 'Verde', 'RTW8881', '36EHJB7ZW0J5YMWBH', 0, 'Novo', 190525.37, 'Disponivel'),
('Volkswagen', 'Gol', 2026, 'Prata', 'EGE1611', 'B74CNGC9D7HTCEWAG', 0, 'Novo', 165408.25, 'Disponivel'),
('Nissan', 'Kicks', 2018, 'Azul', 'LAC2495', 'ZL9S9EGAPNVLAGP97', 119118, 'Usado', 80004.27, 'Reservado'),
('Jeep', 'Compass', 2017, 'Preto', 'LMN3836', 'HXH6HJ80VCFX8H1V6', 89280, 'Seminovo', 212605.85, 'Vendido'),
('Honda', 'Civic', 2025, 'Prata', 'NGC7520', '8G25FHK22GLE0NYN2', 30605, 'Seminovo', 141935.28, 'Disponivel'),
('Ford', 'Ka', 2021, 'Azul', 'YSS4657', '289UK6GHT88RJBGDE', 66419, 'Usado', 93740.71, 'Reservado'),
('Chevrolet', 'Onix', 2017, 'Preto', 'JTT1187', '6NV889TYBC4H15X15', 80244, 'Seminovo', 163860.76, 'Reservado'),
('Chevrolet', 'Tracker', 2015, 'Verde', 'YJW2762', 'W18H877L9D2T81ZVX', 0, 'Novo', 142416.65, 'Disponivel'),
('Chevrolet', 'Onix', 2024, 'Prata', 'LZX9056', 'G4ZZ3ZDSSSWFEWHYL', 0, 'Novo', 67434.66, 'Disponivel'),
('Jeep', 'Renegade', 2020, 'Verde', 'NSQ6407', 'BX11XG8GPY89YLW04', 0, 'Novo', 125659.14, 'Disponivel'),
('Renault', 'Kwid', 2025, 'Vermelho', 'GJI0496', 'RFGYUE74PZEW9W4XN', 0, 'Novo', 192066.59, 'Reservado'),
('Toyota', 'Hilux', 2019, 'Verde', 'RFA8297', 'P6U4DN06KSKW43XEP', 68550, 'Usado', 124315.01, 'Reservado'),
('Ford', 'EcoSport', 2019, 'Vermelho', 'HMH1230', 'SW6844CNLUJBTUMC8', 22048, 'Usado', 89878.16, 'Disponivel'),
('Chevrolet', 'Tracker', 2016, 'Branco', 'NLV1623', 'H9HT8FSHXY1S4PKGM', 79852, 'Seminovo', 97146.36, 'Disponivel'),
('Ford', 'EcoSport', 2022, 'Branco', 'PRL1586', '7SUK070WBCDST1W0H', 34332, 'Seminovo', 196007.49, 'Vendido'),
('Ford', 'Ka', 2022, 'Cinza', 'IJC3432', '5X3CUF873Y4GLT9EZ', 2031, 'Seminovo', 204213.09, 'Reservado'),
('Nissan', 'Kicks', 2026, 'Azul', 'AYB2720', '2NWXFHLSJ3X57JTMX', 97703, 'Usado', 102184.46, 'Reservado'),
('Volkswagen', 'T-Cross', 2016, 'Cinza', 'SHA0893', 'F6NTLD24TKF0LHA46', 49182, 'Seminovo', 76830.62, 'Vendido'),
('Renault', 'Kwid', 2016, 'Preto', 'ZIJ7626', 'PPVN3M3KBVTS5S06F', 0, 'Novo', 169873.65, 'Disponivel'),
('Renault', 'Kwid', 2017, 'Preto', 'WMW6941', 'GDDYS7ZCAT91W20JC', 91835, 'Seminovo', 114572.08, 'Vendido'),
('Volkswagen', 'Polo', 2019, 'Prata', 'OEC5862', 'THXCJ8U04VTTX4LX8', 0, 'Novo', 133155.68, 'Disponivel'),
('Jeep', 'Renegade', 2025, 'Preto', 'EBH2074', 'L64H8C5Z868HKHZFP', 105624, 'Usado', 121998.18, 'Reservado'),
('Volkswagen', 'Polo', 2017, 'Vermelho', 'VSG9089', 'M3ES8GYBVH20GXKBF', 67681, 'Usado', 188950.06, 'Reservado'),
('Renault', 'Kwid', 2022, 'Branco', 'KBU9759', 'JPDVXDE1F2TMS2FBP', 36300, 'Usado', 148985.75, 'Disponivel'),
('Toyota', 'Hilux', 2021, 'Azul', 'EDJ7649', 'JZG09N8517U4F40M4', 85825, 'Seminovo', 176697.75, 'Vendido'),
('Hyundai', 'HB20', 2016, 'Cinza', 'VHU2788', 'FV64F7WKJWS4VDEC9', 0, 'Novo', 134834.76, 'Disponivel'),
('Renault', 'Duster', 2021, 'Azul', 'SIL4918', 'BH6MM2CF3WX65TYMP', 13384, 'Seminovo', 126314.89, 'Disponivel'),
('Fiat', 'Argo', 2026, 'Branco', 'NRA0610', 'L7628W02WFJJANHBN', 34989, 'Usado', 197532.76, 'Disponivel'),
('Volkswagen', 'T-Cross', 2022, 'Cinza', 'UZR3147', 'K74BHLK587B5SNV2D', 20025, 'Usado', 158704.47, 'Reservado'),
('Chevrolet', 'Onix', 2016, 'Cinza', 'PXS9840', '82898RDB4XEU37H8Z', 112100, 'Usado', 169791.24, 'Reservado'),
('Hyundai', 'HB20', 2015, 'Preto', 'PLO3839', 'Y6JV1307LPVF7JMNL', 0, 'Novo', 95401.89, 'Vendido'),
('Renault', 'Kwid', 2016, 'Preto', 'RBA5452', 'M9CEY4HRHR8TYZCUK', 65713, 'Seminovo', 98139.08, 'Vendido');

-- ===== VEICULO (clientes da oficina) =====
INSERT INTO veiculo (placa, id_cliente, modelo, cor, quilometragem, motorizacao) VALUES
('VDW0771', 78, 'Duster', 'Branco', 160557, '2.0'),
('BQD2135', 72, 'Toro', 'Preto', 77078, '1.0 Turbo'),
('QPX1255', 98, 'Creta', 'Verde', 36616, '1.0'),
('NYY0375', 57, 'T-Cross', 'Prata', 132888, '1.3'),
('LWY6532', 35, 'Argo', 'Verde', 139344, '1.6'),
('ZNN6785', 18, 'Ka', 'Branco', 116519, '1.3'),
('ZQC1556', 92, 'Onix', 'Verde', 43576, '1.6'),
('YBV2908', 51, 'Tracker', 'Prata', 110418, '1.6'),
('XXK5048', 39, 'Renegade', 'Vermelho', 38998, '1.0 Turbo'),
('UGR9975', 58, 'Hilux', 'Verde', 170567, '1.6'),
('CBR5628', 39, 'T-Cross', 'Vermelho', 74929, '1.3'),
('RJQ5200', 66, 'Argo', 'Verde', 142040, '2.0'),
('YJX6810', 31, 'EcoSport', 'Verde', 98274, '1.4'),
('DBY1749', 46, 'Duster', 'Azul', 1866, '1.6'),
('ZXS9893', 31, 'HR-V', 'Prata', 78933, '1.4'),
('EWM8315', 87, 'Compass', 'Vermelho', 153164, '1.3'),
('DEW6611', 59, 'Corolla', 'Branco', 111881, '1.3'),
('OCL8698', 28, 'Kwid', 'Vermelho', 103989, '1.4 Turbo'),
('PUN7762', 75, 'EcoSport', 'Preto', 133088, '1.3'),
('OEW8813', 92, 'Kwid', 'Cinza', 124587, '1.0'),
('LDT6115', 72, 'Polo', 'Vermelho', 76414, '1.0'),
('DLJ5447', 20, 'Duster', 'Branco', 37952, '1.3'),
('BJJ3270', 54, 'Compass', 'Branco', 144033, '1.4'),
('NPS4975', 6, 'Argo', 'Verde', 99408, '1.6'),
('YEQ7772', 17, 'Kicks', 'Verde', 85753, '1.0'),
('TNM3658', 86, 'Kicks', 'Branco', 176252, '1.6'),
('CFW0948', 83, 'EcoSport', 'Azul', 32948, '1.0 Turbo'),
('GTR9098', 11, 'Renegade', 'Preto', 125237, '2.0'),
('VRF0433', 16, 'Onix', 'Verde', 152426, '1.6'),
('TKM9070', 69, 'Argo', 'Prata', 115061, '1.3'),
('QKM4111', 4, 'HB20', 'Vermelho', 44581, '1.4'),
('IYC2462', 24, 'Gol', 'Branco', 161581, '1.4'),
('WBJ6152', 4, 'Polo', 'Cinza', 85491, '1.4'),
('BGH9937', 16, 'Hilux', 'Vermelho', 132731, '1.6'),
('BKO8617', 35, 'Toro', 'Branco', 107322, '1.0 Turbo'),
('IRS1382', 3, 'Ka', 'Prata', 149462, '1.6'),
('UQG2582', 11, 'Creta', 'Verde', 64767, '2.0'),
('OBA7942', 72, 'HB20', 'Branco', 16274, '1.6'),
('IVM5398', 77, 'EcoSport', 'Prata', 12423, '1.3'),
('CJC6128', 73, 'Renegade', 'Prata', 113736, '1.3'),
('ZKV5474', 65, 'Kicks', 'Preto', 174111, '1.4'),
('OTK0209', 27, 'HR-V', 'Cinza', 1621, '1.0'),
('RWW7681', 53, 'Polo', 'Verde', 170656, '1.0 Turbo'),
('AVO1569', 69, 'Argo', 'Prata', 101884, '1.3'),
('OLG7030', 16, 'Onix', 'Verde', 74197, '1.0 Turbo'),
('CTU4337', 25, 'Corolla', 'Prata', 10145, '1.4'),
('WTG0361', 91, 'Kwid', 'Verde', 73204, '2.0'),
('FRG9992', 64, 'Duster', 'Branco', 154683, '1.3'),
('ISH8430', 17, 'Argo', 'Azul', 178164, '2.0'),
('VRO0605', 33, 'Kicks', 'Cinza', 107160, '1.4'),
('QOP5803', 88, 'Toro', 'Branco', 73358, '1.6'),
('KAM3519', 58, 'Renegade', 'Verde', 7151, '1.0 Turbo'),
('NCH3254', 89, 'Ka', 'Branco', 164600, '1.0 Turbo'),
('PNZ0954', 4, 'Toro', 'Preto', 28769, '1.6'),
('BKQ3199', 44, 'Ka', 'Cinza', 25579, '1.0 Turbo'),
('DCB0651', 75, 'Creta', 'Verde', 33932, '1.0'),
('JTU6110', 8, 'Creta', 'Vermelho', 14184, '1.4'),
('DTY6399', 52, 'Hilux', 'Branco', 119359, '1.6'),
('TTD5078', 55, 'Creta', 'Prata', 154591, '1.3'),
('ATW1939', 14, 'Toro', 'Preto', 167581, '2.0'),
('NPX9723', 46, 'EcoSport', 'Preto', 12052, '1.0'),
('SNQ5498', 40, 'Gol', 'Verde', 38674, '1.3'),
('TKJ5089', 40, 'Kwid', 'Azul', 178312, '1.3'),
('QRB6533', 31, 'Tracker', 'Azul', 53259, '1.4 Turbo'),
('GVP7959', 44, 'Argo', 'Vermelho', 88491, '2.0'),
('KFD7073', 54, 'Civic', 'Branco', 167948, '1.3'),
('TGH7563', 60, 'Ka', 'Cinza', 48798, '1.4 Turbo'),
('ACL0812', 47, 'Onix', 'Prata', 115950, '1.3'),
('LBA3342', 98, 'Compass', 'Preto', 69181, '1.0 Turbo'),
('RHF3024', 44, 'Polo', 'Branco', 6003, '1.4 Turbo'),
('UZD5347', 49, 'Gol', 'Preto', 97399, '1.4 Turbo'),
('FQZ9611', 85, 'Corolla', 'Preto', 34787, '1.4 Turbo'),
('RMW5596', 25, 'T-Cross', 'Azul', 64607, '1.0'),
('GRJ2530', 76, 'Kicks', 'Azul', 73919, '1.4 Turbo'),
('SPG1791', 66, 'Gol', 'Preto', 133830, '1.6'),
('PQO2558', 48, 'Duster', 'Azul', 127193, '1.0 Turbo'),
('ISM9033', 61, 'Kwid', 'Preto', 119010, '1.4 Turbo'),
('GJN6925', 51, 'Ka', 'Prata', 144823, '1.0'),
('CJO8539', 97, 'Gol', 'Branco', 122463, '2.0'),
('NOO6657', 44, 'Kicks', 'Prata', 72070, '1.6'),
('OHI1514', 23, 'Onix', 'Verde', 132034, '2.0'),
('CZI3111', 83, 'Renegade', 'Prata', 10535, '2.0'),
('GVK4443', 43, 'T-Cross', 'Azul', 158843, '1.3'),
('AYJ4566', 34, 'Renegade', 'Verde', 152531, '1.4 Turbo'),
('UQY2633', 61, 'Onix', 'Azul', 55517, '1.6'),
('SZR7751', 67, 'Ka', 'Prata', 49742, '1.6'),
('OOR0529', 27, 'HB20', 'Verde', 34145, '1.4'),
('ZVL5366', 64, 'Onix', 'Azul', 106240, '1.4 Turbo'),
('KSA9022', 39, 'Renegade', 'Prata', 149447, '1.0 Turbo'),
('SMM3618', 78, 'Kicks', 'Cinza', 49871, '1.6'),
('SOU4121', 43, 'Toro', 'Azul', 145441, '1.3'),
('TPA2316', 89, 'Tracker', 'Prata', 54473, '1.3'),
('QCO0580', 85, 'Civic', 'Preto', 86161, '1.4 Turbo'),
('FDE8671', 51, 'HB20', 'Cinza', 54627, '1.3'),
('NWV7299', 40, 'T-Cross', 'Prata', 154507, '1.3'),
('VOI3027', 92, 'Duster', 'Branco', 105157, '2.0'),
('KSP7790', 68, 'Ka', 'Azul', 24382, '1.4'),
('WWZ4692', 45, 'Creta', 'Cinza', 65809, '1.3'),
('NOM2916', 94, 'Kicks', 'Azul', 11946, '1.3'),
('URJ1376', 36, 'Polo', 'Verde', 145419, '1.0');

-- ===== ESTOQUE =====
INSERT INTO estoque (nome_peca, tipo, fabricante, quantidade, id_fornecedor, id_funcionario) VALUES
('Pneu - Peca 1', 'Pneu', 'Fras-le', 53, 65, 99),
('Pneu - Peca 2', 'Pneu', 'Valeo', 230, 22, 33),
('Eletrica - Peca 3', 'Eletrica', 'Sabo', 22, 60, 4),
('Suspensao - Peca 4', 'Suspensao', 'TRW', 195, 44, 96),
('Carroceria - Peca 5', 'Carroceria', 'Cofap', 203, 5, 2),
('Filtro - Peca 6', 'Filtro', 'Fras-le', 69, 42, 86),
('Oleo/Lubrificante - Peca 7', 'Oleo/Lubrificante', 'TRW', 236, 9, 11),
('Eletrica - Peca 8', 'Eletrica', 'TRW', 71, 61, 36),
('Motor - Peca 9', 'Motor', 'NGK', 9, 78, 13),
('Motor - Peca 10', 'Motor', 'Mahle', 63, 69, 95),
('Carroceria - Peca 11', 'Carroceria', 'NGK', 39, 86, 98),
('Freio - Peca 12', 'Freio', 'Mahle', 78, 57, 46),
('Motor - Peca 13', 'Motor', 'Cofap', 17, 87, 69),
('Eletrica - Peca 14', 'Eletrica', 'TRW', 24, 82, 67),
('Suspensao - Peca 15', 'Suspensao', 'Valeo', 157, 57, 7),
('Freio - Peca 16', 'Freio', 'Bosch', 193, 99, 26),
('Eletrica - Peca 17', 'Eletrica', 'Continental', 122, 26, 12),
('Freio - Peca 18', 'Freio', 'Valeo', 14, 2, 44),
('Eletrica - Peca 19', 'Eletrica', 'Fras-le', 112, 13, 86),
('Motor - Peca 20', 'Motor', 'NGK', 22, 54, 66),
('Suspensao - Peca 21', 'Suspensao', 'Continental', 165, 72, 81),
('Eletrica - Peca 22', 'Eletrica', 'Monroe', 106, 70, 51),
('Carroceria - Peca 23', 'Carroceria', 'Fras-le', 118, 28, 14),
('Pneu - Peca 24', 'Pneu', 'Continental', 88, 2, 52),
('Pneu - Peca 25', 'Pneu', 'Bosch', 199, 28, 59),
('Eletrica - Peca 26', 'Eletrica', 'Fras-le', 142, 84, 80),
('Pneu - Peca 27', 'Pneu', 'Bosch', 34, 28, 53),
('Filtro - Peca 28', 'Filtro', 'Monroe', 255, 14, 92),
('Motor - Peca 29', 'Motor', 'Mahle', 48, 77, 42),
('Carroceria - Peca 30', 'Carroceria', 'NGK', 170, 23, 82),
('Pneu - Peca 31', 'Pneu', 'TRW', 34, 43, 3),
('Oleo/Lubrificante - Peca 32', 'Oleo/Lubrificante', 'Valeo', 261, 82, 95),
('Eletrica - Peca 33', 'Eletrica', 'Sabo', 300, 91, 2),
('Eletrica - Peca 34', 'Eletrica', 'Bosch', 63, 40, 31),
('Carroceria - Peca 35', 'Carroceria', 'Cofap', 40, 8, 18),
('Pneu - Peca 36', 'Pneu', 'TRW', 151, 26, 20),
('Carroceria - Peca 37', 'Carroceria', 'Cofap', 19, 31, 93),
('Oleo/Lubrificante - Peca 38', 'Oleo/Lubrificante', 'Continental', 68, 36, 41),
('Freio - Peca 39', 'Freio', 'Sabo', 212, 83, 37),
('Freio - Peca 40', 'Freio', 'Cofap', 169, 44, 32),
('Eletrica - Peca 41', 'Eletrica', 'Sabo', 27, 86, 32),
('Eletrica - Peca 42', 'Eletrica', 'Monroe', 195, 67, 42),
('Motor - Peca 43', 'Motor', 'TRW', 3, 9, 63),
('Suspensao - Peca 44', 'Suspensao', 'Cofap', 26, 82, 19),
('Eletrica - Peca 45', 'Eletrica', 'NGK', 46, 23, 76),
('Eletrica - Peca 46', 'Eletrica', 'Cofap', 259, 11, 55),
('Oleo/Lubrificante - Peca 47', 'Oleo/Lubrificante', 'Mahle', 84, 93, 26),
('Eletrica - Peca 48', 'Eletrica', 'Valeo', 90, 78, 32),
('Filtro - Peca 49', 'Filtro', 'Mahle', 295, 58, 82),
('Eletrica - Peca 50', 'Eletrica', 'Mahle', 246, 11, 47),
('Carroceria - Peca 51', 'Carroceria', 'Valeo', 85, 61, 57),
('Carroceria - Peca 52', 'Carroceria', 'Sabo', 221, 98, 20),
('Oleo/Lubrificante - Peca 53', 'Oleo/Lubrificante', 'Bosch', 195, 55, 11),
('Filtro - Peca 54', 'Filtro', 'Monroe', 275, 20, 71),
('Motor - Peca 55', 'Motor', 'Mahle', 194, 60, 40),
('Oleo/Lubrificante - Peca 56', 'Oleo/Lubrificante', 'Mahle', 192, 72, 78),
('Oleo/Lubrificante - Peca 57', 'Oleo/Lubrificante', 'Fras-le', 170, 18, 92),
('Oleo/Lubrificante - Peca 58', 'Oleo/Lubrificante', 'Cofap', 79, 25, 1),
('Freio - Peca 59', 'Freio', 'Sabo', 191, 63, 52),
('Carroceria - Peca 60', 'Carroceria', 'Valeo', 191, 50, 63),
('Filtro - Peca 61', 'Filtro', 'Monroe', 36, 53, 5),
('Suspensao - Peca 62', 'Suspensao', 'Valeo', 289, 21, 25),
('Carroceria - Peca 63', 'Carroceria', 'Mahle', 178, 66, 91),
('Oleo/Lubrificante - Peca 64', 'Oleo/Lubrificante', 'Continental', 29, 84, 50),
('Carroceria - Peca 65', 'Carroceria', 'Cofap', 124, 62, 5),
('Pneu - Peca 66', 'Pneu', 'Bosch', 75, 34, 78),
('Oleo/Lubrificante - Peca 67', 'Oleo/Lubrificante', 'NGK', 130, 32, 78),
('Motor - Peca 68', 'Motor', 'Bosch', 59, 99, 12),
('Carroceria - Peca 69', 'Carroceria', 'Valeo', 300, 11, 67),
('Eletrica - Peca 70', 'Eletrica', 'Valeo', 84, 55, 33),
('Filtro - Peca 71', 'Filtro', 'Sabo', 272, 85, 49),
('Filtro - Peca 72', 'Filtro', 'Valeo', 45, 14, 82),
('Pneu - Peca 73', 'Pneu', 'NGK', 137, 96, 27),
('Carroceria - Peca 74', 'Carroceria', 'Mahle', 3, 22, 63),
('Freio - Peca 75', 'Freio', 'Fras-le', 35, 100, 90),
('Carroceria - Peca 76', 'Carroceria', 'Sabo', 213, 84, 37),
('Carroceria - Peca 77', 'Carroceria', 'NGK', 90, 48, 24),
('Motor - Peca 78', 'Motor', 'Cofap', 249, 24, 65),
('Suspensao - Peca 79', 'Suspensao', 'TRW', 290, 28, 24),
('Eletrica - Peca 80', 'Eletrica', 'Bosch', 93, 98, 25),
('Filtro - Peca 81', 'Filtro', 'Valeo', 225, 81, 80),
('Suspensao - Peca 82', 'Suspensao', 'NGK', 40, 38, 11),
('Carroceria - Peca 83', 'Carroceria', 'Fras-le', 141, 9, 44),
('Freio - Peca 84', 'Freio', 'Monroe', 120, 62, 63),
('Suspensao - Peca 85', 'Suspensao', 'Bosch', 31, 35, 97),
('Freio - Peca 86', 'Freio', 'Monroe', 21, 13, 28),
('Freio - Peca 87', 'Freio', 'Valeo', 266, 98, 35),
('Oleo/Lubrificante - Peca 88', 'Oleo/Lubrificante', 'TRW', 172, 78, 55),
('Pneu - Peca 89', 'Pneu', 'Continental', 175, 41, 31),
('Pneu - Peca 90', 'Pneu', 'Valeo', 193, 79, 8),
('Pneu - Peca 91', 'Pneu', 'Continental', 51, 1, 59),
('Carroceria - Peca 92', 'Carroceria', 'NGK', 13, 78, 16),
('Filtro - Peca 93', 'Filtro', 'Cofap', 188, 58, 80),
('Oleo/Lubrificante - Peca 94', 'Oleo/Lubrificante', 'Sabo', 211, 85, 25),
('Freio - Peca 95', 'Freio', 'Continental', 8, 82, 47),
('Freio - Peca 96', 'Freio', 'Continental', 227, 30, 78),
('Oleo/Lubrificante - Peca 97', 'Oleo/Lubrificante', 'Valeo', 41, 45, 55),
('Oleo/Lubrificante - Peca 98', 'Oleo/Lubrificante', 'Fras-le', 197, 38, 78),
('Eletrica - Peca 99', 'Eletrica', 'NGK', 266, 74, 92),
('Freio - Peca 100', 'Freio', 'NGK', 254, 12, 39);

-- ===== SERVICOS =====
INSERT INTO servicos (id_funcionario, id_veiculo, tipo_servico, tempo_estimado, status_servico) VALUES
(87, 71, 'Troca de bateria', '3h', 'Cancelado'),
(15, 62, 'Ar condicionado', '4h', 'Concluido'),
(28, 22, 'Revisao geral', '2h', 'Cancelado'),
(92, 4, 'Alinhamento e balanceamento', '6h', 'Cancelado'),
(99, 36, 'Troca de pastilhas de freio', '5h', 'Cancelado'),
(86, 16, 'Alinhamento e balanceamento', '8h', 'Em andamento'),
(89, 43, 'Troca de pastilhas de freio', '2h', 'Aguardando peca'),
(49, 92, 'Reparo na suspensao', '7h', 'Concluido'),
(29, 34, 'Revisao geral', '5h', 'Em andamento'),
(15, 12, 'Troca de correia dentada', '4h', 'Em andamento'),
(74, 48, 'Alinhamento e balanceamento', '6h', 'Cancelado'),
(74, 95, 'Troca de oleo', '5h', 'Em andamento'),
(76, 69, 'Troca de pastilhas de freio', '7h', 'Cancelado'),
(41, 99, 'Troca de correia dentada', '3h', 'Aguardando aprovacao'),
(85, 78, 'Funilaria e pintura', '4h', 'Em andamento'),
(51, 2, 'Ar condicionado', '8h', 'Aguardando peca'),
(19, 38, 'Troca de pastilhas de freio', '8h', 'Cancelado'),
(19, 77, 'Diagnostico eletronico', '3h', 'Em andamento'),
(77, 41, 'Diagnostico eletronico', '2h', 'Aguardando peca'),
(91, 74, 'Troca de bateria', '4h', 'Cancelado'),
(38, 91, 'Reparo na suspensao', '1h', 'Aguardando peca'),
(20, 92, 'Troca de pastilhas de freio', '4h', 'Em andamento'),
(100, 23, 'Troca de bateria', '7h', 'Aguardando peca'),
(85, 21, 'Troca de oleo', '7h', 'Aguardando peca'),
(55, 87, 'Troca de bateria', '6h', 'Cancelado'),
(51, 10, 'Ar condicionado', '5h', 'Aguardando peca'),
(90, 25, 'Ar condicionado', '7h', 'Em andamento'),
(17, 42, 'Funilaria e pintura', '1h', 'Aguardando peca'),
(59, 84, 'Alinhamento e balanceamento', '3h', 'Cancelado'),
(90, 62, 'Diagnostico eletronico', '3h', 'Concluido'),
(28, 96, 'Troca de pastilhas de freio', '1h', 'Aguardando peca'),
(93, 74, 'Revisao geral', '3h', 'Cancelado'),
(55, 87, 'Alinhamento e balanceamento', '1h', 'Em andamento'),
(46, 61, 'Alinhamento e balanceamento', '1h', 'Em andamento'),
(66, 84, 'Troca de correia dentada', '7h', 'Concluido'),
(81, 93, 'Reparo na suspensao', '4h', 'Em andamento'),
(16, 31, 'Reparo na suspensao', '8h', 'Aguardando peca'),
(89, 77, 'Alinhamento e balanceamento', '7h', 'Em andamento'),
(100, 60, 'Reparo na suspensao', '5h', 'Cancelado'),
(48, 2, 'Revisao geral', '2h', 'Em andamento'),
(16, 63, 'Ar condicionado', '4h', 'Em andamento'),
(76, 74, 'Funilaria e pintura', '8h', 'Aguardando peca'),
(89, 96, 'Revisao geral', '3h', 'Cancelado'),
(62, 83, 'Reparo na suspensao', '5h', 'Aguardando aprovacao'),
(17, 13, 'Troca de correia dentada', '2h', 'Aguardando aprovacao'),
(24, 52, 'Troca de oleo', '7h', 'Aguardando aprovacao'),
(69, 68, 'Troca de bateria', '2h', 'Aguardando aprovacao'),
(75, 69, 'Revisao geral', '4h', 'Em andamento'),
(24, 77, 'Alinhamento e balanceamento', '1h', 'Aguardando aprovacao'),
(58, 41, 'Revisao geral', '1h', 'Concluido'),
(74, 27, 'Alinhamento e balanceamento', '2h', 'Aguardando aprovacao'),
(33, 97, 'Troca de oleo', '2h', 'Em andamento'),
(65, 39, 'Troca de correia dentada', '3h', 'Cancelado'),
(85, 1, 'Troca de pastilhas de freio', '5h', 'Em andamento'),
(67, 38, 'Ar condicionado', '8h', 'Concluido'),
(74, 63, 'Troca de correia dentada', '6h', 'Aguardando aprovacao'),
(69, 66, 'Troca de pastilhas de freio', '2h', 'Em andamento'),
(31, 5, 'Troca de pastilhas de freio', '3h', 'Aguardando peca'),
(28, 18, 'Funilaria e pintura', '4h', 'Aguardando aprovacao'),
(46, 36, 'Alinhamento e balanceamento', '7h', 'Em andamento'),
(71, 33, 'Diagnostico eletronico', '7h', 'Concluido'),
(52, 59, 'Revisao geral', '5h', 'Cancelado'),
(89, 19, 'Ar condicionado', '4h', 'Em andamento'),
(81, 94, 'Diagnostico eletronico', '4h', 'Aguardando peca'),
(73, 85, 'Ar condicionado', '3h', 'Cancelado'),
(20, 41, 'Reparo na suspensao', '7h', 'Em andamento'),
(78, 32, 'Revisao geral', '5h', 'Em andamento'),
(69, 15, 'Ar condicionado', '7h', 'Em andamento'),
(43, 82, 'Revisao geral', '6h', 'Aguardando peca'),
(100, 35, 'Alinhamento e balanceamento', '4h', 'Aguardando peca'),
(2, 13, 'Reparo na suspensao', '4h', 'Cancelado'),
(14, 16, 'Alinhamento e balanceamento', '5h', 'Aguardando aprovacao'),
(63, 13, 'Ar condicionado', '6h', 'Aguardando aprovacao'),
(37, 71, 'Diagnostico eletronico', '2h', 'Em andamento'),
(22, 41, 'Reparo na suspensao', '3h', 'Aguardando peca'),
(95, 87, 'Ar condicionado', '7h', 'Cancelado'),
(76, 17, 'Diagnostico eletronico', '1h', 'Aguardando aprovacao'),
(92, 20, 'Alinhamento e balanceamento', '3h', 'Cancelado'),
(73, 95, 'Diagnostico eletronico', '1h', 'Aguardando peca'),
(91, 100, 'Troca de pastilhas de freio', '7h', 'Cancelado'),
(24, 57, 'Troca de correia dentada', '8h', 'Aguardando aprovacao'),
(37, 36, 'Reparo na suspensao', '4h', 'Aguardando peca'),
(82, 12, 'Diagnostico eletronico', '7h', 'Aguardando peca'),
(12, 82, 'Revisao geral', '2h', 'Concluido'),
(12, 22, 'Funilaria e pintura', '1h', 'Em andamento'),
(96, 37, 'Ar condicionado', '8h', 'Em andamento'),
(55, 87, 'Ar condicionado', '3h', 'Cancelado'),
(64, 66, 'Ar condicionado', '2h', 'Cancelado'),
(2, 79, 'Troca de pastilhas de freio', '1h', 'Cancelado'),
(90, 69, 'Troca de correia dentada', '4h', 'Aguardando aprovacao'),
(88, 78, 'Troca de oleo', '8h', 'Concluido'),
(87, 98, 'Ar condicionado', '4h', 'Concluido'),
(10, 47, 'Alinhamento e balanceamento', '6h', 'Em andamento'),
(55, 64, 'Reparo na suspensao', '3h', 'Aguardando peca'),
(15, 44, 'Troca de pastilhas de freio', '2h', 'Aguardando peca'),
(39, 62, 'Diagnostico eletronico', '5h', 'Concluido'),
(1, 95, 'Funilaria e pintura', '7h', 'Concluido'),
(40, 83, 'Ar condicionado', '1h', 'Cancelado'),
(80, 63, 'Troca de oleo', '6h', 'Em andamento'),
(79, 59, 'Troca de correia dentada', '5h', 'Aguardando peca');

-- ===== SERVICOS_PECAS =====
INSERT INTO servicos_pecas (id_servico, id_estoque, quantidade_usada) VALUES
(14, 1, 3),
(93, 24, 4),
(46, 2, 1),
(56, 63, 2),
(11, 68, 5),
(20, 53, 1),
(63, 1, 2),
(99, 85, 3),
(29, 61, 4),
(48, 39, 3),
(55, 24, 5),
(35, 14, 4),
(85, 57, 2),
(18, 46, 4),
(1, 46, 2),
(15, 25, 3),
(6, 18, 4),
(54, 96, 3),
(5, 21, 2),
(62, 86, 3),
(16, 54, 4),
(71, 64, 2),
(42, 97, 4),
(65, 93, 4),
(17, 15, 1),
(3, 17, 2),
(45, 65, 1),
(99, 88, 2),
(7, 87, 3),
(55, 77, 1),
(56, 62, 3),
(37, 63, 1),
(98, 55, 2),
(80, 20, 5),
(24, 32, 3),
(99, 15, 3),
(90, 32, 4),
(26, 61, 1),
(90, 94, 5),
(79, 24, 2),
(76, 81, 2),
(30, 16, 2),
(52, 5, 3),
(25, 19, 4),
(3, 79, 2),
(12, 7, 4),
(53, 68, 3),
(90, 82, 2),
(29, 44, 4),
(62, 8, 5),
(55, 83, 1),
(39, 15, 3),
(47, 36, 3),
(92, 54, 2),
(41, 7, 2),
(6, 1, 1),
(85, 96, 3),
(28, 37, 4),
(36, 78, 1),
(56, 24, 3),
(63, 47, 3),
(13, 86, 1),
(88, 71, 2),
(43, 47, 3),
(96, 100, 5),
(68, 78, 3),
(31, 84, 3),
(27, 75, 4),
(12, 14, 2),
(81, 96, 5),
(16, 6, 5),
(84, 25, 2),
(91, 58, 1),
(10, 70, 5),
(44, 39, 4),
(98, 26, 5),
(93, 20, 1),
(17, 25, 4),
(71, 92, 3),
(98, 72, 3),
(47, 58, 1),
(56, 9, 4),
(54, 68, 5),
(3, 22, 5),
(36, 90, 2),
(38, 6, 5),
(8, 89, 2),
(95, 51, 4),
(88, 69, 5),
(10, 22, 4),
(97, 66, 4),
(72, 100, 4),
(52, 78, 3),
(27, 24, 1),
(21, 74, 2),
(76, 90, 1),
(66, 59, 5),
(91, 93, 5),
(34, 39, 2),
(38, 91, 3);

-- ===== PAGAMENTO =====
INSERT INTO pagamento (id_servico, id_cliente, id_funcionario, tipo_pagamento, status_pagamento) VALUES
(71, 16, 22, 'Cartao de Credito', 'Pago'),
(69, 31, 38, 'Dinheiro', 'Pendente'),
(36, 18, 35, 'Dinheiro', 'Pendente'),
(27, 69, 15, 'Dinheiro', 'Cancelado'),
(81, 78, 48, 'Cartao de Debito', 'Pago'),
(91, 71, 34, 'Cartao de Credito', 'Parcelado'),
(79, 38, 42, 'Dinheiro', 'Pago'),
(46, 29, 94, 'Cartao de Debito', 'Pendente'),
(33, 3, 69, 'Boleto', 'Pago'),
(93, 96, 89, 'Pix', 'Cancelado'),
(81, 82, 78, 'Boleto', 'Pendente'),
(57, 29, 42, 'Cartao de Debito', 'Pendente'),
(75, 81, 97, 'Pix', 'Pendente'),
(58, 30, 94, 'Pix', 'Cancelado'),
(19, 62, 12, 'Pix', 'Pendente'),
(59, 24, 23, 'Cartao de Credito', 'Parcelado'),
(94, 24, 83, 'Cartao de Debito', 'Pago'),
(40, 21, 23, 'Pix', 'Pendente'),
(9, 19, 10, 'Pix', 'Pendente'),
(59, 83, 52, 'Dinheiro', 'Pendente'),
(94, 97, 2, 'Boleto', 'Pago'),
(49, 50, 3, 'Dinheiro', 'Pago'),
(98, 83, 6, 'Cartao de Credito', 'Pendente'),
(99, 11, 35, 'Cartao de Credito', 'Pago'),
(2, 14, 70, 'Cartao de Debito', 'Pago'),
(26, 18, 62, 'Boleto', 'Parcelado'),
(21, 40, 43, 'Pix', 'Pendente'),
(32, 8, 70, 'Cartao de Debito', 'Pago'),
(3, 6, 14, 'Boleto', 'Cancelado'),
(14, 66, 54, 'Cartao de Credito', 'Pago'),
(29, 4, 30, 'Pix', 'Parcelado'),
(19, 46, 84, 'Cartao de Debito', 'Pendente'),
(88, 50, 88, 'Dinheiro', 'Parcelado'),
(22, 15, 29, 'Dinheiro', 'Cancelado'),
(46, 10, 79, 'Cartao de Debito', 'Pago'),
(47, 11, 6, 'Boleto', 'Pendente'),
(23, 55, 68, 'Cartao de Debito', 'Pendente'),
(87, 55, 20, 'Cartao de Debito', 'Cancelado'),
(45, 14, 35, 'Pix', 'Cancelado'),
(34, 92, 10, 'Dinheiro', 'Pendente'),
(100, 84, 19, 'Cartao de Debito', 'Pendente'),
(50, 58, 93, 'Pix', 'Pago'),
(15, 74, 55, 'Cartao de Debito', 'Pendente'),
(12, 42, 17, 'Cartao de Credito', 'Parcelado'),
(46, 41, 64, 'Pix', 'Parcelado'),
(89, 53, 78, 'Cartao de Debito', 'Pendente'),
(84, 32, 50, 'Pix', 'Parcelado'),
(69, 69, 64, 'Boleto', 'Pendente'),
(50, 11, 75, 'Pix', 'Pendente'),
(90, 12, 31, 'Cartao de Debito', 'Pago'),
(27, 3, 47, 'Boleto', 'Parcelado'),
(18, 15, 8, 'Cartao de Debito', 'Cancelado'),
(100, 18, 38, 'Pix', 'Pendente'),
(71, 54, 32, 'Cartao de Credito', 'Pendente'),
(8, 96, 18, 'Dinheiro', 'Pendente'),
(49, 94, 4, 'Pix', 'Cancelado'),
(7, 90, 14, 'Boleto', 'Pago'),
(62, 77, 21, 'Dinheiro', 'Pendente'),
(47, 19, 11, 'Cartao de Credito', 'Pago'),
(2, 73, 54, 'Cartao de Credito', 'Pendente'),
(61, 96, 18, 'Boleto', 'Cancelado'),
(61, 53, 93, 'Cartao de Debito', 'Parcelado'),
(83, 89, 2, 'Cartao de Debito', 'Pago'),
(20, 8, 83, 'Dinheiro', 'Pendente'),
(65, 21, 2, 'Pix', 'Parcelado'),
(88, 59, 71, 'Cartao de Debito', 'Cancelado'),
(91, 30, 55, 'Cartao de Credito', 'Cancelado'),
(12, 67, 49, 'Cartao de Credito', 'Pendente'),
(52, 80, 8, 'Cartao de Credito', 'Parcelado'),
(24, 96, 72, 'Boleto', 'Pago'),
(89, 60, 62, 'Cartao de Debito', 'Parcelado'),
(49, 22, 7, 'Cartao de Debito', 'Parcelado'),
(25, 35, 14, 'Dinheiro', 'Pago'),
(47, 78, 100, 'Cartao de Debito', 'Pago'),
(31, 37, 21, 'Boleto', 'Pago'),
(9, 28, 77, 'Dinheiro', 'Cancelado'),
(25, 71, 26, 'Dinheiro', 'Pendente'),
(35, 11, 73, 'Boleto', 'Pago'),
(73, 62, 6, 'Dinheiro', 'Cancelado'),
(12, 40, 2, 'Cartao de Debito', 'Cancelado'),
(51, 65, 25, 'Cartao de Debito', 'Parcelado'),
(93, 46, 17, 'Dinheiro', 'Cancelado'),
(53, 95, 65, 'Dinheiro', 'Pendente'),
(4, 76, 49, 'Pix', 'Pago'),
(38, 21, 20, 'Pix', 'Pago'),
(81, 12, 92, 'Cartao de Credito', 'Pendente'),
(88, 84, 19, 'Cartao de Credito', 'Cancelado'),
(58, 17, 44, 'Cartao de Debito', 'Cancelado'),
(80, 56, 6, 'Pix', 'Pendente'),
(27, 79, 78, 'Dinheiro', 'Pendente'),
(73, 81, 64, 'Dinheiro', 'Pago'),
(19, 99, 40, 'Boleto', 'Pago'),
(64, 13, 59, 'Cartao de Debito', 'Pendente'),
(38, 21, 9, 'Cartao de Debito', 'Cancelado'),
(46, 12, 10, 'Cartao de Credito', 'Parcelado'),
(34, 61, 33, 'Pix', 'Pendente'),
(16, 73, 63, 'Dinheiro', 'Cancelado'),
(37, 52, 53, 'Boleto', 'Pendente'),
(57, 47, 66, 'Boleto', 'Cancelado'),
(48, 11, 88, 'Pix', 'Parcelado');

-- ===== VENDA =====
INSERT INTO venda (id_cliente, id_funcionario, id_veiculo_venda, data_venda, valor) VALUES
(88, 6, 80, '2023-04-27', 90994.8),
(32, 90, 72, '2023-01-17', 174682.45),
(14, 38, 49, '2023-11-21', 72048.39),
(10, 29, 50, '2025-08-04', 144773.4),
(45, 60, 60, '2025-12-31', 162101.35),
(60, 14, 11, '2024-01-05', 202522.14),
(51, 99, 56, '2024-02-13', 173061.17),
(9, 41, 44, '2026-05-22', 115266.08),
(90, 95, 61, '2023-08-23', 130101.63),
(5, 70, 20, '2025-08-20', 93715.64),
(28, 41, 73, '2023-03-06', 70464.92),
(100, 49, 8, '2025-01-10', 217866.88),
(61, 28, 7, '2024-03-09', 183172.85),
(98, 88, 55, '2024-07-06', 196903.61),
(23, 11, 19, '2023-05-22', 89112.48),
(11, 39, 92, '2025-07-13', 92933.43),
(68, 28, 86, '2024-06-15', 197475.6),
(7, 12, 55, '2024-12-01', 77213.7),
(39, 22, 26, '2024-12-16', 213589.01),
(62, 61, 69, '2023-11-26', 209839.79),
(56, 46, 89, '2026-03-14', 213978.22),
(2, 72, 77, '2024-02-11', 113099.14),
(86, 75, 79, '2023-10-24', 58616.52),
(94, 96, 95, '2024-10-10', 101653.2),
(59, 19, 64, '2024-10-10', 47482.69),
(87, 53, 34, '2025-12-02', 64881.2),
(58, 17, 82, '2025-07-09', 171400.06),
(75, 13, 5, '2024-03-23', 156810.37),
(25, 54, 90, '2026-01-23', 175498.82),
(77, 49, 28, '2024-12-13', 180517.27),
(25, 87, 74, '2023-01-30', 81708.54),
(47, 3, 39, '2024-09-20', 109794.87),
(16, 90, 64, '2025-07-22', 132864.91),
(46, 46, 70, '2025-05-22', 117459.4),
(98, 43, 15, '2023-12-27', 136554.72),
(48, 23, 71, '2026-05-03', 125294.12),
(56, 49, 37, '2025-06-14', 73465.0),
(90, 80, 13, '2023-06-29', 155968.77),
(14, 12, 84, '2023-02-03', 186039.46),
(53, 14, 64, '2026-07-01', 152845.57),
(13, 82, 57, '2025-10-27', 207265.06),
(5, 86, 38, '2025-05-11', 146715.88),
(100, 59, 71, '2025-02-19', 82077.45),
(61, 16, 45, '2025-08-08', 65037.69),
(83, 91, 95, '2025-03-21', 117263.58),
(48, 29, 65, '2024-08-03', 46330.9),
(85, 34, 40, '2025-04-29', 91831.6),
(1, 54, 5, '2023-02-01', 162827.64),
(48, 67, 95, '2026-05-13', 49593.19),
(22, 74, 56, '2024-05-10', 100557.42),
(51, 25, 79, '2025-03-16', 142254.43),
(74, 55, 17, '2025-03-10', 189996.23),
(23, 52, 41, '2025-11-25', 216037.24),
(30, 13, 91, '2023-09-16', 72727.64),
(81, 74, 51, '2024-06-16', 133244.98),
(21, 42, 27, '2023-07-10', 191534.13),
(56, 2, 81, '2026-04-30', 61321.45),
(80, 91, 70, '2023-06-11', 71783.51),
(4, 96, 94, '2023-09-25', 145063.92),
(82, 81, 100, '2025-01-03', 217097.48),
(84, 29, 39, '2024-02-01', 77647.15),
(32, 93, 100, '2025-02-13', 138698.01),
(85, 7, 36, '2023-06-19', 179818.53),
(81, 3, 82, '2026-04-01', 208620.78),
(15, 59, 77, '2023-09-09', 196714.33),
(37, 34, 24, '2023-07-10', 63738.41),
(47, 27, 51, '2023-07-26', 58541.75),
(3, 53, 10, '2025-09-23', 130931.47),
(10, 27, 88, '2025-05-09', 212863.01),
(41, 82, 58, '2023-11-26', 110669.51),
(2, 23, 85, '2026-03-07', 76466.13),
(5, 16, 44, '2024-12-11', 155462.35),
(79, 77, 70, '2023-01-11', 129684.42),
(95, 33, 16, '2024-01-30', 72717.95),
(69, 3, 67, '2025-11-14', 151069.39),
(28, 47, 15, '2024-03-20', 178168.17),
(18, 29, 11, '2023-09-17', 50162.08),
(62, 26, 12, '2024-12-14', 91828.34),
(84, 38, 60, '2025-10-12', 168914.63),
(52, 25, 33, '2023-12-21', 121310.85),
(92, 36, 51, '2023-07-30', 79628.38),
(99, 76, 40, '2023-12-06', 147138.44),
(93, 63, 56, '2025-07-02', 183967.42),
(96, 35, 41, '2026-06-29', 119154.03),
(50, 55, 26, '2026-03-07', 63822.84),
(81, 9, 58, '2023-12-09', 106760.21),
(66, 33, 76, '2025-04-19', 200653.7),
(83, 68, 46, '2025-03-26', 96357.87),
(24, 42, 55, '2024-01-16', 50239.49),
(10, 28, 85, '2025-01-31', 107605.29),
(100, 41, 16, '2023-01-20', 110093.75),
(2, 92, 43, '2024-03-13', 100753.1),
(42, 30, 72, '2023-05-16', 126440.91),
(78, 28, 68, '2024-03-21', 112478.4),
(36, 92, 78, '2023-06-03', 63011.03),
(83, 54, 88, '2025-06-10', 145440.97),
(41, 26, 26, '2023-04-12', 100612.08),
(64, 6, 36, '2025-05-12', 185476.91),
(58, 22, 77, '2024-10-31', 65870.33),
(31, 74, 3, '2024-08-06', 148454.94);

-- ===== TEST_DRIVE =====
INSERT INTO test_drive (id_cliente, id_funcionario, id_veiculo_venda, data_test, horario, observacao) VALUES
(60, 37, 17, '2025-04-04', '08:00:00', 'Test drive agendado #1'),
(44, 83, 3, '2023-05-23', '08:00:00', 'Test drive agendado #2'),
(54, 93, 39, '2024-07-16', '15:00:00', 'Test drive agendado #3'),
(52, 11, 72, '2024-10-03', '13:30:00', 'Test drive agendado #4'),
(51, 39, 90, '2025-07-19', '15:00:00', 'Test drive agendado #5'),
(48, 80, 14, '2023-03-01', '15:00:00', 'Test drive agendado #6'),
(2, 18, 14, '2024-10-23', '11:00:00', 'Test drive agendado #7'),
(22, 12, 25, '2025-01-25', '14:15:00', 'Test drive agendado #8'),
(89, 7, 34, '2023-03-30', '16:00:00', 'Test drive agendado #9'),
(39, 10, 34, '2024-11-05', '09:00:00', 'Test drive agendado #10'),
(35, 90, 22, '2023-10-10', '17:45:00', 'Test drive agendado #11'),
(16, 17, 41, '2023-10-31', '17:45:00', 'Test drive agendado #12'),
(82, 58, 86, '2023-09-08', '17:45:00', 'Test drive agendado #13'),
(74, 62, 85, '2025-09-30', '16:15:00', 'Test drive agendado #14'),
(99, 94, 62, '2024-04-07', '12:30:00', 'Test drive agendado #15'),
(99, 38, 92, '2023-06-19', '09:30:00', 'Test drive agendado #16'),
(85, 83, 95, '2024-02-26', '13:15:00', 'Test drive agendado #17'),
(64, 8, 28, '2023-01-27', '09:00:00', 'Test drive agendado #18'),
(50, 25, 63, '2023-08-03', '11:45:00', 'Test drive agendado #19'),
(76, 98, 68, '2025-11-18', '13:15:00', 'Test drive agendado #20'),
(91, 59, 84, '2023-11-12', '13:30:00', 'Test drive agendado #21'),
(17, 29, 47, '2025-02-28', '16:00:00', 'Test drive agendado #22'),
(100, 52, 25, '2023-05-21', '15:15:00', 'Test drive agendado #23'),
(22, 88, 40, '2026-03-28', '12:45:00', 'Test drive agendado #24'),
(60, 14, 96, '2023-08-14', '09:15:00', 'Test drive agendado #25'),
(59, 24, 35, '2023-02-28', '11:00:00', 'Test drive agendado #26'),
(46, 34, 16, '2026-02-01', '15:45:00', 'Test drive agendado #27'),
(56, 28, 20, '2025-03-23', '09:30:00', 'Test drive agendado #28'),
(66, 43, 7, '2025-06-22', '16:45:00', 'Test drive agendado #29'),
(13, 7, 84, '2025-02-22', '12:30:00', 'Test drive agendado #30'),
(38, 25, 52, '2023-12-28', '14:15:00', 'Test drive agendado #31'),
(68, 78, 64, '2025-11-28', '17:30:00', 'Test drive agendado #32'),
(88, 7, 83, '2024-05-24', '14:00:00', 'Test drive agendado #33'),
(15, 7, 5, '2026-03-24', '09:15:00', 'Test drive agendado #34'),
(9, 69, 13, '2024-07-18', '12:15:00', 'Test drive agendado #35'),
(51, 51, 13, '2024-03-26', '11:45:00', 'Test drive agendado #36'),
(27, 22, 27, '2024-12-12', '12:45:00', 'Test drive agendado #37'),
(94, 1, 13, '2024-01-15', '12:30:00', 'Test drive agendado #38'),
(95, 40, 89, '2024-05-03', '16:45:00', 'Test drive agendado #39'),
(88, 9, 22, '2024-01-19', '10:30:00', 'Test drive agendado #40'),
(19, 2, 86, '2025-08-29', '13:45:00', 'Test drive agendado #41'),
(3, 23, 34, '2023-06-07', '14:30:00', 'Test drive agendado #42'),
(77, 46, 61, '2026-04-09', '10:00:00', 'Test drive agendado #43'),
(32, 61, 15, '2023-04-03', '08:45:00', 'Test drive agendado #44'),
(30, 68, 65, '2023-12-09', '08:30:00', 'Test drive agendado #45'),
(13, 39, 95, '2024-11-18', '10:00:00', 'Test drive agendado #46'),
(95, 45, 70, '2024-06-11', '15:45:00', 'Test drive agendado #47'),
(47, 59, 2, '2024-12-23', '15:30:00', 'Test drive agendado #48'),
(67, 100, 85, '2026-05-05', '12:30:00', 'Test drive agendado #49'),
(35, 88, 67, '2023-02-12', '15:00:00', 'Test drive agendado #50'),
(29, 85, 19, '2025-01-01', '10:45:00', 'Test drive agendado #51'),
(32, 74, 95, '2025-06-01', '15:00:00', 'Test drive agendado #52'),
(96, 12, 25, '2025-02-12', '13:15:00', 'Test drive agendado #53'),
(81, 87, 70, '2025-07-09', '09:30:00', 'Test drive agendado #54'),
(34, 87, 45, '2024-11-09', '16:15:00', 'Test drive agendado #55'),
(36, 40, 25, '2023-03-26', '14:45:00', 'Test drive agendado #56'),
(79, 16, 56, '2025-07-20', '17:30:00', 'Test drive agendado #57'),
(37, 15, 2, '2025-10-18', '17:30:00', 'Test drive agendado #58'),
(88, 20, 67, '2024-08-16', '10:45:00', 'Test drive agendado #59'),
(39, 63, 37, '2023-05-13', '17:15:00', 'Test drive agendado #60'),
(59, 6, 28, '2024-08-02', '12:00:00', 'Test drive agendado #61'),
(7, 63, 40, '2023-01-11', '17:00:00', 'Test drive agendado #62'),
(85, 1, 7, '2024-05-29', '14:30:00', 'Test drive agendado #63'),
(37, 65, 86, '2026-02-22', '10:30:00', 'Test drive agendado #64'),
(92, 35, 19, '2024-02-07', '10:00:00', 'Test drive agendado #65'),
(38, 29, 5, '2025-08-27', '14:00:00', 'Test drive agendado #66'),
(87, 82, 50, '2025-05-15', '13:15:00', 'Test drive agendado #67'),
(34, 39, 77, '2024-09-28', '14:00:00', 'Test drive agendado #68'),
(87, 42, 75, '2023-10-13', '10:45:00', 'Test drive agendado #69'),
(18, 54, 71, '2024-02-13', '11:30:00', 'Test drive agendado #70'),
(11, 39, 73, '2025-08-02', '12:30:00', 'Test drive agendado #71'),
(49, 56, 13, '2023-10-11', '16:15:00', 'Test drive agendado #72'),
(89, 41, 65, '2025-01-02', '16:45:00', 'Test drive agendado #73'),
(55, 60, 54, '2025-04-20', '15:30:00', 'Test drive agendado #74'),
(72, 4, 99, '2025-05-12', '15:00:00', 'Test drive agendado #75'),
(79, 39, 32, '2026-04-03', '09:15:00', 'Test drive agendado #76'),
(17, 80, 70, '2026-03-04', '16:30:00', 'Test drive agendado #77'),
(97, 51, 17, '2025-04-05', '12:00:00', 'Test drive agendado #78'),
(98, 67, 59, '2023-04-22', '08:45:00', 'Test drive agendado #79'),
(35, 84, 14, '2024-11-13', '09:00:00', 'Test drive agendado #80'),
(38, 73, 62, '2024-11-09', '17:00:00', 'Test drive agendado #81'),
(95, 75, 87, '2025-11-12', '08:00:00', 'Test drive agendado #82'),
(67, 19, 72, '2025-10-11', '08:15:00', 'Test drive agendado #83'),
(87, 82, 20, '2024-09-08', '10:15:00', 'Test drive agendado #84'),
(63, 80, 89, '2024-02-16', '12:00:00', 'Test drive agendado #85'),
(1, 20, 78, '2023-09-05', '09:00:00', 'Test drive agendado #86'),
(32, 27, 14, '2025-08-28', '16:00:00', 'Test drive agendado #87'),
(51, 8, 16, '2024-09-06', '08:45:00', 'Test drive agendado #88'),
(24, 31, 70, '2024-06-17', '14:45:00', 'Test drive agendado #89'),
(85, 79, 16, '2025-06-04', '17:45:00', 'Test drive agendado #90'),
(24, 19, 96, '2024-05-07', '10:00:00', 'Test drive agendado #91'),
(61, 62, 38, '2024-08-15', '10:15:00', 'Test drive agendado #92'),
(48, 86, 36, '2025-03-12', '09:45:00', 'Test drive agendado #93'),
(60, 54, 55, '2023-10-31', '14:00:00', 'Test drive agendado #94'),
(59, 16, 73, '2025-03-08', '08:30:00', 'Test drive agendado #95'),
(5, 83, 84, '2026-06-23', '08:30:00', 'Test drive agendado #96'),
(46, 18, 60, '2025-07-27', '15:00:00', 'Test drive agendado #97'),
(21, 46, 65, '2025-10-27', '12:00:00', 'Test drive agendado #98'),
(91, 68, 50, '2025-11-16', '11:30:00', 'Test drive agendado #99'),
(84, 20, 46, '2026-02-27', '09:15:00', 'Test drive agendado #100');

-- ===== LOG_ACESSO_ESTOQUE =====
INSERT INTO log_acesso_estoque (id_funcionario, id_estoque, tipo_acesso, quantidade_movimentada, observacao) VALUES
(44, 59, 'ENTRADA', 5, 'Acesso registrado automaticamente #1'),
(36, 98, 'ENTRADA', 10, 'Acesso registrado automaticamente #2'),
(51, 9, 'ENTRADA', 16, 'Acesso registrado automaticamente #3'),
(49, 61, 'ENTRADA', 6, 'Acesso registrado automaticamente #4'),
(74, 91, 'ENTRADA', 17, 'Acesso registrado automaticamente #5'),
(34, 17, 'ENTRADA', 11, 'Acesso registrado automaticamente #6'),
(76, 75, 'RETIRADA', 19, 'Acesso registrado automaticamente #7'),
(80, 52, 'CONSULTA', 2, 'Acesso registrado automaticamente #8'),
(4, 94, 'CONSULTA', 8, 'Acesso registrado automaticamente #9'),
(13, 86, 'CONSULTA', 16, 'Acesso registrado automaticamente #10'),
(87, 61, 'RETIRADA', 8, 'Acesso registrado automaticamente #11'),
(99, 94, 'CONSULTA', 4, 'Acesso registrado automaticamente #12'),
(23, 94, 'RETIRADA', 14, 'Acesso registrado automaticamente #13'),
(9, 8, 'ENTRADA', 9, 'Acesso registrado automaticamente #14'),
(15, 5, 'ENTRADA', 3, 'Acesso registrado automaticamente #15'),
(57, 98, 'RETIRADA', 20, 'Acesso registrado automaticamente #16'),
(81, 4, 'CONSULTA', 11, 'Acesso registrado automaticamente #17'),
(14, 90, 'RETIRADA', 13, 'Acesso registrado automaticamente #18'),
(18, 82, 'ENTRADA', 18, 'Acesso registrado automaticamente #19'),
(26, 26, 'RETIRADA', 16, 'Acesso registrado automaticamente #20'),
(57, 87, 'RETIRADA', 8, 'Acesso registrado automaticamente #21'),
(26, 95, 'CONSULTA', 14, 'Acesso registrado automaticamente #22'),
(68, 25, 'CONSULTA', 19, 'Acesso registrado automaticamente #23'),
(4, 81, 'ENTRADA', 4, 'Acesso registrado automaticamente #24'),
(27, 5, 'CONSULTA', 1, 'Acesso registrado automaticamente #25'),
(47, 100, 'RETIRADA', 19, 'Acesso registrado automaticamente #26'),
(70, 10, 'RETIRADA', 6, 'Acesso registrado automaticamente #27'),
(88, 94, 'ENTRADA', 17, 'Acesso registrado automaticamente #28'),
(64, 25, 'CONSULTA', 19, 'Acesso registrado automaticamente #29'),
(61, 65, 'RETIRADA', 12, 'Acesso registrado automaticamente #30'),
(80, 72, 'CONSULTA', 3, 'Acesso registrado automaticamente #31'),
(57, 55, 'ENTRADA', 13, 'Acesso registrado automaticamente #32'),
(10, 73, 'CONSULTA', 5, 'Acesso registrado automaticamente #33'),
(67, 39, 'CONSULTA', 4, 'Acesso registrado automaticamente #34'),
(64, 30, 'CONSULTA', 20, 'Acesso registrado automaticamente #35'),
(70, 43, 'CONSULTA', 8, 'Acesso registrado automaticamente #36'),
(38, 33, 'RETIRADA', 12, 'Acesso registrado automaticamente #37'),
(9, 21, 'RETIRADA', 3, 'Acesso registrado automaticamente #38'),
(69, 74, 'CONSULTA', 17, 'Acesso registrado automaticamente #39'),
(79, 65, 'RETIRADA', 13, 'Acesso registrado automaticamente #40'),
(80, 8, 'ENTRADA', 4, 'Acesso registrado automaticamente #41'),
(75, 61, 'RETIRADA', 1, 'Acesso registrado automaticamente #42'),
(5, 44, 'RETIRADA', 9, 'Acesso registrado automaticamente #43'),
(26, 43, 'CONSULTA', 5, 'Acesso registrado automaticamente #44'),
(27, 71, 'ENTRADA', 11, 'Acesso registrado automaticamente #45'),
(97, 85, 'CONSULTA', 8, 'Acesso registrado automaticamente #46'),
(64, 10, 'ENTRADA', 20, 'Acesso registrado automaticamente #47'),
(90, 98, 'CONSULTA', 12, 'Acesso registrado automaticamente #48'),
(10, 54, 'ENTRADA', 20, 'Acesso registrado automaticamente #49'),
(11, 71, 'RETIRADA', 5, 'Acesso registrado automaticamente #50'),
(35, 93, 'CONSULTA', 4, 'Acesso registrado automaticamente #51'),
(5, 64, 'ENTRADA', 8, 'Acesso registrado automaticamente #52'),
(84, 45, 'RETIRADA', 16, 'Acesso registrado automaticamente #53'),
(39, 30, 'CONSULTA', 2, 'Acesso registrado automaticamente #54'),
(4, 100, 'CONSULTA', 18, 'Acesso registrado automaticamente #55'),
(78, 49, 'ENTRADA', 1, 'Acesso registrado automaticamente #56'),
(71, 62, 'CONSULTA', 13, 'Acesso registrado automaticamente #57'),
(99, 49, 'ENTRADA', 5, 'Acesso registrado automaticamente #58'),
(56, 90, 'RETIRADA', 18, 'Acesso registrado automaticamente #59'),
(18, 15, 'RETIRADA', 4, 'Acesso registrado automaticamente #60'),
(79, 48, 'RETIRADA', 7, 'Acesso registrado automaticamente #61'),
(44, 56, 'CONSULTA', 8, 'Acesso registrado automaticamente #62'),
(30, 12, 'ENTRADA', 1, 'Acesso registrado automaticamente #63'),
(30, 53, 'ENTRADA', 18, 'Acesso registrado automaticamente #64'),
(73, 6, 'CONSULTA', 8, 'Acesso registrado automaticamente #65'),
(8, 10, 'CONSULTA', 5, 'Acesso registrado automaticamente #66'),
(57, 24, 'RETIRADA', 2, 'Acesso registrado automaticamente #67'),
(41, 45, 'ENTRADA', 8, 'Acesso registrado automaticamente #68'),
(38, 17, 'ENTRADA', 13, 'Acesso registrado automaticamente #69'),
(62, 85, 'CONSULTA', 3, 'Acesso registrado automaticamente #70'),
(10, 33, 'ENTRADA', 7, 'Acesso registrado automaticamente #71'),
(64, 91, 'ENTRADA', 12, 'Acesso registrado automaticamente #72'),
(29, 57, 'ENTRADA', 10, 'Acesso registrado automaticamente #73'),
(47, 100, 'ENTRADA', 10, 'Acesso registrado automaticamente #74'),
(84, 32, 'ENTRADA', 9, 'Acesso registrado automaticamente #75'),
(41, 90, 'ENTRADA', 17, 'Acesso registrado automaticamente #76'),
(14, 7, 'RETIRADA', 14, 'Acesso registrado automaticamente #77'),
(91, 80, 'RETIRADA', 9, 'Acesso registrado automaticamente #78'),
(11, 27, 'CONSULTA', 17, 'Acesso registrado automaticamente #79'),
(30, 40, 'ENTRADA', 18, 'Acesso registrado automaticamente #80'),
(27, 16, 'RETIRADA', 5, 'Acesso registrado automaticamente #81'),
(5, 31, 'ENTRADA', 15, 'Acesso registrado automaticamente #82'),
(84, 98, 'RETIRADA', 4, 'Acesso registrado automaticamente #83'),
(3, 64, 'CONSULTA', 9, 'Acesso registrado automaticamente #84'),
(36, 76, 'RETIRADA', 10, 'Acesso registrado automaticamente #85'),
(11, 8, 'RETIRADA', 20, 'Acesso registrado automaticamente #86'),
(50, 64, 'CONSULTA', 13, 'Acesso registrado automaticamente #87'),
(50, 57, 'CONSULTA', 8, 'Acesso registrado automaticamente #88'),
(27, 49, 'CONSULTA', 14, 'Acesso registrado automaticamente #89'),
(69, 7, 'ENTRADA', 10, 'Acesso registrado automaticamente #90'),
(5, 70, 'RETIRADA', 1, 'Acesso registrado automaticamente #91'),
(78, 97, 'RETIRADA', 9, 'Acesso registrado automaticamente #92'),
(97, 76, 'CONSULTA', 1, 'Acesso registrado automaticamente #93'),
(44, 93, 'ENTRADA', 14, 'Acesso registrado automaticamente #94'),
(55, 94, 'ENTRADA', 2, 'Acesso registrado automaticamente #95'),
(14, 71, 'RETIRADA', 10, 'Acesso registrado automaticamente #96'),
(69, 60, 'RETIRADA', 19, 'Acesso registrado automaticamente #97'),
(93, 73, 'ENTRADA', 9, 'Acesso registrado automaticamente #98'),
(21, 49, 'RETIRADA', 8, 'Acesso registrado automaticamente #99'),
(17, 2, 'RETIRADA', 9, 'Acesso registrado automaticamente #100');

SET FOREIGN_KEY_CHECKS = 1;
