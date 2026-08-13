-- Banco SKY LODGE

CREATE DATABASE IF NOT EXISTS sky_lodge
    DEFAULT CHARACTER SET utf8mb4
    DEFAULT COLLATE utf8mb4_unicode_ci;

USE sky_lodge;
-- Tabelas sem dependências (entidades "raiz")

CREATE TABLE FUNCIONARIOS (
    id_funcionario INT AUTO_INCREMENT PRIMARY KEY,
    nome           VARCHAR(150) NOT NULL,
    cpf            VARCHAR(14)  NOT NULL UNIQUE,
    cargo          VARCHAR(50)  NOT NULL,
    nivel_acesso   VARCHAR(30)  NOT NULL,
    senha          VARCHAR(255) NOT NULL
);

CREATE TABLE CLIENTES (
    id_cliente INT AUTO_INCREMENT PRIMARY KEY,
    nome       VARCHAR(150) NOT NULL,
    cpf        VARCHAR(14)  NOT NULL UNIQUE,
    email      VARCHAR(150),
    telefone   VARCHAR(20)
);

CREATE TABLE QUARTOS (
    id_quarto     INT AUTO_INCREMENT PRIMARY KEY,
    tipo          VARCHAR(50) NOT NULL,
    capacidade    INT NOT NULL,
    preco_diaria  DECIMAL(10,2) NOT NULL,
    status        VARCHAR(30) NOT NULL DEFAULT 'disponivel'
);

-- Tabela RESERVAS - depende de QUARTOS, CLIENTES e FUNCIONARIOS
CREATE TABLE RESERVAS (
    id_reserva     INT AUTO_INCREMENT PRIMARY KEY,
    id_quarto      INT NOT NULL,
    id_cliente     INT NOT NULL,
    id_funcionario INT NOT NULL,
    tipo           VARCHAR(50),
    qtd_hospedes   INT NOT NULL,
    tempo          INT,
    checkin        DATETIME NOT NULL,
    checkout       DATETIME,
    CONSTRAINT fk_reservas_quarto
        FOREIGN KEY (id_quarto) REFERENCES QUARTOS(id_quarto),
    CONSTRAINT fk_reservas_cliente
        FOREIGN KEY (id_cliente) REFERENCES CLIENTES(id_cliente),
    CONSTRAINT fk_reservas_funcionario
        FOREIGN KEY (id_funcionario) REFERENCES FUNCIONARIOS(id_funcionario)
);

-- Tabelas que dependem de RESERVAS
CREATE TABLE CONSUMOS (
    id_consumo INT AUTO_INCREMENT PRIMARY KEY,
    id_reserva INT NOT NULL,
    tipo       VARCHAR(50) NOT NULL,
    valor      DECIMAL(10,2) NOT NULL,
    CONSTRAINT fk_consumos_reserva
        FOREIGN KEY (id_reserva) REFERENCES RESERVAS(id_reserva)
);

CREATE TABLE PAGAMENTO (
    id_pagamento INT AUTO_INCREMENT PRIMARY KEY,
    id_reserva   INT NOT NULL,
    id_cliente   INT NOT NULL,
    valor        DECIMAL(10,2) NOT NULL,
    CONSTRAINT fk_pagamento_reserva
        FOREIGN KEY (id_reserva) REFERENCES RESERVAS(id_reserva),
    CONSTRAINT fk_pagamento_cliente
        FOREIGN KEY (id_cliente) REFERENCES CLIENTES(id_cliente)
);

-- Tabela LIMPEZA - depende de QUARTOS e FUNCIONARIOS
CREATE TABLE LIMPEZA (
    id_limpeza     INT AUTO_INCREMENT PRIMARY KEY,
    id_quarto      INT NOT NULL,
    id_funcionario INT NOT NULL,
    data           DATE NOT NULL,
    status         VARCHAR(30) NOT NULL,
    CONSTRAINT fk_limpeza_quarto
        FOREIGN KEY (id_quarto) REFERENCES QUARTOS(id_quarto),
    CONSTRAINT fk_limpeza_funcionario
        FOREIGN KEY (id_funcionario) REFERENCES FUNCIONARIOS(id_funcionario)
);

-- SKY LODGE - Adição de novas colunas nas tabelas existentes
ALTER TABLE FUNCIONARIOS
    ADD COLUMN data_contratacao DATE;

ALTER TABLE CLIENTES
    ADD COLUMN data_nascimento DATE;

ALTER TABLE QUARTOS
    ADD COLUMN andar INT;

ALTER TABLE RESERVAS
    ADD COLUMN observacoes VARCHAR(255);

ALTER TABLE CONSUMOS
    ADD COLUMN data_consumo DATETIME;

ALTER TABLE PAGAMENTO
    ADD COLUMN forma_pagamento ENUM('cartao', 'pix', 'dinheiro', 'transferencia');

ALTER TABLE LIMPEZA
    ADD COLUMN observacoes VARCHAR(255);
    
-- SKY LODGE - Stored Procedures
-- 1) FUNCIONARIOS
-- Classifica o funcionario por tempo de casa (junior/pleno/senior)
DELIMITER $$
CREATE PROCEDURE SP_funcionario_classificacao(
IN p_id_funcionario INT,
OUT p_anos_casa INT,
OUT p_classificacao VARCHAR(20)
)
BEGIN
DECLARE v_data_contratacao DATE;
SELECT data_contratacao INTO v_data_contratacao
FROM funcionarios
WHERE id_funcionario = p_id_funcionario;
SET p_anos_casa = TIMESTAMPDIFF(YEAR,v_data_contratacao,CURDATE());
	IF p_anos_casa >=5 THEN
    SET p_classificacao = 'Senior';
    ELSEIF p_anos_casa >=2 THEN
    SET p_classificacao = 'Pleno';
    ELSE SET p_classificacao = 'Junior';
    END if;
END $$
DELIMITER ;

-- 2) CLIENTES
-- Retorna o historico do cliente: total de reservas e valor total gasto
DELIMITER $$
CREATE PROCEDURE sp_cliente_historico(
IN p_id_cliente INT,
OUT p_total_reservas INT,
OUT p_total_gasto DECIMAL(10,2)
)
BEGIN 
SELECT COUNT(*) INTO p_total_reservas
FROM RESERVAS
WHERE id_cliente = p_id_cliente;
	SELECT COALESCE(SUM(valor),0) INTO p_total_gasto
    FROM PAGAMENTO
    WHERE id_cliente = p_id_cliente;
		IF p_total_reservas = 0 THEN
        SELECT 'Cliente sem reservas registradas' AS Aviso;
        END IF;
END$$
DELIMITER ;

-- 3) QUARTOS
-- Verifica disponibilidade de quartos por tipo e retorna a quantidade
DELIMITER $$
CREATE PROCEDURE sp_quartos_disponiveis_por_tipo(
IN p_tipo VARCHAR(20),
OUT p_quantidade_disponivel INT
)
BEGIN
SELECT COUNT(*) INTO p_quantidade_disponivel
FROM quartos
WHERE tipo = p_tipo
	AND status = 'disponivel';
    IF p_quantidade_disponivel = 0 THEN
    SELECT CONCAT('Nenhum quarto disponivel do tipo: ',p_tipo) AS Aviso;
    END IF;
END$$
DELIMITER ;

-- 4) RESERVAS
-- Cria uma reserva somente se o quarto estiver disponivel,
-- e atualiza o status do quarto para 'reservado'
DELIMITER $$
CREATE PROCEDURE sp_criar_reserva(
    IN p_id_quarto INT,
    IN p_id_cliente INT,
    IN p_id_funcionario INT,
    IN p_tipo VARCHAR(50),
    IN p_qtd_hospedes INT,
    IN p_tempo INT,
    IN p_checkin DATETIME
)
BEGIN
    DECLARE v_status_quarto VARCHAR(30);
 
    SELECT status INTO v_status_quarto
    FROM QUARTOS
    WHERE id_quarto = p_id_quarto;
 
    IF v_status_quarto <> 'disponivel' THEN
        SELECT 'Erro: quarto nao esta disponivel para reserva' AS resultado;
    ELSE
        INSERT INTO RESERVAS (id_quarto, id_cliente, id_funcionario, tipo, qtd_hospedes, tempo, checkin, checkout)
        VALUES (p_id_quarto, p_id_cliente, p_id_funcionario, p_tipo, p_qtd_hospedes, p_tempo,
                p_checkin, DATE_ADD(p_checkin, INTERVAL p_tempo DAY));
 
        UPDATE QUARTOS
        SET status = 'reservado'
        WHERE id_quarto = p_id_quarto;
 
        SELECT 'Reserva criada com sucesso' AS resultado;
    END IF;
END$$
DELIMITER ;

-- 5) CONSUMOS
-- Calcula o total consumido em uma reserva, agrupado por tipo
-- e retorna o total geral
DELIMITER $$
CREATE PROCEDURE sp_total_consumos_reserva(
    IN p_id_reserva INT,
    OUT p_total_geral DECIMAL(10,2)
)
BEGIN
    SELECT COALESCE(SUM(valor), 0) INTO p_total_geral
    FROM CONSUMOS
    WHERE id_reserva = p_id_reserva;
 
    -- Detalhamento por tipo de consumo
    SELECT tipo, SUM(valor) AS total_por_tipo
    FROM CONSUMOS
    WHERE id_reserva = p_id_reserva
    GROUP BY tipo;
END$$
DELIMITER ;

-- 6) PAGAMENTO
-- Registra um pagamento validando se o valor cobre reserva + consumos
DELIMITER $$
CREATE PROCEDURE sp_registrar_pagamento(
    IN p_id_reserva INT,
    IN p_id_cliente INT,
    IN p_valor_pago DECIMAL(10,2),
    IN p_forma_pagamento VARCHAR(30)
)
BEGIN
    DECLARE v_total_consumos DECIMAL(10,2);
    DECLARE v_diaria DECIMAL(10,2);
    DECLARE v_tempo INT;
    DECLARE v_total_esperado DECIMAL(10,2);
 
    SELECT COALESCE(SUM(c.valor), 0) INTO v_total_consumos
    FROM CONSUMOS c
    WHERE c.id_reserva = p_id_reserva;
 
    SELECT q.preco_diaria, r.tempo INTO v_diaria, v_tempo
    FROM RESERVAS r
    JOIN QUARTOS q ON q.id_quarto = r.id_quarto
    WHERE r.id_reserva = p_id_reserva;
 
    SET v_total_esperado = (v_diaria * v_tempo) + v_total_consumos;
 
    IF p_valor_pago < v_total_esperado THEN
        SELECT CONCAT('Aviso: valor pago menor que o esperado. Esperado: ', v_total_esperado) AS aviso;
    END IF;
 
    INSERT INTO PAGAMENTO (id_reserva, id_cliente, valor, forma_pagamento)
    VALUES (p_id_reserva, p_id_cliente, p_valor_pago, p_forma_pagamento);
 
    SELECT 'Pagamento registrado' AS resultado, v_total_esperado AS valor_esperado;
END$$
DELIMITER ;

-- 7) LIMPEZA
-- Lista quartos com limpeza pendente ha mais de X dias
-- e retorna a quantidade encontrada
DELIMITER $$
CREATE PROCEDURE sp_limpezas_atrasadas(
    IN p_dias_limite INT,
    OUT p_quantidade INT
)
BEGIN
    SELECT COUNT(*) INTO p_quantidade
    FROM LIMPEZA
    WHERE status = 'pendente'
      AND DATEDIFF(CURDATE(), data) > p_dias_limite;
 
    SELECT id_limpeza, id_quarto, data, DATEDIFF(CURDATE(), data) AS dias_atraso
    FROM LIMPEZA
    WHERE status = 'pendente'
      AND DATEDIFF(CURDATE(), data) > p_dias_limite
    ORDER BY dias_atraso DESC;
END$$
DELIMITER ;

-- SKY LODGE - Inserts (100 por tabela)
-- FUNCIONARIOS
INSERT INTO FUNCIONARIOS (nome, cpf, cargo, nivel_acesso, senha, data_contratacao) VALUES
('Brenda Alves', '438.150.926-98', 'Manobrista', 'basico', '5W!e0Cg8qi', '2019-11-09'),
('Sr. Caleb Garcia', '158.420.376-53', 'Recepcionista', 'admin', 'n&pU1$Rj^5', '2023-09-11'),
('Sr. Léo Fogaça', '341.857.609-57', 'Camareira', 'basico', 'Tco&44Uw3v', '2025-09-08'),
('Natália Casa Grande', '423.596.871-82', 'Gerente', 'basico', 'z_OhL++h)6', '2026-05-18'),
('Danilo Rodrigues', '845.023.196-51', 'Manobrista', 'basico', '4tqAZQ+i+y', '2022-07-09'),
('Luiz Miguel das Neves', '309.485.762-00', 'Manobrista', 'admin', '77JRRg2f#a', '2020-05-29'),
('Sr. Yuri da Conceição', '930.756.142-70', 'Seguranca', 'basico', '^NRfr1QhI&', '2023-12-30'),
('Beatriz Araújo', '651.798.304-00', 'Seguranca', 'intermediario', 'q^#4*aOh&h', '2022-06-18'),
('Ana Liz Cavalcante', '609.237.541-99', 'Recepcionista', 'basico', 'x#3J%VPp+g', '2021-11-03'),
('Isadora Pacheco', '901.354.278-60', 'Recepcionista', 'basico', 'Hb5Hi^Lz_^', '2026-01-28'),
('Joaquim Freitas', '427.698.051-85', 'Gerente', 'admin', '_1S8EfiY7O', '2018-12-18'),
('Sr. João Castro', '786.405.923-65', 'Seguranca', 'basico', 'SJ$EvLsE(0', '2024-08-09'),
('Enrico Cavalcanti', '602.573.148-90', 'Seguranca', 'basico', 'p1mMMb4@+C', '2021-10-22'),
('Luísa Alves', '142.870.659-30', 'Manobrista', 'admin', 'y^s5$Ntlcv', '2026-03-14'),
('Dr. Davi Silveira', '489.532.671-37', 'Manobrista', 'admin', 'bGh2UGnn3(', '2022-09-13'),
('Srta. Antonella da Paz', '851.672.904-49', 'Cozinheiro', 'basico', 'X!0HUfpH_c', '2025-01-15'),
('Dra. Nicole Aragão', '831.976.254-55', 'Cozinheiro', 'admin', 'pLh7FxN5(e', '2019-04-04'),
('Igor Gomes', '231.869.570-95', 'Camareira', 'basico', 'VdpMG!yh$6', '2022-07-08'),
('Pedro Henrique Mendonça', '065.783.149-20', 'Financeiro', 'basico', 'V)&J81AmLC', '2018-10-07'),
('Ana Júlia Ferreira', '310.678.452-08', 'Manobrista', 'intermediario', '$2M6PWxfjv', '2026-01-15'),
('Maria Flor Gonçalves', '319.052.647-80', 'Camareira', 'intermediario', 'FP8oN*vZ^e', '2023-07-16'),
('Rafaela Martins', '645.910.278-30', 'Gerente', 'basico', '*voT3lDr98', '2020-07-17'),
('Rebeca Novais', '378.905.241-88', 'Financeiro', 'intermediario', 'V3RJhve8+(', '2026-03-20'),
('Srta. Evelyn Cunha', '748.012.536-44', 'Recepcionista', 'basico', '%$09vWhr!9', '2020-08-18'),
('Bruna Azevedo', '671.450.893-00', 'Cozinheiro', 'basico', '@rkDQLKpz3', '2023-08-13'),
('Bruno Castro', '321.709.486-78', 'Camareira', 'intermediario', 'ee0HjkYa%J', '2025-03-22'),
('Bento Cavalcante', '497.032.518-97', 'Seguranca', 'intermediario', '*gT@bbpV@1', '2022-05-17'),
('Melina da Mota', '267.039.514-70', 'Financeiro', 'basico', '1ObHi#Fk_j', '2019-01-17'),
('Maria Cecília Pinto', '790.124.635-99', 'Manobrista', 'intermediario', 'y+7+DS&atM', '2022-09-06'),
('Oliver Mendes', '739.418.520-60', 'Seguranca', 'basico', 'pDk7!4Yz@q', '2022-04-03'),
('Sr. Isaque Oliveira', '639.028.417-96', 'Cozinheiro', 'basico', 'x**o0E@qqx', '2023-08-06'),
('Anna Liz Farias', '865.793.024-29', 'Seguranca', 'intermediario', '&y$4*Hx#C%', '2022-11-10'),
('Emilly Cavalcante', '216.458.390-60', 'Financeiro', 'admin', 'Mbs$7SUizA', '2026-08-09'),
('Bianca da Costa', '654.820.317-80', 'Seguranca', 'intermediario', ')0TlxEZXcf', '2024-12-01'),
('Luiz Otávio Siqueira', '214.953.806-70', 'Seguranca', 'basico', 'tn5QNlqD(x', '2021-07-15'),
('Alice da Luz', '817.256.349-37', 'Manobrista', 'basico', '@3CXPZMaa(', '2019-05-22'),
('Catarina Gomes', '756.481.320-26', 'Recepcionista', 'admin', '#*K9N*iSyE', '2026-03-15'),
('Ayla Ribeiro', '308.621.457-08', 'Gerente', 'intermediario', '@8G_ssp_)6', '2024-12-05'),
('Lorenzo Almeida', '240.153.798-88', 'Recepcionista', 'basico', '*7Pv$jYlLx', '2022-07-14'),
('Ana Sophia Barros', '521.784.963-00', 'Financeiro', 'basico', '**pai8Tn4D', '2022-01-09'),
('Jade Freitas', '271.065.348-62', 'Cozinheiro', 'intermediario', 'w#bI8BJt$s', '2022-09-02'),
('Rodrigo Câmara', '158.024.936-15', 'Cozinheiro', 'admin', '84uA1_f^)x', '2021-12-20'),
('Sr. Léo das Neves', '510.864.723-90', 'Financeiro', 'intermediario', '%K8V(JncO7', '2019-01-19'),
('Kevin Cunha', '248.905.361-24', 'Gerente', 'intermediario', 'ernl2pM@u#', '2021-11-07'),
('Sr. Raul Sales', '516.708.324-90', 'Camareira', 'basico', 'h(1MjR2jDw', '2020-03-10'),
('Daniela Teixeira', '127.345.689-00', 'Manobrista', 'intermediario', '^5A8%PoL_E', '2022-04-24'),
('Ana Cecília Machado', '935.486.107-57', 'Manobrista', 'admin', '@c6KKW+F85', '2021-04-01'),
('Maria Isis da Paz', '425.091.873-41', 'Manobrista', 'basico', '9FkmbWcc#Z', '2021-07-06'),
('Heitor Fernandes', '738.160.249-04', 'Seguranca', 'admin', ')F05Yl0tI_', '2024-08-17'),
('Isabel Nascimento', '347.612.958-64', 'Gerente', 'admin', 'x&8_QZqn*o', '2025-11-07'),
('Pedro Henrique Borges', '375.096.821-77', 'Manobrista', 'basico', '$C*eC_#lM6', '2018-10-06'),
('Dom Novaes', '986.021.573-12', 'Gerente', 'intermediario', 'Y%n6RUzf9$', '2020-02-10'),
('Antonella Moura', '510.367.982-59', 'Cozinheiro', 'intermediario', '+0L*Vh)zDZ', '2020-12-16'),
('Guilherme Aparecida', '546.783.209-38', 'Manobrista', 'admin', 'qC)F5Ysb%O', '2025-01-07'),
('Sra. Anna Liz Lopes', '924.805.631-89', 'Seguranca', 'basico', 'J7E$qTw8%w', '2025-01-07'),
('Eduarda Alves', '270.186.943-96', 'Manobrista', 'intermediario', 'cw0iURTe)(', '2025-12-01'),
('João Vasconcelos', '473.928.105-88', 'Financeiro', 'basico', 'K&7FBw%S@p', '2019-08-01'),
('Davi Miguel da Costa', '705.462.398-38', 'Gerente', 'basico', 'HfCIIj)B)1', '2020-01-25'),
('Pedro Montenegro', '012.785.639-03', 'Financeiro', 'intermediario', '^cS)AJP0v8', '2018-12-22'),
('Julia Rezende', '360.954.281-06', 'Cozinheiro', 'intermediario', 'cA3%KZzW*f', '2023-02-07'),
('Sr. Ravi Lucca Campos', '473.105.268-80', 'Recepcionista', 'basico', '$2+KMsO&H2', '2019-01-06'),
('Olivia da Paz', '801.372.456-53', 'Seguranca', 'admin', 'T69GLBsY!)', '2026-02-13'),
('Gael Henrique Pereira', '860.791.243-78', 'Camareira', 'basico', '#X0z9QCeRe', '2021-04-05'),
('Oliver Pacheco', '407.259.168-85', 'Manobrista', 'intermediario', 'YX7Fc#q()B', '2024-10-22'),
('Ana Liz Santos', '283.497.610-40', 'Cozinheiro', 'admin', 'Ejf*8K2rT4', '2022-06-13'),
('Kamilly da Paz', '186.329.504-60', 'Cozinheiro', 'basico', '+o3L8T8(15', '2021-12-01'),
('Sra. Beatriz Rodrigues', '209.356.478-56', 'Camareira', 'basico', '%i55goJuIn', '2026-02-06'),
('Arthur Miguel Albuquerque', '415.239.708-04', 'Gerente', 'admin', 'C3Zf@Zdb%X', '2021-10-25'),
('Francisco Carvalho', '753.029.148-32', 'Seguranca', 'admin', 'U^E54S+cux', '2020-05-18'),
('Rhavi Cassiano', '756.843.102-90', 'Camareira', 'admin', 'EQ(7s2Rwp(', '2025-10-19'),
('Ana Laura Marques', '286.340.791-04', 'Seguranca', 'intermediario', '+h0$M%iv^v', '2024-10-05'),
('Mariah Freitas', '679.304.128-22', 'Seguranca', 'intermediario', 'Rf@2@RbmRm', '2020-10-25'),
('Srta. Ana Beatriz Ribeiro', '603.185.497-00', 'Camareira', 'basico', '54$0MomgBW', '2026-06-30'),
('Hellena Jesus', '490.861.325-70', 'Gerente', 'admin', '!QUIA1Rv5p', '2021-11-29'),
('Vitória Carvalho', '634.120.897-96', 'Cozinheiro', 'basico', '(3#BiVb43t', '2024-08-01'),
('Isabelly Sampaio', '936.142.578-19', 'Financeiro', 'basico', '(r5JiiB3B$', '2023-01-14'),
('Maria Vitória da Rocha', '235.184.679-64', 'Financeiro', 'basico', '7XgE_Sur%w', '2019-09-17'),
('Isabel Azevedo', '203.479.861-96', 'Gerente', 'admin', 'R7AaR9Pd_v', '2020-02-23'),
('Isis Fogaça', '461.235.780-90', 'Gerente', 'admin', 'uUGS%!0O%1', '2020-06-13'),
('Dra. Olívia da Mata', '014.769.835-93', 'Cozinheiro', 'admin', 'm9EATyoc$G', '2019-01-15'),
('Isabel Barbosa', '569.072.318-59', 'Recepcionista', 'intermediario', '1^8j9Mn7Gk', '2019-05-06'),
('Pedro Miguel Fonseca', '412.083.975-32', 'Cozinheiro', 'admin', 'TWCl!Ijf@0', '2024-02-03'),
('Davi Miguel da Mata', '497.106.382-03', 'Cozinheiro', 'admin', 'EvfOX7ZcH%', '2019-09-13'),
('Sr. Rhavi Dias', '265.973.148-91', 'Camareira', 'admin', 'u%61i@Ld3l', '2023-09-04'),
('José Ribeiro', '268.034.591-60', 'Financeiro', 'basico', '(kEsRWnia8', '2026-05-02'),
('Bianca Albuquerque', '143.856.972-64', 'Manobrista', 'admin', 'VPD&7Yxvv_', '2022-10-12'),
('Dr. Calebe Macedo', '751.208.493-50', 'Recepcionista', 'admin', 'QSC2MlXha_', '2021-09-20'),
('Srta. Gabrielly da Mota', '192.768.304-13', 'Seguranca', 'intermediario', 'Bu7(EQ0bl_', '2019-07-22'),
('Danilo Cirino', '526.341.790-06', 'Financeiro', 'admin', 'u0081oWu*N', '2021-11-19'),
('Maria Vitória Santos', '792.046.135-99', 'Camareira', 'basico', '%LgRS((j3F', '2026-07-12'),
('Josué da Rosa', '074.293.586-83', 'Camareira', 'intermediario', 'pX9XWllUR+', '2020-09-30'),
('Aylla Carvalho', '604.951.782-76', 'Gerente', 'intermediario', 'oH_Y5H^yi+', '2018-08-19'),
('Srta. Natália Porto', '516.837.942-73', 'Recepcionista', 'admin', '%p5si$Rs@u', '2020-03-24'),
('Srta. Liz Castro', '415.206.873-62', 'Manobrista', 'intermediario', 'h_4*3XwQK!', '2022-06-07'),
('Matheus Borges', '195.268.307-68', 'Seguranca', 'basico', 'X@83huaK4S', '2021-06-03'),
('Luara Vieira', '234.501.986-70', 'Seguranca', 'basico', 'q4GZkG5G_Z', '2026-01-29'),
('Mathias Nunes', '652.930.478-92', 'Financeiro', 'admin', 'u4G9biJH!R', '2025-12-23'),
('Vitor Gabriel Duarte', '614.538.092-60', 'Camareira', 'admin', 'X&1gOtd0wQ', '2024-10-12'),
('Lucas Gabriel Lima', '481.259.076-02', 'Seguranca', 'admin', '(0+5sB(p!p', '2021-09-03'),
('Felipe Andrade', '863.217.950-03', 'Gerente', 'basico', 'D54Q$Hqq)A', '2021-07-24');

-- CLIENTES
INSERT INTO CLIENTES (nome, cpf, email, telefone, data_nascimento) VALUES
('Kevin Sousa', '937.248.160-22', 'anthony-gabrieljesus@example.org', '+55 92 8505-0641', '1954-07-26'),
('Otto Mendonça', '024.961.387-50', 'fsouza@example.net', '+55 44 8261-9906', '1985-08-29'),
('Isaac da Rocha', '456.872.913-00', 'domcosta@example.org', '+55 47 2127-7561', '1977-01-20'),
('Rael das Neves', '741.092.635-06', 'fernandosilva@example.org', '44 6804-4206', '1998-09-22'),
('Isadora Brito', '712.065.849-20', 'rfreitas@example.net', '+55 41 9941-0137', '1995-08-24'),
('Lucas Campos', '079.143.568-75', 'brodrigues@example.org', '43 3244-7209', '1982-09-19'),
('Juan Monteiro', '687.092.351-59', 'sarada-cruz@example.net', '+55 15 6578-7598', '1962-06-25'),
('Fernando Alves', '530.627.891-40', 'liambrito@example.org', '+55 94 4803-9652', '1952-08-02'),
('Luiza Sousa', '509.461.732-06', 'marianeandrade@example.org', '+55 31 3930-8705', '2003-01-11'),
('Davi Lucca Fernandes', '250.714.863-26', 'freitasisabela@example.net', '+55 45 5452-2675', '1952-06-16'),
('Maria Alice Câmara', '926.857.104-85', 'kvargas@example.org', '+55 75 9593-9172', '1963-02-18'),
('Isaac Ferreira', '521.698.307-40', 'theosales@example.org', '42 4100-6762', '2000-10-05'),
('Maria Flor Ferreira', '861.934.705-57', 'andradeana-beatriz@example.org', '31 4115-2621', '1977-10-23'),
('Lucca Peixoto', '970.351.682-30', 'fariasnoah@example.org', '64 8844-4310', '1967-05-01'),
('Rebeca Cassiano', '059.372.684-74', 'costelaluigi@example.net', '18 1714-6774', '1946-10-23'),
('Maria Julia Cirino', '569.130.287-68', 'rael49@example.org', '+55 65 1158-6938', '1944-10-04'),
('Stephany Leão', '873.920.654-83', 'isaquesa@example.com', '+55 73 2332-0616', '1954-05-06'),
('Clara Peixoto', '451.039.827-14', 'raquel70@example.net', '99 6162-2999', '1992-03-07'),
('Cauê Nunes', '145.326.879-00', 'cavalcantiyuri@example.com', '+55 63 9960-6530', '1991-04-29'),
('Marcelo Almeida', '548.230.179-60', 'uvasconcelos@example.com', '66 9137-3678', '1999-08-01'),
('Théo Vieira', '214.573.890-88', 'matheuscosta@example.org', '+55 96 0705-3457', '1974-12-17'),
('Camila Rodrigues', '035.846.172-35', 'luan41@example.com', '+55 18 6029-3333', '1958-11-29'),
('Sophie Almeida', '072.514.936-16', 'yan66@example.com', '82 4374-8969', '1947-07-28'),
('Maria Fernanda Novais', '948.503.612-42', 'yuri44@example.org', '+55 65 8309-6520', '1985-03-07'),
('José Pedro Leão', '690.458.137-93', 'wrios@example.net', '21 2824-1724', '1989-12-04'),
('Emilly Rodrigues', '513.286.794-46', 'ana-beatriz71@example.com', '+55 28 9991-7381', '1999-08-09'),
('Vitória da Rosa', '602.197.345-34', 'ana-vitoriasilva@example.org', '+55 38 7525-0074', '1954-11-07'),
('Emanuel Mendonça', '126.537.498-82', 'andradesophie@example.org', '48 0583-0033', '1987-10-10'),
('Dr. Davi Lucca Caldeira', '684.105.293-51', 'luara25@example.com', '44 3260-3323', '1990-07-13'),
('Sofia Cavalcante', '150.382.746-17', 'rezendeasafe@example.org', '+55 49 6761-8472', '1954-08-02'),
('Alexia da Rosa', '614.798.302-40', 'ian17@example.org', '+55 83 4835-6420', '1977-11-20'),
('Rodrigo Farias', '308.576.942-00', 'silveiraguilherme@example.com', '+55 92 7447-0120', '1998-07-26'),
('Dr. Paulo Sousa', '190.785.243-32', 'francisco55@example.org', '+55 49 6674-6762', '1948-04-19'),
('Dra. Ana Liz Castro', '167.843.925-82', 'benjamin27@example.com', '+55 48 6701-4508', '1992-10-21'),
('Heloisa Rios', '581.397.642-64', 'cauealbuquerque@example.net', '+55 67 8772-1753', '1963-02-11'),
('Benicio Montenegro', '386.910.752-95', 'monteiromaite@example.com', '+55 51 7016-6088', '1940-08-16'),
('Kevin Moraes', '837.260.195-02', 'qsilva@example.com', '79 1130-5548', '1976-02-09'),
('Srta. Ana Clara Cavalcante', '726.084.195-85', 'dcunha@example.org', '37 1609-1779', '2005-08-19'),
('Theo Abreu', '806.743.129-96', 'gustavo-henriquegomes@example.net', '32 8669-3465', '2006-08-10'),
('Catarina Carvalho', '684.957.230-00', 'ottopinto@example.net', '18 5228-8515', '1978-11-06'),
('Maria Vitória Rocha', '846.709.531-84', 'cauerios@example.org', '+55 83 4244-2043', '1991-11-10'),
('Luiz Henrique Machado', '183.564.709-00', 'garciahellena@example.com', '28 8004-3973', '2002-08-05'),
('Dra. Maria Eduarda Sá', '983.651.240-33', 'cirinoluiz-felipe@example.net', '97 1606-4842', '1951-07-22'),
('André Farias', '720.184.956-58', 'kvieira@example.net', '44 1583-2818', '1951-06-14'),
('Zoe Guerra', '153.982.467-55', 'sofiamelo@example.net', '+55 13 1573-9930', '1987-01-10'),
('Dr. Danilo Gomes', '489.072.316-13', 'matheus58@example.org', '+55 44 2880-1336', '1997-06-09'),
('Vitor Gabriel Sampaio', '612.037.954-16', 'cavalcantitheodoro@example.net', '+55 35 9346-6766', '1962-02-16'),
('Bárbara Nascimento', '019.572.684-76', 'da-pazluna@example.com', '61 0728-3268', '1960-09-02'),
('Cecília da Rosa', '502.869.374-92', 'otto53@example.com', '97 2223-9431', '1952-12-11'),
('Ana Júlia Sá', '871.250.643-53', 'wfarias@example.org', '+55 93 1491-3577', '1962-12-10'),
('Lorena Sales', '925.683.104-05', 'pedro-miguelsilva@example.net', '73 4525-7775', '1993-04-18'),
('Bianca Cavalcanti', '914.687.530-10', 'almeidanatalia@example.net', '+55 18 9969-3084', '1977-07-27'),
('Olivia Rezende', '256.149.730-52', 'gfonseca@example.org', '+55 94 9282-7229', '2005-02-15'),
('Clara Sousa', '750.136.942-99', 'bryanrios@example.org', '98 5677-0051', '1988-06-19'),
('Kamilly Sousa', '482.356.790-00', 'fernanda38@example.com', '43 5779-0827', '1951-11-16'),
('Théo Ramos', '432.167.098-50', 'ufarias@example.org', '88 7739-2603', '1943-07-19'),
('Elisa Carvalho', '802.917.543-41', 'silveiraalice@example.org', '+55 87 7977-2369', '1950-04-26'),
('Emilly Pinto', '842.567.390-92', 'gabrielagomes@example.org', '+55 47 0388-6291', '1952-09-04'),
('Ana Carolina Viana', '891.037.624-40', 'cfreitas@example.net', '0500 637 6599', '1947-04-04'),
('José Miguel Mendes', '314.769.205-16', 'oliveirarebeca@example.org', '99 0635-6512', '1969-08-02'),
('Isis da Luz', '865.423.197-19', 'esternovais@example.net', '88 4495-6213', '1970-12-25'),
('Srta. Beatriz Cunha', '865.947.031-10', 'borgesjoao-vitor@example.com', '73 1143-5190', '1989-11-17'),
('Stephany da Paz', '902.536.841-70', 'bernardoviana@example.net', '96 8392-0530', '2006-12-16'),
('João Guilherme Vasconcelos', '659.341.027-61', 'novaesalice@example.net', '42 5439-3769', '1940-12-05'),
('Nicolas Montenegro', '189.425.067-20', 'luisa69@example.com', '+55 95 5779-0714', '1945-03-16'),
('Hellena Rocha', '356.248.071-71', 'aliciaborges@example.com', '38 1827-5539', '1958-11-29'),
('Dra. Esther Monteiro', '398.621.405-42', 'leonardo11@example.org', '92 9080-7595', '1974-02-03'),
('Kamilly Mendonça', '284.317.506-26', 'cnogueira@example.net', '41 6271-8750', '1941-06-01'),
('Mateus Pacheco', '158.429.706-94', 'vpimenta@example.com', '+55 77 7636-5564', '1971-04-06'),
('Caroline Oliveira', '314.687.950-66', 'kaiquemelo@example.org', '+55 74 6728-8574', '1957-09-05'),
('Ana Julia Gonçalves', '120.983.765-02', 'eloah58@example.net', '+55 98 5061-5939', '1979-10-10'),
('Zoe Cavalcanti', '458.793.601-48', 'maria-fernanda22@example.net', '37 6996-1125', '1956-02-18'),
('Dr. João Felipe Pereira', '647.928.310-40', 'augustocardoso@example.net', '+55 93 4132-6111', '2004-04-25'),
('Ana Júlia Alves', '681.024.793-96', 'raul34@example.com', '+55 54 2820-0557', '1972-05-19'),
('Júlia Novaes', '728.463.591-64', 'maria-luisa83@example.org', '75 4564-2400', '1976-03-13'),
('Luiz Felipe da Paz', '780.536.291-21', 'ravi08@example.com', '+55 79 6866-3266', '1955-08-12'),
('Otávio Pires', '384.257.610-26', 'cirinojoao-gabriel@example.com', '+55 48 7974-9735', '1941-12-06'),
('Vitor Almeida', '214.983.076-04', 'arthurmonteiro@example.org', '38 6475-7051', '1997-12-22'),
('Benjamin da Mata', '617.892.304-03', 'helenavargas@example.com', '+55 96 0371-8376', '1986-12-13'),
('Lorenzo Castro', '081.236.759-68', 'henry-gabrielda-costa@example.net', '73 5024-9163', '1941-03-21'),
('Renan Sales', '925.601.437-80', 'dante05@example.net', '+55 66 8127-3585', '1995-05-22'),
('Evelyn Almeida', '652.703.491-16', 'kcorreia@example.org', '42 5749-8218', '1951-02-26'),
('João Nogueira', '570.694.328-10', 'pintoemanuella@example.net', '+55 94 5186-3878', '1951-02-04'),
('Lorenzo Jesus', '518.490.632-06', 'costaheitor@example.com', '+55 81 1096-7899', '1958-01-06'),
('Sr. Brayan Albuquerque', '371.950.268-68', 'danilo94@example.net', '+55 22 1413-8113', '1976-10-06'),
('Gael Moura', '326.504.891-89', 'kcaldeira@example.org', '62 8528-9755', '1978-01-07'),
('Dr. Noah Teixeira', '653.491.728-91', 'marcela76@example.org', '+55 19 4908-2404', '2007-07-21'),
('Levi Almeida', '482.063.759-29', 'emanuelly93@example.org', '+55 98 4196-9315', '1994-07-13'),
('Ryan Sales', '914.057.362-16', 'cecilia66@example.org', '+55 91 9060-4805', '1977-04-30'),
('Luan Montenegro', '320.569.487-29', 'luanada-rocha@example.com', '+55 64 2517-9086', '1958-06-20'),
('Sarah Lopes', '297.413.680-03', 'ryanbarbosa@example.com', '71 5911-6655', '1953-07-26'),
('Sr. Leandro Cavalcante', '572.301.486-26', 'enzo-gabrielcamargo@example.net', '+55 28 3924-0514', '1971-03-21'),
('Lucas Costela', '839.462.750-10', 'garciasara@example.org', '+55 98 2043-9407', '1985-02-19'),
('Bernardo Gomes', '451.023.796-07', 'maria-vitoria98@example.org', '+55 77 3878-0038', '1961-05-07'),
('Maria Júlia Souza', '205.796.481-76', 'pirestheo@example.com', '+55 18 8432-5621', '1990-03-31'),
('Heloísa Leão', '326.847.950-29', 'joao-guilhermepacheco@example.net', '+55 83 2482-6292', '1962-03-15'),
('Yasmin Silveira', '125.690.873-86', 'luisa42@example.org', '+55 47 2209-9499', '1982-04-03'),
('Isabel da Conceição', '051.837.624-90', 'hellenamendonca@example.com', '+55 62 2330-6046', '1955-09-30'),
('Gabriela Sá', '312.946.780-78', 'xguerra@example.org', '51 5699-9880', '1976-01-07'),
('Mirella Aparecida', '386.504.927-38', 'anamacedo@example.com', '22 4726-4908', '2002-01-23');

-- QUARTOS
INSERT INTO QUARTOS (tipo, capacidade, preco_diaria, status, andar) VALUES
('Suite', 2, 716.35, 'disponivel', 10),
('Suite', 3, 170.45, 'manutencao', 15),
('Suite', 2, 210.82, 'disponivel', 2),
('Familia', 1, 1176.88, 'ocupado', 3),
('Familia', 4, 323.38, 'reservado', 4),
('Executivo', 5, 874.36, 'manutencao', 7),
('Suite', 3, 1094.59, 'reservado', 2),
('Luxo', 2, 217.23, 'disponivel', 10),
('Executivo', 2, 767.86, 'disponivel', 2),
('Standard', 2, 220.77, 'disponivel', 14),
('Suite', 1, 689.86, 'manutencao', 11),
('Familia', 2, 716.2, 'reservado', 4),
('Familia', 3, 349.93, 'disponivel', 11),
('Familia', 2, 594.76, 'reservado', 14),
('Standard', 5, 836.13, 'disponivel', 1),
('Familia', 5, 506.27, 'disponivel', 4),
('Luxo', 2, 713.1, 'ocupado', 7),
('Luxo', 2, 635.76, 'disponivel', 8),
('Executivo', 1, 203.12, 'disponivel', 2),
('Luxo', 2, 576.73, 'reservado', 4),
('Familia', 1, 322.87, 'disponivel', 7),
('Suite', 3, 449.51, 'reservado', 3),
('Luxo', 2, 378.59, 'disponivel', 10),
('Executivo', 1, 935.37, 'disponivel', 1),
('Executivo', 3, 677.99, 'ocupado', 1),
('Executivo', 1, 1043.91, 'disponivel', 10),
('Standard', 5, 1054.91, 'reservado', 2),
('Executivo', 2, 757.87, 'disponivel', 10),
('Standard', 3, 840.24, 'manutencao', 15),
('Suite', 2, 853.21, 'manutencao', 4),
('Suite', 3, 287.42, 'manutencao', 8),
('Suite', 1, 159.78, 'disponivel', 2),
('Executivo', 2, 681.18, 'ocupado', 15),
('Suite', 1, 1073.23, 'manutencao', 5),
('Luxo', 3, 1025.43, 'manutencao', 10),
('Executivo', 1, 851.26, 'manutencao', 15),
('Standard', 2, 427.69, 'disponivel', 12),
('Executivo', 2, 435.97, 'ocupado', 12),
('Suite', 2, 871.87, 'manutencao', 9),
('Familia', 2, 1100.6, 'disponivel', 2),
('Familia', 2, 196.29, 'manutencao', 13),
('Luxo', 5, 1178.79, 'ocupado', 12),
('Familia', 4, 890.95, 'disponivel', 2),
('Standard', 5, 1099.13, 'disponivel', 14),
('Suite', 4, 730.15, 'reservado', 3),
('Standard', 2, 532.88, 'disponivel', 15),
('Suite', 2, 866.17, 'disponivel', 6),
('Executivo', 3, 1172.53, 'ocupado', 15),
('Luxo', 2, 1175.02, 'ocupado', 15),
('Familia', 1, 338.33, 'manutencao', 13),
('Familia', 5, 1057.27, 'ocupado', 5),
('Luxo', 5, 263.5, 'disponivel', 14),
('Familia', 2, 359.55, 'reservado', 6),
('Suite', 2, 384.07, 'ocupado', 7),
('Suite', 2, 1057.57, 'manutencao', 6),
('Executivo', 3, 863.49, 'manutencao', 1),
('Standard', 2, 337.5, 'manutencao', 1),
('Standard', 4, 606.29, 'manutencao', 7),
('Executivo', 4, 271.43, 'ocupado', 5),
('Standard', 5, 607.86, 'ocupado', 6),
('Familia', 1, 1146.32, 'manutencao', 10),
('Suite', 5, 1040.42, 'manutencao', 9),
('Suite', 5, 578.81, 'reservado', 12),
('Suite', 4, 283.65, 'reservado', 11),
('Familia', 5, 935.54, 'ocupado', 10),
('Executivo', 2, 576.38, 'disponivel', 5),
('Suite', 2, 601.38, 'manutencao', 8),
('Familia', 3, 859.41, 'reservado', 13),
('Luxo', 5, 239.04, 'manutencao', 2),
('Luxo', 5, 475.94, 'ocupado', 3),
('Standard', 1, 407.08, 'reservado', 10),
('Standard', 3, 585.16, 'ocupado', 12),
('Familia', 3, 569.64, 'ocupado', 11),
('Standard', 1, 967.34, 'ocupado', 3),
('Executivo', 3, 202.73, 'ocupado', 15),
('Standard', 3, 290.01, 'reservado', 11),
('Executivo', 4, 775.22, 'reservado', 10),
('Executivo', 3, 1022.1, 'reservado', 15),
('Luxo', 5, 1054.57, 'reservado', 5),
('Luxo', 5, 441.18, 'reservado', 11),
('Luxo', 2, 611.87, 'manutencao', 4),
('Suite', 2, 485.7, 'disponivel', 3),
('Luxo', 2, 552.19, 'ocupado', 12),
('Luxo', 1, 585.61, 'manutencao', 9),
('Familia', 3, 215.38, 'reservado', 7),
('Executivo', 5, 170.51, 'reservado', 8),
('Standard', 2, 463.54, 'reservado', 14),
('Familia', 4, 934.89, 'ocupado', 8),
('Luxo', 2, 607.63, 'disponivel', 7),
('Suite', 5, 863.1, 'reservado', 12),
('Luxo', 3, 1115.52, 'disponivel', 15),
('Familia', 4, 742.61, 'disponivel', 2),
('Familia', 2, 1060.19, 'ocupado', 1),
('Suite', 3, 493.72, 'reservado', 6),
('Suite', 3, 442.17, 'reservado', 5),
('Standard', 3, 170.35, 'disponivel', 6),
('Luxo', 5, 222.05, 'disponivel', 13),
('Standard', 2, 359.33, 'disponivel', 10),
('Luxo', 2, 282.53, 'disponivel', 10),
('Luxo', 3, 884.44, 'manutencao', 3);

-- RESERVAS
INSERT INTO RESERVAS (id_quarto, id_cliente, id_funcionario, tipo, qtd_hospedes, tempo, checkin, checkout, observacoes) VALUES
(78, 78, 96, 'online', 2, 5, '2026-02-25 18:59:26', '2026-03-02 18:59:26', 'Lua de mel'),
(75, 4, 40, 'agencia', 4, 12, '2026-05-14 13:27:06', '2026-05-26 13:27:06', 'Cliente vip'),
(10, 76, 89, 'balcao', 1, 12, '2025-09-19 19:18:35', '2025-10-01 19:18:35', 'Aniversario'),
(88, 77, 16, 'online', 3, 9, '2026-03-13 14:09:21', '2026-03-22 14:09:21', NULL),
(85, 48, 9, 'telefone', 1, 14, '2025-10-27 20:47:50', '2025-11-10 20:47:50', NULL),
(63, 14, 56, 'telefone', 4, 12, '2026-04-18 17:12:39', '2026-04-30 17:12:39', 'Preferencia por andar alto'),
(56, 23, 94, 'telefone', 5, 13, '2026-08-28 07:47:46', '2026-09-10 07:47:46', NULL),
(100, 62, 60, 'agencia', 5, 5, '2026-04-02 01:59:05', '2026-04-07 01:59:05', 'Alergia a penas - travesseiro especial'),
(32, 12, 36, 'agencia', 2, 13, '2026-01-26 17:56:17', '2026-02-08 17:56:17', NULL),
(73, 79, 86, 'agencia', 3, 1, '2025-12-28 02:09:18', '2025-12-29 02:09:18', NULL),
(42, 24, 63, 'balcao', 3, 13, '2025-08-22 21:13:07', '2025-09-04 21:13:07', 'Aniversario'),
(44, 36, 77, 'telefone', 5, 1, '2026-02-21 13:46:20', '2026-02-22 13:46:20', NULL),
(25, 11, 31, 'agencia', 4, 9, '2026-08-29 07:12:30', '2026-09-07 07:12:30', 'Cliente vip'),
(89, 61, 83, 'agencia', 4, 13, '2026-08-28 22:47:47', '2026-09-10 22:47:47', 'Pedido de berco'),
(12, 38, 29, 'agencia', 2, 5, '2026-08-23 07:20:21', '2026-08-28 07:20:21', 'Alergia a penas - travesseiro especial'),
(61, 71, 68, 'telefone', 4, 12, '2025-09-19 16:38:22', '2025-10-01 16:38:22', NULL),
(43, 46, 90, 'agencia', 3, 5, '2025-12-28 08:25:55', '2026-01-02 08:25:55', 'Aniversario'),
(30, 16, 93, 'balcao', 3, 2, '2026-05-15 14:45:36', '2026-05-17 14:45:36', NULL),
(98, 89, 24, 'balcao', 2, 12, '2026-06-11 09:54:07', '2026-06-23 09:54:07', NULL),
(36, 93, 76, 'telefone', 1, 14, '2025-10-21 03:27:33', '2025-11-04 03:27:33', 'Cliente vip'),
(38, 30, 47, 'balcao', 3, 1, '2026-06-20 16:45:04', '2026-06-21 16:45:04', NULL),
(17, 36, 6, 'online', 5, 5, '2025-09-20 02:59:01', '2025-09-25 02:59:01', 'Preferencia por andar alto'),
(82, 97, 63, 'online', 1, 10, '2026-06-09 04:17:14', '2026-06-19 04:17:14', 'Aniversario'),
(61, 62, 57, 'telefone', 2, 1, '2026-05-09 10:26:35', '2026-05-10 10:26:35', 'Aniversario'),
(62, 15, 9, 'agencia', 4, 2, '2025-09-17 14:48:26', '2025-09-19 14:48:26', 'Pedido de berco'),
(20, 20, 73, 'telefone', 1, 4, '2026-06-09 15:02:56', '2026-06-13 15:02:56', 'Lua de mel'),
(72, 98, 54, 'balcao', 5, 7, '2026-06-17 23:25:23', '2026-06-24 23:25:23', NULL),
(57, 39, 76, 'agencia', 3, 10, '2026-10-01 18:41:56', '2026-10-11 18:41:56', 'Pedido de berco'),
(79, 95, 13, 'balcao', 2, 5, '2026-04-30 01:28:27', '2026-05-05 01:28:27', 'Lua de mel'),
(21, 31, 23, 'online', 2, 1, '2025-10-19 09:35:26', '2025-10-20 09:35:26', NULL),
(58, 89, 77, 'agencia', 3, 1, '2026-04-03 18:15:44', '2026-04-04 18:15:44', 'Cliente vip'),
(37, 91, 37, 'agencia', 1, 11, '2025-08-30 23:26:58', '2025-09-10 23:26:58', 'Cliente vip'),
(34, 81, 76, 'balcao', 4, 2, '2025-10-24 01:55:32', '2025-10-26 01:55:32', NULL),
(29, 83, 20, 'telefone', 2, 2, '2026-01-02 02:07:39', '2026-01-04 02:07:39', 'Pedido de berco'),
(22, 40, 77, 'telefone', 4, 2, '2026-08-18 12:22:07', '2026-08-20 12:22:07', NULL),
(89, 39, 90, 'agencia', 3, 9, '2026-08-14 20:05:21', '2026-08-23 20:05:21', NULL),
(64, 57, 11, 'online', 4, 12, '2025-10-20 08:20:14', '2025-11-01 08:20:14', 'Alergia a penas - travesseiro especial'),
(78, 33, 4, 'online', 2, 11, '2025-10-12 21:12:46', '2025-10-23 21:12:46', 'Pedido de berco'),
(98, 87, 35, 'online', 2, 8, '2026-07-05 23:48:19', '2026-07-13 23:48:19', NULL),
(84, 57, 36, 'balcao', 5, 7, '2025-09-03 03:09:59', '2025-09-10 03:09:59', NULL),
(12, 61, 45, 'agencia', 3, 6, '2025-12-21 12:41:20', '2025-12-27 12:41:20', 'Lua de mel'),
(21, 43, 53, 'agencia', 3, 11, '2026-06-19 09:02:42', '2026-06-30 09:02:42', NULL),
(98, 71, 5, 'agencia', 1, 6, '2026-09-25 17:13:55', '2026-10-01 17:13:55', 'Aniversario'),
(42, 15, 99, 'agencia', 5, 14, '2025-12-13 07:30:58', '2025-12-27 07:30:58', 'Pedido de berco'),
(85, 70, 60, 'agencia', 1, 4, '2025-10-28 06:15:09', '2025-11-01 06:15:09', NULL),
(47, 80, 97, 'agencia', 4, 13, '2026-08-30 02:53:13', '2026-09-12 02:53:13', 'Pedido de berco'),
(27, 35, 71, 'balcao', 3, 8, '2026-09-25 11:47:22', '2026-10-03 11:47:22', NULL),
(16, 4, 81, 'balcao', 2, 5, '2025-08-13 18:35:47', '2025-08-18 18:35:47', NULL),
(2, 71, 53, 'online', 2, 14, '2026-07-04 09:20:44', '2026-07-18 09:20:44', 'Lua de mel'),
(60, 16, 83, 'balcao', 4, 12, '2025-08-17 11:18:18', '2025-08-29 11:18:18', 'Aniversario'),
(66, 91, 35, 'agencia', 4, 8, '2026-03-12 07:10:10', '2026-03-20 07:10:10', 'Cliente vip'),
(59, 71, 19, 'agencia', 2, 10, '2026-03-12 17:32:42', '2026-03-22 17:32:42', NULL),
(96, 18, 9, 'telefone', 4, 6, '2026-07-22 07:26:06', '2026-07-28 07:26:06', NULL),
(35, 1, 37, 'telefone', 5, 10, '2026-04-28 07:39:52', '2026-05-08 07:39:52', NULL),
(20, 58, 69, 'agencia', 3, 6, '2026-03-10 12:37:17', '2026-03-16 12:37:17', NULL),
(98, 70, 49, 'agencia', 3, 14, '2025-11-12 16:12:14', '2025-11-26 16:12:14', 'Cliente vip'),
(90, 31, 74, 'agencia', 2, 14, '2026-05-20 06:09:47', '2026-06-03 06:09:47', NULL),
(6, 41, 96, 'agencia', 4, 7, '2026-02-21 14:21:46', '2026-02-28 14:21:46', 'Preferencia por andar alto'),
(64, 5, 17, 'telefone', 1, 14, '2026-02-16 13:03:05', '2026-03-02 13:03:05', NULL),
(13, 68, 59, 'online', 2, 7, '2026-04-25 10:27:43', '2026-05-02 10:27:43', 'Preferencia por andar alto'),
(10, 61, 34, 'telefone', 5, 12, '2025-08-15 01:41:04', '2025-08-27 01:41:04', NULL),
(84, 11, 43, 'agencia', 3, 11, '2026-08-23 03:26:50', '2026-09-03 03:26:50', NULL),
(70, 5, 80, 'online', 2, 11, '2025-12-08 18:25:48', '2025-12-19 18:25:48', 'Aniversario'),
(30, 96, 12, 'agencia', 1, 13, '2026-05-07 02:50:42', '2026-05-20 02:50:42', 'Lua de mel'),
(57, 22, 89, 'telefone', 1, 1, '2026-07-27 16:57:54', '2026-07-28 16:57:54', 'Alergia a penas - travesseiro especial'),
(8, 38, 46, 'telefone', 4, 3, '2025-11-08 17:45:17', '2025-11-11 17:45:17', 'Cliente vip'),
(68, 53, 73, 'balcao', 2, 3, '2025-10-30 00:37:42', '2025-11-02 00:37:42', 'Lua de mel'),
(79, 49, 80, 'balcao', 4, 10, '2025-09-04 17:32:55', '2025-09-14 17:32:55', 'Preferencia por andar alto'),
(30, 60, 82, 'telefone', 4, 5, '2026-01-07 23:31:06', '2026-01-12 23:31:06', 'Pedido de berco'),
(60, 37, 87, 'balcao', 1, 8, '2025-10-13 05:03:23', '2025-10-21 05:03:23', 'Alergia a penas - travesseiro especial'),
(76, 39, 82, 'agencia', 3, 8, '2025-08-26 02:07:02', '2025-09-03 02:07:02', 'Aniversario'),
(26, 50, 62, 'online', 2, 7, '2026-04-15 13:59:57', '2026-04-22 13:59:57', 'Alergia a penas - travesseiro especial'),
(74, 38, 90, 'telefone', 1, 14, '2026-04-26 07:37:06', '2026-05-10 07:37:06', NULL),
(36, 2, 73, 'online', 5, 12, '2025-12-31 08:23:05', '2026-01-12 08:23:05', NULL),
(37, 100, 30, 'telefone', 2, 11, '2025-09-18 15:18:36', '2025-09-29 15:18:36', 'Cliente vip'),
(80, 33, 87, 'balcao', 1, 11, '2025-09-27 15:56:44', '2025-10-08 15:56:44', 'Pedido de berco'),
(40, 57, 5, 'telefone', 2, 2, '2026-10-09 16:19:33', '2026-10-11 16:19:33', 'Aniversario'),
(42, 96, 54, 'balcao', 2, 3, '2025-10-20 00:16:14', '2025-10-23 00:16:14', NULL),
(47, 68, 65, 'telefone', 2, 5, '2025-12-11 10:31:19', '2025-12-16 10:31:19', NULL),
(38, 96, 44, 'online', 4, 2, '2026-05-20 21:01:53', '2026-05-22 21:01:53', 'Preferencia por andar alto'),
(97, 29, 87, 'agencia', 5, 6, '2026-06-06 11:02:49', '2026-06-12 11:02:49', 'Lua de mel'),
(51, 2, 34, 'online', 4, 6, '2026-04-13 02:35:07', '2026-04-19 02:35:07', 'Aniversario'),
(75, 49, 82, 'telefone', 1, 11, '2026-04-08 19:14:54', '2026-04-19 19:14:54', 'Cliente vip'),
(61, 4, 80, 'telefone', 5, 4, '2026-09-27 23:42:25', '2026-10-01 23:42:25', 'Lua de mel'),
(82, 60, 90, 'telefone', 4, 2, '2026-06-27 13:06:26', '2026-06-29 13:06:26', 'Preferencia por andar alto'),
(6, 5, 39, 'agencia', 1, 2, '2026-01-12 17:43:47', '2026-01-14 17:43:47', 'Cliente vip'),
(69, 18, 50, 'agencia', 3, 11, '2025-08-27 12:58:00', '2025-09-07 12:58:00', NULL),
(54, 76, 96, 'balcao', 4, 11, '2026-07-05 17:12:41', '2026-07-16 17:12:41', 'Lua de mel'),
(63, 79, 53, 'telefone', 1, 12, '2025-12-27 19:37:11', '2026-01-08 19:37:11', 'Alergia a penas - travesseiro especial'),
(28, 57, 57, 'balcao', 3, 2, '2026-08-29 16:32:13', '2026-08-31 16:32:13', 'Alergia a penas - travesseiro especial'),
(70, 83, 46, 'online', 4, 5, '2026-07-27 18:25:51', '2026-08-01 18:25:51', 'Cliente vip'),
(16, 59, 12, 'balcao', 5, 1, '2026-07-01 10:14:11', '2026-07-02 10:14:11', 'Pedido de berco'),
(43, 32, 17, 'balcao', 1, 14, '2026-08-06 14:05:10', '2026-08-20 14:05:10', NULL),
(27, 76, 28, 'balcao', 3, 13, '2025-09-08 22:23:46', '2025-09-21 22:23:46', 'Preferencia por andar alto'),
(77, 1, 36, 'balcao', 2, 9, '2026-02-28 21:00:17', '2026-03-09 21:00:17', 'Aniversario'),
(23, 15, 85, 'online', 2, 1, '2025-10-03 06:16:09', '2025-10-04 06:16:09', 'Alergia a penas - travesseiro especial'),
(31, 76, 42, 'online', 2, 5, '2026-08-13 10:42:22', '2026-08-18 10:42:22', 'Pedido de berco'),
(17, 95, 54, 'online', 1, 8, '2025-12-30 12:55:46', '2026-01-07 12:55:46', NULL),
(100, 47, 66, 'online', 4, 9, '2026-02-04 13:31:29', '2026-02-13 13:31:29', 'Cliente vip'),
(79, 6, 94, 'telefone', 4, 11, '2025-11-09 16:19:53', '2025-11-20 16:19:53', 'Pedido de berco');

-- CONSUMOS
INSERT INTO CONSUMOS (id_reserva, tipo, valor, data_consumo) VALUES
(8, 'Lavanderia', 425.18, '2025-10-27 14:57:36'),
(55, 'Estacionamento', 62.9, '2025-09-02 12:30:05'),
(92, 'Lavanderia', 46.01, '2026-03-08 22:56:09'),
(11, 'Room Service', 308.07, '2026-08-04 23:12:57'),
(9, 'Restaurante', 144.76, '2026-02-21 11:05:18'),
(82, 'Spa', 278.69, '2025-09-13 06:57:40'),
(42, 'Lavanderia', 497.37, '2026-05-03 17:31:46'),
(68, 'Room Service', 232.32, '2026-03-21 03:48:30'),
(78, 'Lavanderia', 58.6, '2026-05-27 03:30:31'),
(90, 'Frigobar', 427.87, '2026-04-27 10:09:29'),
(84, 'Spa', 363.21, '2026-01-15 05:55:07'),
(28, 'Lavanderia', 231.26, '2026-06-17 22:03:46'),
(30, 'Lavanderia', 176.08, '2025-11-15 02:35:13'),
(59, 'Lavanderia', 213.83, '2026-03-10 08:01:55'),
(13, 'Room Service', 219.11, '2026-03-27 21:40:40'),
(86, 'Room Service', 193.41, '2026-07-16 21:15:09'),
(20, 'Estacionamento', 462.26, '2026-03-24 15:11:16'),
(9, 'Frigobar', 417.57, '2026-02-09 13:45:56'),
(12, 'Lavanderia', 57.32, '2026-05-05 14:19:40'),
(95, 'Room Service', 407.77, '2026-02-10 01:32:54'),
(72, 'Frigobar', 297.37, '2026-06-03 09:01:52'),
(72, 'Spa', 171.53, '2026-07-01 00:27:11'),
(16, 'Lavanderia', 183.26, '2025-11-05 06:27:05'),
(86, 'Lavanderia', 435.37, '2025-11-26 08:49:05'),
(93, 'Frigobar', 484.52, '2025-10-21 23:07:47'),
(77, 'Room Service', 182.31, '2025-09-24 10:38:41'),
(74, 'Spa', 114.24, '2026-01-29 01:32:43'),
(85, 'Lavanderia', 119.88, '2026-05-30 06:26:08'),
(14, 'Room Service', 424.23, '2026-05-08 14:56:24'),
(48, 'Frigobar', 383.68, '2025-10-26 23:52:54'),
(74, 'Restaurante', 405.54, '2026-03-25 00:06:41'),
(72, 'Spa', 310.65, '2026-01-10 17:02:05'),
(83, 'Spa', 22.86, '2025-08-28 21:14:35'),
(85, 'Estacionamento', 141.05, '2025-12-17 23:25:04'),
(24, 'Room Service', 354.32, '2026-06-02 16:03:12'),
(40, 'Room Service', 182.0, '2025-10-28 19:46:22'),
(24, 'Restaurante', 287.5, '2026-04-03 05:58:32'),
(52, 'Frigobar', 79.52, '2026-04-21 06:59:36'),
(82, 'Frigobar', 54.96, '2025-11-13 04:37:56'),
(68, 'Restaurante', 194.34, '2025-09-06 01:06:14'),
(59, 'Room Service', 87.13, '2025-11-29 22:41:12'),
(40, 'Estacionamento', 168.95, '2026-03-01 03:34:52'),
(73, 'Spa', 51.63, '2026-05-19 10:05:35'),
(7, 'Restaurante', 87.13, '2025-09-22 20:20:06'),
(80, 'Frigobar', 340.24, '2025-12-11 23:56:50'),
(35, 'Lavanderia', 334.35, '2026-01-03 22:08:34'),
(63, 'Spa', 226.6, '2026-03-08 01:29:56'),
(35, 'Restaurante', 379.92, '2026-07-28 22:35:16'),
(15, 'Room Service', 220.66, '2026-06-12 03:57:24'),
(37, 'Estacionamento', 342.46, '2025-10-22 03:09:48'),
(63, 'Spa', 336.89, '2026-06-12 19:34:54'),
(6, 'Restaurante', 203.68, '2026-07-15 02:57:09'),
(77, 'Frigobar', 13.77, '2026-02-03 06:13:03'),
(39, 'Restaurante', 386.0, '2026-02-01 13:49:35'),
(98, 'Room Service', 151.83, '2025-08-25 06:09:52'),
(16, 'Frigobar', 253.72, '2025-09-30 20:27:19'),
(56, 'Restaurante', 73.3, '2025-10-08 00:32:54'),
(69, 'Estacionamento', 122.75, '2026-01-27 12:08:08'),
(72, 'Estacionamento', 405.04, '2026-06-24 06:49:06'),
(10, 'Lavanderia', 432.26, '2026-07-05 11:57:52'),
(6, 'Lavanderia', 19.18, '2026-01-28 04:22:16'),
(10, 'Room Service', 292.12, '2026-06-05 15:15:31'),
(74, 'Lavanderia', 357.65, '2026-07-17 03:15:13'),
(54, 'Room Service', 66.43, '2025-09-01 17:32:50'),
(3, 'Room Service', 94.22, '2026-02-18 14:04:20'),
(80, 'Lavanderia', 417.69, '2026-03-06 14:37:15'),
(47, 'Frigobar', 223.99, '2026-04-16 23:23:13'),
(14, 'Restaurante', 223.48, '2026-03-03 01:01:10'),
(52, 'Spa', 48.54, '2025-08-19 02:33:02'),
(40, 'Estacionamento', 176.36, '2026-03-11 03:47:54'),
(43, 'Restaurante', 47.43, '2025-12-11 10:14:28'),
(82, 'Frigobar', 270.0, '2026-07-12 21:32:23'),
(25, 'Room Service', 182.04, '2026-05-29 22:06:37'),
(83, 'Restaurante', 125.77, '2025-09-05 10:52:37'),
(19, 'Room Service', 106.66, '2025-10-05 19:14:25'),
(78, 'Restaurante', 382.51, '2026-06-15 08:11:13'),
(84, 'Frigobar', 96.8, '2025-12-14 03:23:53'),
(99, 'Estacionamento', 252.12, '2025-12-27 07:44:24'),
(97, 'Spa', 382.34, '2026-02-23 09:46:47'),
(58, 'Estacionamento', 462.84, '2025-10-11 21:19:05'),
(73, 'Estacionamento', 321.3, '2026-03-21 11:47:40'),
(80, 'Room Service', 433.48, '2025-10-19 16:59:16'),
(81, 'Room Service', 83.97, '2025-09-23 22:42:05'),
(9, 'Lavanderia', 226.68, '2026-05-25 00:18:31'),
(39, 'Room Service', 299.8, '2025-12-02 20:47:25'),
(46, 'Spa', 46.35, '2026-06-21 13:54:32'),
(60, 'Lavanderia', 28.43, '2026-04-28 12:45:23'),
(48, 'Room Service', 47.6, '2025-11-19 10:21:02'),
(12, 'Spa', 301.1, '2025-09-12 23:19:04'),
(50, 'Lavanderia', 294.36, '2026-06-28 14:28:05'),
(95, 'Frigobar', 230.37, '2025-12-25 23:40:54'),
(74, 'Estacionamento', 102.24, '2026-06-11 05:17:40'),
(78, 'Lavanderia', 255.67, '2025-11-30 19:14:24'),
(8, 'Lavanderia', 60.72, '2026-02-20 01:22:25'),
(44, 'Estacionamento', 51.32, '2025-10-15 04:35:21'),
(83, 'Restaurante', 29.18, '2025-12-26 22:45:15'),
(91, 'Lavanderia', 495.58, '2025-08-25 22:15:55'),
(68, 'Spa', 308.8, '2025-10-25 02:00:56'),
(47, 'Room Service', 459.79, '2025-09-15 02:12:53'),
(50, 'Lavanderia', 389.49, '2026-02-13 01:53:50');

-- PAGAMENTO
INSERT INTO PAGAMENTO (id_reserva, id_cliente, valor, forma_pagamento) VALUES
(87, 77, 456.34, 'dinheiro'),
(9, 43, 702.86, 'transferencia'),
(37, 33, 4383.84, 'pix'),
(43, 11, 3559.03, 'pix'),
(45, 40, 5811.02, 'transferencia'),
(17, 77, 4296.68, 'cartao'),
(40, 72, 2353.57, 'dinheiro'),
(17, 86, 4261.56, 'cartao'),
(83, 86, 2626.93, 'dinheiro'),
(3, 47, 1956.87, 'pix'),
(44, 99, 2994.68, 'pix'),
(18, 20, 601.42, 'cartao'),
(65, 99, 3307.66, 'cartao'),
(85, 44, 5276.9, 'pix'),
(77, 49, 1052.38, 'pix'),
(89, 99, 3804.73, 'pix'),
(93, 57, 405.6, 'dinheiro'),
(87, 93, 1539.55, 'transferencia'),
(79, 37, 4551.49, 'transferencia'),
(30, 69, 1549.14, 'transferencia'),
(25, 48, 4118.09, 'transferencia'),
(60, 99, 1798.36, 'transferencia'),
(65, 68, 2599.17, 'pix'),
(26, 78, 959.63, 'dinheiro'),
(7, 83, 2961.46, 'dinheiro'),
(71, 14, 4311.7, 'cartao'),
(37, 11, 4614.23, 'dinheiro'),
(58, 66, 1011.99, 'transferencia'),
(12, 29, 4927.71, 'dinheiro'),
(4, 54, 461.55, 'dinheiro'),
(31, 50, 5967.97, 'dinheiro'),
(29, 4, 2014.31, 'cartao'),
(92, 84, 2111.45, 'pix'),
(18, 5, 1828.24, 'transferencia'),
(90, 18, 4589.22, 'transferencia'),
(58, 79, 180.72, 'cartao'),
(3, 33, 1411.58, 'pix'),
(71, 94, 3711.95, 'transferencia'),
(15, 100, 1835.39, 'dinheiro'),
(16, 7, 1544.87, 'transferencia'),
(9, 15, 5044.62, 'transferencia'),
(77, 69, 246.15, 'pix'),
(92, 19, 1853.94, 'cartao'),
(79, 46, 1557.3, 'transferencia'),
(24, 86, 4059.06, 'dinheiro'),
(9, 68, 3332.88, 'cartao'),
(50, 61, 404.68, 'transferencia'),
(48, 33, 4521.8, 'dinheiro'),
(9, 45, 1560.59, 'cartao'),
(99, 75, 4450.84, 'dinheiro'),
(18, 6, 2210.95, 'dinheiro'),
(83, 23, 5007.74, 'transferencia'),
(90, 62, 3845.65, 'pix'),
(9, 92, 4690.71, 'transferencia'),
(5, 38, 1329.31, 'pix'),
(6, 41, 5610.22, 'transferencia'),
(70, 61, 1631.89, 'pix'),
(37, 46, 5193.51, 'cartao'),
(84, 43, 1748.32, 'dinheiro'),
(56, 52, 4498.35, 'transferencia'),
(44, 24, 3052.79, 'transferencia'),
(48, 67, 1710.32, 'cartao'),
(94, 55, 611.72, 'pix'),
(70, 38, 2029.09, 'cartao'),
(42, 85, 1879.49, 'transferencia'),
(78, 92, 2642.78, 'transferencia'),
(45, 58, 397.78, 'dinheiro'),
(79, 56, 1756.15, 'cartao'),
(10, 86, 3879.45, 'dinheiro'),
(66, 96, 4124.55, 'cartao'),
(19, 78, 4116.82, 'transferencia'),
(5, 17, 543.32, 'dinheiro'),
(47, 50, 5704.38, 'cartao'),
(78, 20, 4122.51, 'dinheiro'),
(48, 57, 4614.04, 'pix'),
(68, 47, 2478.5, 'dinheiro'),
(32, 15, 301.59, 'pix'),
(64, 67, 2413.88, 'cartao'),
(34, 100, 1672.7, 'transferencia'),
(28, 79, 1820.62, 'transferencia'),
(26, 16, 944.01, 'cartao'),
(58, 23, 5407.27, 'transferencia'),
(12, 88, 5810.23, 'dinheiro'),
(86, 45, 4300.81, 'dinheiro'),
(39, 21, 4314.08, 'pix'),
(47, 66, 1461.81, 'pix'),
(18, 31, 4773.68, 'cartao'),
(47, 71, 3497.82, 'transferencia'),
(71, 17, 3729.9, 'cartao'),
(9, 40, 2479.24, 'transferencia'),
(68, 53, 4649.61, 'cartao'),
(17, 41, 3907.68, 'transferencia'),
(60, 88, 3176.56, 'pix'),
(100, 71, 3892.79, 'pix'),
(99, 17, 2680.82, 'cartao'),
(16, 67, 1045.14, 'pix'),
(21, 42, 5618.22, 'pix'),
(45, 67, 5385.32, 'cartao'),
(33, 26, 3865.08, 'dinheiro'),
(17, 81, 1921.52, 'cartao');

-- LIMPEZA
INSERT INTO LIMPEZA (id_quarto, id_funcionario, data, status, observacoes) VALUES
(65, 83, '2026-05-30', 'pendente', NULL),
(75, 20, '2026-07-08', 'pendente', NULL),
(80, 93, '2025-10-06', 'em andamento', 'Reposicao de amenities'),
(73, 6, '2025-12-13', 'pendente', 'Troca de roupa de cama extra'),
(6, 83, '2026-02-03', 'em andamento', 'Reposicao de amenities'),
(84, 27, '2026-06-26', 'em andamento', 'Limpeza profunda solicitada'),
(80, 82, '2025-12-02', 'pendente', 'Limpeza profunda solicitada'),
(81, 70, '2025-12-08', 'concluida', NULL),
(39, 62, '2026-05-19', 'pendente', NULL),
(88, 52, '2025-09-15', 'concluida', 'Limpeza profunda solicitada'),
(10, 89, '2026-08-05', 'pendente', 'Manutencao pendente no ar-condicionado'),
(57, 54, '2026-02-15', 'concluida', 'Limpeza profunda solicitada'),
(27, 44, '2026-08-09', 'em andamento', 'Manutencao pendente no ar-condicionado'),
(41, 92, '2025-10-25', 'concluida', NULL),
(45, 52, '2025-08-24', 'pendente', NULL),
(48, 66, '2025-12-30', 'em andamento', 'Troca de roupa de cama extra'),
(41, 31, '2026-06-23', 'concluida', 'Troca de roupa de cama extra'),
(35, 58, '2025-09-22', 'pendente', 'Manutencao pendente no ar-condicionado'),
(13, 7, '2025-12-02', 'concluida', 'Limpeza profunda solicitada'),
(79, 54, '2025-08-27', 'pendente', NULL),
(21, 42, '2026-06-17', 'em andamento', NULL),
(41, 25, '2026-06-26', 'pendente', 'Limpeza profunda solicitada'),
(66, 60, '2025-12-10', 'concluida', 'Reposicao de amenities'),
(64, 3, '2026-07-02', 'pendente', 'Limpeza profunda solicitada'),
(65, 59, '2025-09-17', 'pendente', 'Manutencao pendente no ar-condicionado'),
(75, 46, '2026-05-18', 'pendente', 'Troca de roupa de cama extra'),
(37, 64, '2026-05-10', 'em andamento', NULL),
(84, 87, '2025-08-19', 'concluida', 'Reposicao de amenities'),
(69, 2, '2026-05-15', 'pendente', 'Limpeza profunda solicitada'),
(18, 34, '2026-04-01', 'em andamento', 'Reposicao de amenities'),
(98, 52, '2025-10-26', 'concluida', 'Troca de roupa de cama extra'),
(52, 7, '2025-10-23', 'em andamento', NULL),
(25, 47, '2025-11-23', 'em andamento', 'Reposicao de amenities'),
(10, 50, '2026-02-21', 'em andamento', 'Limpeza profunda solicitada'),
(98, 71, '2026-05-20', 'concluida', NULL),
(80, 88, '2026-04-13', 'em andamento', 'Troca de roupa de cama extra'),
(17, 13, '2025-11-18', 'concluida', 'Reposicao de amenities'),
(44, 72, '2025-10-07', 'concluida', NULL),
(19, 26, '2025-09-21', 'em andamento', NULL),
(52, 65, '2026-07-27', 'pendente', 'Troca de roupa de cama extra'),
(5, 18, '2026-03-03', 'em andamento', 'Reposicao de amenities'),
(61, 67, '2025-09-17', 'concluida', 'Manutencao pendente no ar-condicionado'),
(78, 66, '2026-02-25', 'pendente', 'Reposicao de amenities'),
(79, 41, '2026-02-28', 'pendente', 'Limpeza profunda solicitada'),
(79, 95, '2025-11-18', 'concluida', NULL),
(44, 65, '2026-07-22', 'em andamento', NULL),
(63, 91, '2026-06-01', 'em andamento', 'Reposicao de amenities'),
(61, 3, '2026-03-09', 'concluida', 'Reposicao de amenities'),
(87, 15, '2025-10-12', 'concluida', NULL),
(40, 93, '2025-12-02', 'em andamento', NULL),
(4, 77, '2026-07-03', 'concluida', 'Reposicao de amenities'),
(84, 100, '2026-02-24', 'em andamento', NULL),
(30, 93, '2025-08-29', 'pendente', NULL),
(62, 22, '2025-08-21', 'em andamento', NULL),
(93, 80, '2026-07-07', 'concluida', 'Manutencao pendente no ar-condicionado'),
(88, 32, '2025-08-29', 'pendente', NULL),
(90, 15, '2025-12-29', 'pendente', 'Troca de roupa de cama extra'),
(57, 41, '2025-09-11', 'concluida', 'Manutencao pendente no ar-condicionado'),
(53, 89, '2026-01-01', 'pendente', 'Limpeza profunda solicitada'),
(65, 100, '2026-04-25', 'em andamento', 'Limpeza profunda solicitada'),
(95, 94, '2026-07-03', 'pendente', NULL),
(18, 67, '2026-03-29', 'pendente', NULL),
(42, 85, '2026-04-20', 'concluida', NULL),
(49, 41, '2026-01-21', 'pendente', 'Limpeza profunda solicitada'),
(69, 44, '2025-12-19', 'em andamento', 'Reposicao de amenities'),
(87, 99, '2025-12-10', 'em andamento', NULL),
(83, 89, '2025-10-22', 'concluida', NULL),
(62, 25, '2026-05-15', 'pendente', 'Reposicao de amenities'),
(72, 39, '2026-06-03', 'pendente', 'Reposicao de amenities'),
(99, 37, '2025-09-08', 'em andamento', 'Manutencao pendente no ar-condicionado'),
(89, 91, '2026-07-14', 'concluida', 'Reposicao de amenities'),
(62, 45, '2026-05-17', 'em andamento', NULL),
(93, 36, '2026-03-06', 'concluida', 'Troca de roupa de cama extra'),
(74, 87, '2025-09-14', 'em andamento', 'Limpeza profunda solicitada'),
(51, 45, '2026-05-31', 'pendente', 'Reposicao de amenities'),
(6, 37, '2026-04-23', 'em andamento', 'Troca de roupa de cama extra'),
(45, 57, '2025-09-15', 'em andamento', 'Reposicao de amenities'),
(96, 62, '2025-12-02', 'pendente', 'Manutencao pendente no ar-condicionado'),
(69, 35, '2026-04-03', 'em andamento', NULL),
(35, 18, '2026-05-18', 'pendente', NULL),
(95, 76, '2026-01-30', 'pendente', 'Manutencao pendente no ar-condicionado'),
(7, 86, '2026-07-23', 'em andamento', 'Manutencao pendente no ar-condicionado'),
(82, 30, '2025-10-02', 'pendente', 'Troca de roupa de cama extra'),
(53, 43, '2026-07-04', 'em andamento', 'Limpeza profunda solicitada'),
(13, 88, '2025-11-13', 'pendente', 'Troca de roupa de cama extra'),
(71, 21, '2025-12-22', 'concluida', NULL),
(61, 62, '2025-10-17', 'em andamento', 'Manutencao pendente no ar-condicionado'),
(97, 37, '2026-07-12', 'concluida', 'Reposicao de amenities'),
(83, 8, '2025-12-09', 'pendente', NULL),
(74, 30, '2026-06-22', 'em andamento', NULL),
(93, 5, '2025-12-07', 'pendente', 'Limpeza profunda solicitada'),
(23, 5, '2026-02-05', 'concluida', NULL),
(64, 24, '2025-09-03', 'em andamento', NULL),
(38, 5, '2025-09-21', 'pendente', 'Reposicao de amenities'),
(73, 78, '2026-02-02', 'pendente', 'Reposicao de amenities'),
(37, 59, '2026-06-16', 'em andamento', NULL),
(68, 64, '2025-11-22', 'pendente', NULL),
(65, 60, '2025-12-16', 'concluida', 'Manutencao pendente no ar-condicionado'),
(15, 43, '2026-03-09', 'pendente', NULL),
(59, 83, '2026-02-12', 'concluida', NULL);