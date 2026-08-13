DROP DATABASE IF EXISTS FastBite;

CREATE DATABASE FastBite
CHARACTER SET utf8mb4
COLLATE utf8mb4_unicode_ci;

USE FastBite;


-- =========================================================
-- 1. TABELA CLIENTE
-- =========================================================

CREATE TABLE Cliente (
    cliente_id INT AUTO_INCREMENT PRIMARY KEY,
    nome VARCHAR(100) NOT NULL,
    telefone VARCHAR(20) NOT NULL,
    email VARCHAR(100) NOT NULL UNIQUE,
    senha VARCHAR(255) NOT NULL,
    data_alteracao_senha DATETIME NULL
);


-- =========================================================
-- 2. TABELA RESTAURANTE
-- =========================================================

CREATE TABLE Restaurante (
    restaurante_id INT AUTO_INCREMENT PRIMARY KEY,
    nome VARCHAR(100) NOT NULL,
    endereco VARCHAR(255) NOT NULL,
    telefone VARCHAR(20) NOT NULL,
    categoria VARCHAR(100),
    horario_funcionamento VARCHAR(100),
    latitude DECIMAL(10,8),
    longitude DECIMAL(11,8),
    senha VARCHAR(255) NOT NULL,
    cnpj VARCHAR(18) UNIQUE,

    CONSTRAINT chk_restaurante_latitude
        CHECK (
            latitude IS NULL
            OR latitude BETWEEN -90 AND 90
        ),

    CONSTRAINT chk_restaurante_longitude
        CHECK (
            longitude IS NULL
            OR longitude BETWEEN -180 AND 180
        )
);


-- =========================================================
-- 3. TABELA ENTREGADOR
-- =========================================================

CREATE TABLE Entregador (
    entregador_id INT AUTO_INCREMENT PRIMARY KEY,
    nome VARCHAR(100) NOT NULL,
    telefone VARCHAR(20) NOT NULL,
    veiculo VARCHAR(50),
    estado VARCHAR(30),
    latitude_atual DECIMAL(10,8),
    longitude_atual DECIMAL(11,8),
    senha VARCHAR(255) NOT NULL,
    cnh VARCHAR(20) UNIQUE,

    CONSTRAINT chk_entregador_latitude
        CHECK (
            latitude_atual IS NULL
            OR latitude_atual BETWEEN -90 AND 90
        ),

    CONSTRAINT chk_entregador_longitude
        CHECK (
            longitude_atual IS NULL
            OR longitude_atual BETWEEN -180 AND 180
        )
);


-- =========================================================
-- 4. TABELA CUPOM
-- =========================================================

CREATE TABLE Cupom (
    cupom_id INT AUTO_INCREMENT PRIMARY KEY,
    codigo VARCHAR(30) NOT NULL UNIQUE,
    tipo_desconto VARCHAR(20) NOT NULL,
    valor_desconto DECIMAL(10,2) NOT NULL,
    data_inicio DATE,
    data_fim DATE,
    ativo BOOLEAN NOT NULL DEFAULT TRUE,
    limite_uso INT NOT NULL DEFAULT 1,

    CONSTRAINT chk_cupom_valor
        CHECK (valor_desconto >= 0),

    CONSTRAINT chk_cupom_limite
        CHECK (limite_uso > 0),

    CONSTRAINT chk_cupom_datas
        CHECK (
            data_fim IS NULL
            OR data_inicio IS NULL
            OR data_fim >= data_inicio
        ),

    CONSTRAINT chk_cupom_tipo
        CHECK (
            tipo_desconto IN ('PERCENTUAL', 'VALOR')
        )
);


-- =========================================================
-- 5. TABELA ENDERECO_CLIENTE
-- =========================================================

CREATE TABLE Endereco_cliente (
    endereco_id INT AUTO_INCREMENT PRIMARY KEY,
    cliente_id INT NOT NULL,
    rotulo VARCHAR(50),
    logradouro VARCHAR(150) NOT NULL,
    numero VARCHAR(20),
    complemento VARCHAR(100),
    bairro VARCHAR(100),
    codigo_postal VARCHAR(20),
    latitude DECIMAL(10,8),
    longitude DECIMAL(11,8),

    CONSTRAINT fk_endereco_cliente
        FOREIGN KEY (cliente_id)
        REFERENCES Cliente(cliente_id)
        ON DELETE CASCADE
        ON UPDATE CASCADE,

    CONSTRAINT chk_endereco_latitude
        CHECK (
            latitude IS NULL
            OR latitude BETWEEN -90 AND 90
        ),

    CONSTRAINT chk_endereco_longitude
        CHECK (
            longitude IS NULL
            OR longitude BETWEEN -180 AND 180
        )
);


-- =========================================================
-- 6. TABELA MENU
-- =========================================================

CREATE TABLE Menu (
    menu_id INT AUTO_INCREMENT PRIMARY KEY,
    restaurante_id INT NOT NULL,
    nome VARCHAR(100) NOT NULL,
    data_inicio DATE,
    data_fim DATE,
    ativo BOOLEAN NOT NULL DEFAULT TRUE,

    CONSTRAINT fk_menu_restaurante
        FOREIGN KEY (restaurante_id)
        REFERENCES Restaurante(restaurante_id)
        ON DELETE CASCADE
        ON UPDATE CASCADE,

    CONSTRAINT chk_menu_datas
        CHECK (
            data_fim IS NULL
            OR data_inicio IS NULL
            OR data_fim >= data_inicio
        )
);


-- =========================================================
-- 7. TABELA ITEM_MENU
-- =========================================================

CREATE TABLE Item_menu (
    item_menu_id INT AUTO_INCREMENT PRIMARY KEY,
    menu_id INT NOT NULL,
    nome_prato VARCHAR(100) NOT NULL,
    descricao VARCHAR(255),
    preco DECIMAL(10,2) NOT NULL,
    disponivel BOOLEAN NOT NULL DEFAULT TRUE,
    categoria VARCHAR(50),

    CONSTRAINT fk_item_menu
        FOREIGN KEY (menu_id)
        REFERENCES Menu(menu_id)
        ON DELETE CASCADE
        ON UPDATE CASCADE,

    CONSTRAINT chk_item_menu_preco
        CHECK (preco >= 0)
);


-- =========================================================
-- 8. TABELA PEDIDO
-- =========================================================

CREATE TABLE Pedido (
    pedido_id INT AUTO_INCREMENT PRIMARY KEY,

    cliente_id INT NOT NULL,
    restaurante_id INT NOT NULL,
    entregador_id INT NULL,
    endereco_id INT NOT NULL,
    cupom_id INT NULL,

    data_pedido DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,

    estado VARCHAR(30) NOT NULL DEFAULT 'PENDENTE',

    subtotal DECIMAL(10,2) NOT NULL DEFAULT 0.00,
    taxa_entrega DECIMAL(10,2) NOT NULL DEFAULT 0.00,
    valor_desconto DECIMAL(10,2) NOT NULL DEFAULT 0.00,
    total DECIMAL(10,2) NOT NULL DEFAULT 0.00,

    tempo_estimado VARCHAR(50),
    forma_pagamento VARCHAR(30),

    CONSTRAINT fk_pedido_cliente
        FOREIGN KEY (cliente_id)
        REFERENCES Cliente(cliente_id),

    CONSTRAINT fk_pedido_restaurante
        FOREIGN KEY (restaurante_id)
        REFERENCES Restaurante(restaurante_id),

    CONSTRAINT fk_pedido_entregador
        FOREIGN KEY (entregador_id)
        REFERENCES Entregador(entregador_id)
        ON DELETE SET NULL,

    CONSTRAINT fk_pedido_endereco
        FOREIGN KEY (endereco_id)
        REFERENCES Endereco_cliente(endereco_id),

    CONSTRAINT fk_pedido_cupom
        FOREIGN KEY (cupom_id)
        REFERENCES Cupom(cupom_id)
        ON DELETE SET NULL,

    CONSTRAINT chk_pedido_subtotal
        CHECK (subtotal >= 0),

    CONSTRAINT chk_pedido_taxa
        CHECK (taxa_entrega >= 0),

    CONSTRAINT chk_pedido_desconto
        CHECK (valor_desconto >= 0),

    CONSTRAINT chk_pedido_total
        CHECK (total >= 0)
);


-- =========================================================
-- 9. TABELA ITEM_PEDIDO
-- =========================================================

CREATE TABLE Item_pedido (
    item_pedido_id INT AUTO_INCREMENT PRIMARY KEY,

    pedido_id INT NOT NULL,
    item_menu_id INT NOT NULL,

    quantidade INT NOT NULL,
    preco_unitario DECIMAL(10,2) NOT NULL,
    subtotal DECIMAL(10,2) NOT NULL DEFAULT 0.00,

    observacao VARCHAR(255),

    CONSTRAINT fk_item_pedido
        FOREIGN KEY (pedido_id)
        REFERENCES Pedido(pedido_id)
        ON DELETE CASCADE,

    CONSTRAINT fk_item_menu_pedido
        FOREIGN KEY (item_menu_id)
        REFERENCES Item_menu(item_menu_id),

    CONSTRAINT chk_item_pedido_quantidade
        CHECK (quantidade > 0),

    CONSTRAINT chk_item_pedido_preco
        CHECK (preco_unitario >= 0),

    CONSTRAINT chk_item_pedido_subtotal
        CHECK (subtotal >= 0)
);


-- =========================================================
-- 10. TABELA AVALIACAO
-- =========================================================

CREATE TABLE Avaliacao (
    avaliacao_id INT AUTO_INCREMENT PRIMARY KEY,

    pedido_id INT NOT NULL UNIQUE,

    nota_restaurante INT,
    nota_entregador INT,

    comentario VARCHAR(255),

    data_avaliacao DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,

    editada BOOLEAN NOT NULL DEFAULT FALSE,

    CONSTRAINT fk_avaliacao_pedido
        FOREIGN KEY (pedido_id)
        REFERENCES Pedido(pedido_id)
        ON DELETE CASCADE,

    CONSTRAINT chk_avaliacao_restaurante
        CHECK (
            nota_restaurante IS NULL
            OR nota_restaurante BETWEEN 1 AND 5
        ),

    CONSTRAINT chk_avaliacao_entregador
        CHECK (
            nota_entregador IS NULL
            OR nota_entregador BETWEEN 1 AND 5
        )
);


-- =========================================================
-- 11. TABELA HISTORICO_SENHA
-- =========================================================

CREATE TABLE Historico_Senha (
    historico_id INT AUTO_INCREMENT PRIMARY KEY,

    cliente_id INT NOT NULL,

    senha_antiga VARCHAR(255) NOT NULL,

    data_alteracao DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_historico_cliente
        FOREIGN KEY (cliente_id)
        REFERENCES Cliente(cliente_id)
        ON DELETE CASCADE
);


-- =========================================================
-- INDICES
-- =========================================================

CREATE INDEX idx_endereco_cliente
ON Endereco_cliente(cliente_id);

CREATE INDEX idx_menu_restaurante
ON Menu(restaurante_id);

CREATE INDEX idx_item_menu_menu
ON Item_menu(menu_id);

CREATE INDEX idx_pedido_cliente
ON Pedido(cliente_id);

CREATE INDEX idx_pedido_restaurante
ON Pedido(restaurante_id);

CREATE INDEX idx_pedido_entregador
ON Pedido(entregador_id);

CREATE INDEX idx_item_pedido_pedido
ON Item_pedido(pedido_id);


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


-- =========================================================
-- STORED PROCEDURES
-- UMA PROCEDURE PARA CADA TABELA
-- TOTAL: 11 PROCEDURES
-- =========================================================

DELIMITER $$


-- =========================================================
-- 1. CLIENTE
-- =========================================================

CREATE PROCEDURE sp_inserir_cliente(
    IN p_nome VARCHAR(100),
    IN p_telefone VARCHAR(20),
    IN p_email VARCHAR(100),
    IN p_senha VARCHAR(255)
)
BEGIN

    INSERT INTO Cliente (
        nome,
        telefone,
        email,
        senha
    )
    VALUES (
        p_nome,
        p_telefone,
        p_email,
        p_senha
    );

END$$


-- =========================================================
-- 2. RESTAURANTE
-- =========================================================

CREATE PROCEDURE sp_inserir_restaurante(
    IN p_nome VARCHAR(100),
    IN p_endereco VARCHAR(255),
    IN p_telefone VARCHAR(20),
    IN p_categoria VARCHAR(100),
    IN p_horario_funcionamento VARCHAR(100),
    IN p_latitude DECIMAL(10,8),
    IN p_longitude DECIMAL(11,8),
    IN p_senha VARCHAR(255),
    IN p_cnpj VARCHAR(18)
)
BEGIN

    INSERT INTO Restaurante (
        nome,
        endereco,
        telefone,
        categoria,
        horario_funcionamento,
        latitude,
        longitude,
        senha,
        cnpj
    )
    VALUES (
        p_nome,
        p_endereco,
        p_telefone,
        p_categoria,
        p_horario_funcionamento,
        p_latitude,
        p_longitude,
        p_senha,
        p_cnpj
    );

END$$


-- =========================================================
-- 3. ENTREGADOR
-- =========================================================

CREATE PROCEDURE sp_inserir_entregador(
    IN p_nome VARCHAR(100),
    IN p_telefone VARCHAR(20),
    IN p_veiculo VARCHAR(50),
    IN p_estado VARCHAR(30),
    IN p_latitude_atual DECIMAL(10,8),
    IN p_longitude_atual DECIMAL(11,8),
    IN p_senha VARCHAR(255),
    IN p_cnh VARCHAR(20)
)
BEGIN

    INSERT INTO Entregador (
        nome,
        telefone,
        veiculo,
        estado,
        latitude_atual,
        longitude_atual,
        senha,
        cnh
    )
    VALUES (
        p_nome,
        p_telefone,
        p_veiculo,
        p_estado,
        p_latitude_atual,
        p_longitude_atual,
        p_senha,
        p_cnh
    );

END$$


-- =========================================================
-- 4. CUPOM
-- =========================================================

CREATE PROCEDURE sp_inserir_cupom(
    IN p_codigo VARCHAR(30),
    IN p_tipo_desconto VARCHAR(20),
    IN p_valor_desconto DECIMAL(10,2),
    IN p_data_inicio DATE,
    IN p_data_fim DATE,
    IN p_ativo BOOLEAN,
    IN p_limite_uso INT
)
BEGIN

    INSERT INTO Cupom (
        codigo,
        tipo_desconto,
        valor_desconto,
        data_inicio,
        data_fim,
        ativo,
        limite_uso
    )
    VALUES (
        p_codigo,
        p_tipo_desconto,
        p_valor_desconto,
        p_data_inicio,
        p_data_fim,
        p_ativo,
        p_limite_uso
    );

END$$


-- =========================================================
-- 5. ENDERECO_CLIENTE
-- =========================================================

CREATE PROCEDURE sp_inserir_endereco_cliente(
    IN p_cliente_id INT,
    IN p_rotulo VARCHAR(50),
    IN p_logradouro VARCHAR(150),
    IN p_numero VARCHAR(20),
    IN p_complemento VARCHAR(100),
    IN p_bairro VARCHAR(100),
    IN p_codigo_postal VARCHAR(20),
    IN p_latitude DECIMAL(10,8),
    IN p_longitude DECIMAL(11,8)
)
BEGIN

    INSERT INTO Endereco_cliente (
        cliente_id,
        rotulo,
        logradouro,
        numero,
        complemento,
        bairro,
        codigo_postal,
        latitude,
        longitude
    )
    VALUES (
        p_cliente_id,
        p_rotulo,
        p_logradouro,
        p_numero,
        p_complemento,
        p_bairro,
        p_codigo_postal,
        p_latitude,
        p_longitude
    );

END$$


-- =========================================================
-- 6. MENU
-- =========================================================

CREATE PROCEDURE sp_inserir_menu(
    IN p_restaurante_id INT,
    IN p_nome VARCHAR(100),
    IN p_data_inicio DATE,
    IN p_data_fim DATE,
    IN p_ativo BOOLEAN
)
BEGIN

    INSERT INTO Menu (
        restaurante_id,
        nome,
        data_inicio,
        data_fim,
        ativo
    )
    VALUES (
        p_restaurante_id,
        p_nome,
        p_data_inicio,
        p_data_fim,
        p_ativo
    );

END$$


-- =========================================================
-- 7. ITEM_MENU
-- =========================================================

CREATE PROCEDURE sp_inserir_item_menu(
    IN p_menu_id INT,
    IN p_nome_prato VARCHAR(100),
    IN p_descricao VARCHAR(255),
    IN p_preco DECIMAL(10,2),
    IN p_disponivel BOOLEAN,
    IN p_categoria VARCHAR(50)
)
BEGIN

    INSERT INTO Item_menu (
        menu_id,
        nome_prato,
        descricao,
        preco,
        disponivel,
        categoria
    )
    VALUES (
        p_menu_id,
        p_nome_prato,
        p_descricao,
        p_preco,
        p_disponivel,
        p_categoria
    );

END$$


-- =========================================================
-- 8. PEDIDO
-- =========================================================

CREATE PROCEDURE sp_inserir_pedido(
    IN p_cliente_id INT,
    IN p_restaurante_id INT,
    IN p_entregador_id INT,
    IN p_endereco_id INT,
    IN p_cupom_id INT,
    IN p_taxa_entrega DECIMAL(10,2),
    IN p_valor_desconto DECIMAL(10,2),
    IN p_tempo_estimado VARCHAR(50),
    IN p_forma_pagamento VARCHAR(30)
)
BEGIN

    IF p_taxa_entrega < 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'A taxa de entrega nao pode ser negativa';
    END IF;

    IF p_valor_desconto < 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'O valor do desconto nao pode ser negativo';
    END IF;

    INSERT INTO Pedido (
        cliente_id,
        restaurante_id,
        entregador_id,
        endereco_id,
        cupom_id,
        taxa_entrega,
        valor_desconto,
        tempo_estimado,
        forma_pagamento
    )
    VALUES (
        p_cliente_id,
        p_restaurante_id,
        p_entregador_id,
        p_endereco_id,
        p_cupom_id,
        p_taxa_entrega,
        p_valor_desconto,
        p_tempo_estimado,
        p_forma_pagamento
    );

END$$


-- =========================================================
-- 9. ITEM_PEDIDO
-- =========================================================

CREATE PROCEDURE sp_inserir_item_pedido(
    IN p_pedido_id INT,
    IN p_item_menu_id INT,
    IN p_quantidade INT,
    IN p_preco_unitario DECIMAL(10,2),
    IN p_observacao VARCHAR(255)
)
BEGIN

    IF p_quantidade <= 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'A quantidade deve ser maior que zero';
    END IF;

    IF p_preco_unitario < 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'O preco unitario nao pode ser negativo';
    END IF;

    INSERT INTO Item_pedido (
        pedido_id,
        item_menu_id,
        quantidade,
        preco_unitario,
        subtotal,
        observacao
    )
    VALUES (
        p_pedido_id,
        p_item_menu_id,
        p_quantidade,
        p_preco_unitario,
        p_quantidade * p_preco_unitario,
        p_observacao
    );

END$$


-- =========================================================
-- 10. AVALIACAO
-- =========================================================

CREATE PROCEDURE sp_inserir_avaliacao(
    IN p_pedido_id INT,
    IN p_nota_restaurante INT,
    IN p_nota_entregador INT,
    IN p_comentario VARCHAR(255)
)
BEGIN

    INSERT INTO Avaliacao (
        pedido_id,
        nota_restaurante,
        nota_entregador,
        comentario
    )
    VALUES (
        p_pedido_id,
        p_nota_restaurante,
        p_nota_entregador,
        p_comentario
    );

END$$


-- =========================================================
-- 11. HISTORICO_SENHA
-- =========================================================

CREATE PROCEDURE sp_inserir_historico_senha(
    IN p_cliente_id INT,
    IN p_senha_antiga VARCHAR(255)
)
BEGIN

    INSERT INTO Historico_Senha (
        cliente_id,
        senha_antiga,
        data_alteracao
    )
    VALUES (
        p_cliente_id,
        p_senha_antiga,
        NOW()
    );

END$$


DELIMITER ;


-- =========================================================
-- VERIFICACAO DAS PROCEDURES
-- =========================================================

SHOW PROCEDURE STATUS
WHERE Db = 'FastBite';


-- =========================================================
-- VERIFICACAO DOS TRIGGERS
-- =========================================================

SHOW TRIGGERS FROM FastBite;

INSERT INTO Cliente (nome, telefone, email, senha) VALUES
('Brenda Alves', '(55) 62933-2181', 'brenda.1@gmail.com', 'f6450ec13214c107ada029ba7cdbda865e4b436b844a1b0264a2c6b0db8c'),
('Igor Montenegro', '(55) 14983-8637', 'igor.2@gmail.com', 'f3293232dc4f6f82f27fcb1f5bdf4517cd40e79a4f79ddd795c7d117d365'),
('Otávio Fernandes', '(55) 62923-5116', 'otávio.3@terra.com.br', '33e3f996588677ce376555d9705c6a4e0783924ef7b0f92b335fa735c429'),
('Raul Nascimento', '(55) 32961-8495', 'raul.4@hotmail.com', 'ce581490b64b1af57f3dd921667d393f9fc105954821bc879a05e65f3f53'),
('João Vitor Barros', '(55) 49916-4752', 'joão.5@uol.com.br', '359413d44cbe6faaa20c5f549461160776a4524b0d38d83b83af216a680f'),
('Dra. Ana Sophia Pereira', '(55) 41983-2764', 'dra..6@terra.com.br', '9abb08b2f45a28dfa45524bc45d5ec303da9d6326e62a50677e55e715175'),
('Ian Andrade', '(55) 67964-1395', 'ian.7@outlook.com.br', '8bab06b75ea1b6d9d5d6ebb813d2ee54e55dee4cc38f4f7a33c32438ad40'),
('Natália Casa Grande', '(55) 55923-8849', 'natália.8@outlook.com.br', 'd7dab5e54f99a4788e47e6c7921417c6b8ab37d0f4b40772dfd80d8c30d2'),
('Thomas Monteiro', '(55) 24901-2269', 'thomas.9@outlook.com.br', '338722e96dad3aae7568873eb3b6e1944c3f951dc876e9865a963bee68f4'),
('Vitória da Cunha', '(55) 12918-4514', 'vitória.10@live.com', '8feb07941663abf8aa4078ce46845de740374bbcc90feeaa7c883ba0fa33'),
('Dra. Julia Montenegro', '(55) 42981-4893', 'dra..11@yahoo.com.br', 'e69f5501c5357d2352ed9c109733c02aeeeea9359542edea37c655abf1a4'),
('Agatha Peixoto', '(55) 68970-1543', 'agatha.12@hotmail.com', '0dd2b3752d462dc54fd19c5d455f191db04c757a7abf0401213f49600ec0'),
('Ana Lívia Teixeira', '(55) 33927-8248', 'ana.13@uol.com.br', '215e10fcd56d8f84a4647be5e5e5033754a80a52fed17351305f5e0fec34'),
('Dra. Gabriela Silva', '(55) 66965-7871', 'dra..14@hotmail.com', 'e901ca7cf8dd3bd6503db5a64cc84076fdf0c33906ccbf83bfaa5874e493'),
('Heloísa Pastor', '(55) 48901-0310', 'heloísa.15@icloud.com', '9da1e47888c6e67bb2c6a72957ebd53a2ba9ff55f5c658451f6dac613abc'),
('Raquel Cunha', '(55) 33999-7376', 'raquel.16@hotmail.com', '3acd87b37875d988d51f6176792ecbc36fbfbef607e0f54cf375dba217e7'),
('Dr. Noah Martins', '(55) 17910-6513', 'dr..17@icloud.com', '20a872b8c9b0db8dce86954f4d9357d44e1910fba621feeaf2544f39dfe8'),
('Emilly da Mota', '(55) 92931-7810', 'emilly.18@hotmail.com', '2937df3927ae75623104ee316bff86f680cdf572d592d92e03c3995a81ee'),
('Enzo Jesus', '(55) 95973-6026', 'enzo.19@bol.com.br', '3e5ad9b7522721098d872bafdbc8d9474e0ef3e2179adc3e0e4b390e008e'),
('Laura Lima', '(55) 95923-4309', 'laura.20@terra.com.br', 'f963e5fb0b92852a68ef6f57639f7bce55ea9615edf2634331a84856d836'),
('Pietra Montenegro', '(55) 38908-1219', 'pietra.21@outlook.com.br', '94bb856cffa0d9310575f9140e076ea5fb386fe9343c8c355f3412e82d3c'),
('Isadora Pacheco', '(55) 16991-6998', 'isadora.22@uol.com.br', '8ebb7c3fbd8ea46f9820f81bfdf2ada56da8a54b237da185a7115edbcd7d'),
('Sr. João Gonçalves', '(55) 33947-5107', 'sr..23@hotmail.com', '5a24901dd06a3fe588dc559511b8f424f8f714eb439988230beefc670b5f'),
('Thiago da Luz', '(55) 33951-3542', 'thiago.24@bol.com.br', 'a555b4b24dbe50fd91d6762ae7fb6eb25ea5c09dd23b824e4dec5e65b87e'),
('Vitória Albuquerque', '(55) 65912-4118', 'vitória.25@bol.com.br', '2734b32faf7e12838d616da6bdfd3e51f13fb25595445988c62cdf12c962'),
('Sra. Gabrielly Rodrigues', '(55) 55987-4016', 'sra..26@gmail.com', 'd83a71190ba524e3be8001936c79bcbc3a373e51d11688d8fcae5041de22'),
('João Castro', '(55) 88986-8011', 'joão.27@gmail.com', '200acc2aaf9b0d1973ac2157f50a02df893296a392fa00b03f80cd706c83'),
('Clara Lopes', '(55) 33904-5053', 'clara.28@terra.com.br', '6c2f18a3cfb25601a15b31778316886e15672e1bc32f1b970523a780a919'),
('Daniela da Costa', '(55) 38926-0256', 'daniela.29@yahoo.com.br', '7a90ab9f9cb3129285e0462a87d9c8181d14279298abecd0df8960346e76'),
('Mateus Andrade', '(55) 93933-7543', 'mateus.30@uol.com.br', 'ade7a4f64e245716e71ec89621afe6e844ff520554fac255685855936370'),
('Bernardo Vargas', '(55) 62958-6850', 'bernardo.31@yahoo.com.br', '8a356973a80f1c81187e42a1fe8c09c0f79d4ab26b2234f9ac866257d981'),
('Arthur Miguel Caldeira', '(55) 87955-6981', 'arthur.32@uol.com.br', '803a863b748053f9f48a8679edb404f7d3b9a1b9f8adaa1973aab4e0241f'),
('Sra. Agatha Moreira', '(55) 45956-1595', 'sra..33@icloud.com', '797a3e45e9927c4aa1e860d148f6659636626202bebd827a8c96f7d67a77'),
('Lunna Guerra', '(55) 64982-3662', 'lunna.34@bol.com.br', '4998dc43d0bda6c661a2bf5cb19db8c48a3897db4ca64569ec3cb4cd97af'),
('Kevin da Paz', '(55) 46969-9577', 'kevin.35@icloud.com', '36332455688701f7ae84f8587440366dfdcbd5802dc58c2d676884b99b39'),
('Srta. Antonella da Paz', '(55) 98995-1343', 'srta..36@gmail.com', '16c3358d4a84000c02eb7162eedb611082ca581d06aa240a0c219cdba1db'),
('Ana Sophia Marques', '(55) 85993-6763', 'ana.37@hotmail.com', '758cd091cdce57ceebdb6bd6b8b88435f1e12d65d999a1e5d631cb78f75c'),
('Felipe Sampaio', '(55) 99970-8317', 'felipe.38@icloud.com', '5b21bb292e85d9bfbfc1efc2a41956c235a4d0390a17d7c340a3d785ffef'),
('Luiza Sá', '(55) 88998-6872', 'luiza.39@bol.com.br', '20e448942eb44a145354efa14520de531848cc69c8c45e1ef960d254adc1'),
('Kamilly Vargas', '(55) 99973-4714', 'kamilly.40@terra.com.br', '65c725e16a1b506413b44ea25855381a82c631ea7afb38bce31b7e36418d'),
('Anna Liz Carvalho', '(55) 37936-2316', 'anna.41@icloud.com', '383fc9386f9c95a01244756f7348c7c5a51dddb2bbe3806b56d2ff226f38'),
('Gustavo Leão', '(55) 81990-9670', 'gustavo.42@outlook.com.br', '27071083ce628b0a4eb97e95ad6ade77eff8555663609cdda3d9bda3bb45'),
('Zoe Souza', '(55) 48973-4670', 'zoe.43@outlook.com.br', 'eb09451244f742eb9e9105ed978643bbc39ed50a7e95bdb0c69a1245e957'),
('Carolina Pinto', '(55) 14969-9016', 'carolina.44@yahoo.com.br', '3aea504c445177f88435205b4a6f598657fe88375bdb6f40846b027e91aa'),
('Lunna Cunha', '(55) 91955-6464', 'lunna.45@gmail.com', '3b2a91e3f9fb1f3003e7095334d2a10e213459d75bda49b43847df57656c'),
('Luiz Fernando Câmara', '(55) 19900-3309', 'luiz.46@yahoo.com.br', 'cff24b5f86bb5dd7d36acebc918329b8ac67a2c35002865a36a69e5fd745'),
('Henrique Martins', '(55) 54952-9912', 'henrique.47@gmail.com', '3d8cc646563728d63d4ccddb96d9d5ecc5cdf80be6ae80dea6d1cda011ac'),
('Maria Flor Gonçalves', '(55) 45919-3149', 'maria.48@gmail.com', '38d3a823b791bd2c7386a018e6803349e0556351782f2094f88e45d42838'),
('Maria Eduarda Azevedo', '(55) 97950-6716', 'maria.49@yahoo.com.br', '79c3a7b088136ff62d9399f28790bb439b94e482145205dd9c35b02cf5ca'),
('Dra. Júlia Pimenta', '(55) 94976-9453', 'dra..50@live.com', '20385f34ff95450e74ed50fe80eb6a494b234b8d286f3f21aa4d74b2ed67'),
('Maria Helena Fernandes', '(55) 14975-2735', 'maria.51@bol.com.br', '7ca828c0598d3ff30ff683ac187c7ae025896a2ba6173e6a657ddcf5d2b5'),
('Sra. Alexia Moreira', '(55) 44913-6783', 'sra..52@live.com', 'de2aa8bfbc25df04434f2fc0cc74861e15d8e414096fac2ff4fabb5733a4'),
('Juan Câmara', '(55) 83934-9578', 'juan.53@outlook.com.br', '68eb077cae411df533498b17b26feb30de0a79df70c999cc9056321cec86'),
('Luísa Fogaça', '(55) 91944-4313', 'luísa.54@icloud.com', 'b3fde29b1261c8ab0e2206cee6cfb47cc408654e18c84bff2a2e383b0504'),
('Srta. Evelyn Cunha', '(55) 94949-8941', 'srta..55@uol.com.br', '8e98aa2ac5eec90a24b4830d8de2c493633ffb97129119c77fd50e2de807'),
('Anthony Gabriel Santos', '(55) 33940-0842', 'anthony.56@gmail.com', '46298dc2d50c4ac641dd14bcf31c8ce37b8c60b425a855920ccd6e00c7e2'),
('Pietra Macedo', '(55) 71920-4711', 'pietra.57@hotmail.com', 'cab98e13d9c0a7de4d138afdf290867353d35b1112a0366a216892b6e568'),
('Ana Júlia Cassiano', '(55) 37994-1318', 'ana.58@uol.com.br', '80ecf5252b428f56daa770a51e94bf6748d1cc5e15ce8da109b7fe16ea9c'),
('Milena Macedo', '(55) 65996-4990', 'milena.59@uol.com.br', '85a17d92d19a292d84ba9e2203065ff19d0a63c6df213198fa68f6ea74e8'),
('Bruno Castro', '(55) 51928-1206', 'bruno.60@live.com', 'd93baa3c55fa724b9b93dc849288c9df78ab3b9882873822a4a78c2cadf8'),
('João Pedro Santos', '(55) 63971-3493', 'joão.61@icloud.com', '2ba2f9f3bcd30a566dd17d7398bc95456fabcb4e48d8ec5162c04e9f637c'),
('João Felipe Casa Grande', '(55) 21902-4994', 'joão.62@live.com', '048019187ddea1e6ae0aa700da14d4eec6892bdaf8f74c50eeb61dd2a250'),
('Sra. Júlia Montenegro', '(55) 96971-9065', 'sra..63@gmail.com', 'f2a9b8b1e1f1948a924dac4a561efbd340c926d1308a4b7e407f85b0b099'),
('Alícia Teixeira', '(55) 61990-2787', 'alícia.64@outlook.com.br', '8062feb1b8e6b3e078f8a1ef8f63365d00ce9b505ef02522312850f3ff71'),
('Ayla Melo', '(55) 73965-5125', 'ayla.65@bol.com.br', 'bbb75b87b84580f9e6ad0aede9137147cf6c8b1fde85cc83d267f6e43202'),
('Ana Carolina Marques', '(55) 24954-5168', 'ana.66@live.com', 'a6522c598de4979bac799cdf853bd0f36cf2cc21f522e128df58d90ebf4a'),
('Valentim Fonseca', '(55) 96970-3482', 'valentim.67@live.com', '4e35807341d6724443800d3ae882f3139fdfad25c4129506cdd1bddfd58b'),
('Isabella Santos', '(55) 38948-0861', 'isabella.68@live.com', '473496c38b9c1f755c5f16e603fef74a0662e615c11c2ee4210e988fdaad'),
('Daniela Monteiro', '(55) 64984-6773', 'daniela.69@yahoo.com.br', 'e948d50d6f04e9d86186c52e771e10ddb1a44fda98139bc525a75ee728de'),
('Sophia Souza', '(55) 34914-6584', 'sophia.70@bol.com.br', '26d3cff109495df706c1f97a04d290fdb65392c46619d231304e2cb9e76e'),
('Rebeca Cassiano', '(55) 89987-5588', 'rebeca.71@terra.com.br', '2f399bfa6501e66d03c71fea9a2c42c935292195c45299cefbda26cab7da'),
('Srta. Maria Isis da Conceição', '(55) 84905-7662', 'srta..72@yahoo.com.br', 'cf06e97ddd8a700355bc1797499f9e8dc89461c725714cdaddabb6879a9c'),
('Luísa Brito', '(55) 88918-7026', 'luísa.73@live.com', 'ad77bfea108f66436a2603b757b85a17827d8df0d14d7c9f40b9e05f820f'),
('Lucca Pinto', '(55) 82915-8657', 'lucca.74@hotmail.com', 'b61ae20c5dfbde302b779eccc6aa44b3812a2e0d0e49fb37fcb2ecb198f4'),
('Laura da Conceição', '(55) 24961-1724', 'laura.75@terra.com.br', '2e50708a6a381c3f868c36c78cfc85eb932b150c9f1b2db505fe4c1232ca'),
('Luiz Henrique Freitas', '(55) 87923-8692', 'luiz.76@hotmail.com', 'f1852ac776de7bf80aabdb7fb80ad27315a7814d384813e157ee6f8b549e'),
('Isabella Monteiro', '(55) 35937-4740', 'isabella.77@icloud.com', '689e6c5a935171db91b633f57f57d09679de5576dbf3d356fdeeecfa770b'),
('Manuella Pastor', '(55) 65964-7436', 'manuella.78@uol.com.br', '2d3fa1d969a4e9031a8678b86af894ce7bf7653b8d38ccfeea9f58bf5b4f'),
('Dr. Juan Almeida', '(55) 82940-9097', 'dr..79@terra.com.br', '72bb7e9c244f052a2871084ccf5a7eb2f49a2c6a88111310b1ceceb76b08'),
('José Rocha', '(55) 34910-4709', 'josé.80@hotmail.com', '48c7e9b094d6266262212c0f7ab5d44276b6db9178f4c9f600ce25cab311'),
('Dr. Erick Costa', '(55) 33985-8842', 'dr..81@bol.com.br', '920817000f559e79dee17c0124f9339348f9fafd179ee0aa9eebf2cda433'),
('Sr. Ravi Lucca Barbosa', '(55) 35936-8516', 'sr..82@icloud.com', '47789a1de1560a556e664beeb258d61a0c3edee8d65a161ced7d657e6fd0'),
('Dr. Mateus Porto', '(55) 77913-7098', 'dr..83@uol.com.br', 'de0460d7b3cc22a4470b8542bfafb16e7ac408dceb0dfdabbccb7d6ee194'),
('Nicole Sampaio', '(55) 65961-2004', 'nicole.84@hotmail.com', '6ad1bfb7f88b2874c453537cf2225aff58da96e832e73a3f0264e626a4b0'),
('Catarina Gomes', '(55) 91958-6926', 'catarina.85@outlook.com.br', '74c5a7c0db7185f52fdedf4711cb142764b63ed0771a774d86b4340e53fb'),
('Arthur Gabriel Sales', '(55) 77937-7351', 'arthur.86@terra.com.br', '1b338bb659b79d26e394024ed52d63d5d6df3eefe19a84c3e1dbd074de3a'),
('Gabriel Campos', '(55) 91913-9005', 'gabriel.87@uol.com.br', '62fab5b9140e6ddad3a2c6d7ec87154e2da225f84fcec051504910302062'),
('Giovanna Pastor', '(55) 47935-2904', 'giovanna.88@icloud.com', '9ec00b9a0f5d6df33a1ca46b1a5669096fd8112804ffc34389bfb420ee84'),
('Daniel Ribeiro', '(55) 14920-5395', 'daniel.89@bol.com.br', '7ee6ce5b5266000aab1612a600ed79c436a2252d741077087d237663232a'),
('Sra. Valentina Camargo', '(55) 19977-5891', 'sra..90@uol.com.br', 'c92b5c7905d1a0bb8f7e7d0fb32e93c28eb00e4a8bb4dbf7da3ba1eeab21'),
('Vicente da Rosa', '(55) 91900-7661', 'vicente.91@hotmail.com', 'b65201101b12b2a8f765102e107619750211cb5e022be8ae3e8cd969dd8e'),
('Sr. Benício Cardoso', '(55) 62999-8569', 'sr..92@live.com', '848411394a86021e7049de07405c89fd6f86ca190ff2091e2429d0294af0'),
('Beatriz Vieira', '(55) 31983-6736', 'beatriz.93@outlook.com.br', 'c173ebb04d7cba0b11c832f042982937dae3c515746d308b278b81fa1c70'),
('Levi Lima', '(55) 67945-2711', 'levi.94@outlook.com.br', '25ce7f8a08771961a89ee6335c32c0a6b001c23c9adb16a06b008f335756'),
('Sra. Caroline Novais', '(55) 18998-8516', 'sra..95@gmail.com', '68ce1254ca2c5c0985b6d6477707ad3232318f7f3d8fd3bf86730874c4be'),
('Luana Fogaça', '(55) 28998-3273', 'luana.96@icloud.com', '7f682f499bbb32f21fba74da6b7d74f6ccdbd18d4d882081c69dc3ab2c3e'),
('Henry Gabriel Lima', '(55) 14994-0244', 'henry.97@gmail.com', '0ee86d90215a0e4cbcb85b0636e3d46922ced01ca2876601699fe7e1e831'),
('Murilo Azevedo', '(55) 35901-8366', 'murilo.98@yahoo.com.br', '794b242d721000133d6b6b95bd9cf9195fcadd17740eb1021572a1f8c041'),
('Sra. Antonella Aragão', '(55) 37929-0147', 'sra..99@live.com', '15ce3ef3b27657e7d6ad8eee0f7ef289179a61c803dfd38f3a2338f69803'),
('Théo Camargo', '(55) 73961-4978', 'théo.100@uol.com.br', 'bfe6cbe89903bc3e171f1657f799ef3eca7c1fca5f67206c1ff9689aa950');
 
-- ======================================================================
-- RESTAURANTE (100 registros)
-- ======================================================================
INSERT INTO Restaurante (restaurante_id, nome, endereco, telefone, categoria, horario_funcionamento, latitude, longitude, senha) VALUES
(1, 'Abreu S.A. Lanches', 'Conjunto Teixeira, 64, Abreu - PR', '(62) 2683-8851', 'Lanches', '09:00 - 21:00', -22.7517992, -44.04870363, 'c85c927e06eba5c19b3af8e9aa526a4dc74bf901df70fefdc20a7a228e8e'),
(2, 'Lopes S/A', 'Largo Oliveira, 79, da Rocha do Campo - MG', '(05) 2975-1613', 'Pizza', '11:00 - 23:00', -23.47922582, -46.36269714, '61a706ccdff3299fdd45a405f0f6876022b60a3b0af4cdff8b70c7c4dfd3'),
(3, 'Moura Restaurante', 'Lagoa Camila Câmara, Vasconcelos da Serra - AP', '(81) 8835-5231', 'Churrasco', '11:00 - 20:00', -21.46726876, -44.12232939, '7b7a4d67ddaf624fcdd53319f1546c76b82c25cacbfea43b66f51f44f74f'),
(4, 'Cavalcanti Pereira S.A.', 'Campo de Cavalcanti, 87, Pires Alegre - BA', '(71) 7744-9058', 'Mexicana', '08:00 - 23:00', -21.3607904, -43.78605036, 'afd6032863f863579c7454193e3cbc2b9d150633f2c9176b64a4ae498fab'),
(5, 'Machado Lanches', 'Núcleo da Paz, Ramos - AP', '(99) 8679-8079', 'Frutos do Mar', '08:00 - 23:00', -22.30704804, -46.1402738, '5b0c82a1df7f6e5596c66b27917a9c07b9ab1713701a2c67069d817b8125'),
(6, 'Pereira Bistro', 'Distrito de Araújo, 61, Montenegro - RS', '(20) 3778-8925', 'Pizza', '07:00 - 23:00', -23.23247777, -43.64902028, '99c0c410d310d0b295e7138667b491043fe4d843b2f2862a4b141a9d2fa4'),
(7, 'Gomes', 'Viela Cauã Vieira, 61, Novais - RO', '(64) 4925-1925', 'Vegetariana', '07:00 - 23:00', -21.56233325, -43.19678325, '6777139de4ef333071d703d53014abc3459be3f6fb9ded23575b185b560f'),
(8, 'Cardoso Comida Caseira', 'Chácara de das Neves, 365, Ramos - RO', '(68) 5054-2357', 'Pizza', '11:00 - 22:00', -20.44826228, -44.47332889, '56e72a8119a84d8ee703f3e014af3e2d5cab70a46dd1059332176b3fb6d1'),
(9, 'Cassiano Barbosa Ltda. Bistro', 'Rodovia Vargas, 680, Peixoto - MG', '(22) 2927-0653', 'Saudavel', '08:00 - 20:00', -23.42586734, -45.87956621, 'f9932070a97714407f59f9d689acb31c24b7f0e638e300bfab760d7147d9'),
(10, 'Sá Bistro', 'Fazenda Sophie da Costa, 47, Rocha Verde - PB', '(74) 6886-2392', 'Pizza', '08:00 - 20:00', -22.15552034, -45.06772291, 'a372f0d9bdf7c823f97a6b99cabbe364fb03b09834b0394737b926cfb210'),
(11, 'Ramos - ME Bistro', 'Sítio Gustavo Silva, 214, da Mata - PB', '(82) 6137-5060', 'Japonesa', '09:00 - 22:00', -22.80387328, -45.73887984, 'df60e173922aef51beececf6acff742d66ae19e1db875d49c9fa0f4aada4'),
(12, 'da Costa Lanches', 'Núcleo Câmara, 6, Silva - RS', '(52) 2047-2779', 'Saudavel', '08:00 - 21:00', -22.97907052, -45.33396041, 'de0f41fc501111e8948c18e4fe11d2d2ea12b3d634cee84d5e8cceb816be'),
(13, 'Almeida Ltda.', 'Sítio Siqueira, 286, da Costa da Mata - AM', '(03) 6971-1798', 'Brasileira', '09:00 - 20:00', -22.72961733, -46.58443912, '67b7e74dece755a19f00e124b57de4f209aa7caa36fd41dd40012d07ce21'),
(14, 'Silva Casa Grande Ltda. Bistro', 'Vale Fogaça, 79, Rios - RO', '(18) 5188-8880', 'Mexicana', '09:00 - 20:00', -22.79826519, -43.30552503, '3667723b54e0223780982593c07f72c0f63b051edd0e7ea4faf1c00a7a39'),
(15, 'Aparecida Bistro', 'Núcleo Thiago Souza, 6, Ferreira - ES', '(19) 5205-8527', 'Brasileira', '10:00 - 23:00', -20.23820402, -44.38573327, '61440e8b99ed700ecb26027d4fb23a3a044184a9044264f269d1ca4e5cdf'),
(16, 'Pires Restaurante', 'Campo Silva, 50, Aparecida - SE', '(30) 5486-8740', 'Vegetariana', '08:00 - 21:00', -20.76904187, -44.75968176, '75bbda43e45401ab661363c29a4b424a61d6e2059fbdb98ef92785aa3126'),
(17, 'da Paz Fogaça S/A', 'Loteamento de da Mata, 6, Guerra dos Dourados - MG', '(52) 7758-4161', 'Mexicana', '11:00 - 23:00', -22.22441351, -43.1096272, '61c4a0aadca06f3e296ea4510a4a09acf24ed955a85df11a93d7cce3f417'),
(18, 'Nogueira da Rocha Ltda. Restaurante', 'Largo Ribeiro, das Neves dos Dourados - RN', '(62) 7570-5964', 'Churrasco', '10:00 - 20:00', -20.7280278, -43.60002953, 'c1b706889241726dec49f17d21cb487f5da09a82505525860a941779c30f'),
(19, 'Barbosa e Filhos Restaurante', 'Núcleo Olivia Souza, 30, Andrade de Cardoso - AP', '(35) 5690-9275', 'Arabe', '08:00 - 23:00', -21.33364568, -45.31483768, '4c41a7ca4f6c81c84b7ca16ac7f48b077dd2238331b8393d15f6f5c7b053'),
(20, 'Oliveira S.A.', 'Passarela Ana Sophia Rezende, 23, Sousa - CE', '(78) 6814-4739', 'Doces e Sobremesas', '11:00 - 22:00', -19.90990217, -43.60119307, '6b2321777c205d971ff455f25668d020a53989686b8d6da3eaff11203132'),
(21, 'Costa Lanches', 'Campo Machado, Silva - PB', '(15) 5188-4422', 'Arabe', '07:00 - 22:00', -20.67932482, -45.4753683, 'f37f938d0d9f4a9da1d903660f05f60f74ea0a488333dfd1ced3721c6ca3'),
(22, 'Campos Costa S.A. Bistro', 'Alameda Eloah Novaes, 957, Pimenta - AP', '(14) 6786-6912', 'Mexicana', '08:00 - 23:00', -23.5876678, -44.10046858, '357fc2b5dbf6fc8bfd59dfffdec4042755dbbb78916c10ce19f55db4f8c9'),
(23, 'Machado - ME Bistro', 'Morro de Cardoso, 392, Montenegro do Norte - TO', '(18) 2422-5358', 'Churrasco', '08:00 - 20:00', -20.29202943, -45.62559875, '03e5f7e51581983f1c533f6c230cd06c1463a8a63e0938597aaf8e719aac'),
(24, 'da Cunha S.A.', 'Ladeira de Cardoso, 99, Montenegro - RS', '(29) 9229-9590', 'Saudavel', '08:00 - 21:00', -22.17912736, -46.11842347, 'a9bc070cb9739727acf4493424fa9c83ab2fdc7b186519eb06472196250c'),
(25, 'Barros S/A', 'Jardim de Rezende, 79, Monteiro - RS', '(84) 4736-4710', 'Lanches', '11:00 - 22:00', -21.74329831, -46.29727619, 'd7cf58ec53a299c298a5a1a8ff6704a75694fd427fac77b6c720662e9a20'),
(26, 'Mendes Bistro', 'Loteamento Pereira, 65, Guerra Grande - SP', '(58) 8153-7147', 'Cafeteria', '09:00 - 21:00', -23.37988437, -43.53916544, '064920aa8f50286b9377611add746de81a5b01866505d785e9f9f467a848'),
(27, 'Aragão Ltda. Lanches', 'Pátio de da Cruz, 65, Teixeira - CE', '(78) 7747-0168', 'Pizza', '10:00 - 20:00', -19.88365892, -44.78225779, '093234419a6608bcd67115e2a80c7202098e524c1f1ba5c8745732ba32c1'),
(28, 'Cunha Pacheco Ltda. Restaurante', 'Lago Monteiro, da Paz de Nascimento - AC', '(16) 2456-5060', 'Japonesa', '10:00 - 21:00', -22.59278481, -43.55924105, 'a0216ec62b7aa181b3ce5cabe455381c0b398096bf9820b2daefb664ff0c'),
(29, 'Fonseca Novaes Ltda. Comida Caseira', 'Rodovia Manuella Teixeira, Pinto do Campo - BA', '(16) 5585-2398', 'Brasileira', '11:00 - 21:00', -20.8907939, -45.26362772, '035c828c6e1b1840666a18311d771124bdddbf2328f50bbea4c61e5d2e02'),
(30, 'Aparecida S/A Bistro', 'Loteamento de Melo, 972, Duarte - RN', '(52) 6949-5888', 'Doces e Sobremesas', '11:00 - 23:00', -23.14018406, -45.89108959, '08069652faf664d355f5c02aae93e48ac96847f9630191ee42fadedc1f6e'),
(31, 'Melo Bistro', 'Núcleo Farias, 7, Vieira do Sul - RN', '(74) 9930-9728', 'Lanches', '11:00 - 21:00', -21.36392757, -46.67411298, '3bf213b82dc3ca07bc894e8e7bbfac37a43683029faa96094a937f7bc545'),
(32, 'Casa Grande Lanches', 'Feira de Andrade, 113, Dias de Leão - BA', '(63) 6897-0283', 'Brasileira', '07:00 - 20:00', -20.33338548, -46.44491354, '9533644ca73ce41efad70b0c7432757dc70e56bef8f4f82479ca6434ca83'),
(33, 'Moura Restaurante', 'Estação Maria Clara Nascimento, 68, Pimenta do Amparo - DF', '(34) 8434-4375', 'Vegetariana', '10:00 - 21:00', -21.55091106, -44.09593076, 'edb8f863784ddd5ab9195039610bb71f4478df8c67827f209977fadaca68'),
(34, 'da Paz', 'Viela de Nogueira, Gonçalves da Praia - SP', '(24) 0415-7473', 'Saudavel', '10:00 - 21:00', -20.61844619, -43.79301081, '3fd9b12da1eb77ed9496031fb27e46869a9548e4f4725ba48c18050045b0'),
(35, 'Novais Restaurante', 'Conjunto Henrique Pimenta, 133, Porto - ES', '(01) 6571-2082', 'Pizza', '07:00 - 23:00', -22.25366925, -45.22003181, '6bf57e0be9cab0a50f21d742ab70190a8a1b40567f664a8286c7c27783f9'),
(36, 'Mendes Lanches', 'Lago Duarte, 20, Nascimento - SC', '(02) 6206-7240', 'Arabe', '07:00 - 20:00', -22.07003913, -45.47851062, '1125a234af98e85f68020d3d1a220671f020f648dc22cad39402bb437608'),
(37, 'Farias Ltda. Lanches', 'Setor de Moura, 92, da Mata de Correia - SE', '(15) 2742-0549', 'Brasileira', '08:00 - 21:00', -21.56211414, -46.19534373, '617261485d67ffc1ba1bfe0bbe6fd0fb451c2f42d6cc5b35dbe6c791f52b'),
(38, 'Cavalcanti Pimenta e Filhos Restaurante', 'Rodovia Beatriz Borges, 31, Mendes - MT', '(30) 4637-4549', 'Vegetariana', '10:00 - 21:00', -20.27695337, -46.4286144, '21de82c50a3769fde261eab8c2ad8b2f81aba499c092ec646a7d0d18c1fe'),
(39, 'da Luz e Filhos', 'Feira de Araújo, 8, Castro das Flores - RO', '(84) 1459-3327', 'Pizza', '07:00 - 20:00', -19.91781422, -43.36507886, '092d39517e0225db50a09bbec573cf588472e194aeecc1159ffe2a8d036c'),
(40, 'Leão Restaurante', 'Recanto de Sá, 233, Moura de Santos - MS', '(19) 1088-3982', 'Japonesa', '10:00 - 23:00', -21.77083801, -43.58725858, '9716645d72b62a4099a7ef9d56f646f022e1eed2e43712ccfb42c818a859'),
(41, 'Camargo Lanches', 'Trecho Mendonça, 9, Araújo de Marques - BA', '(86) 7908-7406', 'Japonesa', '10:00 - 20:00', -19.85582639, -45.74526899, '4d53476ae780fe9d8dba50a67507888407475ffe870c947f365eb9188bd8'),
(42, 'Souza S.A. Comida Caseira', 'Área Lima, 91, Azevedo - PR', '(04) 6226-5676', 'Vegetariana', '10:00 - 23:00', -23.01177206, -45.63185183, '4f8d9dd154acc085ffc203f35d05d9f68b3cdd3917a46089e409137f9ac2'),
(43, 'Rezende Ferreira S/A Lanches', 'Passarela de Moura, 13, da Rosa - PB', '(86) 8633-7524', 'Saudavel', '11:00 - 20:00', -20.75769287, -46.49420502, 'd28da746ff4a031fb0f4b29e625ec4d0d37c6f5bc255fffda272f08ee369'),
(44, 'Andrade e Filhos', 'Alameda de da Costa, 21, Machado - RN', '(03) 0673-8302', 'Doces e Sobremesas', '11:00 - 21:00', -23.3838576, -44.87181741, 'a2e72f622407ccc705d738d74afae3a18b29fb93c3a7f60efb2aae911556'),
(45, 'da Conceição Restaurante', 'Travessa de Dias, 495, Casa Grande do Galho - ES', '(64) 4089-2687', 'Pizza', '11:00 - 20:00', -21.0341923, -45.85326598, '3871f0b3843e6912f2052c8872da6ba1be0b08e44196f29993c839049f69'),
(46, 'Ramos Lanches', 'Rua Antonella Sampaio, 36, Garcia da Serra - SP', '(87) 3342-7086', 'Saudavel', '08:00 - 20:00', -21.24635026, -45.1907903, 'a651850bebf096dafc84707752cddf6d1f8de922a432bf75ddfd87597492'),
(47, 'Gomes da Cruz Ltda.', 'Via Emanuel Machado, 91, Aragão - GO', '(69) 9013-9837', 'Saudavel', '11:00 - 22:00', -20.04811622, -45.96466688, '4d65fcf2519f3bb0806e638076cd149aa0dfb82291352d0c2ea2deecfb1f'),
(48, 'da Rosa Bistro', 'Estrada Sousa, Souza - SP', '(73) 9363-8546', 'Brasileira', '09:00 - 23:00', -23.10266253, -44.37619716, '2cf4ccfa1bbab2ce871b874eeee622d0e6f2009d76aee3e906358aa100c5'),
(49, 'das Neves Comida Caseira', 'Rodovia Maysa Martins, 8, Costela da Praia - MT', '(60) 9320-4899', 'Italiana', '07:00 - 20:00', -21.85851501, -43.10556401, '92ade7e74ec29474d2b0763347de102b4e2cc2dddca1f1a554c14ef3895f'),
(50, 'Cassiano Lanches', 'Fazenda Gabrielly Nunes, 97, da Cunha do Amparo - SC', '(77) 2522-8728', 'Pizza', '11:00 - 21:00', -21.67763816, -46.22315635, 'd244d07da20eb5189619e9109fa5e6bda642476b5beaeb287d70ac59f241'),
(51, 'Moura S/A Bistro', 'Viaduto Aragão, 7, Pires - ES', '(12) 0387-5099', 'Pizza', '08:00 - 22:00', -22.51704791, -45.12253554, '52260b17e66fb24a1d9453a9c0ba52d9de0f9fb38faeee3f972ad45b6877'),
(52, 'Almeida', 'Sítio de Jesus, Almeida - PE', '(48) 4086-2118', 'Chinesa', '09:00 - 20:00', -21.06211983, -44.70343178, '124c7f374605f30353cf2939829007f71a5ef11f9453f4b374478873134e'),
(53, 'Pinto Moura Ltda. Lanches', 'Ladeira Isabella Barros, 86, Sampaio - ES', '(41) 0166-6870', 'Japonesa', '09:00 - 20:00', -20.21909171, -44.02729994, '9ec63f4df4cf95fd2e981e181a2cfb9d5332c4bc7d38f60b2ccbd6e78594'),
(54, 'Barros Monteiro - ME Restaurante', 'Travessa Gabriel Moura, 4, Sales - RJ', '(74) 0148-9025', 'Vegetariana', '09:00 - 21:00', -20.87307369, -45.96704968, '740517538e08bf81e38e1081e1383e0b2819cb0478fb670414664b4e8ab4'),
(55, 'Pastor Casa Grande e Filhos Bistro', 'Campo Ana Clara Castro, 739, Gomes Grande - SE', '(18) 5016-3159', 'Churrasco', '10:00 - 22:00', -20.15972133, -43.65402663, '727190f0534a78e57e1daadba0acfc8875e21f47e21553a279ec1b180e4a'),
(56, 'Vasconcelos Lanches', 'Vereda da Mata, 47, Novaes das Flores - PA', '(29) 6194-3114', 'Arabe', '10:00 - 22:00', -23.43247031, -45.49919646, 'd6c4858d3474b3f29ca9fded5ad9c0e652e14dc646c511de27d2f343f4db'),
(57, 'Sousa Gomes Ltda. Restaurante', 'Chácara Abreu, 67, Caldeira Grande - AP', '(26) 7888-6101', 'Arabe', '09:00 - 21:00', -20.78332255, -44.71395048, '27ed33e712e423d16aa0853fef49e4eea6195e9f2bf25f2d57133630efca'),
(58, 'Peixoto - EI Comida Caseira', 'Parque Apollo da Rocha, 26, Oliveira - PE', '(26) 2244-4721', 'Churrasco', '07:00 - 20:00', -23.31407333, -43.52081698, '11845769ae3a6d187b99b8490c52c32785b371d29fb2b2db5df30c99204c'),
(59, 'Leão Restaurante', 'Campo Eloah da Cunha, 47, Caldeira de Carvalho - MA', '(06) 5965-7569', 'Churrasco', '07:00 - 22:00', -21.38646365, -46.16686237, '7062568a4b059eaaa64e7c4eb9833ae52beb31cc0f241b48d5b576475a45'),
(60, 'Pereira Restaurante', 'Recanto Dias, 66, Sousa do Amparo - RJ', '(35) 6465-1939', 'Lanches', '09:00 - 22:00', -20.18387034, -43.8339597, 'a09f5fbd17fa5d11191e793a0dd1b362c67a26e6d50a44c421782e833531'),
(61, 'Rodrigues Vargas - EI Lanches', 'Quadra de Santos, Macedo - SE', '(41) 6724-3426', 'Italiana', '08:00 - 21:00', -21.06565304, -45.42675692, '89604660b48866748c785fdb9321ee3f8f45b08d85c0d9c66d998f1eb4d9'),
(62, 'Machado - EI', 'Passarela de Nascimento, 168, Sampaio da Prata - RN', '(11) 3529-0965', 'Cafeteria', '10:00 - 21:00', -20.08209747, -45.8477456, 'ce27e5c969183c6648830ea0d8f49510a111beb6ae3126a155fbf9517378'),
(63, 'Caldeira Restaurante', 'Jardim Câmara, Machado - MS', '(67) 9825-0714', 'Frutos do Mar', '08:00 - 23:00', -23.50581182, -44.0483679, '73ca1ca95f67555adb97b6ca3f701e15dbc9a9f2e7c15eddb773382e0995'),
(64, 'Camargo e Filhos Bistro', 'Lagoa Caroline Marques, 88, Melo do Campo - PB', '(75) 1401-0512', 'Frutos do Mar', '10:00 - 21:00', -22.5861383, -43.86545177, '789b51bc37eb6c4b7804dcc037a77ef410de050a474f05acc92e4874bf08'),
(65, 'Moreira Cavalcanti - EI Lanches', 'Sítio Letícia Martins, 36, Porto - RO', '(66) 0937-9660', 'Mexicana', '07:00 - 23:00', -22.75475187, -43.76028822, '9d6c70714f0ee972117e0d26280d516e29e09f7bfa76f3aed338aa42ac01'),
(66, 'da Mota Sá e Filhos Comida Caseira', 'Travessa Caldeira, 625, Marques - AM', '(47) 8596-9691', 'Italiana', '09:00 - 21:00', -22.75289052, -44.32388054, 'ddc11614f6de872b321b8509da6bb769051078f06961540d143e646ba2b1'),
(67, 'Pinto Comida Caseira', 'Lagoa de Pimenta, 612, da Costa - MA', '(12) 5286-6929', 'Italiana', '09:00 - 20:00', -19.9258214, -45.69515003, '98ad4afb2a932ddf8215b0abb1bb14d0524b6c0b8bf2ab1f2552712d3c31'),
(68, 'Mendonça Porto - EI', 'Estação de Novais, 57, Cirino - MT', '(79) 0507-2368', 'Mexicana', '11:00 - 22:00', -20.03089887, -46.28476969, '612ee620539a4120550352174613bb2d4725eaba6c453a8ce03003cd62d1'),
(69, 'Jesus Bistro', 'Pátio Lívia Mendonça, 11, da Rocha - AL', '(43) 8427-9788', 'Japonesa', '11:00 - 22:00', -23.45462265, -44.55234348, 'd5728c50000ea19f0e30dde82e2159594983508f02835e0cedf2fd9b1a14'),
(70, 'da Mata - EI Bistro', 'Setor Bryan Teixeira, 48, Caldeira de Goiás - MA', '(07) 4517-1339', 'Chinesa', '09:00 - 23:00', -21.29640636, -44.85887699, '14c01f1389ed6d3701287b1a157b631dae491b3cee13894c69f40d59d39a'),
(71, 'Cavalcante Comida Caseira', 'Favela Costela, 6, Peixoto da Prata - CE', '(54) 4948-1260', 'Saudavel', '08:00 - 22:00', -23.43133117, -45.13019294, '176a7fefce9328d2d2cc04b8f190d3cf7554734bc9b668b78b55fffcb603'),
(72, 'Sampaio Cardoso S.A.', 'Largo de da Cruz, 37, Pires das Pedras - MG', '(71) 1684-5775', 'Frutos do Mar', '11:00 - 21:00', -22.21595841, -46.44809428, '1a055e92768bff587ac42e20b248cc59a90195b79b7da9d108a2aea74afb'),
(73, 'Siqueira - ME Bistro', 'Vila de Fogaça, 9, Cunha das Pedras - TO', '(37) 4545-8929', 'Saudavel', '09:00 - 20:00', -20.8649338, -45.61883983, '33c107da2a2272466a3d3ebdc19feccdc46c572bc4f41a226ae3030c07eb'),
(74, 'Rodrigues Bistro', 'Área Brito, 20, Macedo - PB', '(06) 3242-4154', 'Arabe', '10:00 - 22:00', -22.07087853, -45.63564127, '47763223237316b3f8758e8760f8fe35574e5a56cbbdc0d70afeaa5e28ad'),
(75, 'Aragão Gonçalves e Filhos Restaurante', 'Vila de Sá, 26, Abreu - DF', '(71) 2938-7005', 'Brasileira', '10:00 - 23:00', -21.02619181, -43.44990004, '12e39bbd9c6edea07c30bbfaa59e4d655331e0c65fa5f07bfe339b073165'),
(76, 'Sales', 'Campo Raul Gomes, 2, Dias - MS', '(42) 6221-8909', 'Saudavel', '09:00 - 23:00', -21.51783859, -46.69853862, '09069530b5cbba0bb184381db5e64b9db776812c78c514b9ba3e3b1cd80f'),
(77, 'Ferreira Bistro', 'Vereda Souza, 86, Borges - AM', '(21) 9656-5234', 'Brasileira', '10:00 - 22:00', -21.83304488, -45.10822472, '2e0d21186c9b6e060dbb04338ae047a3208dcaeaf23e41686723739e74db'),
(78, 'Novaes Peixoto - EI Restaurante', 'Lago de Vasconcelos, 5, Moreira - RN', '(83) 6403-7613', 'Churrasco', '10:00 - 21:00', -21.09636717, -45.67836894, '95cbae3be03665708257fc4e314e4280187d145e385bc865510b2c97a82c'),
(79, 'Moura S/A', 'Conjunto Hellena Nunes, 95, Teixeira - PR', '(10) 9104-3006', 'Italiana', '07:00 - 21:00', -21.04337645, -45.8912936, 'bedf69d4320f2f40c29b48bb61ac6eef8536ceed01df55bf900b631e007c'),
(80, 'Lima Restaurante', 'Chácara Stella Nascimento, 224, Barros do Galho - DF', '(28) 5691-4630', 'Japonesa', '07:00 - 20:00', -22.66959833, -44.98950916, '87221ca7b95da0af8c4581e049bde76a0615ab428db5d27006adf6314e75'),
(81, 'Camargo Lanches', 'Trevo de Araújo, 22, Santos - BA', '(02) 7588-4252', 'Doces e Sobremesas', '10:00 - 21:00', -20.87028552, -45.31767752, '61d2d36b561c2cdf8cb518b840ea6acc4995ab2dfdeb6b9eb8340bb9f65d'),
(82, 'Siqueira Comida Caseira', 'Loteamento Lima, Moura de Minas - GO', '(91) 7785-0792', 'Brasileira', '08:00 - 20:00', -20.20789266, -43.60241396, '579d57743bdfa1b40cd7da7d42e002f67f25185444252de13473cda55d76'),
(83, 'Vargas Lanches', 'Viela de Silveira, da Conceição - SC', '(80) 0030-7562', 'Frutos do Mar', '10:00 - 21:00', -22.93163061, -43.25132225, '4a2d193739de9bdc20871934a47ff796fe4e09e5c41029630d3adee5ee50'),
(84, 'Novaes e Filhos', 'Pátio de Câmara, 73, da Mata de Minas - RJ', '(51) 8023-8061', 'Doces e Sobremesas', '07:00 - 21:00', -20.11361395, -46.26310904, 'c1b6e356e41112da720051cea3e8abfbae8daf7a0080956f5a32fc714625'),
(85, 'Vasconcelos Restaurante', 'Largo Erick Novaes, 60, da Rocha - RJ', '(49) 3759-7383', 'Frutos do Mar', '10:00 - 22:00', -19.98984949, -43.49086667, 'acafdb39fe54e489ff6ec44bf96a8d3551bf1883cc1a34555269f9b304d6'),
(86, 'Alves', 'Morro de Porto, 6, Teixeira - RO', '(64) 1383-6702', 'Cafeteria', '11:00 - 23:00', -20.44383716, -44.72766098, '21ac26486910eb58eaf71ed762373804f3430739ac28724bbb715de35e12'),
(87, 'Aparecida S.A. Restaurante', 'Pátio de Sampaio, 27, Montenegro - BA', '(61) 9906-2344', 'Chinesa', '10:00 - 23:00', -22.61507212, -45.80993694, 'ac04e5dfbd58c14827630eca42c7169104d5b1ce2270dfde885fcb92cd0b'),
(88, 'Sampaio Bistro', 'Largo de Dias, 44, Costa - BA', '(91) 2127-7561', 'Frutos do Mar', '11:00 - 23:00', -21.21835594, -45.71144919, '75d2fcc05d96e266967b9e56cc24c3d003ce25867404d79c9791dc91769f'),
(89, 'Machado das Neves - ME Lanches', 'Chácara Castro, 19, Duarte - BA', '(13) 5680-4420', 'Chinesa', '09:00 - 21:00', -22.56748259, -45.54904555, 'f094b2fc5cfce89d5662628d1518d0c655231772887cad68e3d61c0a9d00'),
(90, 'Novais', 'Feira de Brito, 31, Albuquerque - AL', '(32) 3651-9941', 'Pizza', '08:00 - 21:00', -22.72120638, -44.20178068, 'c1eafc04c0ad61df2e583444d022ca5d07a8535aeffa60c69400114e3daa'),
(91, 'Costa e Filhos Restaurante', 'Chácara Farias, 1, Aragão de Cavalcante - RJ', '(66) 7066-2532', 'Pizza', '10:00 - 23:00', -22.34265071, -45.02267251, 'c6e407715dbd50a56fb698a52e34b9c067bc7473ad4c4e43b13dc4c71026'),
(92, 'Cassiano Lanches', 'Vale de Pimenta, Ramos - MA', '(76) 8701-4626', 'Brasileira', '10:00 - 23:00', -20.16161378, -44.59731411, '95a27b20c84a889b1444076ab2f56d3a84b2405eb72050ebb4fca2ab741b'),
(93, 'Pires Nogueira S/A Lanches', 'Morro de Mendes, 975, Gomes Paulista - CE', '(05) 9304-0785', 'Cafeteria', '11:00 - 23:00', -21.78747702, -43.30613003, '9e43b0eb60a02d892954ef764d223c8040df05533b1906be5577bee1d8bf'),
(94, 'Castro Brito S.A. Bistro', 'Ladeira Nascimento, 4, Fogaça da Serra - CE', '(39) 5590-5992', 'Frutos do Mar', '10:00 - 23:00', -21.55476184, -44.05531738, '245158768d03a51619d0656e33f0d3857d77217535c192b64de214f6ce24'),
(95, 'Monteiro Nogueira Ltda.', 'Área Fernando Araújo, 49, Moura - PR', '(05) 9325-2500', 'Brasileira', '10:00 - 21:00', -22.56284582, -44.95168882, 'b05287b17d189327ae19f3df1411ad1dacba70a59b7c25caaafbf149fe3a'),
(96, 'Vasconcelos Camargo - EI Comida Caseira', 'Campo Evelyn Santos, 29, da Rosa Alegre - BA', '(26) 7528-9539', 'Italiana', '10:00 - 21:00', -20.40607848, -43.38965017, '6139c352f16774a6d184b29c682e616102f577bf641ba2b643b7ae040341'),
(97, 'das Neves', 'Lago de Cardoso, 70, Cirino - RN', '(59) 3917-2513', 'Churrasco', '07:00 - 23:00', -21.35080745, -44.31320088, '9a63dce3c232831aa04be5c15639a97b574c660451cffa55190c1a6a0e7c'),
(98, 'Cavalcante Lanches', 'Viaduto Porto, 17, Costela de Goiás - RR', '(15) 4100-6762', 'Arabe', '10:00 - 21:00', -20.30596485, -46.0457755, '7329d266afd5e95533e2b1ce502de1917c2dc3e2c3ebac341d30cd46f93e'),
(99, 'Garcia Bistro', 'Parque de Brito, 49, Machado - AP', '(04) 0541-1526', 'Mexicana', '09:00 - 21:00', -21.87214256, -45.48499803, 'd9a8fab9822778e7e9128cd29f57a542058c3ad03eb4b6171df31a9e47b2'),
(100, 'Novaes S/A Comida Caseira', 'Vale de Mendes, 7, Pereira - PA', '(20) 1533-6884', 'Vegetariana', '10:00 - 22:00', -20.42733852, -45.00689539, '90b8cbfd16ae04878ccfab7edbb1639ba7746e31003b50ac1d33a24bfbd1');
 
-- ======================================================================
-- ENTREGADOR (100 registros)
-- ======================================================================
INSERT INTO Entregador (entregador_id, nome, telefone, veiculo, estado, latitude_atual, longitude_atual, senha) VALUES
(1, 'Isaac Brito', '(06) 99872-0506', 'A pe', 'disponivel', -19.80035025, -45.44014276, '9625628e42aec530eb1ff3df2e8d52db78d95449285a77b765ddb62d81f7'),
(2, 'Pietra Costa', '(10) 93241-7146', 'Moto', 'disponivel', -20.73391382, -43.28139776, '11cb50d38b9d0d29bc515d4740dca22ef9357782c0e63fa7dee034f2cf66'),
(3, 'Julia Borges', '(86) 92565-2704', 'Bicicleta', 'disponivel', -21.2389245, -45.84123821, '3496dc8db890f01ebfd38152fe2cf2a8e5dd51685f9808e7aa0d6e7dad96'),
(4, 'Henry Gabriel da Mata', '(90) 92115-8693', 'Patinete Eletrico', 'disponivel', -21.45691559, -45.91532765, '1a2d2bfde07f7ca9d6a09430cde2e0781802b791089f26ea2b131e05bd66'),
(5, 'Stephany Leão', '(87) 99374-1608', 'Carro', 'offline', -22.96240126, -44.51390902, '7567681ca2101b57e1d1262aca895a3de992f69ebe98e01b06ff086b1396'),
(6, 'Clara Campos', '(72) 92332-0616', 'Moto', 'em_entrega', -19.93406106, -46.3108445, '5f5c5fffe416bc4411a902a4b5cb1fcd1612ae6224971289c384b3101d1c'),
(7, 'Clara Peixoto', '(45) 91168-6854', 'Moto', 'offline', -21.41197243, -43.43110586, 'a4f763d1d7781c8c07c9ce543bf813ccd9b5c881515d06767eda6b18a0a8'),
(8, 'Vicente Viana', '(61) 96229-9911', 'Patinete Eletrico', 'em_pausa', -20.02241173, -45.9860128, '4c237089ce50d2d938f1761d36bf0daa3657a8fbb692ef0995edcf06aadd'),
(9, 'João Pedro Nascimento', '(56) 94679-9702', 'A pe', 'em_entrega', -23.21277504, -43.91906881, '25c1b1da8043a3a1bff183f1dbc4801ab9fd7994b2b374e038aa04ba1a89'),
(10, 'Murilo Andrade', '(65) 93074-5054', 'A pe', 'disponivel', -20.57433658, -44.6626428, 'bce51ef60409915d45e551cef56fc1ce2693ef3168012c2d5601a8bd3d7d'),
(11, 'Beatriz da Conceição', '(24) 97546-9137', 'Moto', 'offline', -21.57556807, -44.31852317, 'd1c036056376f2b36fbd6a13c76dbf973270bb37fde5d2c6e79a65d20776'),
(12, 'Raquel Teixeira', '(85) 90821-4862', 'Moto', 'offline', -23.55192183, -45.18778853, 'f667cd57e941d5e29be9bc5888d9e6f469912c718518ea1e0dae6edb1b94'),
(13, 'Ana Cavalcanti', '(33) 90307-0534', 'Patinete Eletrico', 'disponivel', -21.95261107, -45.39612306, '9e7473fcd43c40ca6a0198f8ecf2e5d5d9fc731bb1ddf19974579ee4b4b0'),
(14, 'Sofia Gonçalves', '(10) 93579-7279', 'Patinete Eletrico', 'em_entrega', -21.94514885, -44.05833691, '2f03dc7693be17c197b1612396790384abcb64680edcc73884d5c97df15d'),
(15, 'Sr. José Pedro Souza', '(14) 90602-9333', 'Carro', 'em_pausa', -21.83347967, -43.72735545, '5f90c524716b824666db5c01f75f397f970e029b6d0fc7afae82da5b3c8a'),
(16, 'Nicolas Moraes', '(00) 97229-0349', 'A pe', 'offline', -22.37524258, -45.81621739, '1d33221900baf3e2275e4ba02df509c7725cd8ae12ea4810e30a337c9d71'),
(17, 'João Guilherme Lima', '(65) 97437-4896', 'Moto', 'offline', -20.2498015, -45.82209162, 'eca4b059f97728615da54f5f6dad8ec126e8b0ece131f5839411d1ee5dcb'),
(18, 'Thomas Ribeiro', '(58) 99944-1715', 'Patinete Eletrico', 'em_pausa', -22.32169284, -44.92049659, '4587e52b36fd73e49982d4ca3780f9a4158f794531fed5e3c4759f952655'),
(19, 'Lunna da Mota', '(44) 93283-0965', 'Carro', 'em_entrega', -21.74731026, -45.42263012, '965c76af0aa1edb0711c3b7d8908838abb5ad6f9326f2feb3fdf2f91ea95'),
(20, 'Srta. Sara da Rocha', '(46) 96609-9353', 'Carro', 'offline', -22.53729775, -44.55384197, '368322fb4cf76ea43326c1651b408d007600e7abf8a1f1ca13064fc095df'),
(21, 'Olívia Rios', '(58) 94282-4172', 'Carro', 'disponivel', -21.63681644, -46.01219688, '89c6b6683f2825ca6cf1f651b0d974fccb12e6d4357b2565819a86543a64'),
(22, 'Dra. Emilly Rodrigues', '(51) 93534-6554', 'Bicicleta', 'em_pausa', -21.74340418, -43.97060725, '048f7fdc9215db557a12f6209e7e62611f50d495a034037ab1c20d78e5db'),
(23, 'Bárbara Melo', '(09) 99917-3816', 'Patinete Eletrico', 'em_pausa', -21.89693671, -46.63792427, '15810e9d31d204bdac7e7cd092273656800188d19805334f64f37da5e1ca'),
(24, 'Ana Júlia Cassiano', '(23) 95697-2521', 'Carro', 'em_entrega', -22.06327571, -45.82410141, '8f91d73879efea4f77d09e36f0cc5efe35cf231ac18c3200a886562d542f'),
(25, 'Emanuelly Dias', '(00) 97432-9271', 'A pe', 'offline', -21.80161014, -44.78868105, '1763157f09cdc67f9b5d723aa69e19e51f532e7355bda0975512918263f2'),
(26, 'Mariane Guerra', '(67) 96008-3505', 'Patinete Eletrico', 'offline', -22.26312, -45.06651705, 'a2074f4b230997cab707703c9678411610ae2fafe0000f14da81e5750137'),
(27, 'Esther Almeida', '(03) 93542-1689', 'Carro', 'offline', -22.72395544, -44.10337641, '0357544be987bde1d213ac158c32330df79039bb17e72d71b350852ae9c1'),
(28, 'Augusto da Rosa', '(47) 98985-6257', 'Carro', 'disponivel', -20.77705196, -43.27684078, 'a0e39e6ffd9364809590b9e508d7ae50eb15ebaa132b9f349a00b7e8fe5b'),
(29, 'Enzo Guerra', '(03) 93230-9821', 'Bicicleta', 'em_entrega', -22.77773837, -44.95688509, '127d07426e02d201ab26d3abd8f5bfd534057c1774dc8b0d48acb8ed0258'),
(30, 'Ana Carolina Garcia', '(48) 99090-1001', 'A pe', 'offline', -19.8740596, -43.70253789, '61aa520d0f7e62981845174a8f13d270a80111856216c28fc9c6a9b862cd'),
(31, 'Camila Novaes', '(47) 92304-6184', 'Carro', 'em_entrega', -22.22865194, -45.61183668, '132c0e0e3000729b3dbbd57d9ea08f50d8372664c73d471a23a81f3ba05e'),
(32, 'Srta. Mariah Caldeira', '(89) 91411-7393', 'A pe', 'em_entrega', -22.55761696, -43.19253825, '90174e6304e604ea052c96fcfb6e433e1207fff30e869ec580a143197835'),
(33, 'Gabriela Fogaça', '(64) 92087-3753', 'A pe', 'offline', -20.94981391, -46.24539383, '764743cd9197ebd4939b176ab424eae2fb37c75f16cf8002442d62b6c359'),
(34, 'Aurora Camargo', '(97) 92181-1437', 'Patinete Eletrico', 'disponivel', -20.28366501, -44.63336881, '26edfec03f521e7109726c1f9d9d1e4be8c473c05bd2c6c37f243ae32573'),
(35, 'João Martins', '(01) 92045-5611', 'Patinete Eletrico', 'em_pausa', -21.92621857, -46.03629079, '14a9219b7faa297684c962752b99fe41bbfe55c792388c81ae3c3a1f9c5b'),
(36, 'Anthony Carvalho', '(25) 95794-1552', 'Moto', 'offline', -20.02395833, -44.98017493, '841356f98001246b21faf8403284d454a1eb6d3bee2e9457c0d5d5061f15'),
(37, 'Mirella da Mata', '(67) 96212-0216', 'Moto', 'em_pausa', -21.73136307, -44.62272384, '1a1f94b4414a0425d0ae7b7ba04913dcc4562d9de640245ef914817da0b3'),
(38, 'Maysa Cirino', '(96) 95902-7716', 'Moto', 'em_entrega', -23.03304918, -44.67377745, '98e3ad2a8d96c9daa0bb709d918d3592fb7116bf2db0a8c96149823c18af'),
(39, 'José Pedro Rezende', '(50) 98993-5889', 'Carro', 'disponivel', -19.82311113, -46.27357438, '5bf610b0071b9c761e07eef1b4158a6eb5c6a570c9bad6d9ecb943ac5d22'),
(40, 'Isadora Mendes', '(56) 92890-0287', 'Patinete Eletrico', 'em_entrega', -20.65236455, -45.33063911, 'ad830b2f4b6183113e531074d39dc7316ebf81d0da065843cb4458ee6ce8'),
(41, 'Breno Sá', '(75) 93540-8386', 'Patinete Eletrico', 'offline', -20.33136667, -43.13588746, '5b835a467be5451140baa92a410f827d7d9ecc9508d70a2dd4e2078530ca'),
(42, 'Bruno Marques', '(79) 97177-5170', 'Carro', 'disponivel', -21.28340253, -44.0356785, '079906fe13fe908f9442e03af061001c478cdc65a6d3734dc84b257d159f'),
(43, 'Ana Carolina Novais', '(80) 91994-8837', 'Bicicleta', 'em_entrega', -22.59434472, -46.40772512, 'a462d14127d23e53211adf0cbec4dcc7397afacc4f91cb401af23f358b38'),
(44, 'Sr. Henry Gabriel Marques', '(58) 99975-7113', 'Bicicleta', 'em_entrega', -21.50242947, -46.13648258, '0568793a6ac4f55e59262f6ecd4f22941ccf5e90b03836a01419991c9d10'),
(45, 'Dr. Yan Moreira', '(51) 90272-6149', 'Patinete Eletrico', 'em_pausa', -20.98038968, -45.00831508, '6b52a8e02710dbd2d8edbd8a42fde916cbf20b0685113cb3dc0e214ce063'),
(46, 'Matteo Cunha', '(73) 95160-9177', 'Moto', 'em_entrega', -22.50520142, -45.68221386, '750c82daf142e51929e2f65d002f9142c4c20a82cfaf4e5e0545cd24de7d'),
(47, 'Catarina Monteiro', '(08) 90869-7829', 'Patinete Eletrico', 'disponivel', -20.9879373, -43.37392024, '963b4c32e739bf987d9cbbc066f77f8f05c99a328f0a7a2332c3450d9e33'),
(48, 'Cauã Gomes', '(99) 95866-9346', 'A pe', 'em_entrega', -21.98447193, -44.73957544, 'a32b2e91bed88cd7c165f10dbf010e8b23af8dfb6ac5bb15c36c8711f984'),
(49, 'Rael Carvalho', '(26) 99848-5833', 'Bicicleta', 'offline', -20.45880159, -46.44292459, 'df389fd40e04e8d2c5c7c2a6bd6a76abc77ad0e0a5e5619a78ef5c4715b6'),
(50, 'Sra. Manuella Rocha', '(22) 98851-5879', 'Bicicleta', 'offline', -21.33883266, -43.73273492, '558f39ab78ff46b126faea0382f62cc36bd802f814bf50a266b63fdb3beb'),
(51, 'Maria Vitória Rocha', '(84) 96081-0620', 'Carro', 'em_pausa', -23.1274561, -44.22075923, '634198ac539e7d9ebfd50ba5c4d3044975475bcfc5b0e0a099e50f82ee06'),
(52, 'João Felipe Sá', '(24) 94204-3805', 'Patinete Eletrico', 'offline', -21.69820573, -44.92233721, '42723f70b18463bc28c35e5bde22715d5d144160073a7eaa8ec6f2bfbda1'),
(53, 'Henry Gabriel Souza', '(86) 93840-6665', 'Moto', 'disponivel', -20.22019302, -44.05567788, '4bd81ce82853ac432509072e77a3cd5e843a5dae97c0d1e166c4a52ee879'),
(54, 'Anthony Gabriel Souza', '(43) 99735-9893', 'A pe', 'offline', -23.50171341, -45.8758721, '633766e81d7ff7fd609d1e25807235e741b196f73291be65b422647d7415'),
(55, 'Juan Machado', '(21) 92281-6064', 'A pe', 'disponivel', -19.80162482, -44.2797863, '214f1e2b70878445eef9cd17278fc14cebc8a6e384a8419acdd953a7eba5'),
(56, 'Enrico Pacheco', '(40) 95720-2590', 'Carro', 'disponivel', -20.70018578, -46.06931338, '799c68d7c9700b92e85d2bb45e9eb575c0a314543c7e1dda68cc06c221b5'),
(57, 'Liz Mendonça', '(98) 95158-3281', 'A pe', 'em_pausa', -20.11892341, -46.04663907, '90da1997f60a9d3ef53d605803d3219dc00e9b48ee0576c77e4e3fafe806'),
(58, 'Oliver Nogueira', '(86) 91533-5554', 'A pe', 'em_pausa', -21.18781807, -44.92978711, '3e2bae667b3d0b54e7d421390f1cc54b5378ab9aa633779e1eb3ba6c6219'),
(59, 'Vitória Melo', '(80) 91573-9930', 'Moto', 'em_pausa', -22.27774799, -45.50008978, '6db4a44369cb86f75b78660c0f4a20500f69dcb2a62810d4c6437d48c037'),
(60, 'Dr. Danilo Gomes', '(48) 94085-8877', 'Moto', 'em_entrega', -22.34674608, -44.20277477, 'f98875b8a11d1c7140cbee9a3bc127e788e75eb6ae16d34b0c1e06a3dbd3'),
(61, 'Evelyn Duarte', '(81) 91288-0133', 'Carro', 'em_pausa', -20.50844907, -44.71965221, '631c9106e08c6150ce9cbb646f4d6be29de36808bee581b7be0b0c289e0d'),
(62, 'Bella Costela', '(86) 91207-5011', 'Patinete Eletrico', 'disponivel', -22.4048348, -45.53621437, '7218fd50fef8556c6ee78b7fb893cf9660a5fb19dede13be88191ed82674'),
(63, 'Brayan Oliveira', '(34) 96676-6506', 'Patinete Eletrico', 'disponivel', -21.10089053, -44.74666306, '85b06dec7e6e7ff400171a7a2763e29e4b091584f18fc2d5521633080062'),
(64, 'Alana Ramos', '(91) 99015-8144', 'Patinete Eletrico', 'disponivel', -22.88718634, -45.39759431, 'e0cba319730d41320fe1fe9db90a3037e5ab49e1c5bd63939716711efa95'),
(65, 'Pedro Lucas Garcia', '(60) 97283-2684', 'Patinete Eletrico', 'em_pausa', -20.71203596, -45.96719034, '175061d442dd1f396b611abd9fa50a8e613249aee48efe7db103f2a2021d'),
(66, 'Kaique Rocha', '(50) 98821-0099', 'A pe', 'em_entrega', -20.07484351, -45.12278206, '1f106df923b2f093931605e96854c07b202ef6c15b30b9048f8dbad91d9b'),
(67, 'Antonella das Neves', '(35) 93682-2239', 'Patinete Eletrico', 'disponivel', -23.49029612, -44.4319198, '7366022f7022a366e21f737db4640710e3fc831bd23aa909d835ad7e77ad'),
(68, 'Danilo Cirino', '(90) 98781-4141', 'Bicicleta', 'em_entrega', -22.41914947, -46.65077193, 'f92d4ef682eaf972f8ff3916eaaeca4c3614824c9b9c14299bcb528de936'),
(69, 'Raquel Farias', '(52) 93149-1357', 'Patinete Eletrico', 'disponivel', -22.74613749, -43.67093955, '219f4d4e2f55ddc609ca8d0d385a75ae3506c5945db3ea39ac16e4c71c5e'),
(70, 'Lorena Sales', '(92) 99955-6205', 'Moto', 'em_pausa', -20.00116918, -44.36824512, 'ca2b4296421481c815046b92e240fed9d9ae9a6b955a1b373b19b33eddd5'),
(71, 'Pedro Henrique da Mota', '(52) 95777-5478', 'Bicicleta', 'em_pausa', -20.05591837, -45.64929838, 'd4b62b4f2375abeda2aadf49218c22f11161dbda953caea6e76fc36e0742'),
(72, 'Anna Liz da Mota', '(28) 93411-0809', 'Carro', 'em_pausa', -20.42804901, -43.17111932, '2c0c2f3f338d2dd22295088281cdfae34ccbc75c36f9b707490aaf3cd84f'),
(73, 'Hadassa Andrade', '(84) 98872-5639', 'Bicicleta', 'em_pausa', -21.50519271, -45.31909035, '66b36f350e2d84c625921927f6b9d3c60eee37072fc5fbf67f7a7a50eaf0'),
(74, 'Davi Luiz Martins', '(88) 91658-0392', 'A pe', 'em_entrega', -20.31669765, -45.70550935, 'f237ade6c2fa07fb4c2ac0209c9b32e1f9f8275e1beee2a42bb718617f2c'),
(75, 'Pietro Castro', '(29) 99275-0373', 'Patinete Eletrico', 'offline', -20.0498561, -44.87214437, '0c74e22093e333c2b0fae2dcc9d24a987f7fd2dec32ad2a29c9170406d9f'),
(76, 'Sr. Asafe Rios', '(38) 95677-0051', 'Moto', 'offline', -20.84100627, -43.68508668, '52b94111d4231b9ba359a51bd039a1d065cb7c68459650fa86585f2b137d'),
(77, 'Kamilly Sousa', '(49) 98926-6591', 'A pe', 'em_pausa', -20.31200974, -45.09242939, '0150fb58f5655a7213e872257acea9c0a40128ed2e35b9556c599be7edae'),
(78, 'Heloisa Moreira', '(65) 95779-0827', 'Patinete Eletrico', 'offline', -22.33672817, -43.95365836, 'ef645aa7f1f4e31c5d9d3e0e60aa6dc3785d73a1c302b058239bb08f601a'),
(79, 'Théo Ramos', '(43) 92225-9136', 'Patinete Eletrico', 'em_pausa', -20.05516143, -43.56943394, '2035d50e07a5c5cebc88d5ed81aa2d4a28a85f720827d054be8988397f2b'),
(80, 'Srta. Rafaela Rocha', '(77) 93926-0302', 'Bicicleta', 'em_pausa', -22.7124627, -43.90803989, '77044539423b071dc9f3ec00c1c088e66904a9332ee5e32467d4655faac9'),
(81, 'Davi Luiz Pires', '(80) 99202-4286', 'Moto', 'offline', -20.77012042, -44.16117963, '42b2e2d04133a791db9188ae002733b46659437719757663220c86030a2e'),
(82, 'Allana Silveira', '(41) 93797-7236', 'Patinete Eletrico', 'em_pausa', -19.84402679, -43.84738282, 'cb42aab02d55f72327ba6b09f05092fed021957d08e52bf3c378322663cb'),
(83, 'Emilly Pinto', '(84) 92579-9136', 'Bicicleta', 'em_pausa', -19.93366713, -46.24551343, '4ac21357257c9a0a77995fac58389309a93d936e2511a19ea4902f5e9d7d'),
(84, 'Antony Costa', '(88) 96291-2799', 'A pe', 'offline', -20.29513881, -43.55291465, '80b8fbbed0a37a6f27472adcfceff8b0141ffbb264421b531d6efff8d5ea'),
(85, 'Sarah Sá', '(11) 97298-0686', 'Patinete Eletrico', 'disponivel', -21.60138587, -45.05505893, '277024c01d9fcfeb0b30f079476c67300609991a9af489fb920cf1cb2b30'),
(86, 'Vinícius Lima', '(37) 96599-1624', 'Bicicleta', 'em_pausa', -20.29045471, -43.20815554, '5ae0aee3ce336e48a7fdd62912bbd3d08e1ec7c9afab4c0319807b12ff5e'),
(87, 'Bryan da Paz', '(98) 96430-0981', 'Moto', 'em_pausa', -20.63020389, -45.74591799, '0278cb92385060c13d1830e7eefa87664f90ce0e718482c90454c1b40e97'),
(88, 'Gabrielly Sales', '(56) 95126-9448', 'A pe', 'em_pausa', -21.13062072, -43.63364495, 'd28f299a09d678ab09704b2a6913c3424679e1ace6c989539e2d513247c3'),
(89, 'Dr. Miguel Sá', '(36) 98872-5887', 'A pe', 'em_pausa', -19.97426955, -44.44352296, '8703a7325b5a12fb602e543c6d092c60294ba6a35c567cd2f9d0904e6c18'),
(90, 'Luiz Felipe Vasconcelos', '(62) 91372-1386', 'Patinete Eletrico', 'disponivel', -21.25365405, -45.85482712, '0ca8b1082294cf907c43a82c195aceb2472400decf6a4ce0553310ca5e8c'),
(91, 'Ana Júlia Castro', '(60) 91279-6114', 'Carro', 'em_entrega', -20.76228781, -45.1377027, '43c280d8624ffc459a161c2560d71cbd5df1f9be42adcd047eb21f90a990'),
(92, 'Arthur Miguel Silveira', '(66) 99849-0277', 'Moto', 'disponivel', -21.9140215, -44.20159581, 'b249cf7b49394f4bd03652f1a944c61685ef883761eb30710415d5fa4b19'),
(93, 'Stella da Paz', '(30) 99883-9205', 'Moto', 'disponivel', -22.36737627, -46.49797078, '93d86eb47c19a38d2b5322409aba7ecaf25a54e095199f328a57aceb2b22'),
(94, 'Emanuel Borges', '(46) 95669-3801', 'Carro', 'offline', -21.96339021, -45.82088924, '9a6bd33655761aa9d08208b1140b0f39f74408623f979b38b44f0cdffdb4'),
(95, 'Larissa Silveira', '(89) 95543-9376', 'Patinete Eletrico', 'em_entrega', -22.95406213, -46.41571394, 'fcb0038c5fab2e2c0b640c1f553d60aa62e277429f9bf4c0d1039676217c'),
(96, 'Erick Jesus', '(81) 98184-5184', 'Patinete Eletrico', 'em_entrega', -21.70886444, -44.60063433, '01f3d0d19394f7c249e224913618068d6a8413d076e0c9df884b3974864d'),
(97, 'Isis Sales', '(76) 99735-7790', 'Bicicleta', 'em_pausa', -21.1759624, -45.0455462, '0b87d741983f2587ec370c36bab4d6c08de2111b2e138577fdc141f8a0ab'),
(98, 'Bernardo Garcia', '(33) 95658-8043', 'Moto', 'em_pausa', -20.17540419, -44.26060081, '52ba118fd4d01e421e68e739d218fad542a019f03a034bd32dcd892245e4'),
(99, 'Manuela Barbosa', '(82) 97553-9423', 'Bicicleta', 'disponivel', -21.92142682, -45.45596375, '7ebd0d1c74a37cfde4249f7d82ea2585359f8777a414a947a4a4d97e1c32'),
(100, 'Isaac Sousa', '(34) 93333-9521', 'A pe', 'offline', -21.17203293, -45.17248782, 'b493032e66d22d040a432ed139684450ef4c70df8dc1c63ab033566fd08e');

-- ======================================================================
-- CUPOM (100 registros)  
-- ======================================================================


INSERT INTO Cupom (
    codigo,
    tipo_desconto,
    valor_desconto,
    data_inicio,
    data_fim,
    ativo,
    limite_uso
)
VALUES
('FAST10', 'PERCENTUAL', 10.00, '2026-08-01', '2026-08-31', TRUE, 100),
('FAST15', 'PERCENTUAL', 15.00, '2026-08-01', '2026-09-15', TRUE, 50),
('FAST20', 'PERCENTUAL', 20.00, '2026-08-01', '2026-09-30', TRUE, 30),
('FAST5',  'VALOR',       5.00, '2026-08-01', '2026-08-31', TRUE, 100),
('FAST10R', 'VALOR',     10.00, '2026-08-05', '2026-09-05', TRUE, 80),
('BEMVINDO', 'PERCENTUAL', 10.00, '2026-08-01', '2026-12-31', TRUE, 200),
('PRIMEIRO', 'VALOR',     15.00, '2026-08-01', '2026-12-31', TRUE, 100),
('DELIVERY20', 'PERCENTUAL', 20.00, '2026-08-10', '2026-09-10', TRUE, 50),
('FRETEGRATIS', 'VALOR', 25.00, '2026-08-10', '2026-08-31', TRUE, 20),
('CLIENTEVIP', 'PERCENTUAL', 25.00, '2026-08-01', '2026-12-31', TRUE, 10);
 
-- ======================================================================
-- ENDERECO_CLIENTE (100 registros)
-- ======================================================================
INSERT INTO Endereco_cliente (endereco_id, cliente_id, rotulo, logradouro, numero, complemento, codigo_postal, latitude, longitude) VALUES
(1, 42, 'Casa', 'Viela Ribeiro', '328', 'Bloco C', '90807-595', -21.9055201, -44.11641352),
(2, 22, 'Apartamento', 'Travessa Yan Mendonça', '1440', 'Bloco A', '84639208', -21.26356437, -45.13421419),
(3, 82, 'Casa', 'Recanto Valentina Andrade', '308', 'Bloco D', '62718-750', -21.65027313, -44.00036726),
(4, 21, 'Casa', 'Viela Costela', '585', NULL, '91559-428', -23.12032591, -45.85041663),
(5, 83, 'Casa dos Pais', 'Feira Vitor Gabriel Melo', '1484', 'Apto 206', '52763-655', -21.01956418, -43.28423529),
(6, 48, 'Apartamento', 'Ladeira Manuella Cirino', '315', 'Bloco B', '93143866', -22.08747063, -44.36158135),
(7, 32, 'Casa', 'Distrito Sousa', '107', NULL, '70267288', -21.63256796, -43.41124698),
(8, 16, 'Casa dos Pais', 'Largo de Viana', '1067', 'Apto 370', '44890-612', -19.81381257, -45.67192324),
(9, 63, 'Trabalho', 'Favela da Cunha', '503', NULL, '17545-588', -22.94390582, -44.13186838),
(10, 12, 'Casa dos Pais', 'Morro Asafe Jesus', '1424', 'Bloco A', '59399824', -20.21293961, -43.63509662),
(11, 92, 'Trabalho', 'Largo Nina Mendonça', '1481', NULL, '16947-225', -19.85649632, -43.84856357),
(12, 31, 'Apartamento', 'Vereda Jade Barbosa', '108', NULL, '25355449', -20.54608544, -44.71407104),
(13, 79, 'Casa', 'Passarela de da Mata', '270', NULL, '59876-220', -21.60235651, -43.93100762),
(14, 74, 'Casa', 'Feira Ribeiro', '514', NULL, '13261-117', -21.82983384, -44.83750396),
(15, 17, 'Outro', 'Avenida de Alves', '2408', NULL, '81149-216', -21.68911761, -43.57443814),
(16, 16, 'Outro', 'Fazenda Thales Sousa', '627', 'Apto 165', '72282-005', -22.37388915, -44.14640432),
(17, 45, 'Outro', 'Recanto Maria Helena Nogueira', '1164', 'Apto 50', '87282-997', -21.18678305, -44.7169709),
(18, 17, 'Casa dos Pais', 'Vereda de Nunes', '2186', 'Apto 57', '88457-831', -22.94943763, -44.45187493),
(19, 78, 'Casa dos Pais', 'Lagoa Emanuelly Jesus', '2309', NULL, '24008-254', -23.42724515, -44.39076656),
(20, 74, 'Casa dos Pais', 'Setor Antony Sales', '864', NULL, '74064-930', -21.70745537, -44.44220956),
(21, 38, 'Casa dos Pais', 'Núcleo de Correia', '1979', 'Bloco D', '86632-663', -21.87653229, -44.22099114),
(22, 21, 'Apartamento', 'Chácara Lavínia Pires', '1703', 'Apto 257', '89448463', -22.30726824, -46.18279271),
(23, 92, 'Casa dos Pais', 'Estação Carvalho', '1415', 'Bloco B', '17974-973', -21.64307549, -46.31773784),
(24, 31, 'Apartamento', 'Alameda Kevin Aragão', '502', 'Apto 146', '21442703', -23.06466499, -46.51782095),
(25, 50, 'Outro', 'Distrito Albuquerque', '1713', 'Bloco B', '35647-570', -20.05174417, -44.10393766),
(26, 25, 'Trabalho', 'Chácara João Vitor Araújo', '2041', NULL, '61872-346', -20.25951248, -44.90946702),
(27, 12, 'Apartamento', 'Condomínio Vargas', '2071', 'Apto 244', '67303718', -21.38329237, -46.52483072),
(28, 37, 'Apartamento', 'Favela de Melo', '2448', 'Bloco D', '45208-814', -21.56057515, -43.65017948),
(29, 56, 'Trabalho', 'Vereda Ana Cecília Costa', '1084', NULL, '03136-502', -22.20943806, -45.25790616),
(30, 73, 'Outro', 'Trecho Isaque Gonçalves', '798', NULL, '00979251', -22.13187447, -45.07872423),
(31, 71, 'Casa dos Pais', 'Esplanada Monteiro', '487', NULL, '95005281', -22.18184632, -43.14756441),
(32, 72, 'Casa dos Pais', 'Residencial da Conceição', '591', NULL, '85730-652', -23.42784726, -46.20666906),
(33, 43, 'Apartamento', 'Área Maria Vitória Santos', '2128', 'Apto 243', '84873-928', -22.35372978, -44.49295476),
(34, 21, 'Apartamento', 'Largo Maria Helena da Mota', '1226', NULL, '18274485', -20.90678874, -45.62075397),
(35, 3, 'Casa dos Pais', 'Aeroporto Natália Garcia', '1357', NULL, '09593518', -21.38193186, -43.83168267),
(36, 93, 'Casa', 'Estrada Sabrina Rodrigues', '2445', 'Apto 252', '82945-651', -20.85867957, -44.5993162),
(37, 22, 'Outro', 'Rua Ribeiro', '1558', NULL, '02203173', -21.42423297, -44.17812472),
(38, 25, 'Casa', 'Área Oliveira', '1807', 'Apto 170', '78994-053', -22.03075158, -45.96598994),
(39, 65, 'Outro', 'Campo de Albuquerque', '1932', 'Apto 386', '71705865', -21.6290038, -44.68080762),
(40, 85, 'Apartamento', 'Avenida de Pimenta', '2153', 'Apto 202', '80141-381', -21.85327858, -44.78074257),
(41, 70, 'Casa dos Pais', 'Fazenda Nascimento', '1083', 'Apto 322', '33839-288', -19.96211789, -45.69557697),
(42, 39, 'Trabalho', 'Colônia Elisa Rocha', '1220', NULL, '61228-685', -22.39524517, -45.44430857),
(43, 93, 'Casa dos Pais', 'Esplanada de Nascimento', '1179', NULL, '55855-665', -20.49016565, -43.26340809),
(44, 19, 'Casa dos Pais', 'Feira de Nunes', '173', 'Bloco A', '68457760', -20.0887634, -44.33850062),
(45, 96, 'Apartamento', 'Área de da Paz', '877', 'Bloco C', '82404335', -23.07836277, -44.48356268),
(46, 76, 'Trabalho', 'Vila da Mota', '994', 'Apto 35', '10752245', -23.40053379, -45.21211508),
(47, 92, 'Apartamento', 'Feira de da Conceição', '412', NULL, '41969-315', -19.93482868, -43.17952144),
(48, 21, 'Apartamento', 'Estação Mariah Sales', '1949', 'Bloco B', '94096105', -22.37956273, -44.3747675),
(49, 99, 'Casa', 'Praça Lara Campos', '2352', 'Apto 128', '90604805', -22.01203707, -43.6846224),
(50, 5, 'Apartamento', 'Travessa de Cassiano', '2030', NULL, '83206-799', -23.56478476, -44.65533727),
(51, 14, 'Casa dos Pais', 'Chácara de Câmara', '1166', 'Apto 242', '46225-179', -20.36597299, -45.01512523),
(52, 25, 'Casa', 'Avenida de Novaes', '1355', 'Bloco D', '41686-227', -20.86932694, -46.6492969),
(53, 44, 'Casa dos Pais', 'Estrada de Mendonça', '2326', 'Apto 355', '93898-331', -21.2783729, -44.40058714),
(54, 52, 'Apartamento', 'Praça Ayla Rodrigues', '2111', NULL, '16655355', -21.05682776, -46.03478768),
(55, 18, 'Apartamento', 'Via de Alves', '1326', 'Bloco A', '25979-270', -22.14241732, -45.09175212),
(56, 35, 'Casa dos Pais', 'Estrada Rodrigues', '1237', 'Bloco A', '21103-924', -21.11600321, -44.20603307),
(57, 8, 'Casa', 'Loteamento Sales', '1907', NULL, '47705383', -20.99292024, -43.37681835),
(58, 91, 'Casa dos Pais', 'Setor Moreira', '481', 'Bloco C', '87920-698', -21.2644233, -45.91113704),
(59, 18, 'Apartamento', 'Jardim Cavalcante', '628', NULL, '43940701', -20.93262524, -43.4139312),
(60, 97, 'Outro', 'Viaduto Vitor Hugo Ribeiro', '895', NULL, '10463-681', -21.60307471, -44.79857675),
(61, 47, 'Casa', 'Residencial Sophia Borges', '2311', 'Apto 67', '38780038', -21.42373364, -46.16053143),
(62, 42, 'Outro', 'Loteamento Mariana Gonçalves', '1810', NULL, '05554384', -23.25442175, -44.86264873),
(63, 8, 'Apartamento', 'Vereda da Cunha', '541', NULL, '08432-562', -21.4571375, -44.68833008),
(64, 87, 'Casa dos Pais', 'Parque Moreira', '90', NULL, '63926495', -20.76594297, -44.61807945),
(65, 6, 'Apartamento', 'Setor João Costela', '1412', NULL, '98324826', -20.04858536, -46.45153107),
(66, 61, 'Casa', 'Via Nunes', '1176', 'Apto 219', '51881252', -20.6898548, -43.17800017),
(67, 83, 'Apartamento', 'Alameda de Teixeira', '1534', NULL, '66474-231', -22.17254697, -44.24217073),
(68, 85, 'Outro', 'Estação Alves', '545', NULL, '99939-330', -22.92180021, -44.76586945),
(69, 68, 'Trabalho', 'Chácara Maria Liz Carvalho', '913', 'Bloco A', '52677-223', -21.84058518, -44.11126169),
(70, 55, 'Outro', 'Área Jesus', '1554', NULL, '46333127', -22.28459301, -45.70766098),
(71, 93, 'Casa', 'Residencial de Sales', '132', NULL, '73660-965', -22.68546808, -46.45775275),
(72, 77, 'Casa', 'Vale Stella Moura', '1829', 'Apto 316', '81770388', -20.7859439, -45.25184474),
(73, 30, 'Outro', 'Área Hellena Moreira', '890', 'Apto 396', '34764472', -21.68519577, -45.65865158),
(74, 94, 'Outro', 'Lago Cauê Sales', '1307', 'Apto 305', '77181298', -22.45329515, -46.18426244),
(75, 85, 'Outro', 'Passarela Jesus', '906', 'Bloco C', '70279-371', -23.36836098, -43.28532708),
(76, 95, 'Trabalho', 'Largo Luan Silva', '1750', NULL, '11751868', -19.90529711, -43.31028892),
(77, 86, 'Apartamento', 'Esplanada de Garcia', '2149', NULL, '02592-222', -23.03297309, -45.34474332),
(78, 97, 'Outro', 'Avenida de Leão', '1940', 'Bloco B', '47421-230', -20.34134329, -46.1803337),
(79, 60, 'Casa', 'Jardim de Albuquerque', '2304', 'Apto 221', '77809-733', -22.12400761, -45.78201568),
(80, 43, 'Casa', 'Viaduto de Melo', '1843', 'Apto 199', '67199-038', -23.40416081, -45.34219529),
(81, 78, 'Outro', 'Vale Oliver Aragão', '162', 'Apto 47', '20502099', -21.77830202, -43.56989413),
(82, 43, 'Casa dos Pais', 'Loteamento Erick Aragão', '63', NULL, '62249998', -20.76185894, -43.98440933),
(83, 32, 'Outro', 'Quadra Souza', '838', 'Bloco B', '01455-616', -20.65304725, -45.32961772),
(84, 69, 'Casa dos Pais', 'Campo de da Rocha', '1264', NULL, '21458-683', -21.82918455, -43.80986016),
(85, 93, 'Apartamento', 'Favela de Pimenta', '1312', 'Bloco C', '19817946', -22.02706535, -44.67491098),
(86, 29, 'Trabalho', 'Largo de da Luz', '67', 'Bloco D', '29978-772', -23.02083664, -45.51248497),
(87, 49, 'Outro', 'Fazenda de Santos', '1007', 'Bloco C', '30107-139', -20.69922962, -44.94096404),
(88, 93, 'Apartamento', 'Pátio Caleb Farias', '1888', 'Apto 96', '83034-414', -23.06815759, -44.73243322),
(89, 24, 'Outro', 'Rodovia Ísis Duarte', '241', NULL, '15569902', -20.00828518, -44.29442404),
(90, 98, 'Casa', 'Loteamento Fernandes', '1690', NULL, '70272-785', -20.91275566, -46.66709074),
(91, 65, 'Apartamento', 'Pátio Daniel Moreira', '1529', NULL, '95880-395', -23.54021929, -44.78403505),
(92, 53, 'Casa', 'Campo Kaique da Mota', '69', 'Bloco C', '56829962', -23.53485813, -43.772634),
(93, 87, 'Apartamento', 'Condomínio de Viana', '735', 'Apto 64', '50461-735', -22.68431844, -44.46878897),
(94, 33, 'Casa dos Pais', 'Lagoa Pedro Moura', '1095', 'Bloco A', '21503-178', -19.95466838, -45.04760812),
(95, 32, 'Trabalho', 'Recanto Montenegro', '1229', NULL, '35784521', -23.24469808, -45.33464952),
(96, 71, 'Apartamento', 'Viela de Cardoso', '230', 'Apto 336', '07681040', -23.28579273, -43.65681274),
(97, 83, 'Casa dos Pais', 'Trevo de Borges', '2318', 'Apto 58', '70184-094', -22.79661519, -43.57477919),
(98, 73, 'Apartamento', 'Favela de Duarte', '1111', 'Bloco A', '34485714', -20.18261573, -44.67136449),
(99, 5, 'Trabalho', 'Esplanada da Mota', '1289', 'Apto 18', '09881385', -20.74143301, -44.13423896),
(100, 51, 'Casa', 'Largo de da Mata', '1226', NULL, '49321495', -21.02726713, -44.75397525);
 
-- ======================================================================
-- MENU (100 registros)
-- ======================================================================
INSERT INTO Menu (menu_id, restaurante_id, nome, data_inicio, data_fim) VALUES
(1, 50, 'Cardapio Sazonal', '2025-02-05', '2025-10-25'),
(2, 89, 'Cardapio Sazonal', '2025-01-21', '2025-07-28'),
(3, 96, 'Cardapio de Jantar', '2025-01-14', '2025-04-09'),
(4, 56, 'Cardapio de Almoco', '2025-01-20', '2025-06-16'),
(5, 78, 'Cardapio Fim de Semana', '2025-06-02', '2025-11-10'),
(6, 100, 'Cardapio de Jantar', '2025-01-08', '2025-08-18'),
(7, 35, 'Promocoes da Semana', '2025-05-06', '2025-09-01'),
(8, 46, 'Cardapio Fim de Semana', '2025-04-07', '2025-09-24'),
(9, 24, 'Cardapio Sazonal', '2025-05-30', '2026-01-14'),
(10, 49, 'Cardapio Principal', '2025-07-17', '2026-02-20'),
(11, 38, 'Cardapio de Almoco', '2025-07-02', '2025-09-18'),
(12, 11, 'Cardapio de Jantar', '2025-02-09', '2025-07-16'),
(13, 92, 'Cardapio Sazonal', '2025-02-09', '2025-10-16'),
(14, 50, 'Cardapio de Jantar', '2025-04-03', '2025-06-29'),
(15, 12, 'Cardapio Principal', '2025-03-20', '2025-09-09'),
(16, 47, 'Cardapio de Jantar', '2025-01-27', '2025-04-30'),
(17, 12, 'Cardapio de Almoco', '2025-04-21', '2025-10-12'),
(18, 72, 'Cardapio Fim de Semana', '2025-05-12', '2025-10-23'),
(19, 14, 'Cardapio Principal', '2025-01-23', '2025-06-22'),
(20, 71, 'Cardapio Principal', '2025-06-02', '2026-01-01'),
(21, 42, 'Promocoes da Semana', '2025-01-04', '2025-05-18'),
(22, 53, 'Promocoes da Semana', '2025-07-19', '2025-10-08'),
(23, 93, 'Cardapio Fim de Semana', '2025-03-04', '2025-09-26'),
(24, 67, 'Cardapio de Almoco', '2025-06-25', '2025-11-29'),
(25, 22, 'Cardapio de Almoco', '2025-03-10', '2025-07-25'),
(26, 35, 'Promocoes da Semana', '2025-02-07', '2025-04-24'),
(27, 22, 'Promocoes da Semana', '2025-03-12', '2025-08-26'),
(28, 39, 'Promocoes da Semana', '2025-07-20', '2025-10-07'),
(29, 47, 'Cardapio de Jantar', '2025-03-05', '2025-11-04'),
(30, 81, 'Promocoes da Semana', '2025-06-02', '2026-01-05'),
(31, 26, 'Promocoes da Semana', '2025-01-28', '2025-05-02'),
(32, 39, 'Cardapio Principal', '2025-04-12', '2025-09-04'),
(33, 80, 'Promocoes da Semana', '2025-03-26', '2025-09-14'),
(34, 43, 'Promocoes da Semana', '2025-06-16', '2026-01-14'),
(35, 18, 'Cardapio de Jantar', '2025-03-24', '2025-10-24'),
(36, 89, 'Cardapio de Almoco', '2025-05-03', '2025-09-20'),
(37, 23, 'Promocoes da Semana', '2025-03-23', '2025-08-04'),
(38, 95, 'Cardapio Sazonal', '2025-06-12', '2025-12-14'),
(39, 74, 'Cardapio de Almoco', '2025-03-25', '2025-08-28'),
(40, 36, 'Promocoes da Semana', '2025-04-04', '2025-07-02'),
(41, 73, 'Cardapio de Almoco', '2025-06-01', '2025-12-17'),
(42, 24, 'Cardapio Sazonal', '2025-07-16', '2026-02-01'),
(43, 4, 'Cardapio Sazonal', '2025-04-29', '2025-12-26'),
(44, 27, 'Promocoes da Semana', '2025-03-16', '2025-12-13'),
(45, 89, 'Cardapio Principal', '2025-04-15', '2025-12-03'),
(46, 64, 'Cardapio de Almoco', '2025-06-12', '2025-10-27'),
(47, 31, 'Cardapio de Jantar', '2025-06-18', '2025-09-25'),
(48, 92, 'Promocoes da Semana', '2025-04-07', '2025-06-24'),
(49, 58, 'Cardapio Fim de Semana', '2025-05-03', '2025-11-28'),
(50, 52, 'Cardapio Fim de Semana', '2025-05-10', '2026-03-02'),
(51, 89, 'Promocoes da Semana', '2025-05-20', '2025-07-28'),
(52, 47, 'Cardapio Sazonal', '2025-05-18', '2025-12-16'),
(53, 82, 'Cardapio Principal', '2025-01-28', '2025-10-11'),
(54, 32, 'Cardapio Sazonal', '2025-06-20', '2025-11-17'),
(55, 22, 'Cardapio Sazonal', '2025-06-06', '2025-08-16'),
(56, 73, 'Cardapio Sazonal', '2025-06-23', '2026-02-03'),
(57, 52, 'Cardapio de Jantar', '2025-04-21', '2025-07-17'),
(58, 2, 'Cardapio Principal', '2025-03-08', '2025-07-02'),
(59, 66, 'Cardapio Sazonal', '2025-05-13', '2025-12-01'),
(60, 75, 'Cardapio Sazonal', '2025-05-28', '2025-09-21'),
(61, 58, 'Cardapio de Jantar', '2025-04-11', '2025-10-06'),
(62, 99, 'Cardapio Sazonal', '2025-05-31', '2026-01-22'),
(63, 65, 'Cardapio de Almoco', '2025-03-30', '2025-06-04'),
(64, 62, 'Cardapio Principal', '2025-03-17', '2025-08-30'),
(65, 11, 'Cardapio Principal', '2025-07-06', '2025-10-10'),
(66, 45, 'Cardapio de Jantar', '2025-03-29', '2025-09-21'),
(67, 27, 'Cardapio Fim de Semana', '2025-05-04', '2025-09-30'),
(68, 61, 'Cardapio Principal', '2025-04-23', '2025-12-23'),
(69, 90, 'Promocoes da Semana', '2025-03-23', '2025-06-08'),
(70, 39, 'Cardapio Principal', '2025-07-01', '2025-09-28'),
(71, 3, 'Cardapio de Jantar', '2025-06-15', '2025-09-10'),
(72, 87, 'Cardapio de Almoco', '2025-07-09', '2025-11-08'),
(73, 67, 'Cardapio de Almoco', '2025-05-22', '2025-08-30'),
(74, 43, 'Cardapio Fim de Semana', '2025-04-20', '2025-10-15'),
(75, 30, 'Promocoes da Semana', '2025-06-11', '2025-09-26'),
(76, 24, 'Cardapio Sazonal', '2025-06-18', '2025-12-05'),
(77, 51, 'Cardapio Principal', '2025-07-08', '2026-02-10'),
(78, 26, 'Promocoes da Semana', '2025-06-01', '2025-11-17'),
(79, 50, 'Cardapio Principal', '2025-06-30', '2025-10-22'),
(80, 27, 'Cardapio de Jantar', '2025-07-12', '2026-03-09'),
(81, 9, 'Cardapio Fim de Semana', '2025-01-27', '2025-10-18'),
(82, 69, 'Cardapio de Almoco', '2025-04-04', '2025-08-25'),
(83, 26, 'Promocoes da Semana', '2025-01-30', '2025-06-06'),
(84, 86, 'Promocoes da Semana', '2025-05-16', '2025-12-25'),
(85, 41, 'Cardapio Fim de Semana', '2025-04-10', '2025-11-12'),
(86, 51, 'Cardapio Fim de Semana', '2025-01-30', '2025-06-28'),
(87, 46, 'Promocoes da Semana', '2025-06-08', '2025-09-20'),
(88, 87, 'Cardapio Sazonal', '2025-03-18', '2026-01-07'),
(89, 79, 'Cardapio Fim de Semana', '2025-01-22', '2025-09-11'),
(90, 18, 'Cardapio de Jantar', '2025-01-31', '2025-06-01'),
(91, 40, 'Cardapio Principal', '2025-02-16', '2025-07-21'),
(92, 89, 'Cardapio de Almoco', '2025-05-11', '2025-10-17'),
(93, 54, 'Cardapio Fim de Semana', '2025-02-05', '2025-08-31'),
(94, 50, 'Promocoes da Semana', '2025-02-17', '2025-08-20'),
(95, 82, 'Cardapio Fim de Semana', '2025-06-27', '2026-04-18'),
(96, 83, 'Cardapio de Almoco', '2025-05-23', '2025-09-02'),
(97, 63, 'Cardapio de Jantar', '2025-02-05', '2025-05-23'),
(98, 41, 'Promocoes da Semana', '2025-06-08', '2025-08-20'),
(99, 46, 'Cardapio Principal', '2025-05-05', '2025-08-07'),
(100, 25, 'Promocoes da Semana', '2025-05-24', '2025-11-29');
 
-- ======================================================================
-- ITEM_MENU (150 registros)
-- ======================================================================
INSERT INTO Item_menu (item_menu_id, menu_id, nome_prato, descricao, preco, disponivel) VALUES
(1, 84, 'Brownie com Sorvete', 'Preparado com ingredientes selecionados e servido com acompanhamento', 64.68, 0),
(2, 91, 'Risoto de Camarao', 'Preparado com ingredientes selecionados e servido com acompanhamento', 49.0, 1),
(3, 73, 'X-Burguer', 'Preparado com ingredientes selecionados e servido gelado', 33.27, 1),
(4, 29, 'Espeto de Picanha', 'Preparado com ingredientes selecionados e servido na hora', 23.36, 0),
(5, 73, 'Yakisoba de Frango', 'Preparado com ingredientes selecionados e servido com acompanhamento', 53.88, 1),
(6, 74, 'Pizza Margherita', 'Preparado com ingredientes selecionados e servido na hora', 71.91, 1),
(7, 70, 'Risoto de Camarao', 'Preparado com ingredientes selecionados e servido quente', 70.7, 0),
(8, 70, 'Temaki de Salmao', 'Preparado com ingredientes selecionados e servido com acompanhamento', 18.09, 1),
(9, 39, 'Cafe Expresso', 'Preparado com ingredientes selecionados e servido quente', 45.88, 1),
(10, 12, 'Burrito de Frango', 'Preparado com ingredientes selecionados e servido quente', 71.95, 1),
(11, 27, 'Camarao Empanado', 'Preparado com ingredientes selecionados e servido em porcao individual', 65.03, 0),
(12, 22, 'Bowl Fitness de Frango', 'Preparado com ingredientes selecionados e servido gelado', 72.69, 1),
(13, 8, 'Costela ao Bafo', 'Preparado com ingredientes selecionados e servido na hora', 52.48, 1),
(14, 42, 'Kibe Frito', 'Preparado com ingredientes selecionados e servido na hora', 33.05, 1),
(15, 66, 'Cappuccino', 'Preparado com ingredientes selecionados e servido quente', 20.75, 0),
(16, 8, 'Moqueca de Peixe', 'Preparado com ingredientes selecionados e servido gelado', 66.01, 1),
(17, 32, 'Pizza Calabresa', 'Preparado com ingredientes selecionados e servido na hora', 76.18, 0),
(18, 63, 'Pizza Calabresa', 'Preparado com ingredientes selecionados e servido em porcao individual', 60.49, 0),
(19, 49, 'Burrito de Frango', 'Preparado com ingredientes selecionados e servido quente', 60.59, 1),
(20, 52, 'Petit Gateau', 'Preparado com ingredientes selecionados e servido na hora', 65.48, 1),
(21, 59, 'Brownie com Sorvete', 'Preparado com ingredientes selecionados e servido na hora', 56.46, 1),
(22, 94, 'Burrito de Frango', 'Preparado com ingredientes selecionados e servido na hora', 77.91, 0),
(23, 28, 'Tacos de Carne', 'Preparado com ingredientes selecionados e servido gelado', 49.48, 1),
(24, 37, 'Wrap de Frango', 'Preparado com ingredientes selecionados e servido em porcao individual', 56.13, 0),
(25, 44, 'Cappuccino', 'Preparado com ingredientes selecionados e servido quente', 13.58, 0),
(26, 3, 'Pizza Margherita', 'Preparado com ingredientes selecionados e servido gelado', 45.2, 1),
(27, 55, 'Temaki de Salmao', 'Preparado com ingredientes selecionados e servido gelado', 80.47, 1),
(28, 21, 'Cafe Expresso', 'Preparado com ingredientes selecionados e servido na hora', 17.37, 1),
(29, 33, 'X-Bacon', 'Preparado com ingredientes selecionados e servido na hora', 63.06, 1),
(30, 7, 'Nhoque ao Sugo', 'Preparado com ingredientes selecionados e servido na hora', 67.98, 1),
(31, 55, 'Salada de Quinoa', 'Preparado com ingredientes selecionados e servido quente', 66.2, 1),
(32, 28, 'Brownie com Sorvete', 'Preparado com ingredientes selecionados e servido quente', 20.52, 1),
(33, 67, 'Esfiha de Carne', 'Preparado com ingredientes selecionados e servido com acompanhamento', 10.64, 1),
(34, 16, 'Cafe Expresso', 'Preparado com ingredientes selecionados e servido com acompanhamento', 65.42, 0),
(35, 10, 'Feijoada Completa', 'Preparado com ingredientes selecionados e servido com acompanhamento', 17.05, 1),
(36, 14, 'Wrap de Frango', 'Preparado com ingredientes selecionados e servido na hora', 80.38, 1),
(37, 49, 'Rolinho Primavera', 'Preparado com ingredientes selecionados e servido gelado', 61.23, 1),
(38, 9, 'Petit Gateau', 'Preparado com ingredientes selecionados e servido em porcao individual', 10.58, 1),
(39, 57, 'Lasanha a Bolonhesa', 'Preparado com ingredientes selecionados e servido gelado', 60.15, 1),
(40, 53, 'Bowl Fitness de Frango', 'Preparado com ingredientes selecionados e servido com acompanhamento', 78.7, 1),
(41, 13, 'Pizza Calabresa', 'Preparado com ingredientes selecionados e servido quente', 57.07, 0),
(42, 45, 'Tacos de Carne', 'Preparado com ingredientes selecionados e servido na hora', 73.19, 1),
(43, 36, 'Salada de Quinoa', 'Preparado com ingredientes selecionados e servido quente', 29.75, 1),
(44, 100, 'Kibe Frito', 'Preparado com ingredientes selecionados e servido quente', 77.73, 1),
(45, 27, 'Petit Gateau', 'Preparado com ingredientes selecionados e servido em porcao individual', 50.66, 0),
(46, 38, 'Salada de Quinoa', 'Preparado com ingredientes selecionados e servido quente', 72.6, 1),
(47, 64, 'Nhoque ao Sugo', 'Preparado com ingredientes selecionados e servido quente', 29.19, 1),
(48, 68, 'Cappuccino', 'Preparado com ingredientes selecionados e servido quente', 88.85, 1),
(49, 17, 'Nhoque ao Sugo', 'Preparado com ingredientes selecionados e servido em porcao individual', 43.57, 1),
(50, 98, 'Brownie com Sorvete', 'Preparado com ingredientes selecionados e servido quente', 11.24, 1),
(51, 2, 'Moqueca de Peixe', 'Preparado com ingredientes selecionados e servido gelado', 13.09, 1),
(52, 51, 'Petit Gateau', 'Preparado com ingredientes selecionados e servido na hora', 60.19, 0),
(53, 55, 'Kibe Frito', 'Preparado com ingredientes selecionados e servido com acompanhamento', 16.49, 1),
(54, 36, 'X-Bacon', 'Preparado com ingredientes selecionados e servido na hora', 16.22, 1),
(55, 20, 'Espeto de Picanha', 'Preparado com ingredientes selecionados e servido na hora', 41.16, 1),
(56, 40, 'Kibe Frito', 'Preparado com ingredientes selecionados e servido com acompanhamento', 68.3, 1),
(57, 8, 'Feijoada Completa', 'Preparado com ingredientes selecionados e servido quente', 83.87, 1),
(58, 59, 'Bowl Fitness de Frango', 'Preparado com ingredientes selecionados e servido em porcao individual', 14.3, 1),
(59, 16, 'X-Burguer', 'Preparado com ingredientes selecionados e servido gelado', 66.02, 1),
(60, 64, 'Lasanha a Bolonhesa', 'Preparado com ingredientes selecionados e servido em porcao individual', 51.28, 1),
(61, 22, 'Lasanha a Bolonhesa', 'Preparado com ingredientes selecionados e servido gelado', 69.88, 1),
(62, 94, 'Cappuccino', 'Preparado com ingredientes selecionados e servido quente', 71.61, 1),
(63, 43, 'Camarao Empanado', 'Preparado com ingredientes selecionados e servido com acompanhamento', 31.66, 1),
(64, 34, 'Kibe Frito', 'Preparado com ingredientes selecionados e servido em porcao individual', 60.1, 0),
(65, 59, 'Petit Gateau', 'Preparado com ingredientes selecionados e servido na hora', 14.34, 1),
(66, 48, 'Combo Sushi 20 pecas', 'Preparado com ingredientes selecionados e servido na hora', 71.77, 1),
(67, 30, 'Yakisoba de Frango', 'Preparado com ingredientes selecionados e servido em porcao individual', 10.11, 1),
(68, 32, 'X-Salada', 'Preparado com ingredientes selecionados e servido com acompanhamento', 39.02, 1),
(69, 23, 'Suco Natural', 'Preparado com ingredientes selecionados e servido quente', 54.13, 0),
(70, 29, 'Wrap de Frango', 'Preparado com ingredientes selecionados e servido gelado', 43.2, 1),
(71, 35, 'Risoto de Camarao', 'Preparado com ingredientes selecionados e servido quente', 55.62, 1),
(72, 65, 'Esfiha de Carne', 'Preparado com ingredientes selecionados e servido quente', 24.25, 1),
(73, 52, 'X-Bacon', 'Preparado com ingredientes selecionados e servido com acompanhamento', 79.18, 1),
(74, 42, 'X-Bacon', 'Preparado com ingredientes selecionados e servido em porcao individual', 46.44, 1),
(75, 26, 'Salada Caesar', 'Preparado com ingredientes selecionados e servido em porcao individual', 72.66, 1),
(76, 60, 'Lasanha a Bolonhesa', 'Preparado com ingredientes selecionados e servido em porcao individual', 87.65, 1),
(77, 94, 'Cappuccino', 'Preparado com ingredientes selecionados e servido em porcao individual', 70.74, 1),
(78, 20, 'X-Burguer', 'Preparado com ingredientes selecionados e servido com acompanhamento', 11.81, 1),
(79, 82, 'Risoto de Camarao', 'Preparado com ingredientes selecionados e servido quente', 85.98, 1),
(80, 98, 'Esfiha de Carne', 'Preparado com ingredientes selecionados e servido com acompanhamento', 77.82, 1),
(81, 14, 'Temaki de Salmao', 'Preparado com ingredientes selecionados e servido em porcao individual', 88.55, 0),
(82, 63, 'X-Salada', 'Preparado com ingredientes selecionados e servido gelado', 66.83, 1),
(83, 6, 'Suco Natural', 'Preparado com ingredientes selecionados e servido gelado', 81.68, 0),
(84, 90, 'Cappuccino', 'Preparado com ingredientes selecionados e servido na hora', 46.58, 1),
(85, 75, 'Pizza Margherita', 'Preparado com ingredientes selecionados e servido em porcao individual', 20.58, 0),
(86, 10, 'Costela ao Bafo', 'Preparado com ingredientes selecionados e servido em porcao individual', 14.88, 1),
(87, 31, 'Salada Caesar', 'Preparado com ingredientes selecionados e servido na hora', 77.97, 0),
(88, 90, 'Risoto de Camarao', 'Preparado com ingredientes selecionados e servido na hora', 35.34, 1),
(89, 30, 'X-Bacon', 'Preparado com ingredientes selecionados e servido gelado', 20.79, 1),
(90, 20, 'Pizza Margherita', 'Preparado com ingredientes selecionados e servido gelado', 45.87, 1),
(91, 53, 'Pizza Margherita', 'Preparado com ingredientes selecionados e servido em porcao individual', 38.56, 1),
(92, 58, 'Salada Caesar', 'Preparado com ingredientes selecionados e servido com acompanhamento', 31.1, 1),
(93, 12, 'Combo Sushi 20 pecas', 'Preparado com ingredientes selecionados e servido na hora', 76.01, 1),
(94, 28, 'Risoto de Camarao', 'Preparado com ingredientes selecionados e servido na hora', 21.77, 1),
(95, 46, 'Nhoque ao Sugo', 'Preparado com ingredientes selecionados e servido em porcao individual', 13.82, 1),
(96, 34, 'Risoto de Camarao', 'Preparado com ingredientes selecionados e servido gelado', 12.39, 0),
(97, 58, 'Espeto de Picanha', 'Preparado com ingredientes selecionados e servido em porcao individual', 29.89, 0),
(98, 14, 'Camarao Empanado', 'Preparado com ingredientes selecionados e servido gelado', 19.62, 1),
(99, 100, 'Feijoada Completa', 'Preparado com ingredientes selecionados e servido gelado', 25.75, 0),
(100, 48, 'Esfiha de Carne', 'Preparado com ingredientes selecionados e servido quente', 56.49, 1),
(101, 10, 'X-Burguer', 'Preparado com ingredientes selecionados e servido quente', 25.72, 0),
(102, 17, 'X-Bacon', 'Preparado com ingredientes selecionados e servido na hora', 19.7, 0),
(103, 7, 'Combo Sushi 20 pecas', 'Preparado com ingredientes selecionados e servido em porcao individual', 44.55, 0),
(104, 64, 'X-Burguer', 'Preparado com ingredientes selecionados e servido com acompanhamento', 64.56, 1),
(105, 46, 'Temaki de Salmao', 'Preparado com ingredientes selecionados e servido gelado', 31.9, 0),
(106, 20, 'X-Salada', 'Preparado com ingredientes selecionados e servido em porcao individual', 59.43, 1),
(107, 83, 'Salada Caesar', 'Preparado com ingredientes selecionados e servido com acompanhamento', 42.86, 0),
(108, 8, 'X-Bacon', 'Preparado com ingredientes selecionados e servido na hora', 40.54, 0),
(109, 26, 'Salada de Quinoa', 'Preparado com ingredientes selecionados e servido em porcao individual', 29.83, 1),
(110, 49, 'Camarao Empanado', 'Preparado com ingredientes selecionados e servido na hora', 48.27, 0),
(111, 45, 'Suco Natural', 'Preparado com ingredientes selecionados e servido em porcao individual', 50.09, 0),
(112, 35, 'Combo Sushi 20 pecas', 'Preparado com ingredientes selecionados e servido quente', 35.41, 1),
(113, 4, 'Cappuccino', 'Preparado com ingredientes selecionados e servido na hora', 14.59, 0),
(114, 68, 'Lasanha a Bolonhesa', 'Preparado com ingredientes selecionados e servido em porcao individual', 89.87, 1),
(115, 13, 'Feijoada Completa', 'Preparado com ingredientes selecionados e servido gelado', 31.22, 1),
(116, 98, 'Feijoada Completa', 'Preparado com ingredientes selecionados e servido em porcao individual', 77.62, 0),
(117, 46, 'Suco Natural', 'Preparado com ingredientes selecionados e servido gelado', 23.99, 1),
(118, 95, 'Kibe Frito', 'Preparado com ingredientes selecionados e servido na hora', 83.02, 1),
(119, 91, 'Kibe Frito', 'Preparado com ingredientes selecionados e servido na hora', 85.7, 1),
(120, 73, 'Temaki de Salmao', 'Preparado com ingredientes selecionados e servido com acompanhamento', 53.27, 1),
(121, 63, 'X-Salada', 'Preparado com ingredientes selecionados e servido quente', 14.39, 1),
(122, 3, 'Petit Gateau', 'Preparado com ingredientes selecionados e servido com acompanhamento', 9.95, 1),
(123, 17, 'Wrap de Frango', 'Preparado com ingredientes selecionados e servido gelado', 83.4, 1),
(124, 8, 'X-Burguer', 'Preparado com ingredientes selecionados e servido gelado', 56.83, 1),
(125, 100, 'Pizza Margherita', 'Preparado com ingredientes selecionados e servido em porcao individual', 78.75, 1),
(126, 48, 'Kibe Frito', 'Preparado com ingredientes selecionados e servido com acompanhamento', 56.78, 1),
(127, 39, 'Wrap de Frango', 'Preparado com ingredientes selecionados e servido gelado', 87.97, 0),
(128, 82, 'Brownie com Sorvete', 'Preparado com ingredientes selecionados e servido na hora', 23.84, 1),
(129, 29, 'Esfiha de Carne', 'Preparado com ingredientes selecionados e servido em porcao individual', 75.06, 0),
(130, 40, 'Yakisoba de Frango', 'Preparado com ingredientes selecionados e servido na hora', 20.09, 1),
(131, 90, 'Costela ao Bafo', 'Preparado com ingredientes selecionados e servido com acompanhamento', 77.96, 1),
(132, 24, 'Bowl Fitness de Frango', 'Preparado com ingredientes selecionados e servido na hora', 83.58, 1),
(133, 82, 'Costela ao Bafo', 'Preparado com ingredientes selecionados e servido quente', 84.84, 1),
(134, 43, 'Yakisoba de Frango', 'Preparado com ingredientes selecionados e servido quente', 28.94, 1),
(135, 22, 'Salada de Quinoa', 'Preparado com ingredientes selecionados e servido quente', 75.63, 1),
(136, 58, 'X-Burguer', 'Preparado com ingredientes selecionados e servido na hora', 26.67, 1),
(137, 45, 'Moqueca de Peixe', 'Preparado com ingredientes selecionados e servido quente', 67.53, 1),
(138, 50, 'Burrito de Frango', 'Preparado com ingredientes selecionados e servido com acompanhamento', 87.43, 0),
(139, 64, 'Cappuccino', 'Preparado com ingredientes selecionados e servido com acompanhamento', 38.0, 0),
(140, 13, 'Risoto de Camarao', 'Preparado com ingredientes selecionados e servido com acompanhamento', 73.0, 1),
(141, 21, 'Burrito de Frango', 'Preparado com ingredientes selecionados e servido quente', 73.84, 1),
(142, 38, 'X-Burguer', 'Preparado com ingredientes selecionados e servido na hora', 30.79, 1),
(143, 10, 'Wrap de Frango', 'Preparado com ingredientes selecionados e servido gelado', 80.93, 1),
(144, 94, 'X-Bacon', 'Preparado com ingredientes selecionados e servido em porcao individual', 85.25, 1),
(145, 44, 'Bowl Fitness de Frango', 'Preparado com ingredientes selecionados e servido em porcao individual', 81.36, 1),
(146, 56, 'Salada de Quinoa', 'Preparado com ingredientes selecionados e servido gelado', 58.49, 0),
(147, 21, 'X-Salada', 'Preparado com ingredientes selecionados e servido quente', 36.39, 1),
(148, 53, 'Kibe Frito', 'Preparado com ingredientes selecionados e servido em porcao individual', 67.66, 1),
(149, 85, 'Salada Caesar', 'Preparado com ingredientes selecionados e servido na hora', 28.9, 1),
(150, 51, 'Costela ao Bafo', 'Preparado com ingredientes selecionados e servido em porcao individual', 77.09, 1);
 
-- ======================================================================
-- PEDIDO (100 registros)
-- ======================================================================
INSERT INTO Pedido
(pedido_id, cliente_id, restaurante_id, entregador_id, endereco_id, cupom_id, data_pedido, estado, subtotal, taxa_entrega, valor_desconto, total, tempo_estimado)
VALUES
(1, 7, 47, 38, 85, NULL, '2025-08-07 12:01:13', 'pendente', 50.75, 6.50, 0.00, 57.25, '25 min'),
(2, 61, 15, 51, 66, NULL, '2025-11-09 12:41:34', 'em_preparo', 89.75, 7.45, 0.00, 97.20, '44 min'),
(3, 48, 24, 6, 6, NULL, '2025-05-08 15:36:03', 'saiu_para_entrega', 47.20, 11.36, 0.00, 58.56, '26 min'),
(4, 11, 86, 70, 53, NULL, '2025-10-08 19:03:53', 'em_preparo', 89.68, 9.27, 0.00, 98.95, '54 min'),
(5, 88, 61, 31, 61, 51, '2025-12-02 19:36:57', 'entregue', 113.03, 9.86, 22.31, 100.58, '29 min'),
(6, 16, 97, 23, 8, NULL, '2025-04-05 11:27:05', 'saiu_para_entrega', 197.89, 8.22, 0.00, 206.11, '60 min'),
(7, 19, 77, 41, 44, 72, '2025-07-18 16:54:17', 'em_preparo', 113.54, 14.01, 5.89, 121.66, '64 min'),
(8, 80, 76, 54, 15, NULL, '2025-03-19 20:37:48', 'entregue', 193.67, 4.20, 0.00, 197.87, '26 min'),
(9, 73, 100, NULL, 98, NULL, '2025-05-13 21:31:36', 'pendente', 129.61, 3.45, 0.00, 133.06, '37 min'),
(10, 52, 19, 78, 54, 43, '2025-12-08 11:47:30', 'entregue', 185.75, 13.76, 9.85, 189.66, '70 min'),
(11, 39, 40, 63, 42, NULL, '2025-04-05 15:47:28', 'em_preparo', 159.33, 6.85, 0.00, 166.18, '66 min'),
(12, 54, 78, 12, 25, NULL, '2025-07-24 18:48:33', 'cancelado', 176.09, 12.85, 0.00, 188.94, '52 min'),
(13, 21, 9, 91, 48, 68, '2025-10-01 13:12:56', 'em_preparo', 169.93, 13.04, 14.86, 168.11, '49 min'),
(14, 7, 47, 26, 36, 60, '2025-09-13 21:59:07', 'cancelado', 142.61, 5.90, 17.59, 130.92, '48 min'),
(15, 23, 61, 71, 45, 34, '2025-12-27 22:05:18', 'entregue', 24.94, 3.60, 4.44, 24.10, '69 min'),
(16, 28, 29, 29, 87, 84, '2025-07-17 11:55:49', 'cancelado', 194.08, 11.19, 23.51, 181.76, '28 min'),
(17, 83, 23, 2, 5, 40, '2025-12-23 21:17:27', 'entregue', 181.19, 13.22, 21.53, 172.88, '33 min'),
(18, 60, 39, 67, 79, NULL, '2025-01-17 21:53:53', 'cancelado', 87.36, 10.77, 0.00, 98.13, '58 min'),
(19, 37, 39, 14, 28, 36, '2025-11-11 15:16:41', 'cancelado', 148.00, 13.71, 14.03, 147.68, '29 min'),
(20, 67, 98, NULL, 77, NULL, '2025-06-22 13:46:01', 'confirmado', 137.97, 14.97, 0.00, 152.94, '36 min'),
(21, 54, 52, 95, 5, NULL, '2025-10-27 14:21:46', 'saiu_para_entrega', 148.41, 11.24, 0.00, 159.65, '60 min'),
(22, 61, 86, 65, 66, NULL, '2025-11-18 13:18:06', 'em_preparo', 104.74, 11.89, 0.00, 116.63, '66 min'),
(23, 72, 98, NULL, 32, NULL, '2025-04-12 14:47:55', 'confirmado', 75.28, 12.46, 0.00, 87.74, '41 min'),
(24, 48, 34, 38, 6, NULL, '2025-08-02 21:37:37', 'entregue', 189.97, 3.85, 0.00, 193.82, '32 min'),
(25, 65, 16, 49, 91, NULL, '2025-03-05 14:21:26', 'cancelado', 197.69, 13.71, 0.00, 211.40, '49 min'),
(26, 19, 41, 24, 44, NULL, '2025-11-06 16:40:03', 'cancelado', 20.85, 6.28, 0.00, 27.13, '68 min'),
(27, 100, 22, 98, 21, NULL, '2025-02-05 20:27:40', 'entregue', 97.29, 8.15, 0.00, 105.44, '50 min'),
(28, 50, 1, NULL, 25, NULL, '2025-06-25 19:12:01', 'pendente', 141.81, 10.52, 0.00, 152.33, '35 min'),
(29, 29, 89, 40, 86, 65, '2025-10-10 13:04:52', 'em_preparo', 28.23, 14.38, 3.34, 39.27, '53 min'),
(30, 77, 68, 56, 72, 63, '2025-06-25 14:10:58', 'em_preparo', 185.28, 7.84, 15.61, 177.51, '66 min'),
(31, 17, 28, 3, 15, 92, '2025-11-26 11:24:56', 'cancelado', 135.26, 12.25, 19.41, 128.10, '58 min'),
(32, 7, 85, NULL, 3, 15, '2025-07-15 17:07:35', 'pendente', 65.49, 11.42, 5.29, 71.62, '63 min'),
(33, 81, 2, 54, 85, 67, '2025-05-20 20:44:08', 'em_preparo', 95.39, 13.78, 12.09, 97.08, '59 min'),
(34, 16, 37, NULL, 16, 26, '2025-05-27 19:12:22', 'pendente', 146.62, 6.54, 8.20, 144.96, '51 min'),
(35, 27, 89, 43, 31, 86, '2025-02-04 20:42:31', 'saiu_para_entrega', 46.85, 4.08, 5.94, 44.99, '66 min'),
(36, 93, 13, 83, 43, NULL, '2025-05-09 18:03:06', 'em_preparo', 166.37, 13.49, 0.00, 179.86, '38 min'),
(37, 47, 87, 55, 61, 98, '2025-01-01 13:42:41', 'em_preparo', 50.69, 7.29, 5.86, 52.12, '59 min'),
(38, 35, 94, 44, 56, 52, '2025-08-09 17:44:54', 'pendente', 106.08, 8.06, 19.40, 94.74, '30 min'),
(39, 15, 17, 93, 8, NULL, '2025-03-04 17:58:37', 'cancelado', 106.88, 9.83, 0.00, 116.71, '48 min'),
(40, 24, 79, 100, 89, NULL, '2025-11-27 22:57:08', 'saiu_para_entrega', 106.95, 8.86, 0.00, 115.81, '46 min'),
(41, 57, 6, 41, 2, NULL, '2025-11-17 22:36:46', 'pendente', 121.70, 14.73, 0.00, 136.43, '62 min'),
(42, 44, 67, 89, 53, NULL, '2025-12-08 18:22:42', 'entregue', 141.73, 7.62, 0.00, 149.35, '55 min'),
(43, 79, 7, NULL, 13, NULL, '2025-08-28 18:55:10', 'pendente', 33.48, 8.90, 0.00, 42.38, '35 min'),
(44, 43, 36, NULL, 82, NULL, '2025-07-27 14:05:29', 'pendente', 99.95, 9.88, 0.00, 109.83, '25 min'),
(45, 64, 58, 16, 64, NULL, '2025-01-04 17:26:02', 'em_preparo', 120.28, 3.00, 0.00, 123.28, '25 min'),
(46, 78, 80, 39, 19, NULL, '2025-08-11 16:52:03', 'cancelado', 166.99, 13.13, 0.00, 180.12, '41 min'),
(47, 72, 99, 77, 32, NULL, '2025-06-23 18:07:06', 'entregue', 156.68, 5.66, 0.00, 162.34, '41 min'),
(48, 46, 82, 71, 67, 14, '2025-01-06 18:08:52', 'em_preparo', 149.03, 11.66, 9.84, 150.85, '59 min'),
(49, 26, 25, NULL, 51, 25, '2025-12-11 12:48:26', 'pendente', 28.37, 10.60, 4.28, 34.69, '27 min'),
(50, 99, 58, 85, 49, NULL, '2025-01-17 22:03:35', 'saiu_para_entrega', 188.36, 13.07, 0.00, 201.43, '50 min'),
(51, 66, 100, NULL, 23, NULL, '2025-03-04 17:42:38', 'confirmado', 129.11, 6.86, 0.00, 135.97, '44 min'),
(52, 54, 78, 98, 32, 44, '2025-05-15 13:08:26', 'cancelado', 128.45, 13.64, 16.29, 125.80, '64 min'),
(53, 71, 41, 95, 31, 80, '2025-12-10 21:22:58', 'cancelado', 141.03, 14.78, 20.80, 135.01, '31 min'),
(54, 65, 70, 82, 91, NULL, '2025-06-18 18:37:36', 'cancelado', 189.68, 11.52, 0.00, 201.20, '63 min'),
(55, 96, 69, 55, 45, NULL, '2025-01-13 13:03:42', 'em_preparo', 30.19, 6.20, 0.00, 36.39, '70 min'),
(56, 21, 37, 33, 22, NULL, '2025-12-26 15:13:48', 'cancelado', 117.41, 7.30, 0.00, 124.71, '48 min'),
(57, 14, 79, 95, 51, NULL, '2025-09-13 14:32:50', 'cancelado', 163.43, 11.35, 0.00, 174.78, '64 min'),
(58, 86, 7, 50, 77, NULL, '2025-11-11 19:03:00', 'saiu_para_entrega', 153.86, 5.44, 0.00, 159.30, '69 min'),
(59, 57, 29, 91, 91, NULL, '2025-10-18 22:38:12', 'cancelado', 159.71, 14.57, 0.00, 174.28, '38 min'),
(60, 58, 23, 10, 24, NULL, '2025-12-17 12:24:02', 'cancelado', 97.13, 9.68, 0.00, 106.81, '28 min'),
(61, 21, 75, 1, 34, NULL, '2025-03-02 13:59:20', 'em_preparo', 127.44, 12.28, 0.00, 139.72, '60 min'),
(62, 79, 85, 63, 13, 91, '2025-06-17 14:11:33', 'em_preparo', 32.27, 9.06, 3.63, 37.70, '54 min'),
(63, 52, 12, 29, 54, NULL, '2025-06-12 15:13:48', 'em_preparo', 131.29, 8.70, 0.00, 139.99, '55 min'),
(64, 97, 84, 45, 78, 83, '2025-10-20 14:02:43', 'pendente', 179.42, 7.58, 30.40, 156.60, '27 min'),
(65, 50, 33, 93, 25, 67, '2025-06-17 19:28:31', 'entregue', 27.89, 13.78, 2.20, 39.47, '52 min'),
(66, 11, 13, NULL, 99, NULL, '2025-01-21 12:13:42', 'confirmado', 133.31, 5.56, 0.00, 138.87, '63 min'),
(67, 55, 14, NULL, 70, NULL, '2025-02-24 21:09:01', 'confirmado', 102.66, 6.98, 0.00, 109.64, '25 min'),
(68, 10, 7, NULL, 72, 30, '2025-05-14 17:28:40', 'confirmado', 92.80, 6.80, 10.06, 89.54, '27 min'),
(69, 69, 1, 93, 84, NULL, '2025-10-02 22:54:04', 'cancelado', 84.39, 9.03, 0.00, 93.42, '38 min'),
(70, 88, 39, 12, 37, NULL, '2025-08-13 17:52:42', 'entregue', 25.55, 4.88, 0.00, 30.43, '34 min'),
(71, 18, 96, 70, 59, NULL, '2025-03-10 21:56:58', 'saiu_para_entrega', 193.77, 13.41, 0.00, 207.18, '61 min'),
(72, 48, 2, 72, 6, 1, '2025-10-20 17:34:35', 'entregue', 190.46, 6.66, 30.90, 166.22, '66 min'),
(73, 45, 28, 83, 17, 29, '2025-10-27 15:12:07', 'saiu_para_entrega', 52.64, 12.60, 9.36, 55.88, '68 min'),
(74, 71, 60, 71, 31, 9, '2025-05-04 14:46:37', 'cancelado', 107.69, 6.97, 7.46, 107.20, '61 min'),
(75, 31, 13, 80, 12, NULL, '2025-06-16 18:21:39', 'em_preparo', 138.70, 11.32, 0.00, 150.02, '29 min'),
(76, 73, 73, 41, 98, 41, '2025-04-26 14:45:47', 'em_preparo', 135.35, 6.32, 14.07, 127.60, '63 min'),
(77, 94, 43, 60, 74, 40, '2025-08-18 12:11:41', 'saiu_para_entrega', 129.19, 13.10, 23.10, 119.19, '28 min'),
(78, 69, 26, 94, 84, NULL, '2025-01-28 19:40:01', 'em_preparo', 166.28, 9.95, 0.00, 176.23, '69 min'),
(79, 76, 28, NULL, 46, NULL, '2025-03-12 17:14:57', 'pendente', 158.99, 11.80, 0.00, 170.79, '38 min'),
(80, 18, 60, 66, 55, 65, '2025-01-22 14:54:51', 'entregue', 196.73, 11.21, 32.18, 175.76, '28 min'),
(81, 58, 21, NULL, 73, NULL, '2025-03-24 22:30:22', 'confirmado', 27.28, 12.14, 0.00, 39.42, '34 min'),
(82, 9, 34, 30, 6, NULL, '2025-09-26 16:24:30', 'em_preparo', 185.22, 13.58, 0.00, 198.80, '22 min'),
(83, 84, 42, NULL, 67, NULL, '2025-05-27 22:16:37', 'pendente', 117.98, 5.09, 0.00, 123.07, '61 min'),
(84, 49, 47, 84, 87, NULL, '2025-07-08 19:25:22', 'entregue', 167.10, 7.14, 0.00, 174.24, '70 min'),
(85, 62, 78, NULL, 18, NULL, '2025-04-03 19:41:17', 'pendente', 58.07, 5.24, 0.00, 63.31, '43 min'),
(86, 78, 92, NULL, 81, NULL, '2025-12-04 18:43:30', 'pendente', 106.22, 10.09, 0.00, 116.31, '61 min'),
(87, 53, 3, 74, 92, 66, '2025-01-19 13:03:10', 'confirmado', 66.49, 5.16, 12.88, 58.77, '58 min'),
(88, 73, 82, NULL, 98, NULL, '2025-04-15 20:30:55', 'pendente', 106.70, 5.63, 0.00, 112.33, '46 min'),
(89, 77, 19, 99, 72, NULL, '2025-09-09 13:46:43', 'entregue', 81.68, 8.44, 0.00, 90.12, '57 min'),
(90, 9, 30, 50, 17, 26, '2025-09-28 19:43:26', 'saiu_para_entrega', 168.77, 10.27, 12.93, 166.11, '59 min'),
(91, 77, 5, 65, 72, 85, '2025-03-20 19:52:00', 'entregue', 181.45, 12.30, 26.74, 167.01, '53 min'),
(92, 54, 48, NULL, 55, 62, '2025-07-12 20:51:47', 'pendente', 183.41, 13.05, 25.02, 171.44, '47 min'),
(93, 18, 33, 99, 55, NULL, '2025-02-10 20:56:34', 'saiu_para_entrega', 93.56, 5.27, 0.00, 98.83, '65 min'),
(94, 96, 1, 67, 45, NULL, '2025-07-21 14:44:51', 'entregue', 76.86, 7.35, 0.00, 84.21, '29 min'),
(95, 55, 84, 33, 70, NULL, '2025-07-19 16:39:17', 'entregue', 198.52, 7.77, 0.00, 206.29, '33 min'),
(96, 53, 71, 62, 92, 72, '2025-08-09 15:36:22', 'entregue', 159.36, 7.78, 11.27, 155.87, '62 min'),
(97, 16, 96, 90, 8, 66, '2025-07-26 16:51:35', 'confirmado', 130.52, 11.21, 7.55, 134.18, '44 min'),
(98, 82, 1, NULL, 3, NULL, '2025-07-03 12:16:14', 'pendente', 86.75, 10.31, 0.00, 97.06, '66 min'),
(99, 50, 52, 84, 25, NULL, '2025-10-02 13:40:31', 'entregue', 99.01, 5.42, 0.00, 104.43, '62 min'),
(100, 67, 37, 77, 66, NULL, '2025-04-20 13:43:02', 'confirmado', 84.75, 10.86, 0.00, 95.61, '30 min');
-- ======================================================================
-- ITEM_PEDIDO (150 registros)
-- ======================================================================
INSERT INTO Item_pedido
(item_pedido_id, pedido_id, item_menu_id, quantidade, preco_unitario, subtotal)
VALUES
(1, 12, 71, 4, 55.62, 222.48),
(2, 46, 102, 4, 19.70, 78.80),
(3, 76, 52, 1, 60.19, 60.19),
(4, 95, 18, 1, 60.49, 60.49),
(5, 71, 73, 3, 79.18, 237.54),
(6, 45, 71, 2, 55.62, 111.24),
(7, 78, 50, 4, 11.24, 44.96),
(8, 52, 148, 1, 67.66, 67.66),
(9, 34, 45, 4, 50.66, 202.64),
(10, 65, 28, 1, 17.37, 17.37),
(11, 65, 76, 3, 87.65, 262.95),
(12, 15, 132, 3, 83.58, 250.74),
(13, 69, 148, 3, 67.66, 202.98),
(14, 89, 114, 4, 89.87, 359.48),
(15, 73, 124, 2, 56.83, 113.66),
(16, 97, 87, 4, 77.97, 311.88),
(17, 88, 118, 1, 83.02, 83.02),
(18, 62, 30, 3, 67.98, 203.94),
(19, 9, 98, 2, 19.62, 39.24),
(20, 87, 59, 3, 66.02, 198.06),
(21, 53, 91, 1, 38.56, 38.56),
(22, 90, 68, 2, 39.02, 78.04),
(23, 37, 24, 4, 56.13, 224.52),
(24, 87, 88, 1, 35.34, 35.34),
(25, 71, 46, 4, 72.60, 290.40),
(26, 41, 91, 2, 38.56, 77.12),
(27, 74, 69, 2, 54.13, 108.26),
(28, 96, 49, 4, 43.57, 174.28),
(29, 95, 52, 2, 60.19, 120.38),
(30, 95, 62, 3, 71.61, 214.83),
(31, 27, 59, 2, 66.02, 132.04),
(32, 32, 92, 2, 31.10, 62.20),
(33, 100, 28, 1, 17.37, 17.37),
(34, 11, 127, 1, 87.97, 87.97),
(35, 98, 139, 1, 38.00, 38.00),
(36, 62, 96, 3, 12.39, 37.17),
(37, 64, 148, 3, 67.66, 202.98),
(38, 63, 47, 3, 29.19, 87.57),
(39, 51, 57, 2, 83.87, 167.74),
(40, 7, 135, 4, 75.63, 302.52),
(41, 62, 139, 1, 38.00, 38.00),
(42, 65, 89, 4, 20.79, 83.16),
(43, 88, 45, 4, 50.66, 202.64),
(44, 16, 133, 4, 84.84, 339.36),
(45, 41, 3, 1, 33.27, 33.27),
(46, 87, 54, 4, 16.22, 64.88),
(47, 75, 26, 3, 45.20, 135.60),
(48, 47, 67, 2, 10.11, 20.22),
(49, 71, 68, 2, 39.02, 78.04),
(50, 35, 121, 3, 14.39, 43.17),
(51, 47, 48, 4, 88.85, 355.40),
(52, 55, 54, 4, 16.22, 64.88),
(53, 90, 96, 3, 12.39, 37.17),
(54, 52, 72, 4, 24.25, 97.00),
(55, 24, 147, 2, 36.39, 72.78),
(56, 74, 59, 1, 66.02, 66.02),
(57, 93, 70, 2, 43.20, 86.40),
(58, 72, 111, 4, 50.09, 200.36),
(59, 26, 38, 2, 10.58, 21.16),
(60, 61, 3, 2, 33.27, 66.54),
(61, 54, 128, 2, 23.84, 47.68),
(62, 81, 133, 3, 84.84, 254.52),
(63, 63, 77, 3, 70.74, 212.22),
(64, 72, 146, 1, 58.49, 58.49),
(65, 51, 26, 2, 45.20, 90.40),
(66, 8, 56, 3, 68.30, 204.90),
(67, 61, 25, 4, 13.58, 54.32),
(68, 96, 86, 3, 14.88, 44.64),
(69, 47, 93, 3, 76.01, 228.03),
(70, 45, 6, 4, 71.91, 287.64),
(71, 16, 90, 2, 45.87, 91.74),
(72, 74, 148, 2, 67.66, 135.32),
(73, 100, 73, 3, 79.18, 237.54),
(74, 42, 131, 4, 77.96, 311.84),
(75, 100, 115, 1, 31.22, 31.22),
(76, 49, 74, 4, 46.44, 185.76),
(77, 81, 38, 2, 10.58, 21.16),
(78, 82, 87, 4, 77.97, 311.88),
(79, 81, 147, 4, 36.39, 145.56),
(80, 10, 21, 2, 56.46, 112.92),
(81, 44, 59, 3, 66.02, 198.06),
(82, 41, 75, 3, 72.66, 217.98),
(83, 78, 102, 3, 19.70, 59.10),
(84, 57, 93, 4, 76.01, 304.04),
(85, 53, 43, 2, 29.75, 59.50),
(86, 3, 33, 2, 10.64, 21.28),
(87, 85, 65, 1, 14.34, 14.34),
(88, 27, 43, 4, 29.75, 119.00),
(89, 14, 25, 1, 13.58, 13.58),
(90, 61, 141, 1, 73.84, 73.84),
(91, 4, 102, 1, 19.70, 19.70),
(92, 14, 68, 2, 39.02, 78.04),
(93, 11, 100, 3, 56.49, 169.47),
(94, 30, 64, 3, 60.10, 180.30),
(95, 57, 33, 2, 10.64, 21.28),
(96, 68, 44, 1, 77.73, 77.73),
(97, 5, 92, 3, 31.10, 93.30),
(98, 61, 120, 3, 53.27, 159.81),
(99, 71, 114, 2, 89.87, 179.74),
(100, 90, 139, 2, 38.00, 76.00);

DROP TRIGGER IF EXISTS trg_item_pedido_insercao;

DELIMITER $$

CREATE TRIGGER trg_item_pedido_insercao
AFTER INSERT ON Item_pedido
FOR EACH ROW
BEGIN

    UPDATE Pedido
    SET
        subtotal = (
            SELECT COALESCE(
                SUM(ip.subtotal),
                0
            )
            FROM Item_pedido ip
            WHERE ip.pedido_id = NEW.pedido_id
        ),

        total = GREATEST(
            (
                SELECT COALESCE(
                    SUM(ip.subtotal),
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
-- ======================================================================
-- AVALIACAO (100 registros)
-- ======================================================================
INSERT INTO Avaliacao (avaliacao_id, pedido_id, nota_restaurante, nota_entregador, comentario, data_avaliacao) VALUES
(1, 99, 1, 2, 'Faltou um item no pedido.', '2025-01-07 11:31:12'),
(2, 67, 1, 1, 'Embalagem veio toda amassada.', '2025-11-16 16:03:23'),
(3, 16, 2, 5, NULL, '2025-02-01 14:41:31'),
(4, 31, 1, 4, NULL, '2025-01-12 21:52:23'),
(5, 93, 1, 5, 'Poderia ter chegado um pouco mais rapido.', '2025-09-02 10:53:19'),
(6, 38, 1, 2, 'Demorou mais do que o esperado.', '2025-02-24 15:34:24'),
(7, 4, 2, 2, 'Entregador foi grosseiro.', '2025-10-21 13:35:47'),
(8, 26, 5, 4, 'Excelente atendimento do entregador.', '2025-11-19 19:43:29'),
(9, 73, 4, 1, 'Poderia melhorar a embalagem.', '2025-03-18 20:32:21'),
(10, 84, 2, 5, NULL, '2025-08-12 18:35:20'),
(11, 52, 3, 4, NULL, '2025-07-27 18:38:15'),
(12, 15, 5, 5, 'Comida deliciosa, embalagem impecavel.', '2025-07-25 16:23:28'),
(13, 87, 4, 4, 'Entrega rapida e comida saborosa!', '2025-12-02 17:38:01'),
(14, 22, 5, 2, 'Poderia ter chegado um pouco mais rapido.', '2025-01-10 15:13:54'),
(15, 9, 3, 1, 'Comida chegou atrasada e fria.', '2025-09-17 12:06:02'),
(16, 7, 4, 3, 'Poderia melhorar a embalagem.', '2025-03-09 19:56:37'),
(17, 28, 2, 2, 'Comida chegou atrasada e fria.', '2025-05-03 20:36:58'),
(18, 55, 2, 1, 'Pedido errado, nao era o que eu pedi.', '2025-08-06 23:52:57'),
(19, 62, 5, 1, NULL, '2025-11-10 09:46:51'),
(20, 42, 5, 4, 'Excelente atendimento do entregador.', '2025-01-25 18:22:56'),
(21, 83, 4, 4, 'Excelente atendimento do entregador.', '2025-04-24 08:40:49'),
(22, 27, 4, 1, 'Poderia ter chegado um pouco mais rapido.', '2025-09-02 18:34:36'),
(23, 51, 2, 3, NULL, '2025-12-08 12:03:43'),
(24, 79, 4, 4, 'Excelente atendimento do entregador.', '2025-04-14 17:50:25'),
(25, 54, 2, 2, 'Pedido errado, nao era o que eu pedi.', '2025-02-16 09:35:25'),
(26, 98, 3, 1, 'Embalagem veio toda amassada.', '2025-09-14 12:48:08'),
(27, 40, 4, 5, 'Comida deliciosa, embalagem impecavel.', '2025-08-13 14:35:39'),
(28, 53, 5, 2, 'Poderia melhorar a embalagem.', '2025-02-09 21:20:43'),
(29, 43, 5, 1, 'Poderia ter mais opcoes vegetarianas.', '2025-11-14 21:23:22'),
(30, 91, 2, 3, 'Poderia ter chegado um pouco mais rapido.', '2025-10-21 08:49:19'),
(31, 78, 2, 3, NULL, '2025-08-20 12:28:02'),
(32, 1, 2, 2, 'Pedido errado, nao era o que eu pedi.', '2025-03-25 10:07:47'),
(33, 60, 1, 2, 'Faltou um item no pedido.', '2025-05-01 18:44:51'),
(34, 24, 1, 3, 'Atendimento ruim, nao recomendo.', '2025-08-01 18:13:47'),
(35, 50, 5, 2, 'Poderia melhorar a embalagem.', '2025-09-17 16:35:30'),
(36, 76, 5, 2, NULL, '2025-12-22 08:24:37'),
(37, 70, 5, 1, 'Poderia ter chegado um pouco mais rapido.', '2025-03-02 17:12:50'),
(38, 59, 5, 3, 'Entrega rapida e comida saborosa!', '2025-08-21 08:04:24'),
(39, 10, 3, 3, 'Poderia ter mais opcoes vegetarianas.', '2025-01-10 20:14:24'),
(40, 34, 5, 1, 'Poderia ter chegado um pouco mais rapido.', '2025-08-28 10:11:12'),
(41, 5, 5, 4, 'Entrega rapida e comida saborosa!', '2025-01-08 17:21:31'),
(42, 11, 4, 2, 'Poderia ter mais opcoes vegetarianas.', '2025-06-22 19:22:40'),
(43, 97, 3, 2, NULL, '2025-05-26 09:40:16'),
(44, 39, 4, 1, NULL, '2025-05-08 12:21:57'),
(45, 65, 4, 2, 'Poderia ter mais opcoes vegetarianas.', '2025-12-13 15:26:15'),
(46, 74, 5, 2, NULL, '2025-05-20 18:28:34'),
(47, 47, 2, 2, 'Faltou um item no pedido.', '2025-10-18 14:55:08'),
(48, 88, 3, 5, 'Tudo perfeito, recomendo!', '2025-07-25 12:41:59'),
(49, 23, 5, 2, 'Poderia ter chegado um pouco mais rapido.', '2025-02-18 11:11:20'),
(50, 56, 2, 1, 'Pedido errado, nao era o que eu pedi.', '2025-07-14 17:28:47'),
(51, 86, 3, 2, 'Poderia melhorar a embalagem.', '2025-02-05 13:01:48'),
(52, 37, 5, 5, 'Otimo custo beneficio.', '2025-10-19 15:38:14'),
(53, 13, 2, 1, 'Pedido errado, nao era o que eu pedi.', '2025-02-23 23:08:32'),
(54, 95, 5, 4, 'Vou pedir novamente com certeza!', '2025-03-28 20:31:30'),
(55, 71, 2, 2, 'Entregador foi grosseiro.', '2025-04-02 21:48:00'),
(56, 35, 3, 4, 'Poderia melhorar a embalagem.', '2025-12-22 14:48:13'),
(57, 19, 1, 2, 'Atendimento ruim, nao recomendo.', '2025-10-16 18:55:29'),
(58, 36, 2, 4, NULL, '2025-01-20 20:46:20'),
(59, 29, 4, 5, 'Entrega rapida e comida saborosa!', '2025-09-04 22:29:52'),
(60, 66, 1, 2, 'Embalagem veio toda amassada.', '2025-12-02 20:33:48'),
(61, 94, 1, 2, 'Comida chegou atrasada e fria.', '2025-08-13 17:49:52'),
(62, 68, 3, 4, 'Poderia melhorar a embalagem.', '2025-07-10 09:44:33'),
(63, 58, 2, 4, NULL, '2025-08-03 11:11:49'),
(64, 33, 5, 5, 'Tudo perfeito, recomendo!', '2025-07-14 18:28:01'),
(65, 18, 2, 4, NULL, '2025-12-07 22:05:16'),
(66, 85, 3, 2, NULL, '2025-12-04 10:07:45'),
(67, 49, 4, 3, 'Poderia ter mais opcoes vegetarianas.', '2025-09-23 20:46:50'),
(68, 3, 5, 5, 'Tudo perfeito, recomendo!', '2025-07-18 20:02:49'),
(69, 25, 2, 3, NULL, '2025-11-28 12:10:55'),
(70, 57, 2, 2, 'Pedido chegou frio, mas o sabor era bom.', '2025-07-10 17:46:49'),
(71, 45, 4, 3, NULL, '2025-03-04 12:12:00'),
(72, 72, 5, 3, 'Entrega rapida e comida saborosa!', '2025-08-16 23:34:51'),
(73, 41, 1, 5, NULL, '2025-04-07 23:29:26'),
(74, 30, 4, 1, NULL, '2025-10-01 15:56:35'),
(75, 63, 3, 5, 'Comida deliciosa, embalagem impecavel.', '2025-01-06 12:03:41'),
(76, 17, 3, 1, 'Faltou um item no pedido.', '2025-01-22 17:21:58'),
(77, 14, 1, 1, 'Demorou mais do que o esperado.', '2025-07-06 13:43:18'),
(78, 69, 5, 5, 'Tudo perfeito, recomendo!', '2025-08-24 19:59:02'),
(79, 92, 1, 3, 'Pedido errado, nao era o que eu pedi.', '2025-06-13 10:48:27'),
(80, 46, 5, 1, 'Poderia ter chegado um pouco mais rapido.', '2025-08-05 11:44:55'),
(81, 82, 3, 3, NULL, '2025-07-17 14:44:13'),
(82, 8, 5, 1, 'Poderia ter mais opcoes vegetarianas.', '2025-10-24 10:30:46'),
(83, 81, 5, 3, 'Chegou antes do prazo e ainda quente.', '2025-10-28 18:16:33'),
(84, 44, 5, 5, 'Vou pedir novamente com certeza!', '2025-03-20 23:33:46'),
(85, 80, 4, 4, 'Tudo perfeito, recomendo!', '2025-10-08 17:12:00'),
(86, 90, 1, 1, 'Atendimento ruim, nao recomendo.', '2025-11-26 11:47:54'),
(87, 64, 2, 5, NULL, '2025-07-02 18:22:35'),
(88, 21, 2, 1, 'Entregador foi grosseiro.', '2025-12-10 16:50:04'),
(89, 100, 3, 3, NULL, '2025-09-11 08:07:43'),
(90, 12, 3, 3, NULL, '2025-12-19 08:53:11'),
(91, 48, 2, 3, 'Poderia ter chegado um pouco mais rapido.', '2025-11-16 23:51:02'),
(92, 20, 2, 4, 'Poderia melhorar a embalagem.', '2025-11-15 18:29:50'),
(93, 77, 4, 1, NULL, '2025-05-19 18:35:34'),
(94, 96, 1, 2, 'Pedido errado, nao era o que eu pedi.', '2025-06-03 12:17:53'),
(95, 61, 1, 3, 'Embalagem veio toda amassada.', '2025-11-18 13:36:38'),
(96, 89, 4, 2, NULL, '2025-02-28 17:45:54'),
(97, 75, 3, 1, 'Comida chegou atrasada e fria.', '2025-07-03 23:56:15'),
(98, 6, 3, 4, 'Poderia ter chegado um pouco mais rapido.', '2025-04-17 17:11:07'),
(99, 2, 3, 1, 'Entregador foi grosseiro.', '2025-02-15 08:51:30'),
(100, 32, 5, 2, 'Poderia melhorar a embalagem.', '2025-06-16 17:49:20')
,( 1 , 'DESCONTO477', 'fixo', 8.98, '2025-07-16', '2025-09-30', 1), (2, 'PROMO400', 'fixo', 16.5, '2025-06-01', '2025-06-18', 0), (3, 'DESCONTO18', 'percentual', 27.77, '2025-09-12', '2025-11-02', 1), (4, 'FRETE831', 'fixo', 9.38, '2025-04-08', '2025-07-11', 1), (5, 'PROMO653', 'percentual', 27.59, '2025-01-21', '2025-03-16', 0), (6, 'FASTBITE603', 'fixo', 19.65, '2025-02-16', '2025-04-09', 1), (7, 'BEMVINDO189', 'percentual', 8.3, '2025-10-04', '2025-12-04', 1), (8, 'PROMO273', 'fixo', 24.35, '2025-06-01', '2025-09-19', 1), (9, 'FASTBITE489', 'percentual', 8.52, '2025-04-26', '2025-08-05', 0), (10, 'FRETE384', 'percentual', 24.77, '2025-01-08', '2025-02-25', 1), (11, 'BEMVINDO387', 'fixo', 16.69, '2025-07-10', '2025-08-07', 1), (12, 'BEMVINDO35', 'fixo', 23.31, '2025-04-24', '2025-07-30', 1), (13, 'BEMVINDO941', 'fixo', 17.98, '2025-03-01', '2025-04-02', 1), (14, 'FASTBITE321', 'fixo', 7.32, '2025-05-01', '2025-07-23', 1), (15, 'BEMVINDO474', 'fixo', 18.41, '2025-10-04', '2025-12-11', 1), (16, 'BEMVINDO680', 'percentual', 25.84, '2025-07-28', '2025-09-16', 1), (17, 'DESCONTO232', 'fixo', 13.89, '2025-05-01', '2025-07-01', 1), (18, 'DESCONTO567', 'fixo', 6.21, '2025-05-22', '2025-06-30', 1), (19, 'BEMVINDO103', 'percentual', 21.04, '2025-01-11', '2025-02-01', 1), (20, 'PROMO138', 'percentual', 6.72, '2025-10-11', '2025-11-21', 1), (21, 'PROMO346', 'percentual', 24.72, '2025-01-02', '2025-02-21', 1), (22, 'PROMO563', 'fixo', 20.97, '2025-02-26', '2025-06-05', 1), (23, 'PROMO25', 'fixo', 20.8, '2025-05-02', '2025-07-31', 1), (24, 'FASTBITE188', 'fixo', 6.05, '2025-08-04', '2025-10-25', 1), (25, 'FASTBITE497', 'fixo', 20.56, '2025-09-20', '2025-12-19', 1), (26, 'BEMVINDO525', 'percentual', 28.64, '2025-01-23', '2025-05-11', 1), (27, 'BEMVINDO668', 'percentual', 6.52, '2025-09-03', '2025-11-08', 0), (28, 'FASTBITE512', 'fixo', 6.47, '2025-02-11', '2025-04-08', 1), (29, 'FASTBITE139', 'fixo', 17.49, '2025-10-27', '2026-01-20', 1), (30, 'BEMVINDO621', 'fixo', 14.07, '2025-08-09', '2025-09-05', 1), (31, 'FRETE748', 'percentual', 15.75, '2025-04-27', '2025-07-03', 1), (32, 'BEMVINDO418', 'fixo', 19.59, '2025-06-10', '2025-08-18', 1), (33, 'DESCONTO393', 'percentual', 22.17, '2025-08-31', '2025-09-23', 1), (34, 'FASTBITE105', 'fixo', 6.93, '2025-07-10', '2025-11-05', 1), 
(35, 'FRETE71', 'fixo', 18.4, '2025-07-30', '2025-09-28', 0), (36, 'FASTBITE304', 'fixo', 12.03, '2025-10-23', '2026-01-10', 1), 
(37, 'PROMO682', 'fixo', 9.48, '2025-02-25', '2025-04-25', 1), (38, 'FASTBITE790', 'fixo', 16.48, '2025-08-08', '2025-11-02', 1), 
(39, 'FRETE961', 'fixo', 5.58, '2025-05-20', '2025-09-01', 1), (40, 'DESCONTO369', 'percentual', 9.54, '2025-03-15', '2025-06-10', 0), 
(41, 'FASTBITE155', 'percentual', 7.29, '2025-09-29', '2025-11-10', 0), (42, 'DESCONTO171', 'fixo', 11.23, '2025-06-16', '2025-10-08', 1),
 (43, 'FASTBITE169', 'percentual', 23.86, '2025-01-26', '2025-05-07', 1), (44, 'DESCONTO463', 'fixo', 14.71, '2025-08-15', '2025-10-22', 1),
 (45, 'PROMO783', 'percentual', 13.63, '2025-02-26', '2025-04-18', 0), (46, 'FRETE693', 'fixo', 5.91, '2025-07-22', '2025-10-21', 1), 
 (47, 'FASTBITE219', 'fixo', 23.91, '2025-03-12', '2025-07-02', 1), (48, 'DESCONTO345', 'percentual', 5.19, '2025-08-09', '2025-09-15', 1),
 (49, 'BEMVINDO555', 'percentual', 17.51, '2025-07-01', '2025-07-25', 0),
 (50, 'FASTBITE456', 'percentual', 16.49, '2025-02-09', '2025-04-05', 0),
 (51, 'FRETE424', 'fixo', 10.79, '2025-07-27', '2025-08-13', 1), (52, 'PROMO830', 'fixo', 21.64, '2025-07-05', '2025-07-31', 0), 
 (53, 'FASTBITE259', 'fixo', 16.78, '2025-09-26', '2025-10-21', 0), (54, 'DESCONTO773', 'fixo', 9.43, '2025-03-28', '2025-04-21', 1),
 (55, 'FRETE532', 'percentual', 27.65, '2025-06-28', '2025-08-26', 1), (56, 'PROMO115', 'percentual', 11.4, '2025-03-30', '2025-06-30', 1),
 (57, 'FASTBITE191', 'fixo', 14.28, '2025-10-16', '2026-02-05', 0), (58, 'FRETE668', 'fixo', 22.28, '2025-06-11', '2025-07-15', 0), 
 (59, 'FASTBITE490', 'fixo', 17.63, '2025-05-21', '2025-08-19', 1), (60, 'DESCONTO529', 'percentual', 12.76, '2025-08-20', '2025-09-08', 1)
 , (61, 'DESCONTO861', 'fixo', 6.53) ;


