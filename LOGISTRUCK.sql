CREATE DATABASE logistruck;
USE logistruck;

CREATE TABLE clientes (
    id_cliente  INT PRIMARY KEY,
    nome       VARCHAR(255) NOT NULL,
    tipo      VARCHAR(255) 
);

ALTER TABLE clientes
ADD CONSTRAINT chk_clientes_tipo
CHECK (tipo IN ('PF', 'PJ'));

CREATE TABLE rotas (
    id_rota     INT PRIMARY KEY,
    cidade      VARCHAR(255) NOT NULL,
    bairro      VARCHAR(255),
    uf          VARCHAR(2) NOT NULL
);

ALTER TABLE rotas
ADD COLUMN complemento VARCHAR(255);

CREATE TABLE frota (
    id_veiculo  INT PRIMARY KEY,
    placa       VARCHAR(10) NOT NULL UNIQUE,
    modelo      VARCHAR(255),
    km          INT DEFAULT 0
);

CREATE TABLE funcionarios (
    id_funcionario  INT PRIMARY KEY,
    nome            VARCHAR(255) NOT NULL,
    cpf             VARCHAR(11) NOT NULL,
    habilitacao     VARCHAR(12) NOT NULL ,
    cargo           VARCHAR(255)
);

ALTER TABLE funcionarios
ADD CONSTRAINT uq_funcionarios_cpf
UNIQUE (cpf);

CREATE TABLE entregas (
    id_entrega      INT PRIMARY KEY,
    id_rota         INT NOT NULL,
    id_cliente      INT NOT NULL,
    id_veiculo      INT NOT NULL,
    id_funcionario  INT NOT NULL,
    status          VARCHAR(255),
    CONSTRAINT fk_entregas_rota
        FOREIGN KEY (id_rota) REFERENCES rotas(id_rota),
    CONSTRAINT fk_entregas_cliente
        FOREIGN KEY (id_cliente) REFERENCES clientes(id_cliente),
    CONSTRAINT fk_entregas_veiculo
        FOREIGN KEY (id_veiculo) REFERENCES frota(id_veiculo),
    CONSTRAINT fk_entregas_funcionario
        FOREIGN KEY (id_funcionario) REFERENCES funcionarios(id_funcionario)
);
ALTER TABLE Entregas
ADD COLUMN data_entrega DATE;

CREATE TABLE manutencao (
    id_manutencao   INT PRIMARY KEY,
    id_veiculo      INT NOT NULL,
    id_funcionario  INT NOT NULL,
    troca_oleo     BOOLEAN,
    quilometragem   INT,
    data_manutencao DATE,
    CONSTRAINT fk_manutencao_veiculo
        FOREIGN KEY (id_veiculo) REFERENCES frota(id_veiculo),
    CONSTRAINT fk_manutencao_funcionario
        FOREIGN KEY (id_funcionario) REFERENCES funcionarios(id_funcionario)
);


CREATE TABLE consumo_combustivel (
    id_consumo      INT PRIMARY KEY,
    id_veiculo      INT NOT NULL,
    id_funcionario  INT NOT NULL,
    litros          DECIMAL (10,2),
    km_percorrido   INT,
    data            DATE,
    CONSTRAINT fk_consumo_veiculo
        FOREIGN KEY (id_veiculo) REFERENCES frota(id_veiculo),
    CONSTRAINT fk_consumo_funcionario
        FOREIGN KEY (id_funcionario) REFERENCES funcionarios(id_funcionario)
);

ALTER TABLE consumo_combustivel
MODIFY litros DECIMAL(10,2);

DELIMITER $$

CREATE TRIGGER trg_atualiza_km
AFTER INSERT ON consumo_combustivel
FOR EACH ROW
BEGIN
    UPDATE frota
    SET km = km + NEW.km_percorrido
    WHERE id_veiculo = NEW.id_veiculo;
END $$
DELIMITER ;

ALTER TABLE consumo_combustivel
ADD CONSTRAINT chk_consumo_km
CHECK (km_percorrido >= 0);

ALTER TABLE frota
ADD CONSTRAINT chk_frota_km
CHECK (km >= 0);

ALTER TABLE consumo_combustivel
ADD CONSTRAINT chk_consumo_litros
CHECK (litros > 0);

ALTER TABLE consumo_combustivel
MODIFY litros DECIMAL(10,2);

DELIMITER $$

-- Sempre que um veículo for abastecido, o sistema deve registrar o abastecimento, 
-- informando o veículo, o funcionário responsável,
-- a quantidade de combustível, a quilometragem percorrida e a data.

CREATE PROCEDURE registrar_abastecimento(
    IN p_id_consumo INT,
    IN p_id_veiculo INT,
    IN p_id_funcionario INT,
    IN p_litros DECIMAL(10,2),
    IN p_km_percorrido INT,
    IN p_data DATE
)
BEGIN
    INSERT INTO consumo_combustivel (
        id_consumo,
        id_veiculo,
        id_funcionario,
        litros,
        km_percorrido,
        data
    )
    VALUES (
        p_id_consumo,
        p_id_veiculo,
        p_id_funcionario,
        p_litros,
        p_km_percorrido,
        p_data
    );
END $$

DELIMITER ;

CALL registrar_abastecimento(
    101,
    10,
    25,
    150.50,
    320,
    '2026-08-12'
);

-- cadastrar_cliente
-- Insere um novo cliente na tabela clientes. Recebe o id, nome e tipo 
-- ('PF' ou 'PJ' — lembrando que existe a constraint chk_clientes_tipo validando isso).

DELIMITER $$
CREATE PROCEDURE cadastrar_cliente(
    IN p_id_cliente INT,
    IN p_nome        VARCHAR(255),
    IN p_tipo        VARCHAR(255)
)
BEGIN
    INSERT INTO clientes (id_cliente, nome, tipo)
    VALUES (p_id_cliente, p_nome, p_tipo);
END $$
DELIMITER ;

-- cadastrar_rota
-- Insere uma nova rota na tabela rotas. Recebe id, cidade, bairro, 
-- UF e complemento (endereço de destino/origem da entrega).

DELIMITER $$
CREATE PROCEDURE cadastrar_rota(
    IN p_id_rota     INT,
    IN p_cidade      VARCHAR(255),
    IN p_bairro      VARCHAR(255),
    IN p_uf          VARCHAR(2),
    IN p_complemento VARCHAR(255)
)
BEGIN
    INSERT INTO rotas (id_rota, cidade, bairro, uf, complemento)
    VALUES (p_id_rota, p_cidade, p_bairro, p_uf, p_complemento);
END $$
DELIMITER ;
 
 -- Insere um veículo novo na frota (frota). Recebe id, placa, modelo e km inicial. 
 -- se você não passar km (NULL), ela grava 0 automaticamente,
 -- mantendo o mesmo padrão do DEFAULT 0 da coluna.

 DELIMITER $$
CREATE PROCEDURE cadastrar_veiculo(
    IN p_id_veiculo INT,
    IN p_placa      VARCHAR(10),
    IN p_modelo     VARCHAR(255),
    IN p_km         INT
)
BEGIN
    INSERT INTO frota (id_veiculo, placa, modelo, km)
    VALUES (p_id_veiculo, p_placa, p_modelo, COALESCE(p_km, 0));
END $$
DELIMITER ;

-- cadastrar_funcionario
-- Insere um funcionário na tabela funcionarios. Recebe id, nome, CPF, 
-- habilitação (CNH) e cargo — por exemplo,
-- motorista, mecânico, etc.

DELIMITER $$
CREATE PROCEDURE cadastrar_funcionario(
    IN p_id_funcionario INT,
    IN p_nome           VARCHAR(255),
    IN p_cpf            VARCHAR(11),
    IN p_habilitacao    VARCHAR(12),
    IN p_cargo          VARCHAR(255)
)
BEGIN
    INSERT INTO funcionarios (id_funcionario, nome, cpf, habilitacao, cargo)
    VALUES (p_id_funcionario, p_nome, p_cpf, p_habilitacao, p_cargo);
END $$
DELIMITER ;

-- registrar_entrega
-- Insere uma entrega na tabela entregas, associando: a rota, o cliente, o veículo, o funcionário responsável, 
-- o status da entrega e a data. É basicamente o "pedido de transporte" ligando todas as outras tabelas.

DELIMITER $$
CREATE PROCEDURE registrar_entrega(
    IN p_id_entrega     INT,
    IN p_id_rota        INT,
    IN p_id_cliente     INT,
    IN p_id_veiculo     INT,
    IN p_id_funcionario INT,
    IN p_status         VARCHAR(255),
    IN p_data_entrega   DATE
)
BEGIN
    INSERT INTO entregas (
        id_entrega, id_rota, id_cliente, id_veiculo,
        id_funcionario, status, data_entrega
    )
    VALUES (
        p_id_entrega, p_id_rota, p_id_cliente, p_id_veiculo,
        p_id_funcionario, p_status, p_data_entrega
    );
END $$
DELIMITER ;

-- registrar_manutencao
-- Insere um registro de manutenção do veículo (manutencao): qual veículo, qual funcionário fez o serviço,
-- se houve troca de óleo, a quilometragem no momento da manutenção e a data.

DELIMITER $$
CREATE PROCEDURE registrar_manutencao(
    IN p_id_manutencao   INT,
    IN p_id_veiculo      INT,
    IN p_id_funcionario  INT,
    IN p_troca_oleo      BOOLEAN,
    IN p_quilometragem   INT,
    IN p_data_manutencao DATE
)
BEGIN
    INSERT INTO manutencao (
        id_manutencao, id_veiculo, id_funcionario,
        troca_oleo, quilometragem, data_manutencao
    )
    VALUES (
        p_id_manutencao, p_id_veiculo, p_id_funcionario,
        p_troca_oleo, p_quilometragem, p_data_manutencao
    );
END $$
DELIMITER ;

-- valida_motorista_entrega
-- Regra: só pode ser registrada uma entrega se o funcionário
-- vinculado tiver o cargo de 'Motorista'. Caso contrário, a
-- inserção é bloqueada com uma mensagem de erro.

DELIMITER $$
CREATE TRIGGER trg_valida_motorista_entrega
BEFORE INSERT ON entregas
FOR EACH ROW
BEGIN
    DECLARE v_cargo VARCHAR(255);
 
    SELECT cargo INTO v_cargo
    FROM funcionarios
    WHERE id_funcionario = NEW.id_funcionario;
 
    IF v_cargo IS NULL OR v_cargo <> 'Motorista' THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'O funcionário informado não é um motorista e não pode ser vinculado a uma entrega.';
    END IF;
END $$
DELIMITER ;

--  trg_data_entrega_automatica
-- Regra: sempre que o status de uma entrega for atualizado
-- para 'Entregue' e a data_entrega ainda não tiver sido
-- preenchida, o sistema grava automaticamente a data atual.

DELIMITER $$
CREATE TRIGGER trg_data_entrega_automatica
BEFORE UPDATE ON entregas
FOR EACH ROW
BEGIN
    IF NEW.status = 'Entregue' AND NEW.data_entrega IS NULL THEN
        SET NEW.data_entrega = CURDATE();
    END IF;
END $$
DELIMITER ;

INSERT INTO clientes (id_cliente, nome, tipo) VALUES
(1, 'Bruno Almeida', 'PF'),
(2, 'Otávio Pereira', 'PF'),
(3, 'Igor Oliveira', 'PF'),
(4, 'Souza Transportes Ltda', 'PJ'),
(5, 'Nicolas Rodrigues', 'PF'),
(6, 'Juliana Ferreira', 'PF'),
(7, 'Rodrigues Transportes EIRELI', 'PJ'),
(8, 'Silva Transportes S.A.', 'PJ'),
(9, 'Lima Transportes ME', 'PJ'),
(10, 'Nicolas Lima', 'PF'),
(11, 'Felipe Melo', 'PF'),
(12, 'Wesley Araújo', 'PF'),
(13, 'Souza Transportes EIRELI', 'PJ'),
(14, 'Yasmin Oliveira', 'PF'),
(15, 'Dias Transportes ME', 'PJ'),
(16, 'Eduarda Souza', 'PF'),
(17, 'Sabrina Oliveira', 'PF'),
(18, 'Gabriela Melo', 'PF'),
(19, 'Ribeiro Transportes ME', 'PJ'),
(20, 'Ximena Araújo', 'PF'),
(21, 'Rafael Oliveira', 'PF'),
(22, 'Igor Rodrigues', 'PF'),
(23, 'Diego Melo', 'PF'),
(24, 'Martins Transportes S.A.', 'PJ'),
(25, 'Souza Transportes S.A.', 'PJ'),
(26, 'Ursula Melo', 'PF'),
(27, 'Oliveira Transportes S.A.', 'PJ'),
(28, 'Ferreira Transportes EIRELI', 'PJ'),
(29, 'Ribeiro Transportes S.A.', 'PJ'),
(30, 'Pereira Transportes S.A.', 'PJ'),
(31, 'Rocha Transportes EIRELI', 'PJ'),
(32, 'Araújo Transportes S.A.', 'PJ'),
(33, 'Gustavo Carvalho', 'PF'),
(34, 'Daniel Santos', 'PF'),
(35, 'Karina Barbosa', 'PF'),
(36, 'Yasmin Melo', 'PF'),
(37, 'Gomes Transportes ME', 'PJ'),
(38, 'Hugo Martins', 'PF'),
(39, 'Lima Transportes Ltda', 'PJ'),
(40, 'Barbosa Transportes S.A.', 'PJ'),
(41, 'Silva Transportes ME', 'PJ'),
(42, 'Gustavo Santos', 'PF'),
(43, 'Gomes Transportes S.A.', 'PJ'),
(44, 'Ximena Costa', 'PF'),
(45, 'Marcelo Lima', 'PF'),
(46, 'Silva Transportes Ltda', 'PJ'),
(47, 'Nascimento Transportes S.A.', 'PJ'),
(48, 'Paula Rocha', 'PF'),
(49, 'Felipe Carvalho', 'PF'),
(50, 'Igor Pereira', 'PF'),
(51, 'Elaine Martins', 'PF'),
(52, 'Quésia Gomes', 'PF'),
(53, 'Ferreira Transportes S.A.', 'PJ'),
(54, 'Melo Transportes ME', 'PJ'),
(55, 'Gomes Transportes EIRELI', 'PJ'),
(56, 'Paula Rodrigues', 'PF'),
(57, 'Vitor Silva', 'PF'),
(58, 'Larissa Rodrigues', 'PF'),
(59, 'Eduarda Souza', 'PF'),
(60, 'Eduarda Souza', 'PF'),
(61, 'Oliveira Transportes S.A.', 'PJ'),
(62, 'Carvalho Transportes S.A.', 'PJ'),
(63, 'Kevin Rocha', 'PF'),
(64, 'Rodrigues Transportes EIRELI', 'PJ'),
(65, 'Ferreira Transportes Ltda', 'PJ'),
(66, 'Bernardo Araújo', 'PF'),
(67, 'Barbosa Transportes EIRELI', 'PJ'),
(68, 'Gabriela Souza', 'PF'),
(69, 'Lima Transportes Ltda', 'PJ'),
(70, 'Mariana Ferreira', 'PF'),
(71, 'Pereira Transportes EIRELI', 'PJ'),
(72, 'Rafael Ribeiro', 'PF'),
(73, 'Eduarda Ribeiro', 'PF'),
(74, 'Daniel Martins', 'PF'),
(75, 'Felipe Rodrigues', 'PF'),
(76, 'Aline Carvalho', 'PF'),
(77, 'Ferreira Transportes EIRELI', 'PJ'),
(78, 'Karina Melo', 'PF'),
(79, 'Yasmin Almeida', 'PF'),
(80, 'Nascimento Transportes EIRELI', 'PJ'),
(81, 'Pereira Transportes S.A.', 'PJ'),
(82, 'Ferreira Transportes Ltda', 'PJ'),
(83, 'Ursula Souza', 'PF'),
(84, 'Larissa Carvalho', 'PF'),
(85, 'Daniel Gomes', 'PF'),
(86, 'Lucas Oliveira', 'PF'),
(87, 'Paula Melo', 'PF'),
(88, 'Kevin Rodrigues', 'PF'),
(89, 'Natália Oliveira', 'PF'),
(90, 'Rocha Transportes ME', 'PJ'),
(91, 'Ferreira Transportes ME', 'PJ'),
(92, 'Quésia Melo', 'PF'),
(93, 'Thiago Ribeiro', 'PF'),
(94, 'Oliveira Transportes Ltda', 'PJ'),
(95, 'Dias Transportes Ltda', 'PJ'),
(96, 'Igor Ferreira', 'PF'),
(97, 'Pereira Transportes ME', 'PJ'),
(98, 'Paula Araújo', 'PF'),
(99, 'Costa Transportes EIRELI', 'PJ'),
(100, 'Dias Transportes Ltda', 'PJ');
 
-- rotas
INSERT INTO rotas (id_rota, cidade, bairro, uf) VALUES
(1, 'Contagem', 'Alto da Serra', 'MG'),
(2, 'Curitiba', 'Industrial', 'PR'),
(3, 'Brasília', 'Bela Vista', 'DF'),
(4, 'Curitiba', 'Novo Horizonte', 'PR'),
(5, 'Porto Alegre', 'Cidade Nova', 'RS'),
(6, 'Goiânia', 'Liberdade', 'GO'),
(7, 'Recife', 'Parque das Nações', 'PE'),
(8, 'Recife', 'Cidade Nova', 'PE'),
(9, 'Betim', 'São Pedro', 'MG'),
(10, 'Brasília', 'Jardim América', 'DF'),
(11, 'Belo Horizonte', 'Alvorada', 'MG'),
(12, 'Brasília', 'Jardim América', 'DF'),
(13, 'São Paulo', 'Parque das Nações', 'SP'),
(14, 'Porto Alegre', 'Cidade Nova', 'RS'),
(15, 'Salvador', 'Esperança', 'BA'),
(16, 'Contagem', 'Alvorada', 'MG'),
(17, 'Contagem', 'Centro', 'MG'),
(18, 'Curitiba', 'Vila Nova', 'PR'),
(19, 'Porto Alegre', 'Novo Horizonte', 'RS'),
(20, 'Rio de Janeiro', 'Bosque', 'RJ'),
(21, 'Manaus', 'Novo Horizonte', 'AM'),
(22, 'Porto Alegre', 'Alvorada', 'RS'),
(23, 'Porto Alegre', 'Jardim América', 'RS'),
(24, 'Goiânia', 'Bosque', 'GO'),
(25, 'Rio de Janeiro', 'Bosque', 'RJ'),
(26, 'Recife', 'Boa Vista', 'PE'),
(27, 'Curitiba', 'Bosque', 'PR'),
(28, 'Contagem', 'Alvorada', 'MG'),
(29, 'Belém', 'Industrial', 'PA'),
(30, 'Fortaleza', 'São José', 'CE'),
(31, 'Salvador', 'Alvorada', 'BA'),
(32, 'São Paulo', 'São José', 'SP'),
(33, 'Campinas', 'Alvorada', 'SP'),
(34, 'Fortaleza', 'Cidade Nova', 'CE'),
(35, 'Salvador', 'Bela Vista', 'BA'),
(36, 'Joinville', 'Jardim América', 'SC'),
(37, 'Vitória', 'Boa Vista', 'ES'),
(38, 'Recife', 'Esperança', 'PE'),
(39, 'Uberlândia', 'Alto da Serra', 'MG'),
(40, 'Fortaleza', 'Boa Vista', 'CE'),
(41, 'São Paulo', 'Santa Mônica', 'SP'),
(42, 'Joinville', 'Parque das Nações', 'SC'),
(43, 'Brasília', 'Vila Nova', 'DF'),
(44, 'Brasília', 'Bosque', 'DF'),
(45, 'Betim', 'Palmeiras', 'MG'),
(46, 'Contagem', 'Parque das Nações', 'MG'),
(47, 'São Paulo', 'Bela Vista', 'SP'),
(48, 'Brasília', 'São José', 'DF'),
(49, 'Manaus', 'Cidade Nova', 'AM'),
(50, 'Rio de Janeiro', 'Bela Vista', 'RJ'),
(51, 'Belém', 'Alvorada', 'PA'),
(52, 'Uberlândia', 'Parque das Nações', 'MG'),
(53, 'Londrina', 'Liberdade', 'PR'),
(54, 'Betim', 'Bela Vista', 'MG'),
(55, 'Joinville', 'Higienópolis', 'SC'),
(56, 'Recife', 'Cidade Nova', 'PE'),
(57, 'Rio de Janeiro', 'Alvorada', 'RJ'),
(58, 'São Paulo', 'Vila Rica', 'SP'),
(59, 'Contagem', 'Santa Mônica', 'MG'),
(60, 'Uberlândia', 'Alvorada', 'MG'),
(61, 'Belo Horizonte', 'Parque das Nações', 'MG'),
(62, 'Belém', 'Parque das Nações', 'PA'),
(63, 'Curitiba', 'Alto da Serra', 'PR'),
(64, 'Betim', 'Alto da Serra', 'MG'),
(65, 'Londrina', 'Parque das Nações', 'PR'),
(66, 'Joinville', 'Alto da Serra', 'SC'),
(67, 'Contagem', 'Industrial', 'MG'),
(68, 'Recife', 'Alvorada', 'PE'),
(69, 'Joinville', 'São José', 'SC'),
(70, 'Belém', 'Higienópolis', 'PA'),
(71, 'Goiânia', 'Palmeiras', 'GO'),
(72, 'Contagem', 'Centro', 'MG'),
(73, 'Goiânia', 'Alto da Serra', 'GO'),
(74, 'Recife', 'Alvorada', 'PE'),
(75, 'Manaus', 'Liberdade', 'AM'),
(76, 'Campinas', 'Esperança', 'SP'),
(77, 'Natal', 'Esperança', 'RN'),
(78, 'Recife', 'Vila Rica', 'PE'),
(79, 'Vitória', 'São José', 'ES'),
(80, 'Belo Horizonte', 'Alto da Serra', 'MG'),
(81, 'Betim', 'Liberdade', 'MG'),
(82, 'Campinas', 'Vila Nova', 'SP'),
(83, 'Fortaleza', 'Alto da Serra', 'CE'),
(84, 'Fortaleza', 'Santa Mônica', 'CE'),
(85, 'Porto Alegre', 'Centro', 'RS'),
(86, 'Rio de Janeiro', 'Boa Vista', 'RJ'),
(87, 'Vitória', 'Liberdade', 'ES'),
(88, 'Belo Horizonte', 'Esperança', 'MG'),
(89, 'Londrina', 'Higienópolis', 'PR'),
(90, 'Recife', 'Palmeiras', 'PE'),
(91, 'Vitória', 'Palmeiras', 'ES'),
(92, 'Fortaleza', 'Industrial', 'CE'),
(93, 'São Paulo', 'Bela Vista', 'SP'),
(94, 'Londrina', 'Boa Vista', 'PR'),
(95, 'Salvador', 'Vila Rica', 'BA'),
(96, 'Natal', 'Jardim América', 'RN'),
(97, 'Contagem', 'Boa Vista', 'MG'),
(98, 'Curitiba', 'Esperança', 'PR'),
(99, 'Porto Alegre', 'Esperança', 'RS'),
(100, 'Betim', 'Novo Horizonte', 'MG');
 
-- frota
INSERT INTO frota (id_veiculo, placa, modelo, km) VALUES
(1, 'PYX9X86', 'Volvo VM 270', 234787),
(2, 'XTM4Y34', 'Volvo VM 270', 255068),
(3, 'QHC4H45', 'DAF XF', 284195),
(4, 'CDJ2W31', 'Ford Cargo', 214699),
(5, 'IMB6M90', 'Mercedes-Benz Atego', 200429),
(6, 'MYH6N88', 'Mercedes-Benz Atego', 116625),
(7, 'MHM6K62', 'MAN TGX', 67913),
(8, 'ZNX9S01', 'Ford Cargo', 72145),
(9, 'WEG5G75', 'DAF XF', 199771),
(10, 'HYK1P08', 'Volvo FH 540', 184480),
(11, 'FBY0Y03', 'Iveco Daily', 11684),
(12, 'QGM1S37', 'Volkswagen Constellation', 194407),
(13, 'EPT1Y24', 'Scania R450', 14462),
(14, 'YOX6M31', 'Mercedes-Benz Atego', 128323),
(15, 'CUW9Z19', 'Volvo FH 540', 183034),
(16, 'NRB5A67', 'Scania R450', 228291),
(17, 'YQV2N28', 'Volkswagen Constellation', 283157),
(18, 'UMV9I53', 'Scania R450', 147238),
(19, 'WGM9V65', 'Volvo FH 540', 260158),
(20, 'WEF4K49', 'Volkswagen Constellation', 292394),
(21, 'AYC6P83', 'MAN TGX', 258331),
(22, 'LAH6W34', 'Mercedes-Benz Atego', 194472),
(23, 'MNL8K57', 'Volkswagen Constellation', 161758),
(24, 'GDF1X82', 'Iveco Daily', 114447),
(25, 'THP8T41', 'Iveco Daily', 156318),
(26, 'FEA8E40', 'Volvo FH 540', 291119),
(27, 'HYQ7D09', 'Volkswagen Constellation', 247099),
(28, 'MIZ4P11', 'Ford Cargo', 258816),
(29, 'BQB2Z94', 'Scania R450', 131123),
(30, 'DTP9H86', 'MAN TGX', 233113),
(31, 'HPL9T09', 'Scania R450', 109940),
(32, 'QGC3F81', 'Mercedes-Benz Actros', 2402),
(33, 'KRM0H44', 'MAN TGX', 38318),
(34, 'RYU9V36', 'Scania R450', 286507),
(35, 'FDG2C02', 'Volkswagen Constellation', 299428),
(36, 'XLM4W64', 'Volvo VM 270', 284105),
(37, 'MCB6X59', 'Volkswagen Constellation', 14560),
(38, 'CZV9S04', 'Mercedes-Benz Atego', 22092),
(39, 'TEN7I29', 'Ford Cargo', 258805),
(40, 'ZMK5V12', 'DAF XF', 216820),
(41, 'SHY8B71', 'DAF XF', 133329),
(42, 'IZK8A87', 'Ford Cargo', 29418),
(43, 'EJT7Y03', 'Volkswagen Constellation', 288949),
(44, 'DHW7D09', 'Iveco Daily', 84035),
(45, 'IAK3D71', 'Mercedes-Benz Actros', 262292),
(46, 'YHS6P73', 'MAN TGX', 290021),
(47, 'DEP2C46', 'DAF XF', 267200),
(48, 'GAS9S72', 'MAN TGX', 283371),
(49, 'MIT6O53', 'Iveco Daily', 201787),
(50, 'GUB7W66', 'Mercedes-Benz Actros', 260694),
(51, 'ZDZ5D71', 'Volvo VM 270', 240561),
(52, 'ADW2C74', 'DAF XF', 209395),
(53, 'QWW8M57', 'Volvo VM 270', 19821),
(54, 'QGR4H16', 'Scania R450', 53694),
(55, 'LSX0K04', 'DAF XF', 197524),
(56, 'LGK2F21', 'Mercedes-Benz Atego', 201563),
(57, 'QGX2H74', 'MAN TGX', 134864),
(58, 'RXM4V82', 'Scania R450', 232593),
(59, 'YZH6W47', 'Volkswagen Constellation', 105447),
(60, 'ZWC6S59', 'Volkswagen Constellation', 155785),
(61, 'AVK0S09', 'MAN TGX', 151048),
(62, 'UFU3U39', 'Volkswagen Constellation', 72711),
(63, 'QXQ4Z70', 'Mercedes-Benz Atego', 192292),
(64, 'TCH6F32', 'Volvo VM 270', 192814),
(65, 'NXV4P45', 'Scania R450', 246540),
(66, 'ZDZ6Z85', 'Scania R450', 207870),
(67, 'ANL4S65', 'Scania R450', 123590),
(68, 'MQY5T31', 'MAN TGX', 159434),
(69, 'QDB0J71', 'Scania R450', 124102),
(70, 'XDL8N92', 'Ford Cargo', 52915),
(71, 'VQY4B53', 'MAN TGX', 234148),
(72, 'YWC5R50', 'Ford Cargo', 145641),
(73, 'EDW7C39', 'Volvo FH 540', 27517),
(74, 'UGD9G18', 'Iveco Daily', 114220),
(75, 'VGU9A42', 'Mercedes-Benz Actros', 284228),
(76, 'GER0E05', 'Iveco Daily', 170749),
(77, 'AGD6Q11', 'MAN TGX', 236025),
(78, 'UNC8H90', 'Volvo VM 270', 159141),
(79, 'LZB7M61', 'MAN TGX', 233554),
(80, 'BCP1E49', 'Mercedes-Benz Atego', 288496),
(81, 'SJP4O89', 'Ford Cargo', 52998),
(82, 'UCR8X36', 'MAN TGX', 120796),
(83, 'KVK1K65', 'Volkswagen Constellation', 197241),
(84, 'YRM1C16', 'Scania R450', 196374),
(85, 'VOP8R51', 'Ford Cargo', 186387),
(86, 'WYK0J94', 'DAF XF', 55316),
(87, 'PFR3D58', 'DAF XF', 61232),
(88, 'TOU8Y99', 'Volvo VM 270', 14764),
(89, 'PRS0F44', 'DAF XF', 185037),
(90, 'AWO6C20', 'Scania R450', 279125),
(91, 'FKI5J59', 'Mercedes-Benz Atego', 45541),
(92, 'WET0V14', 'MAN TGX', 223305),
(93, 'MLH8D56', 'Scania R450', 149502),
(94, 'RPN4B36', 'Mercedes-Benz Atego', 29721),
(95, 'AHF2Y44', 'DAF XF', 63906),
(96, 'ATE6R38', 'Volvo VM 270', 186685),
(97, 'BWB0O15', 'Mercedes-Benz Atego', 226068),
(98, 'OSK1M05', 'Mercedes-Benz Actros', 242223),
(99, 'VXC1H69', 'Ford Cargo', 275707),
(100, 'CWT3K21', 'Volvo VM 270', 60782);
 

INSERT INTO funcionarios (id_funcionario, nome, cpf, habilitacao, cargo) VALUES
(1, 'Helena Gomes', '17096455686', 'D', 'Mecânico'),
(2, 'Ursula Pereira', '34080886545', 'E', 'Motorista'),
(3, 'Camila Rocha', '51244513243', 'D', 'Motorista'),
(4, 'Vitor Oliveira', '69366170563', 'B', 'Auxiliar de Logística'),
(5, 'Felipe Barbosa', '91275575686', 'D', 'Supervisor de Frota'),
(6, 'João Costa', '77229791654', 'AB', 'Supervisor de Frota'),
(7, 'Gustavo Gomes', '75101458098', 'AB', 'Motorista'),
(8, 'Aline Souza', '86712861740', 'A', 'Motorista'),
(9, 'Quésia Ferreira', '26608456572', 'A', 'Auxiliar de Logística'),
(10, 'Wesley Rodrigues', '53469207376', 'D', 'Mecânico'),
(11, 'Isabela Souza', '20109595271', 'AB', 'Motorista'),
(12, 'Vitor Almeida', '95870685306', 'AB', 'Supervisor de Frota'),
(13, 'Marcelo Barbosa', '64571086412', 'E', 'Mecânico'),
(14, 'Ximena Melo', '53621743522', 'C', 'Ajudante'),
(15, 'Natália Nascimento', '75221771329', 'B', 'Ajudante'),
(16, 'Fábio Silva', '37444513045', 'B', 'Auxiliar de Logística'),
(17, 'Larissa Costa', '92952019266', 'A', 'Auxiliar de Logística'),
(18, 'Karina Rocha', '97225608563', 'B', 'Supervisor de Frota'),
(19, 'Thiago Ribeiro', '37789135342', 'B', 'Ajudante'),
(20, 'Gabriela Souza', '45430959230', 'C', 'Auxiliar de Logística'),
(21, 'Elaine Nascimento', '05323458661', 'A', 'Supervisor de Frota'),
(22, 'Ximena Lima', '13446536197', 'AB', 'Auxiliar de Logística'),
(23, 'Vitor Gomes', '57760497757', 'D', 'Supervisor de Frota'),
(24, 'Karina Gomes', '44256487755', 'E', 'Supervisor de Frota'),
(25, 'Helena Melo', '92299776445', 'E', 'Mecânico'),
(26, 'Sabrina Santos', '96728252172', 'A', 'Auxiliar de Logística'),
(27, 'Otávio Rodrigues', '68467220762', 'E', 'Motorista'),
(28, 'Lucas Barbosa', '19295498411', 'B', 'Supervisor de Frota'),
(29, 'Quésia Costa', '06113222793', 'E', 'Auxiliar de Logística'),
(30, 'Ana Almeida', '69329449379', 'D', 'Ajudante'),
(31, 'Paula Dias', '25184674840', 'B', 'Auxiliar de Logística'),
(32, 'Aline Ribeiro', '04750894211', 'E', 'Supervisor de Frota'),
(33, 'Ximena Melo', '57200265582', 'AB', 'Ajudante'),
(34, 'Rafael Ferreira', '46820457719', 'B', 'Auxiliar de Logística'),
(35, 'Ursula Rocha', '55716503635', 'E', 'Supervisor de Frota'),
(36, 'Aline Pereira', '59512269807', 'B', 'Motorista'),
(37, 'Rafael Melo', '39217779673', 'B', 'Auxiliar de Logística'),
(38, 'Ursula Nascimento', '87732308705', 'D', 'Auxiliar de Logística'),
(39, 'Aline Nascimento', '74774731518', 'E', 'Motorista'),
(40, 'Helena Souza', '40699605407', 'D', 'Mecânico'),
(41, 'Bruno Gomes', '82334592686', 'E', 'Motorista'),
(42, 'Felipe Melo', '58050288400', 'AB', 'Auxiliar de Logística'),
(43, 'Kevin Souza', '28383719759', 'A', 'Motorista'),
(44, 'Bernardo Rodrigues', '25315372202', 'C', 'Ajudante'),
(45, 'Yasmin Lima', '14540305332', 'C', 'Motorista'),
(46, 'Juliana Rodrigues', '04440226511', 'AB', 'Motorista'),
(47, 'Zeca Lima', '92399264523', 'C', 'Mecânico'),
(48, 'Hugo Rocha', '87446267709', 'C', 'Auxiliar de Logística'),
(49, 'Zeca Martins', '16566937102', 'E', 'Auxiliar de Logística'),
(50, 'Juliana Rocha', '42908733753', 'A', 'Supervisor de Frota'),
(51, 'Camila Lima', '53447616378', 'C', 'Auxiliar de Logística'),
(52, 'Bernardo Melo', '11649333134', 'B', 'Mecânico'),
(53, 'Natália Rocha', '35544599112', 'B', 'Mecânico'),
(54, 'Camila Dias', '64840072251', 'C', 'Auxiliar de Logística'),
(55, 'Fábio Martins', '24762802808', 'A', 'Ajudante'),
(56, 'Nicolas Rocha', '55192595981', 'C', 'Motorista'),
(57, 'Rafael Pereira', '30774768445', 'E', 'Motorista'),
(58, 'Diego Araújo', '51878706809', 'B', 'Supervisor de Frota'),
(59, 'Diego Silva', '66067740020', 'D', 'Ajudante'),
(60, 'Helena Ribeiro', '71381771915', 'A', 'Auxiliar de Logística'),
(61, 'Karina Ribeiro', '53931205667', 'E', 'Motorista'),
(62, 'Thiago Ferreira', '26080333845', 'B', 'Supervisor de Frota'),
(63, 'Eduarda Silva', '74465100991', 'AB', 'Supervisor de Frota'),
(64, 'Larissa Oliveira', '06610104358', 'AB', 'Ajudante'),
(65, 'Ximena Pereira', '45081178617', 'A', 'Motorista'),
(66, 'Ana Rodrigues', '29385160250', 'C', 'Motorista'),
(67, 'Diego Nascimento', '72399775719', 'A', 'Ajudante'),
(68, 'Igor Araújo', '99120284847', 'D', 'Motorista'),
(69, 'Gustavo Pereira', '93834291711', 'C', 'Supervisor de Frota'),
(70, 'Ursula Barbosa', '83762817930', 'AB', 'Mecânico'),
(71, 'Lucas Silva', '07214690590', 'A', 'Ajudante'),
(72, 'Camila Pereira', '06121280622', 'C', 'Auxiliar de Logística'),
(73, 'Elaine Souza', '73549531328', 'AB', 'Motorista'),
(74, 'Elaine Gomes', '59399123735', 'E', 'Mecânico'),
(75, 'Kevin Rocha', '22509217983', 'A', 'Ajudante'),
(76, 'Larissa Pereira', '11979619697', 'B', 'Auxiliar de Logística'),
(77, 'Lucas Melo', '38661430336', 'A', 'Mecânico'),
(78, 'Camila Silva', '79843514866', 'B', 'Supervisor de Frota'),
(79, 'Eduarda Souza', '58056409181', 'A', 'Mecânico'),
(80, 'Nicolas Ferreira', '54000864026', 'A', 'Supervisor de Frota'),
(81, 'Hugo Nascimento', '10428516068', 'C', 'Auxiliar de Logística'),
(82, 'Otávio Martins', '38055591949', 'B', 'Ajudante'),
(83, 'Mariana Pereira', '33324876544', 'B', 'Auxiliar de Logística'),
(84, 'Larissa Rocha', '54146643860', 'C', 'Mecânico'),
(85, 'Ximena Silva', '24612877885', 'B', 'Motorista'),
(86, 'Thiago Gomes', '49728561035', 'B', 'Supervisor de Frota'),
(87, 'Larissa Martins', '72222658964', 'B', 'Ajudante'),
(88, 'Marcelo Silva', '46831568366', 'AB', 'Motorista'),
(89, 'Elaine Oliveira', '88666769243', 'A', 'Auxiliar de Logística'),
(90, 'Kevin Ferreira', '01287163037', 'AB', 'Supervisor de Frota'),
(91, 'Vitor Araújo', '41165481939', 'C', 'Ajudante'),
(92, 'Ursula Costa', '51771444405', 'E', 'Mecânico'),
(93, 'Ana Lima', '53009455461', 'C', 'Mecânico'),
(94, 'Mariana Costa', '36082509660', 'E', 'Motorista'),
(95, 'Aline Ribeiro', '62618171111', 'B', 'Mecânico'),
(96, 'Helena Ferreira', '06986105712', 'B', 'Supervisor de Frota'),
(97, 'Sabrina Almeida', '88016389273', 'AB', 'Ajudante'),
(98, 'Hugo Melo', '19454676887', 'B', 'Supervisor de Frota'),
(99, 'Fábio Santos', '96357062363', 'D', 'Auxiliar de Logística'),
(100, 'Daniel Silva', '02642484841', 'C', 'Motorista');
 

INSERT INTO entregas (id_entrega, id_rota, id_cliente, id_veiculo, id_funcionario, status) VALUES
(1, 14, 52, 53, 5, 'Atrasada'),
(2, 71, 1, 12, 78, 'Atrasada'),
(3, 82, 39, 66, 72, 'Em trânsito'),
(4, 84, 86, 59, 44, 'Entregue'),
(5, 7, 29, 59, 43, 'Atrasada'),
(6, 99, 80, 77, 61, 'Entregue'),
(7, 92, 58, 15, 13, 'Em trânsito'),
(8, 1, 44, 46, 82, 'Entregue'),
(9, 71, 67, 48, 90, 'Pendente'),
(10, 6, 22, 64, 18, 'Cancelada'),
(11, 14, 33, 79, 26, 'Em trânsito'),
(12, 16, 51, 28, 59, 'Em trânsito'),
(13, 92, 44, 14, 97, 'Cancelada'),
(14, 6, 82, 87, 76, 'Pendente'),
(15, 99, 58, 59, 85, 'Atrasada'),
(16, 65, 18, 64, 1, 'Atrasada'),
(17, 95, 7, 71, 56, 'Atrasada'),
(18, 62, 66, 100, 23, 'Atrasada'),
(19, 23, 94, 17, 14, 'Cancelada'),
(20, 85, 77, 78, 42, 'Atrasada'),
(21, 50, 54, 78, 89, 'Em trânsito'),
(22, 36, 51, 44, 38, 'Cancelada'),
(23, 18, 18, 53, 78, 'Atrasada'),
(24, 39, 90, 71, 41, 'Atrasada'),
(25, 81, 28, 26, 27, 'Atrasada'),
(26, 92, 38, 88, 45, 'Em trânsito'),
(27, 91, 84, 23, 65, 'Atrasada'),
(28, 89, 82, 42, 91, 'Pendente'),
(29, 98, 46, 72, 62, 'Atrasada'),
(30, 74, 86, 91, 54, 'Atrasada'),
(31, 37, 55, 2, 67, 'Pendente'),
(32, 4, 49, 19, 7, 'Pendente'),
(33, 26, 35, 97, 21, 'Entregue'),
(34, 88, 33, 19, 8, 'Entregue'),
(35, 27, 97, 70, 5, 'Entregue'),
(36, 58, 14, 79, 87, 'Atrasada'),
(37, 29, 96, 83, 72, 'Cancelada'),
(38, 31, 66, 90, 37, 'Pendente'),
(39, 49, 50, 54, 88, 'Entregue'),
(40, 71, 7, 2, 96, 'Entregue'),
(41, 26, 80, 100, 57, 'Em trânsito'),
(42, 82, 91, 91, 83, 'Entregue'),
(43, 97, 76, 70, 95, 'Atrasada'),
(44, 26, 100, 93, 25, 'Entregue'),
(45, 58, 23, 88, 10, 'Em trânsito'),
(46, 23, 95, 66, 16, 'Cancelada'),
(47, 6, 55, 36, 72, 'Entregue'),
(48, 17, 21, 75, 33, 'Pendente'),
(49, 43, 60, 91, 20, 'Pendente'),
(50, 20, 42, 77, 7, 'Atrasada'),
(51, 85, 39, 63, 74, 'Atrasada'),
(52, 46, 10, 91, 41, 'Atrasada'),
(53, 29, 24, 67, 9, 'Atrasada'),
(54, 21, 54, 70, 69, 'Cancelada'),
(55, 12, 45, 29, 28, 'Entregue'),
(56, 43, 47, 38, 28, 'Atrasada'),
(57, 68, 61, 72, 97, 'Pendente'),
(58, 15, 86, 45, 58, 'Em trânsito'),
(59, 83, 79, 80, 32, 'Pendente'),
(60, 88, 42, 49, 15, 'Cancelada'),
(61, 33, 70, 93, 37, 'Pendente'),
(62, 67, 99, 48, 66, 'Atrasada'),
(63, 58, 63, 6, 38, 'Em trânsito'),
(64, 42, 66, 11, 13, 'Em trânsito'),
(65, 99, 69, 69, 1, 'Pendente'),
(66, 27, 86, 81, 100, 'Em trânsito'),
(67, 88, 55, 14, 27, 'Atrasada'),
(68, 90, 95, 100, 56, 'Pendente'),
(69, 96, 88, 20, 4, 'Cancelada'),
(70, 92, 43, 5, 12, 'Pendente'),
(71, 7, 23, 33, 72, 'Pendente'),
(72, 74, 30, 34, 53, 'Cancelada'),
(73, 58, 81, 52, 56, 'Entregue'),
(74, 3, 50, 87, 16, 'Atrasada'),
(75, 1, 83, 93, 80, 'Pendente'),
(76, 97, 96, 75, 6, 'Pendente'),
(77, 46, 65, 14, 38, 'Entregue'),
(78, 78, 12, 37, 98, 'Cancelada'),
(79, 49, 51, 85, 4, 'Cancelada'),
(80, 21, 69, 29, 18, 'Cancelada'),
(81, 70, 38, 82, 19, 'Entregue'),
(82, 87, 94, 83, 48, 'Pendente'),
(83, 71, 72, 19, 16, 'Pendente'),
(84, 1, 74, 77, 51, 'Atrasada'),
(85, 71, 11, 40, 27, 'Entregue'),
(86, 28, 53, 83, 66, 'Em trânsito'),
(87, 21, 24, 29, 79, 'Entregue'),
(88, 25, 15, 24, 86, 'Atrasada'),
(89, 7, 97, 71, 60, 'Atrasada'),
(90, 10, 38, 86, 9, 'Entregue'),
(91, 13, 26, 93, 75, 'Cancelada'),
(92, 43, 46, 17, 86, 'Em trânsito'),
(93, 13, 37, 80, 9, 'Em trânsito'),
(94, 41, 63, 58, 43, 'Atrasada'),
(95, 85, 40, 89, 75, 'Em trânsito'),
(96, 73, 73, 47, 41, 'Cancelada'),
(97, 22, 1, 41, 32, 'Em trânsito'),
(98, 92, 95, 83, 56, 'Entregue'),
(99, 47, 18, 87, 94, 'Entregue'),
(100, 62, 60, 58, 46, 'Entregue');
 
-- manutencao
INSERT INTO manutencao (id_manutencao, id_veiculo, id_funcionario, troca_oleo, quilometragem, data_manutencao) VALUES
(1, 63, 71, TRUE, 93154, '2023-05-28'),
(2, 18, 69, TRUE, 139010, '2023-12-03'),
(3, 3, 65, TRUE, 213407, '2024-01-18'),
(4, 34, 70, FALSE, 78926, '2025-07-08'),
(5, 99, 76, FALSE, 71192, '2026-09-17'),
(6, 12, 51, FALSE, 264280, '2023-11-08'),
(7, 79, 88, TRUE, 270555, '2024-08-06'),
(8, 23, 73, TRUE, 254495, '2025-01-08'),
(9, 98, 63, TRUE, 33957, '2025-06-08'),
(10, 6, 86, TRUE, 272521, '2025-07-16'),
(11, 59, 6, TRUE, 170906, '2023-12-17'),
(12, 82, 36, FALSE, 286396, '2024-07-21'),
(13, 49, 47, TRUE, 271880, '2025-07-08'),
(14, 67, 52, FALSE, 181896, '2026-08-20'),
(15, 1, 65, TRUE, 231633, '2024-04-03'),
(16, 66, 83, FALSE, 111895, '2024-03-06'),
(17, 47, 78, TRUE, 121767, '2026-06-24'),
(18, 15, 62, FALSE, 252145, '2024-10-06'),
(19, 83, 53, TRUE, 128753, '2023-03-19'),
(20, 76, 21, TRUE, 269772, '2023-10-05'),
(21, 8, 22, FALSE, 95391, '2026-10-19'),
(22, 82, 3, FALSE, 45956, '2024-08-20'),
(23, 61, 62, TRUE, 116009, '2026-10-05'),
(24, 75, 99, TRUE, 268808, '2025-03-24'),
(25, 88, 44, FALSE, 37093, '2024-07-13'),
(26, 17, 14, TRUE, 107088, '2026-03-20'),
(27, 13, 23, FALSE, 21466, '2023-02-16'),
(28, 85, 17, TRUE, 227228, '2026-06-28'),
(29, 6, 90, FALSE, 121316, '2026-07-12'),
(30, 76, 95, TRUE, 224078, '2024-05-16'),
(31, 99, 30, TRUE, 149513, '2026-05-07'),
(32, 1, 91, TRUE, 274961, '2023-09-01'),
(33, 49, 84, TRUE, 166623, '2026-06-04'),
(34, 20, 55, FALSE, 137997, '2026-10-12'),
(35, 79, 36, FALSE, 107794, '2026-09-26'),
(36, 72, 62, TRUE, 195098, '2026-05-10'),
(37, 74, 45, FALSE, 73387, '2023-12-08'),
(38, 58, 90, TRUE, 53574, '2024-09-13'),
(39, 44, 71, TRUE, 85273, '2026-11-01'),
(40, 12, 19, FALSE, 229263, '2023-02-09'),
(41, 29, 48, TRUE, 20794, '2026-07-20'),
(42, 84, 67, FALSE, 31127, '2024-11-16'),
(43, 57, 2, TRUE, 272661, '2025-04-02'),
(44, 77, 66, TRUE, 89857, '2023-06-08'),
(45, 84, 1, TRUE, 46530, '2025-07-12'),
(46, 86, 51, FALSE, 106020, '2023-12-23'),
(47, 9, 12, FALSE, 294136, '2025-06-27'),
(48, 36, 29, TRUE, 239424, '2026-10-01'),
(49, 34, 23, FALSE, 266414, '2023-09-03'),
(50, 65, 38, FALSE, 62346, '2025-09-27'),
(51, 74, 33, FALSE, 198698, '2026-04-25'),
(52, 44, 100, FALSE, 242550, '2023-08-04'),
(53, 34, 9, FALSE, 116543, '2024-06-14'),
(54, 46, 67, TRUE, 139071, '2024-05-03'),
(55, 52, 87, FALSE, 40860, '2024-08-11'),
(56, 46, 28, FALSE, 96831, '2024-08-24'),
(57, 26, 31, TRUE, 140148, '2024-04-07'),
(58, 32, 80, FALSE, 82786, '2023-02-03'),
(59, 87, 85, FALSE, 4472, '2023-08-12'),
(60, 80, 41, FALSE, 145039, '2026-03-25'),
(61, 66, 36, FALSE, 117440, '2024-01-17'),
(62, 55, 62, TRUE, 264441, '2025-07-28'),
(63, 88, 100, TRUE, 240702, '2023-12-17'),
(64, 59, 41, TRUE, 7197, '2024-07-19'),
(65, 13, 42, FALSE, 137157, '2024-09-09'),
(66, 31, 35, FALSE, 180881, '2025-03-16'),
(67, 55, 27, FALSE, 196197, '2025-07-09'),
(68, 58, 24, TRUE, 120834, '2023-12-09'),
(69, 31, 72, FALSE, 200692, '2024-03-26'),
(70, 95, 20, FALSE, 6107, '2024-07-16'),
(71, 18, 81, FALSE, 256129, '2025-05-18'),
(72, 73, 7, FALSE, 52891, '2024-01-07'),
(73, 33, 61, TRUE, 236853, '2025-05-12'),
(74, 47, 72, FALSE, 181428, '2023-07-04'),
(75, 45, 87, TRUE, 283296, '2024-05-12'),
(76, 42, 87, FALSE, 235320, '2023-07-20'),
(77, 37, 60, TRUE, 88857, '2025-07-21'),
(78, 79, 74, FALSE, 38404, '2023-03-11'),
(79, 30, 41, FALSE, 153754, '2025-10-21'),
(80, 51, 35, FALSE, 191402, '2026-07-06'),
(81, 24, 3, TRUE, 124012, '2025-12-23'),
(82, 96, 11, TRUE, 88509, '2026-02-04'),
(83, 9, 61, TRUE, 14822, '2026-09-25'),
(84, 11, 14, FALSE, 82408, '2023-11-13'),
(85, 40, 30, TRUE, 149989, '2026-11-05'),
(86, 17, 68, TRUE, 15979, '2023-11-12'),
(87, 42, 61, FALSE, 284421, '2025-09-15'),
(88, 18, 90, TRUE, 240360, '2026-09-21'),
(89, 82, 69, FALSE, 183016, '2026-09-08'),
(90, 12, 57, FALSE, 192775, '2026-05-05'),
(91, 39, 2, TRUE, 275368, '2024-06-10'),
(92, 61, 69, TRUE, 258913, '2026-05-01'),
(93, 99, 56, FALSE, 122223, '2023-09-12'),
(94, 25, 53, FALSE, 207963, '2024-03-23'),
(95, 95, 83, FALSE, 199368, '2024-05-03'),
(96, 55, 81, TRUE, 271852, '2025-05-21'),
(97, 96, 69, FALSE, 217480, '2024-02-06'),
(98, 18, 38, TRUE, 239730, '2026-05-23'),
(99, 80, 63, TRUE, 169109, '2023-03-02'),
(100, 69, 3, TRUE, 54620, '2025-05-05');
 
-- consumo_combustivel
INSERT INTO consumo_combustivel (id_consumo, id_veiculo, id_funcionario, litros, km_percorrido, data) VALUES
(1, 92, 57, '377.2', 526, '2023-03-01'),
(2, 64, 28, '203.86', 688, '2026-06-15'),
(3, 90, 5, '198.61', 1777, '2024-01-09'),
(4, 100, 51, '82.12', 1012, '2024-04-27'),
(5, 33, 49, '422.71', 299, '2024-07-25'),
(6, 57, 32, '381.93', 118, '2024-08-24'),
(7, 99, 13, '284.51', 476, '2026-07-22'),
(8, 40, 42, '121.38', 1541, '2023-12-18'),
(9, 67, 16, '163.99', 1357, '2025-04-12'),
(10, 7, 86, '148.0', 281, '2024-11-14'),
(11, 42, 2, '125.31', 615, '2023-07-26'),
(12, 32, 2, '485.98', 1240, '2026-12-20'),
(13, 20, 48, '396.86', 559, '2024-08-03'),
(14, 88, 80, '202.29', 1605, '2023-01-12'),
(15, 83, 20, '365.6', 1670, '2023-03-16'),
(16, 30, 41, '491.75', 1664, '2025-08-24'),
(17, 25, 3, '360.16', 783, '2024-05-02'),
(18, 63, 91, '246.88', 653, '2026-04-19'),
(19, 24, 70, '206.45', 1549, '2026-05-28'),
(20, 77, 71, '122.15', 1137, '2024-08-10'),
(21, 34, 70, '215.2', 51, '2026-12-06'),
(22, 3, 80, '435.57', 1639, '2024-06-24'),
(23, 9, 85, '485.22', 1727, '2026-04-17'),
(24, 88, 64, '394.58', 365, '2025-06-14'),
(25, 83, 42, '99.71', 1121, '2023-01-27'),
(26, 17, 23, '443.07', 463, '2023-08-07'),
(27, 13, 5, '306.96', 1762, '2026-11-16'),
(28, 68, 80, '365.59', 574, '2023-06-08'),
(29, 78, 92, '81.89', 1955, '2024-11-16'),
(30, 11, 60, '410.46', 174, '2025-09-24'),
(31, 54, 48, '407.41', 169, '2025-09-02'),
(32, 94, 10, '425.51', 209, '2024-09-04'),
(33, 13, 93, '153.96', 839, '2024-04-17'),
(34, 85, 32, '306.51', 1990, '2024-09-24'),
(35, 72, 54, '385.75', 1619, '2025-11-15'),
(36, 90, 86, '242.18', 263, '2024-03-18'),
(37, 52, 65, '201.88', 373, '2026-06-11'),
(38, 71, 42, '430.18', 894, '2026-12-11'),
(39, 78, 31, '303.42', 488, '2026-09-24'),
(40, 33, 47, '482.74', 966, '2026-01-24'),
(41, 5, 37, '318.09', 1110, '2024-05-01'),
(42, 39, 29, '146.67', 694, '2023-12-27'),
(43, 36, 71, '280.07', 1218, '2024-02-02'),
(44, 59, 46, '120.25', 592, '2025-10-08'),
(45, 30, 33, '414.98', 238, '2026-10-07'),
(46, 94, 10, '375.61', 1673, '2026-03-16'),
(47, 89, 90, '309.3', 1908, '2023-10-21'),
(48, 39, 5, '378.86', 1230, '2026-02-25'),
(49, 8, 99, '200.48', 1851, '2026-07-28'),
(50, 16, 99, '152.02', 1386, '2023-11-25'),
(51, 81, 49, '74.36', 1123, '2023-06-18'),
(52, 73, 20, '197.07', 1479, '2024-03-02'),
(53, 87, 94, '498.82', 962, '2023-04-14'),
(54, 38, 51, '116.61', 738, '2023-08-19'),
(55, 96, 7, '296.67', 587, '2023-07-17'),
(56, 56, 100, '364.04', 1610, '2024-08-18'),
(57, 26, 63, '227.89', 1220, '2024-09-20'),
(58, 95, 68, '160.81', 196, '2025-07-11'),
(59, 88, 74, '90.32', 1425, '2026-07-12'),
(60, 45, 25, '194.33', 1266, '2023-05-06'),
(61, 45, 79, '419.71', 1694, '2026-10-05'),
(62, 57, 6, '465.9', 528, '2024-11-12'),
(63, 20, 97, '377.82', 225, '2023-12-02'),
(64, 32, 80, '467.03', 1829, '2025-01-11'),
(65, 89, 15, '187.3', 1014, '2023-06-07'),
(66, 95, 69, '145.34', 1169, '2025-09-16'),
(67, 80, 94, '496.54', 1473, '2023-07-19'),
(68, 85, 68, '69.57', 398, '2023-05-07'),
(69, 90, 80, '172.08', 1002, '2023-02-13'),
(70, 85, 35, '348.34', 1919, '2025-02-01'),
(71, 38, 84, '223.94', 829, '2023-06-16'),
(72, 77, 69, '89.61', 457, '2026-09-23'),
(73, 3, 6, '161.33', 1134, '2025-06-16'),
(74, 51, 96, '120.65', 760, '2025-06-21'),
(75, 39, 31, '498.2', 1076, '2025-01-21'),
(76, 33, 50, '450.68', 1718, '2023-09-09'),
(77, 29, 20, '203.8', 854, '2024-02-24'),
(78, 49, 67, '482.27', 1304, '2024-07-08'),
(79, 74, 20, '241.91', 689, '2025-08-18'),
(80, 17, 27, '343.61', 1239, '2024-03-10'),
(81, 89, 91, '454.39', 1912, '2024-07-25'),
(82, 19, 84, '469.86', 1928, '2024-06-03'),
(83, 72, 69, '476.87', 292, '2024-06-27'),
(84, 19, 94, '63.27', 702, '2026-07-10'),
(85, 57, 96, '470.2', 1881, '2025-03-25'),
(86, 25, 14, '109.2', 103, '2025-10-19'),
(87, 79, 30, '318.36', 522, '2023-06-03'),
(88, 89, 100, '264.47', 1078, '2026-12-21'),
(89, 48, 24, '433.46', 1056, '2026-03-06'),
(90, 25, 29, '64.5', 1615, '2023-05-14'),
(91, 29, 96, '352.1', 465, '2024-02-06'),
(92, 57, 79, '270.47', 715, '2026-04-14'),
(93, 52, 100, '68.82', 1555, '2026-12-11'),
(94, 51, 79, '472.61', 1221, '2023-09-04'),
(95, 58, 59, '422.15', 136, '2024-09-18'),
(96, 51, 95, '67.66', 843, '2023-04-10'),
(97, 57, 51, '447.98', 1634, '2025-08-06'),
(98, 55, 38, '325.91', 161, '2024-08-27'),
(99, 83, 58, '90.7', 1075, '2023-03-25'),
(100, 75, 90, '295.88', 855, '2026-06-15');
