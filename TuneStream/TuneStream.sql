CREATE DATABASE tunestream
	DEFAULT CHARACTER SET utf8mb4
    DEFAULT COLLATE utf8mb4_unicode_ci;
USE tunestream;

CREATE TABLE USUARIOS (
    IDusuario INT AUTO_INCREMENT PRIMARY KEY,
    Nome VARCHAR(255) NOT NULL,
    Email VARCHAR(255) UNIQUE NOT NULL,
    DataCadastro DATE NOT NULL,
    TipoConta ENUM('Free', 'Premium') NOT NULL,
    StatusConta ENUM('Ativo', 'Inativo', 'Suspenso') NOT NULL
);

CREATE TABLE ARTISTAS (
    IDartista INT AUTO_INCREMENT PRIMARY KEY,
    NomeArtistico VARCHAR(255) NOT NULL,
    Biografia TEXT,
    PaisOrigem VARCHAR(100),
    TaxaRoyalty FLOAT NOT NULL
);


CREATE TABLE PLAYLISTS (
    IDplaylist INT AUTO_INCREMENT PRIMARY KEY,
    IDusuario INT NOT NULL,
    NomePlaylist VARCHAR(255) NOT NULL,
    DataCriacao DATE NOT NULL,
    E_Publica BOOLEAN NOT NULL,
    FOREIGN KEY (IDusuario) REFERENCES USUARIOS(IDusuario)
);

CREATE TABLE ALBUNS (
    IDalbum INT AUTO_INCREMENT PRIMARY KEY,
    IDartista INT NOT NULL,
    Titulo VARCHAR(255) NOT NULL,
    DataLancamento DATE NOT NULL,
    TipoMidia ENUM('Album', 'Single', 'EP', 'Podcast') NOT NULL,
    FOREIGN KEY (IDartista) REFERENCES ARTISTAS(IDartista)
);

CREATE TABLE ROYALTIES (
    IDroyalty INT AUTO_INCREMENT PRIMARY KEY,
    IDartista INT NOT NULL,
    PeriodoMesAno VARCHAR(7) NOT NULL, 
    TotalReproducoes INT NOT NULL DEFAULT 0,
    ValorTotalPago FLOAT NOT NULL DEFAULT 0.0,
    StatusPagamento ENUM('Pendente', 'Pago') NOT NULL,
    FOREIGN KEY (IDartista) REFERENCES ARTISTAS(IDartista)
);


CREATE TABLE FAIXAS (
    IDfaixa INT AUTO_INCREMENT PRIMARY KEY,
    IDalbum INT NOT NULL,
    TituloFaixa VARCHAR(255) NOT NULL,
    Duracao VARCHAR(10) NOT NULL,
    ArquivoURL VARCHAR(512) NOT NULL,
    FOREIGN KEY (IDalbum) REFERENCES ALBUNS(IDalbum)
);

CREATE TABLE PLAYLIST_FAIXAS (
    IDplaylist INT NOT NULL,
    IDfaixa INT NOT NULL,
    DataAdicao DATE NOT NULL,
    PRIMARY KEY (IDplaylist, IDfaixa),
    FOREIGN KEY (IDplaylist) REFERENCES PLAYLISTS(IDplaylist),
    FOREIGN KEY (IDfaixa) REFERENCES FAIXAS(IDfaixa)
);

CREATE TABLE HISTORICO (
    IDhistorico INT AUTO_INCREMENT PRIMARY KEY,
    IDusuario INT NOT NULL,
    IDfaixa INT NOT NULL,
    DataHoraReproducao DATETIME NOT NULL,
    FOREIGN KEY (IDusuario) REFERENCES USUARIOS(IDusuario),
    FOREIGN KEY (IDfaixa) REFERENCES FAIXAS(IDfaixa)
);
ALTER TABLE USUARIOS
ADD COLUMN SenhaHash VARCHAR(255) NOT NULL DEFAULT '';

ALTER TABLE ARTISTAS
ADD COLUMN Verificado BOOLEAN NOT NULL DEFAULT FALSE;

ALTER TABLE PLAYLISTS
ADD COLUMN Descricao TEXT;

ALTER TABLE ALBUNS
ADD COLUMN CapaURL VARCHAR(512);

ALTER TABLE ROYALTIES
ADD COLUMN DataPagamento DATE;

ALTER TABLE FAIXAS
ADD COLUMN Genero VARCHAR(100);

ALTER TABLE PLAYLIST_FAIXAS
ADD COLUMN Ordem INT NOT NULL DEFAULT 1;

ALTER TABLE HISTORICO
ADD COLUMN DispositivoReproducao VARCHAR(50);

-- Store Procedure da Tabela USUARIOS
-- Cadastra um usuário, impedindo e-mail duplicado
DELIMITER //
CREATE PROCEDURE sp_CadastrarUsuario(
    IN p_Nome VARCHAR(255),
    IN p_Email VARCHAR(255),
    IN p_DataCadastro DATE,
    IN p_TipoConta ENUM('Free','Premium'),
    IN p_StatusConta ENUM('Ativo','Inativo','Suspenso'),
    IN p_SenhaHash VARCHAR(255),
    OUT p_Resultado VARCHAR(100))
BEGIN
    DECLARE v_existe INT;
 
    SELECT COUNT(*) INTO v_existe
    FROM usuarios
    WHERE Email = p_Email;
 
    IF v_existe > 0 THEN
        SET p_Resultado = 'Email já cadastrado';
    ELSE
        INSERT INTO usuarios (Nome, Email, DataCadastro, TipoConta, StatusConta, SenhaHash)
        VALUES (p_Nome, p_Email, p_DataCadastro, p_TipoConta, p_StatusConta, p_SenhaHash);
        SET p_Resultado = 'Usuário cadastrado com sucesso';
    END IF;
END //
DELIMITER ;

-- Store Procedure da Tabela ARTISTAS
-- Cadastra um artista, validando a faixa da taxa de royalty (0 a 100)
DELIMITER //
CREATE PROCEDURE sp_CadastrarArtista(
    IN p_NomeArtistico VARCHAR(255),
    IN p_Biografia TEXT,
    IN p_PaisOrigem VARCHAR(100),
    IN p_TaxaRoyalty FLOAT,
    OUT p_Resultado VARCHAR(100))
BEGIN
    IF p_TaxaRoyalty < 0 OR p_TaxaRoyalty > 100 THEN
        SET p_Resultado = 'Taxa de royalty inválida (deve estar entre 0 e 100)';
    ELSE
        INSERT INTO artistas (NomeArtistico, Biografia, PaisOrigem, TaxaRoyalty)
        VALUES (p_NomeArtistico, p_Biografia, p_PaisOrigem, p_TaxaRoyalty);
        SET p_Resultado = 'Artista cadastrado com sucesso';
    END IF;
END //
DELIMITER ;

-- Store Procedure da Tabela PLAYLISTS
-- Cria uma playlist somente se o usuário existir e estiver com a conta ativa
DELIMITER //
CREATE PROCEDURE sp_CriarPlaylist(
    IN p_IDusuario INT,
    IN p_NomePlaylist VARCHAR(255),
    IN p_DataCriacao DATE,
    IN p_E_Publica BOOLEAN,
    IN p_Descricao TEXT,
    OUT p_Resultado VARCHAR(100))
BEGIN
    DECLARE v_StatusConta VARCHAR(20);
 
    SELECT StatusConta INTO v_StatusConta
    FROM usuarios
    WHERE IDusuario = p_IDusuario;
 
    IF v_StatusConta IS NULL THEN
        SET p_Resultado = 'Usuário não encontrado';
    ELSEIF v_StatusConta <> 'Ativo' THEN
        SET p_Resultado = 'Usuário não está com a conta ativa';
    ELSE
        INSERT INTO playlists (IDusuario, NomePlaylist, DataCriacao, E_Publica, Descricao)
        VALUES (p_IDusuario, p_NomePlaylist, p_DataCriacao, p_E_Publica, p_Descricao);
        SET p_Resultado = 'Playlist criada com sucesso';
    END IF;
END //
DELIMITER ;

-- Store Procedure da Tabela ALBUNS
-- Cadastra um álbum somente se o artista existir
DELIMITER //
CREATE PROCEDURE sp_CadastrarAlbum(
    IN p_IDartista INT,
    IN p_Titulo VARCHAR(255),
    IN p_DataLancamento DATE,
    IN p_TipoMidia ENUM('Album','Single','EP','Podcast'),
    IN p_CapaURL VARCHAR(512),
    OUT p_Resultado VARCHAR(100))
BEGIN
    DECLARE v_ArtistaExiste INT;
 
    SELECT COUNT(*) INTO v_ArtistaExiste
    FROM artistas
    WHERE IDartista = p_IDartista;
 
    IF v_ArtistaExiste = 0 THEN
        SET p_Resultado = 'Artista não encontrado';
    ELSE
        INSERT INTO albuns (IDartista, Titulo, DataLancamento, TipoMidia, CapaURL)
        VALUES (p_IDartista, p_Titulo, p_DataLancamento, p_TipoMidia, p_CapaURL);
        SET p_Resultado = 'Álbum cadastrado com sucesso';
    END IF;
END //
DELIMITER ;

-- Store Procedure da Tabela ROYALTIES
-- Gera o registro de royalty do período calculando o valor
-- automaticamente (TotalReproducoes x TaxaRoyalty do artista)
DELIMITER //
CREATE PROCEDURE sp_GerarRoyalty(
    IN p_IDartista INT,
    IN p_PeriodoMesAno VARCHAR(7),
    IN p_TotalReproducoes INT,
    OUT p_Resultado VARCHAR(100))
BEGIN
    DECLARE v_TaxaRoyalty FLOAT;
    DECLARE v_JaExiste INT;
    DECLARE v_ValorTotal FLOAT;
 
    SELECT TaxaRoyalty INTO v_TaxaRoyalty
    FROM artistas
    WHERE IDartista = p_IDartista;
 
    SELECT COUNT(*) INTO v_JaExiste
    FROM royalties
    WHERE IDartista = p_IDartista AND PeriodoMesAno = p_PeriodoMesAno;
 
    IF v_TaxaRoyalty IS NULL THEN
        SET p_Resultado = 'Artista não encontrado';
    ELSEIF v_JaExiste > 0 THEN
        SET p_Resultado = 'Já existe registro de royalty para este período';
    ELSE
        SET v_ValorTotal = p_TotalReproducoes * v_TaxaRoyalty;
 
        INSERT INTO royalties (IDartista, PeriodoMesAno, TotalReproducoes, ValorTotalPago, StatusPagamento)
        VALUES (p_IDartista, p_PeriodoMesAno, p_TotalReproducoes, v_ValorTotal, 'Pendente');
 
        SET p_Resultado = CONCAT('Royalty gerado no valor de ', v_ValorTotal);
    END IF;
END //
DELIMITER ;

-- Store Procedure da Tabela FAIXAS
-- Cadastra uma faixa somente se o álbum existir
DELIMITER //
CREATE PROCEDURE sp_CadastrarFaixa(
    IN p_IDalbum INT,
    IN p_TituloFaixa VARCHAR(255),
    IN p_Duracao VARCHAR(10),
    IN p_ArquivoURL VARCHAR(512),
    IN p_Genero VARCHAR(100),
    OUT p_Resultado VARCHAR(100))
BEGIN
    DECLARE v_AlbumExiste INT;
 
    SELECT COUNT(*) INTO v_AlbumExiste
    FROM albuns
    WHERE IDalbum = p_IDalbum;
 
    IF v_AlbumExiste = 0 THEN
        SET p_Resultado = 'Álbum não encontrado';
    ELSE
        INSERT INTO faixas (IDalbum, TituloFaixa, Duracao, ArquivoURL, Genero)
        VALUES (p_IDalbum, p_TituloFaixa, p_Duracao, p_ArquivoURL, p_Genero);
        SET p_Resultado = 'Faixa cadastrada com sucesso';
    END IF;
END //
DELIMITER ;

-- Store Procedure da Tabela PLAYLIST_FAIXAS
-- Adiciona uma faixa a uma playlist, evitando duplicidade e
-- calculando automaticamente a próxima posição (Ordem)
DELIMITER //
CREATE PROCEDURE sp_AdicionarFaixaPlaylist(
    IN p_IDplaylist INT,
    IN p_IDfaixa INT,
    OUT p_Resultado VARCHAR(100))
BEGIN
    DECLARE v_PlaylistExiste INT;
    DECLARE v_FaixaExiste INT;
    DECLARE v_JaAdicionada INT;
    DECLARE v_ProximaOrdem INT;
 
    SELECT COUNT(*) INTO v_PlaylistExiste FROM playlists WHERE IDplaylist = p_IDplaylist;
    SELECT COUNT(*) INTO v_FaixaExiste FROM faixas WHERE IDfaixa = p_IDfaixa;
    SELECT COUNT(*) INTO v_JaAdicionada
    FROM playlist_faixas
    WHERE IDplaylist = p_IDplaylist AND IDfaixa = p_IDfaixa;
 
    IF v_PlaylistExiste = 0 THEN
        SET p_Resultado = 'Playlist não encontrada';
    ELSEIF v_FaixaExiste = 0 THEN
        SET p_Resultado = 'Faixa não encontrada';
    ELSEIF v_JaAdicionada > 0 THEN
        SET p_Resultado = 'Faixa já está na playlist';
    ELSE
        SELECT IFNULL(MAX(Ordem), 0) + 1 INTO v_ProximaOrdem
        FROM playlist_faixas
        WHERE IDplaylist = p_IDplaylist;
 
        INSERT INTO playlist_faixas (IDplaylist, IDfaixa, DataAdicao, Ordem)
        VALUES (p_IDplaylist, p_IDfaixa, CURDATE(), v_ProximaOrdem);
 
        SET p_Resultado = 'Faixa adicionada à playlist com sucesso';
    END IF;
END //
DELIMITER ;

-- Store Procedure da Tabela HISTORICO
-- Registra uma reprodução, bloqueando usuários suspensos
DELIMITER //
CREATE PROCEDURE sp_RegistrarReproducao(
    IN p_IDusuario INT,
    IN p_IDfaixa INT,
    IN p_DispositivoReproducao VARCHAR(50),
    OUT p_Resultado VARCHAR(100))
BEGIN
    DECLARE v_StatusConta VARCHAR(20);
    DECLARE v_FaixaExiste INT;
 
    SELECT StatusConta INTO v_StatusConta
    FROM usuarios
    WHERE IDusuario = p_IDusuario;
 
    SELECT COUNT(*) INTO v_FaixaExiste
    FROM faixas
    WHERE IDfaixa = p_IDfaixa;
 
    IF v_StatusConta IS NULL THEN
        SET p_Resultado = 'Usuário não encontrado';
    ELSEIF v_StatusConta = 'Suspenso' THEN
        SET p_Resultado = 'Usuário suspenso, reprodução não permitida';
    ELSEIF v_FaixaExiste = 0 THEN
        SET p_Resultado = 'Faixa não encontrada';
    ELSE
        INSERT INTO historico (IDusuario, IDfaixa, DataHoraReproducao, DispositivoReproducao)
        VALUES (p_IDusuario, p_IDfaixa, NOW(), p_DispositivoReproducao);
        SET p_Resultado = 'Reprodução registrada com sucesso';
    END IF;
END //
DELIMITER ;

-- ---------------- USUARIOS ----------------
INSERT INTO USUARIOS (IDusuario, Nome, Email, DataCadastro, TipoConta, StatusConta, SenhaHash) VALUES (1, 'Patrícia Pereira', 'user1@tunestream.com', '2024-02-09', 'Premium', 'Ativo', '$2b$12$hash000001fakehashvalueexample');
INSERT INTO USUARIOS (IDusuario, Nome, Email, DataCadastro, TipoConta, StatusConta, SenhaHash) VALUES (2, 'Thiago Santos', 'user2@tunestream.com', '2024-01-10', 'Free', 'Inativo', '$2b$12$hash000002fakehashvalueexample');
INSERT INTO USUARIOS (IDusuario, Nome, Email, DataCadastro, TipoConta, StatusConta, SenhaHash) VALUES (3, 'Fernanda Souza', 'user3@tunestream.com', '2023-03-30', 'Free', 'Ativo', '$2b$12$hash000003fakehashvalueexample');
INSERT INTO USUARIOS (IDusuario, Nome, Email, DataCadastro, TipoConta, StatusConta, SenhaHash) VALUES (4, 'Mariana Barbosa', 'user4@tunestream.com', '2024-03-10', 'Free', 'Ativo', '$2b$12$hash000004fakehashvalueexample');
INSERT INTO USUARIOS (IDusuario, Nome, Email, DataCadastro, TipoConta, StatusConta, SenhaHash) VALUES (5, 'Lucas Cardoso', 'user5@tunestream.com', '2023-03-05', 'Free', 'Ativo', '$2b$12$hash000005fakehashvalueexample');
INSERT INTO USUARIOS (IDusuario, Nome, Email, DataCadastro, TipoConta, StatusConta, SenhaHash) VALUES (6, 'Lucas Souza', 'user6@tunestream.com', '2024-07-24', 'Premium', 'Ativo', '$2b$12$hash000006fakehashvalueexample');
INSERT INTO USUARIOS (IDusuario, Nome, Email, DataCadastro, TipoConta, StatusConta, SenhaHash) VALUES (7, 'Beatriz Barbosa', 'user7@tunestream.com', '2023-05-01', 'Free', 'Ativo', '$2b$12$hash000007fakehashvalueexample');
INSERT INTO USUARIOS (IDusuario, Nome, Email, DataCadastro, TipoConta, StatusConta, SenhaHash) VALUES (8, 'André Costa', 'user8@tunestream.com', '2023-04-16', 'Free', 'Ativo', '$2b$12$hash000008fakehashvalueexample');
INSERT INTO USUARIOS (IDusuario, Nome, Email, DataCadastro, TipoConta, StatusConta, SenhaHash) VALUES (9, 'Eduardo Santos', 'user9@tunestream.com', '2024-07-14', 'Premium', 'Ativo', '$2b$12$hash000009fakehashvalueexample');
INSERT INTO USUARIOS (IDusuario, Nome, Email, DataCadastro, TipoConta, StatusConta, SenhaHash) VALUES (10, 'Bruno Ferreira', 'user10@tunestream.com', '2024-05-23', 'Premium', 'Ativo', '$2b$12$hash000010fakehashvalueexample');
INSERT INTO USUARIOS (IDusuario, Nome, Email, DataCadastro, TipoConta, StatusConta, SenhaHash) VALUES (11, 'Patrícia Gomes', 'user11@tunestream.com', '2024-08-22', 'Premium', 'Ativo', '$2b$12$hash000011fakehashvalueexample');
INSERT INTO USUARIOS (IDusuario, Nome, Email, DataCadastro, TipoConta, StatusConta, SenhaHash) VALUES (12, 'Lucas Costa', 'user12@tunestream.com', '2024-12-16', 'Premium', 'Ativo', '$2b$12$hash000012fakehashvalueexample');
INSERT INTO USUARIOS (IDusuario, Nome, Email, DataCadastro, TipoConta, StatusConta, SenhaHash) VALUES (13, 'Rodrigo Rocha', 'user13@tunestream.com', '2024-05-21', 'Premium', 'Ativo', '$2b$12$hash000013fakehashvalueexample');
INSERT INTO USUARIOS (IDusuario, Nome, Email, DataCadastro, TipoConta, StatusConta, SenhaHash) VALUES (14, 'Rodrigo Teixeira', 'user14@tunestream.com', '2023-03-16', 'Free', 'Ativo', '$2b$12$hash000014fakehashvalueexample');
INSERT INTO USUARIOS (IDusuario, Nome, Email, DataCadastro, TipoConta, StatusConta, SenhaHash) VALUES (15, 'Aline Lima', 'user15@tunestream.com', '2023-06-05', 'Premium', 'Ativo', '$2b$12$hash000015fakehashvalueexample');
INSERT INTO USUARIOS (IDusuario, Nome, Email, DataCadastro, TipoConta, StatusConta, SenhaHash) VALUES (16, 'André Oliveira', 'user16@tunestream.com', '2025-02-21', 'Free', 'Ativo', '$2b$12$hash000016fakehashvalueexample');
INSERT INTO USUARIOS (IDusuario, Nome, Email, DataCadastro, TipoConta, StatusConta, SenhaHash) VALUES (17, 'Tatiane Lima', 'user17@tunestream.com', '2023-12-15', 'Premium', 'Ativo', '$2b$12$hash000017fakehashvalueexample');
INSERT INTO USUARIOS (IDusuario, Nome, Email, DataCadastro, TipoConta, StatusConta, SenhaHash) VALUES (18, 'Renata Gomes', 'user18@tunestream.com', '2023-03-12', 'Premium', 'Inativo', '$2b$12$hash000018fakehashvalueexample');
INSERT INTO USUARIOS (IDusuario, Nome, Email, DataCadastro, TipoConta, StatusConta, SenhaHash) VALUES (19, 'Felipe Oliveira', 'user19@tunestream.com', '2023-03-04', 'Premium', 'Ativo', '$2b$12$hash000019fakehashvalueexample');
INSERT INTO USUARIOS (IDusuario, Nome, Email, DataCadastro, TipoConta, StatusConta, SenhaHash) VALUES (20, 'Renata Gomes', 'user20@tunestream.com', '2023-10-19', 'Premium', 'Inativo', '$2b$12$hash000020fakehashvalueexample');
INSERT INTO USUARIOS (IDusuario, Nome, Email, DataCadastro, TipoConta, StatusConta, SenhaHash) VALUES (21, 'Eduardo Silva', 'user21@tunestream.com', '2024-04-17', 'Free', 'Ativo', '$2b$12$hash000021fakehashvalueexample');
INSERT INTO USUARIOS (IDusuario, Nome, Email, DataCadastro, TipoConta, StatusConta, SenhaHash) VALUES (22, 'Felipe Souza', 'user22@tunestream.com', '2023-08-12', 'Premium', 'Ativo', '$2b$12$hash000022fakehashvalueexample');
INSERT INTO USUARIOS (IDusuario, Nome, Email, DataCadastro, TipoConta, StatusConta, SenhaHash) VALUES (23, 'Lucas Ribeiro', 'user23@tunestream.com', '2024-02-05', 'Premium', 'Ativo', '$2b$12$hash000023fakehashvalueexample');
INSERT INTO USUARIOS (IDusuario, Nome, Email, DataCadastro, TipoConta, StatusConta, SenhaHash) VALUES (24, 'Rafael Gomes', 'user24@tunestream.com', '2024-02-16', 'Free', 'Inativo', '$2b$12$hash000024fakehashvalueexample');
INSERT INTO USUARIOS (IDusuario, Nome, Email, DataCadastro, TipoConta, StatusConta, SenhaHash) VALUES (25, 'Tatiane Carvalho', 'user25@tunestream.com', '2025-06-03', 'Free', 'Ativo', '$2b$12$hash000025fakehashvalueexample');
INSERT INTO USUARIOS (IDusuario, Nome, Email, DataCadastro, TipoConta, StatusConta, SenhaHash) VALUES (26, 'Eduardo Ribeiro', 'user26@tunestream.com', '2023-08-25', 'Free', 'Ativo', '$2b$12$hash000026fakehashvalueexample');
INSERT INTO USUARIOS (IDusuario, Nome, Email, DataCadastro, TipoConta, StatusConta, SenhaHash) VALUES (27, 'Lucas Rodrigues', 'user27@tunestream.com', '2023-01-13', 'Free', 'Ativo', '$2b$12$hash000027fakehashvalueexample');
INSERT INTO USUARIOS (IDusuario, Nome, Email, DataCadastro, TipoConta, StatusConta, SenhaHash) VALUES (28, 'Camila Nascimento', 'user28@tunestream.com', '2023-01-05', 'Free', 'Ativo', '$2b$12$hash000028fakehashvalueexample');
INSERT INTO USUARIOS (IDusuario, Nome, Email, DataCadastro, TipoConta, StatusConta, SenhaHash) VALUES (29, 'Bruno Cardoso', 'user29@tunestream.com', '2023-11-23', 'Premium', 'Ativo', '$2b$12$hash000029fakehashvalueexample');
INSERT INTO USUARIOS (IDusuario, Nome, Email, DataCadastro, TipoConta, StatusConta, SenhaHash) VALUES (30, 'Vanessa Teixeira', 'user30@tunestream.com', '2024-11-01', 'Premium', 'Ativo', '$2b$12$hash000030fakehashvalueexample');
INSERT INTO USUARIOS (IDusuario, Nome, Email, DataCadastro, TipoConta, StatusConta, SenhaHash) VALUES (31, 'Simone Barbosa', 'user31@tunestream.com', '2024-02-06', 'Free', 'Ativo', '$2b$12$hash000031fakehashvalueexample');
INSERT INTO USUARIOS (IDusuario, Nome, Email, DataCadastro, TipoConta, StatusConta, SenhaHash) VALUES (32, 'Felipe Ribeiro', 'user32@tunestream.com', '2023-03-05', 'Free', 'Suspenso', '$2b$12$hash000032fakehashvalueexample');
INSERT INTO USUARIOS (IDusuario, Nome, Email, DataCadastro, TipoConta, StatusConta, SenhaHash) VALUES (33, 'Larissa Costa', 'user33@tunestream.com', '2023-04-23', 'Free', 'Ativo', '$2b$12$hash000033fakehashvalueexample');
INSERT INTO USUARIOS (IDusuario, Nome, Email, DataCadastro, TipoConta, StatusConta, SenhaHash) VALUES (34, 'Ana Cardoso', 'user34@tunestream.com', '2023-06-04', 'Free', 'Inativo', '$2b$12$hash000034fakehashvalueexample');
INSERT INTO USUARIOS (IDusuario, Nome, Email, DataCadastro, TipoConta, StatusConta, SenhaHash) VALUES (35, 'Bruno Silva', 'user35@tunestream.com', '2023-03-14', 'Premium', 'Ativo', '$2b$12$hash000035fakehashvalueexample');
INSERT INTO USUARIOS (IDusuario, Nome, Email, DataCadastro, TipoConta, StatusConta, SenhaHash) VALUES (36, 'Beatriz Almeida', 'user36@tunestream.com', '2023-12-22', 'Premium', 'Ativo', '$2b$12$hash000036fakehashvalueexample');
INSERT INTO USUARIOS (IDusuario, Nome, Email, DataCadastro, TipoConta, StatusConta, SenhaHash) VALUES (37, 'João Martins', 'user37@tunestream.com', '2024-04-22', 'Free', 'Ativo', '$2b$12$hash000037fakehashvalueexample');
INSERT INTO USUARIOS (IDusuario, Nome, Email, DataCadastro, TipoConta, StatusConta, SenhaHash) VALUES (38, 'Beatriz Santos', 'user38@tunestream.com', '2025-02-06', 'Free', 'Ativo', '$2b$12$hash000038fakehashvalueexample');
INSERT INTO USUARIOS (IDusuario, Nome, Email, DataCadastro, TipoConta, StatusConta, SenhaHash) VALUES (39, 'Tatiane Costa', 'user39@tunestream.com', '2024-06-12', 'Free', 'Suspenso', '$2b$12$hash000039fakehashvalueexample');
INSERT INTO USUARIOS (IDusuario, Nome, Email, DataCadastro, TipoConta, StatusConta, SenhaHash) VALUES (40, 'Vanessa Araújo', 'user40@tunestream.com', '2023-05-31', 'Premium', 'Inativo', '$2b$12$hash000040fakehashvalueexample');
INSERT INTO USUARIOS (IDusuario, Nome, Email, DataCadastro, TipoConta, StatusConta, SenhaHash) VALUES (41, 'Aline Rocha', 'user41@tunestream.com', '2023-11-02', 'Premium', 'Inativo', '$2b$12$hash000041fakehashvalueexample');
INSERT INTO USUARIOS (IDusuario, Nome, Email, DataCadastro, TipoConta, StatusConta, SenhaHash) VALUES (42, 'Priscila Almeida', 'user42@tunestream.com', '2024-06-14', 'Free', 'Ativo', '$2b$12$hash000042fakehashvalueexample');
INSERT INTO USUARIOS (IDusuario, Nome, Email, DataCadastro, TipoConta, StatusConta, SenhaHash) VALUES (43, 'Aline Rodrigues', 'user43@tunestream.com', '2024-06-29', 'Free', 'Ativo', '$2b$12$hash000043fakehashvalueexample');
INSERT INTO USUARIOS (IDusuario, Nome, Email, DataCadastro, TipoConta, StatusConta, SenhaHash) VALUES (44, 'Débora Rodrigues', 'user44@tunestream.com', '2024-09-19', 'Premium', 'Suspenso', '$2b$12$hash000044fakehashvalueexample');
INSERT INTO USUARIOS (IDusuario, Nome, Email, DataCadastro, TipoConta, StatusConta, SenhaHash) VALUES (45, 'Leonardo Ferreira', 'user45@tunestream.com', '2025-04-05', 'Free', 'Ativo', '$2b$12$hash000045fakehashvalueexample');
INSERT INTO USUARIOS (IDusuario, Nome, Email, DataCadastro, TipoConta, StatusConta, SenhaHash) VALUES (46, 'Gustavo Rodrigues', 'user46@tunestream.com', '2023-07-24', 'Free', 'Ativo', '$2b$12$hash000046fakehashvalueexample');
INSERT INTO USUARIOS (IDusuario, Nome, Email, DataCadastro, TipoConta, StatusConta, SenhaHash) VALUES (47, 'Ana Silva', 'user47@tunestream.com', '2025-03-20', 'Free', 'Ativo', '$2b$12$hash000047fakehashvalueexample');
INSERT INTO USUARIOS (IDusuario, Nome, Email, DataCadastro, TipoConta, StatusConta, SenhaHash) VALUES (48, 'Priscila Teixeira', 'user48@tunestream.com', '2023-12-19', 'Free', 'Inativo', '$2b$12$hash000048fakehashvalueexample');
INSERT INTO USUARIOS (IDusuario, Nome, Email, DataCadastro, TipoConta, StatusConta, SenhaHash) VALUES (49, 'Eduardo Araújo', 'user49@tunestream.com', '2023-03-24', 'Free', 'Ativo', '$2b$12$hash000049fakehashvalueexample');
INSERT INTO USUARIOS (IDusuario, Nome, Email, DataCadastro, TipoConta, StatusConta, SenhaHash) VALUES (50, 'Fernanda Lima', 'user50@tunestream.com', '2023-07-29', 'Free', 'Suspenso', '$2b$12$hash000050fakehashvalueexample');
INSERT INTO USUARIOS (IDusuario, Nome, Email, DataCadastro, TipoConta, StatusConta, SenhaHash) VALUES (51, 'Bruno Silva', 'user51@tunestream.com', '2024-05-05', 'Premium', 'Ativo', '$2b$12$hash000051fakehashvalueexample');
INSERT INTO USUARIOS (IDusuario, Nome, Email, DataCadastro, TipoConta, StatusConta, SenhaHash) VALUES (52, 'Débora Oliveira', 'user52@tunestream.com', '2025-05-04', 'Premium', 'Inativo', '$2b$12$hash000052fakehashvalueexample');
INSERT INTO USUARIOS (IDusuario, Nome, Email, DataCadastro, TipoConta, StatusConta, SenhaHash) VALUES (53, 'Gustavo Ferreira', 'user53@tunestream.com', '2024-05-04', 'Premium', 'Ativo', '$2b$12$hash000053fakehashvalueexample');
INSERT INTO USUARIOS (IDusuario, Nome, Email, DataCadastro, TipoConta, StatusConta, SenhaHash) VALUES (54, 'Débora Lima', 'user54@tunestream.com', '2023-03-30', 'Premium', 'Suspenso', '$2b$12$hash000054fakehashvalueexample');
INSERT INTO USUARIOS (IDusuario, Nome, Email, DataCadastro, TipoConta, StatusConta, SenhaHash) VALUES (55, 'Juliana Gomes', 'user55@tunestream.com', '2024-02-16', 'Premium', 'Ativo', '$2b$12$hash000055fakehashvalueexample');
INSERT INTO USUARIOS (IDusuario, Nome, Email, DataCadastro, TipoConta, StatusConta, SenhaHash) VALUES (56, 'Rafael Costa', 'user56@tunestream.com', '2023-05-11', 'Free', 'Ativo', '$2b$12$hash000056fakehashvalueexample');
INSERT INTO USUARIOS (IDusuario, Nome, Email, DataCadastro, TipoConta, StatusConta, SenhaHash) VALUES (57, 'Larissa Pereira', 'user57@tunestream.com', '2024-09-18', 'Premium', 'Suspenso', '$2b$12$hash000057fakehashvalueexample');
INSERT INTO USUARIOS (IDusuario, Nome, Email, DataCadastro, TipoConta, StatusConta, SenhaHash) VALUES (58, 'André Araújo', 'user58@tunestream.com', '2023-06-09', 'Free', 'Ativo', '$2b$12$hash000058fakehashvalueexample');
INSERT INTO USUARIOS (IDusuario, Nome, Email, DataCadastro, TipoConta, StatusConta, SenhaHash) VALUES (59, 'Ana Santos', 'user59@tunestream.com', '2024-06-23', 'Premium', 'Ativo', '$2b$12$hash000059fakehashvalueexample');
INSERT INTO USUARIOS (IDusuario, Nome, Email, DataCadastro, TipoConta, StatusConta, SenhaHash) VALUES (60, 'Leonardo Ferreira', 'user60@tunestream.com', '2025-04-25', 'Premium', 'Ativo', '$2b$12$hash000060fakehashvalueexample');
INSERT INTO USUARIOS (IDusuario, Nome, Email, DataCadastro, TipoConta, StatusConta, SenhaHash) VALUES (61, 'Fernanda Nascimento', 'user61@tunestream.com', '2024-05-28', 'Free', 'Ativo', '$2b$12$hash000061fakehashvalueexample');
INSERT INTO USUARIOS (IDusuario, Nome, Email, DataCadastro, TipoConta, StatusConta, SenhaHash) VALUES (62, 'Camila Barbosa', 'user62@tunestream.com', '2024-03-05', 'Premium', 'Ativo', '$2b$12$hash000062fakehashvalueexample');
INSERT INTO USUARIOS (IDusuario, Nome, Email, DataCadastro, TipoConta, StatusConta, SenhaHash) VALUES (63, 'Diego Araújo', 'user63@tunestream.com', '2024-04-14', 'Premium', 'Inativo', '$2b$12$hash000063fakehashvalueexample');
INSERT INTO USUARIOS (IDusuario, Nome, Email, DataCadastro, TipoConta, StatusConta, SenhaHash) VALUES (64, 'Vanessa Carvalho', 'user64@tunestream.com', '2025-04-26', 'Premium', 'Ativo', '$2b$12$hash000064fakehashvalueexample');
INSERT INTO USUARIOS (IDusuario, Nome, Email, DataCadastro, TipoConta, StatusConta, SenhaHash) VALUES (65, 'Thiago Pereira', 'user65@tunestream.com', '2024-06-20', 'Free', 'Inativo', '$2b$12$hash000065fakehashvalueexample');
INSERT INTO USUARIOS (IDusuario, Nome, Email, DataCadastro, TipoConta, StatusConta, SenhaHash) VALUES (66, 'Aline Costa', 'user66@tunestream.com', '2024-09-15', 'Free', 'Ativo', '$2b$12$hash000066fakehashvalueexample');
INSERT INTO USUARIOS (IDusuario, Nome, Email, DataCadastro, TipoConta, StatusConta, SenhaHash) VALUES (67, 'Rafael Pereira', 'user67@tunestream.com', '2024-04-29', 'Premium', 'Ativo', '$2b$12$hash000067fakehashvalueexample');
INSERT INTO USUARIOS (IDusuario, Nome, Email, DataCadastro, TipoConta, StatusConta, SenhaHash) VALUES (68, 'Carlos Lima', 'user68@tunestream.com', '2024-11-29', 'Free', 'Ativo', '$2b$12$hash000068fakehashvalueexample');
INSERT INTO USUARIOS (IDusuario, Nome, Email, DataCadastro, TipoConta, StatusConta, SenhaHash) VALUES (69, 'Gustavo Santos', 'user69@tunestream.com', '2024-07-27', 'Free', 'Ativo', '$2b$12$hash000069fakehashvalueexample');
INSERT INTO USUARIOS (IDusuario, Nome, Email, DataCadastro, TipoConta, StatusConta, SenhaHash) VALUES (70, 'Carlos Santos', 'user70@tunestream.com', '2024-06-03', 'Free', 'Ativo', '$2b$12$hash000070fakehashvalueexample');
INSERT INTO USUARIOS (IDusuario, Nome, Email, DataCadastro, TipoConta, StatusConta, SenhaHash) VALUES (71, 'Simone Oliveira', 'user71@tunestream.com', '2024-03-29', 'Free', 'Suspenso', '$2b$12$hash000071fakehashvalueexample');
INSERT INTO USUARIOS (IDusuario, Nome, Email, DataCadastro, TipoConta, StatusConta, SenhaHash) VALUES (72, 'Bruno Rocha', 'user72@tunestream.com', '2023-07-24', 'Premium', 'Ativo', '$2b$12$hash000072fakehashvalueexample');
INSERT INTO USUARIOS (IDusuario, Nome, Email, DataCadastro, TipoConta, StatusConta, SenhaHash) VALUES (73, 'Thiago Martins', 'user73@tunestream.com', '2024-06-03', 'Premium', 'Ativo', '$2b$12$hash000073fakehashvalueexample');
INSERT INTO USUARIOS (IDusuario, Nome, Email, DataCadastro, TipoConta, StatusConta, SenhaHash) VALUES (74, 'Simone Almeida', 'user74@tunestream.com', '2024-07-26', 'Premium', 'Ativo', '$2b$12$hash000074fakehashvalueexample');
INSERT INTO USUARIOS (IDusuario, Nome, Email, DataCadastro, TipoConta, StatusConta, SenhaHash) VALUES (75, 'Larissa Pereira', 'user75@tunestream.com', '2024-03-02', 'Free', 'Ativo', '$2b$12$hash000075fakehashvalueexample');
INSERT INTO USUARIOS (IDusuario, Nome, Email, DataCadastro, TipoConta, StatusConta, SenhaHash) VALUES (76, 'Mariana Rodrigues', 'user76@tunestream.com', '2024-03-14', 'Free', 'Ativo', '$2b$12$hash000076fakehashvalueexample');
INSERT INTO USUARIOS (IDusuario, Nome, Email, DataCadastro, TipoConta, StatusConta, SenhaHash) VALUES (77, 'Gustavo Santos', 'user77@tunestream.com', '2025-03-06', 'Free', 'Ativo', '$2b$12$hash000077fakehashvalueexample');
INSERT INTO USUARIOS (IDusuario, Nome, Email, DataCadastro, TipoConta, StatusConta, SenhaHash) VALUES (78, 'André Araújo', 'user78@tunestream.com', '2023-05-27', 'Free', 'Ativo', '$2b$12$hash000078fakehashvalueexample');
INSERT INTO USUARIOS (IDusuario, Nome, Email, DataCadastro, TipoConta, StatusConta, SenhaHash) VALUES (79, 'Larissa Rodrigues', 'user79@tunestream.com', '2025-02-03', 'Premium', 'Ativo', '$2b$12$hash000079fakehashvalueexample');
INSERT INTO USUARIOS (IDusuario, Nome, Email, DataCadastro, TipoConta, StatusConta, SenhaHash) VALUES (80, 'Felipe Costa', 'user80@tunestream.com', '2024-11-14', 'Premium', 'Ativo', '$2b$12$hash000080fakehashvalueexample');
INSERT INTO USUARIOS (IDusuario, Nome, Email, DataCadastro, TipoConta, StatusConta, SenhaHash) VALUES (81, 'Marcos Rocha', 'user81@tunestream.com', '2024-02-18', 'Free', 'Ativo', '$2b$12$hash000081fakehashvalueexample');
INSERT INTO USUARIOS (IDusuario, Nome, Email, DataCadastro, TipoConta, StatusConta, SenhaHash) VALUES (82, 'Patrícia Oliveira', 'user82@tunestream.com', '2025-01-09', 'Free', 'Ativo', '$2b$12$hash000082fakehashvalueexample');
INSERT INTO USUARIOS (IDusuario, Nome, Email, DataCadastro, TipoConta, StatusConta, SenhaHash) VALUES (83, 'Larissa Gomes', 'user83@tunestream.com', '2024-12-21', 'Free', 'Ativo', '$2b$12$hash000083fakehashvalueexample');
INSERT INTO USUARIOS (IDusuario, Nome, Email, DataCadastro, TipoConta, StatusConta, SenhaHash) VALUES (84, 'Bruno Nascimento', 'user84@tunestream.com', '2024-06-08', 'Premium', 'Ativo', '$2b$12$hash000084fakehashvalueexample');
INSERT INTO USUARIOS (IDusuario, Nome, Email, DataCadastro, TipoConta, StatusConta, SenhaHash) VALUES (85, 'Ricardo Rodrigues', 'user85@tunestream.com', '2025-06-16', 'Free', 'Ativo', '$2b$12$hash000085fakehashvalueexample');
INSERT INTO USUARIOS (IDusuario, Nome, Email, DataCadastro, TipoConta, StatusConta, SenhaHash) VALUES (86, 'Carlos Costa', 'user86@tunestream.com', '2023-10-04', 'Premium', 'Inativo', '$2b$12$hash000086fakehashvalueexample');
INSERT INTO USUARIOS (IDusuario, Nome, Email, DataCadastro, TipoConta, StatusConta, SenhaHash) VALUES (87, 'Leonardo Almeida', 'user87@tunestream.com', '2024-02-20', 'Free', 'Inativo', '$2b$12$hash000087fakehashvalueexample');
INSERT INTO USUARIOS (IDusuario, Nome, Email, DataCadastro, TipoConta, StatusConta, SenhaHash) VALUES (88, 'Renata Martins', 'user88@tunestream.com', '2024-12-18', 'Free', 'Ativo', '$2b$12$hash000088fakehashvalueexample');
INSERT INTO USUARIOS (IDusuario, Nome, Email, DataCadastro, TipoConta, StatusConta, SenhaHash) VALUES (89, 'Gustavo Costa', 'user89@tunestream.com', '2024-03-11', 'Premium', 'Ativo', '$2b$12$hash000089fakehashvalueexample');
INSERT INTO USUARIOS (IDusuario, Nome, Email, DataCadastro, TipoConta, StatusConta, SenhaHash) VALUES (90, 'Ana Oliveira', 'user90@tunestream.com', '2025-03-31', 'Free', 'Ativo', '$2b$12$hash000090fakehashvalueexample');
INSERT INTO USUARIOS (IDusuario, Nome, Email, DataCadastro, TipoConta, StatusConta, SenhaHash) VALUES (91, 'Lucas Oliveira', 'user91@tunestream.com', '2023-09-28', 'Premium', 'Ativo', '$2b$12$hash000091fakehashvalueexample');
INSERT INTO USUARIOS (IDusuario, Nome, Email, DataCadastro, TipoConta, StatusConta, SenhaHash) VALUES (92, 'Patrícia Barbosa', 'user92@tunestream.com', '2024-03-03', 'Premium', 'Ativo', '$2b$12$hash000092fakehashvalueexample');
INSERT INTO USUARIOS (IDusuario, Nome, Email, DataCadastro, TipoConta, StatusConta, SenhaHash) VALUES (93, 'Beatriz Souza', 'user93@tunestream.com', '2024-06-23', 'Premium', 'Inativo', '$2b$12$hash000093fakehashvalueexample');
INSERT INTO USUARIOS (IDusuario, Nome, Email, DataCadastro, TipoConta, StatusConta, SenhaHash) VALUES (94, 'Rafael Almeida', 'user94@tunestream.com', '2023-02-21', 'Free', 'Inativo', '$2b$12$hash000094fakehashvalueexample');
INSERT INTO USUARIOS (IDusuario, Nome, Email, DataCadastro, TipoConta, StatusConta, SenhaHash) VALUES (95, 'Débora Nascimento', 'user95@tunestream.com', '2024-06-27', 'Premium', 'Ativo', '$2b$12$hash000095fakehashvalueexample');
INSERT INTO USUARIOS (IDusuario, Nome, Email, DataCadastro, TipoConta, StatusConta, SenhaHash) VALUES (96, 'Vanessa Costa', 'user96@tunestream.com', '2023-10-05', 'Free', 'Ativo', '$2b$12$hash000096fakehashvalueexample');
INSERT INTO USUARIOS (IDusuario, Nome, Email, DataCadastro, TipoConta, StatusConta, SenhaHash) VALUES (97, 'Camila Souza', 'user97@tunestream.com', '2023-01-16', 'Free', 'Ativo', '$2b$12$hash000097fakehashvalueexample');
INSERT INTO USUARIOS (IDusuario, Nome, Email, DataCadastro, TipoConta, StatusConta, SenhaHash) VALUES (98, 'Fernanda Rocha', 'user98@tunestream.com', '2024-05-01', 'Free', 'Ativo', '$2b$12$hash000098fakehashvalueexample');
INSERT INTO USUARIOS (IDusuario, Nome, Email, DataCadastro, TipoConta, StatusConta, SenhaHash) VALUES (99, 'André Carvalho', 'user99@tunestream.com', '2024-11-03', 'Free', 'Inativo', '$2b$12$hash000099fakehashvalueexample');
INSERT INTO USUARIOS (IDusuario, Nome, Email, DataCadastro, TipoConta, StatusConta, SenhaHash) VALUES (100, 'Juliana Rocha', 'user100@tunestream.com', '2023-11-12', 'Premium', 'Suspenso', '$2b$12$hash000100fakehashvalueexample');
 
-- ---------------- ARTISTAS ----------------
INSERT INTO ARTISTAS (IDartista, NomeArtistico, Biografia, PaisOrigem, TaxaRoyalty) VALUES (1, 'The Golden Sound', 'Artista de Canadá, conhecido(a) por misturar influências locais com sonoridades contemporâneas.', 'Canadá', 0.0495);
INSERT INTO ARTISTAS (IDartista, NomeArtistico, Biografia, PaisOrigem, TaxaRoyalty) VALUES (2, 'Tatiane Pereira', 'Artista de Brasil, conhecido(a) por misturar influências locais com sonoridades contemporâneas.', 'Brasil', 0.0082);
INSERT INTO ARTISTAS (IDartista, NomeArtistico, Biografia, PaisOrigem, TaxaRoyalty) VALUES (3, 'The Velvet Sound', 'Artista de Brasil, conhecido(a) por misturar influências locais com sonoridades contemporâneas.', 'Brasil', 0.0088);
INSERT INTO ARTISTAS (IDartista, NomeArtistico, Biografia, PaisOrigem, TaxaRoyalty) VALUES (4, 'The Wild Beat', 'Artista de Alemanha, conhecido(a) por misturar influências locais com sonoridades contemporâneas.', 'Alemanha', 0.0159);
INSERT INTO ARTISTAS (IDartista, NomeArtistico, Biografia, PaisOrigem, TaxaRoyalty) VALUES (5, 'The Blue Horizon', 'Artista de Reino Unido, conhecido(a) por misturar influências locais com sonoridades contemporâneas.', 'Reino Unido', 0.0121);
INSERT INTO ARTISTAS (IDartista, NomeArtistico, Biografia, PaisOrigem, TaxaRoyalty) VALUES (6, 'The Blue Beat', 'Artista de Colômbia, conhecido(a) por misturar influências locais com sonoridades contemporâneas.', 'Colômbia', 0.0483);
INSERT INTO ARTISTAS (IDartista, NomeArtistico, Biografia, PaisOrigem, TaxaRoyalty) VALUES (7, 'The Golden Wave', 'Artista de Austrália, conhecido(a) por misturar influências locais com sonoridades contemporâneas.', 'Austrália', 0.0189);
INSERT INTO ARTISTAS (IDartista, NomeArtistico, Biografia, PaisOrigem, TaxaRoyalty) VALUES (8, 'The Silver Wave', 'Artista de Colômbia, conhecido(a) por misturar influências locais com sonoridades contemporâneas.', 'Colômbia', 0.0222);
INSERT INTO ARTISTAS (IDartista, NomeArtistico, Biografia, PaisOrigem, TaxaRoyalty) VALUES (9, 'The Crimson Drift', 'Artista de Japão, conhecido(a) por misturar influências locais com sonoridades contemporâneas.', 'Japão', 0.014);
INSERT INTO ARTISTAS (IDartista, NomeArtistico, Biografia, PaisOrigem, TaxaRoyalty) VALUES (10, 'Mariana Almeida', 'Artista de Suécia, conhecido(a) por misturar influências locais com sonoridades contemporâneas.', 'Suécia', 0.009);
INSERT INTO ARTISTAS (IDartista, NomeArtistico, Biografia, PaisOrigem, TaxaRoyalty) VALUES (11, 'The Solar Wave', 'Artista de Canadá, conhecido(a) por misturar influências locais com sonoridades contemporâneas.', 'Canadá', 0.006);
INSERT INTO ARTISTAS (IDartista, NomeArtistico, Biografia, PaisOrigem, TaxaRoyalty) VALUES (12, 'The Golden Echo', 'Artista de Alemanha, conhecido(a) por misturar influências locais com sonoridades contemporâneas.', 'Alemanha', 0.0481);
INSERT INTO ARTISTAS (IDartista, NomeArtistico, Biografia, PaisOrigem, TaxaRoyalty) VALUES (13, 'André Teixeira', 'Artista de Canadá, conhecido(a) por misturar influências locais com sonoridades contemporâneas.', 'Canadá', 0.0394);
INSERT INTO ARTISTAS (IDartista, NomeArtistico, Biografia, PaisOrigem, TaxaRoyalty) VALUES (14, 'The Silver Beat', 'Artista de Coreia do Sul, conhecido(a) por misturar influências locais com sonoridades contemporâneas.', 'Coreia do Sul', 0.0328);
INSERT INTO ARTISTAS (IDartista, NomeArtistico, Biografia, PaisOrigem, TaxaRoyalty) VALUES (15, 'Carlos Rocha', 'Artista de Japão, conhecido(a) por misturar influências locais com sonoridades contemporâneas.', 'Japão', 0.0243);
INSERT INTO ARTISTAS (IDartista, NomeArtistico, Biografia, PaisOrigem, TaxaRoyalty) VALUES (16, 'Ricardo Rocha', 'Artista de México, conhecido(a) por misturar influências locais com sonoridades contemporâneas.', 'México', 0.0277);
INSERT INTO ARTISTAS (IDartista, NomeArtistico, Biografia, PaisOrigem, TaxaRoyalty) VALUES (17, 'Tatiane Cardoso', 'Artista de México, conhecido(a) por misturar influências locais com sonoridades contemporâneas.', 'México', 0.0452);
INSERT INTO ARTISTAS (IDartista, NomeArtistico, Biografia, PaisOrigem, TaxaRoyalty) VALUES (18, 'Mariana Silva', 'Artista de Brasil, conhecido(a) por misturar influências locais com sonoridades contemporâneas.', 'Brasil', 0.011);
INSERT INTO ARTISTAS (IDartista, NomeArtistico, Biografia, PaisOrigem, TaxaRoyalty) VALUES (19, 'The Neon Pulse', 'Artista de Suécia, conhecido(a) por misturar influências locais com sonoridades contemporâneas.', 'Suécia', 0.0253);
INSERT INTO ARTISTAS (IDartista, NomeArtistico, Biografia, PaisOrigem, TaxaRoyalty) VALUES (20, 'Débora Silva', 'Artista de Japão, conhecido(a) por misturar influências locais com sonoridades contemporâneas.', 'Japão', 0.0289);
INSERT INTO ARTISTAS (IDartista, NomeArtistico, Biografia, PaisOrigem, TaxaRoyalty) VALUES (21, 'Felipe Almeida', 'Artista de Brasil, conhecido(a) por misturar influências locais com sonoridades contemporâneas.', 'Brasil', 0.0256);
INSERT INTO ARTISTAS (IDartista, NomeArtistico, Biografia, PaisOrigem, TaxaRoyalty) VALUES (22, 'Diego Rocha', 'Artista de Austrália, conhecido(a) por misturar influências locais com sonoridades contemporâneas.', 'Austrália', 0.0291);
INSERT INTO ARTISTAS (IDartista, NomeArtistico, Biografia, PaisOrigem, TaxaRoyalty) VALUES (23, 'Diego Martins', 'Artista de Argentina, conhecido(a) por misturar influências locais com sonoridades contemporâneas.', 'Argentina', 0.0414);
INSERT INTO ARTISTAS (IDartista, NomeArtistico, Biografia, PaisOrigem, TaxaRoyalty) VALUES (24, 'The Golden Groove', 'Artista de Portugal, conhecido(a) por misturar influências locais com sonoridades contemporâneas.', 'Portugal', 0.0383);
INSERT INTO ARTISTAS (IDartista, NomeArtistico, Biografia, PaisOrigem, TaxaRoyalty) VALUES (25, 'The Midnight Pulse', 'Artista de Estados Unidos, conhecido(a) por misturar influências locais com sonoridades contemporâneas.', 'Estados Unidos', 0.0266);
INSERT INTO ARTISTAS (IDartista, NomeArtistico, Biografia, PaisOrigem, TaxaRoyalty) VALUES (26, 'The Blue Static', 'Artista de Japão, conhecido(a) por misturar influências locais com sonoridades contemporâneas.', 'Japão', 0.0339);
INSERT INTO ARTISTAS (IDartista, NomeArtistico, Biografia, PaisOrigem, TaxaRoyalty) VALUES (27, 'Bruno Pereira', 'Artista de Colômbia, conhecido(a) por misturar influências locais com sonoridades contemporâneas.', 'Colômbia', 0.0164);
INSERT INTO ARTISTAS (IDartista, NomeArtistico, Biografia, PaisOrigem, TaxaRoyalty) VALUES (28, 'The Solar Static', 'Artista de Reino Unido, conhecido(a) por misturar influências locais com sonoridades contemporâneas.', 'Reino Unido', 0.0056);
INSERT INTO ARTISTAS (IDartista, NomeArtistico, Biografia, PaisOrigem, TaxaRoyalty) VALUES (29, 'Priscila Ferreira', 'Artista de Japão, conhecido(a) por misturar influências locais com sonoridades contemporâneas.', 'Japão', 0.027);
INSERT INTO ARTISTAS (IDartista, NomeArtistico, Biografia, PaisOrigem, TaxaRoyalty) VALUES (30, 'The Midnight Horizon', 'Artista de Espanha, conhecido(a) por misturar influências locais com sonoridades contemporâneas.', 'Espanha', 0.0395);
INSERT INTO ARTISTAS (IDartista, NomeArtistico, Biografia, PaisOrigem, TaxaRoyalty) VALUES (31, 'Rodrigo Oliveira', 'Artista de Austrália, conhecido(a) por misturar influências locais com sonoridades contemporâneas.', 'Austrália', 0.0263);
INSERT INTO ARTISTAS (IDartista, NomeArtistico, Biografia, PaisOrigem, TaxaRoyalty) VALUES (32, 'The Midnight Echo', 'Artista de Suécia, conhecido(a) por misturar influências locais com sonoridades contemporâneas.', 'Suécia', 0.0278);
INSERT INTO ARTISTAS (IDartista, NomeArtistico, Biografia, PaisOrigem, TaxaRoyalty) VALUES (33, 'The Crimson Pulse', 'Artista de Portugal, conhecido(a) por misturar influências locais com sonoridades contemporâneas.', 'Portugal', 0.0462);
INSERT INTO ARTISTAS (IDartista, NomeArtistico, Biografia, PaisOrigem, TaxaRoyalty) VALUES (34, 'Mariana Cardoso', 'Artista de Estados Unidos, conhecido(a) por misturar influências locais com sonoridades contemporâneas.', 'Estados Unidos', 0.0114);
INSERT INTO ARTISTAS (IDartista, NomeArtistico, Biografia, PaisOrigem, TaxaRoyalty) VALUES (35, 'The Electric Sound', 'Artista de Alemanha, conhecido(a) por misturar influências locais com sonoridades contemporâneas.', 'Alemanha', 0.0419);
INSERT INTO ARTISTAS (IDartista, NomeArtistico, Biografia, PaisOrigem, TaxaRoyalty) VALUES (36, 'The Neon Vibe', 'Artista de Portugal, conhecido(a) por misturar influências locais com sonoridades contemporâneas.', 'Portugal', 0.0274);
INSERT INTO ARTISTAS (IDartista, NomeArtistico, Biografia, PaisOrigem, TaxaRoyalty) VALUES (37, 'The Velvet Wave', 'Artista de Reino Unido, conhecido(a) por misturar influências locais com sonoridades contemporâneas.', 'Reino Unido', 0.0052);
INSERT INTO ARTISTAS (IDartista, NomeArtistico, Biografia, PaisOrigem, TaxaRoyalty) VALUES (38, 'The Silver Pulse', 'Artista de Colômbia, conhecido(a) por misturar influências locais com sonoridades contemporâneas.', 'Colômbia', 0.0219);
INSERT INTO ARTISTAS (IDartista, NomeArtistico, Biografia, PaisOrigem, TaxaRoyalty) VALUES (39, 'Tatiane Lima', 'Artista de Brasil, conhecido(a) por misturar influências locais com sonoridades contemporâneas.', 'Brasil', 0.0196);
INSERT INTO ARTISTAS (IDartista, NomeArtistico, Biografia, PaisOrigem, TaxaRoyalty) VALUES (40, 'The Velvet Echo', 'Artista de Austrália, conhecido(a) por misturar influências locais com sonoridades contemporâneas.', 'Austrália', 0.0138);
INSERT INTO ARTISTAS (IDartista, NomeArtistico, Biografia, PaisOrigem, TaxaRoyalty) VALUES (41, 'Simone Nascimento', 'Artista de Argentina, conhecido(a) por misturar influências locais com sonoridades contemporâneas.', 'Argentina', 0.0217);
INSERT INTO ARTISTAS (IDartista, NomeArtistico, Biografia, PaisOrigem, TaxaRoyalty) VALUES (42, 'The Velvet Static', 'Artista de Estados Unidos, conhecido(a) por misturar influências locais com sonoridades contemporâneas.', 'Estados Unidos', 0.0212);
INSERT INTO ARTISTAS (IDartista, NomeArtistico, Biografia, PaisOrigem, TaxaRoyalty) VALUES (43, 'The Crimson Wave', 'Artista de Argentina, conhecido(a) por misturar influências locais com sonoridades contemporâneas.', 'Argentina', 0.0096);
INSERT INTO ARTISTAS (IDartista, NomeArtistico, Biografia, PaisOrigem, TaxaRoyalty) VALUES (44, 'The Silver Groove', 'Artista de Argentina, conhecido(a) por misturar influências locais com sonoridades contemporâneas.', 'Argentina', 0.0246);
INSERT INTO ARTISTAS (IDartista, NomeArtistico, Biografia, PaisOrigem, TaxaRoyalty) VALUES (45, 'The Golden Vibe', 'Artista de México, conhecido(a) por misturar influências locais com sonoridades contemporâneas.', 'México', 0.048);
INSERT INTO ARTISTAS (IDartista, NomeArtistico, Biografia, PaisOrigem, TaxaRoyalty) VALUES (46, 'Gustavo Ribeiro', 'Artista de Austrália, conhecido(a) por misturar influências locais com sonoridades contemporâneas.', 'Austrália', 0.0444);
INSERT INTO ARTISTAS (IDartista, NomeArtistico, Biografia, PaisOrigem, TaxaRoyalty) VALUES (47, 'Diego Oliveira', 'Artista de Brasil, conhecido(a) por misturar influências locais com sonoridades contemporâneas.', 'Brasil', 0.047);
INSERT INTO ARTISTAS (IDartista, NomeArtistico, Biografia, PaisOrigem, TaxaRoyalty) VALUES (48, 'The Midnight Static', 'Artista de México, conhecido(a) por misturar influências locais com sonoridades contemporâneas.', 'México', 0.0112);
INSERT INTO ARTISTAS (IDartista, NomeArtistico, Biografia, PaisOrigem, TaxaRoyalty) VALUES (49, 'The Midnight Wave', 'Artista de Austrália, conhecido(a) por misturar influências locais com sonoridades contemporâneas.', 'Austrália', 0.0467);
INSERT INTO ARTISTAS (IDartista, NomeArtistico, Biografia, PaisOrigem, TaxaRoyalty) VALUES (50, 'Rafael Martins', 'Artista de Canadá, conhecido(a) por misturar influências locais com sonoridades contemporâneas.', 'Canadá', 0.0205);
INSERT INTO ARTISTAS (IDartista, NomeArtistico, Biografia, PaisOrigem, TaxaRoyalty) VALUES (51, 'The Crimson Beat', 'Artista de Canadá, conhecido(a) por misturar influências locais com sonoridades contemporâneas.', 'Canadá', 0.0345);
INSERT INTO ARTISTAS (IDartista, NomeArtistico, Biografia, PaisOrigem, TaxaRoyalty) VALUES (52, 'The Midnight Drift', 'Artista de Japão, conhecido(a) por misturar influências locais com sonoridades contemporâneas.', 'Japão', 0.0227);
INSERT INTO ARTISTAS (IDartista, NomeArtistico, Biografia, PaisOrigem, TaxaRoyalty) VALUES (53, 'Débora Costa', 'Artista de Estados Unidos, conhecido(a) por misturar influências locais com sonoridades contemporâneas.', 'Estados Unidos', 0.0144);
INSERT INTO ARTISTAS (IDartista, NomeArtistico, Biografia, PaisOrigem, TaxaRoyalty) VALUES (54, 'The Wild Groove', 'Artista de Espanha, conhecido(a) por misturar influências locais com sonoridades contemporâneas.', 'Espanha', 0.0458);
INSERT INTO ARTISTAS (IDartista, NomeArtistico, Biografia, PaisOrigem, TaxaRoyalty) VALUES (55, 'Lucas Oliveira', 'Artista de Reino Unido, conhecido(a) por misturar influências locais com sonoridades contemporâneas.', 'Reino Unido', 0.0204);
INSERT INTO ARTISTAS (IDartista, NomeArtistico, Biografia, PaisOrigem, TaxaRoyalty) VALUES (56, 'Patrícia Rodrigues', 'Artista de Colômbia, conhecido(a) por misturar influências locais com sonoridades contemporâneas.', 'Colômbia', 0.0166);
INSERT INTO ARTISTAS (IDartista, NomeArtistico, Biografia, PaisOrigem, TaxaRoyalty) VALUES (57, 'Simone Silva', 'Artista de Coreia do Sul, conhecido(a) por misturar influências locais com sonoridades contemporâneas.', 'Coreia do Sul', 0.0442);
INSERT INTO ARTISTAS (IDartista, NomeArtistico, Biografia, PaisOrigem, TaxaRoyalty) VALUES (58, 'The Velvet Drift', 'Artista de Portugal, conhecido(a) por misturar influências locais com sonoridades contemporâneas.', 'Portugal', 0.022);
INSERT INTO ARTISTAS (IDartista, NomeArtistico, Biografia, PaisOrigem, TaxaRoyalty) VALUES (59, 'The Solar Vibe', 'Artista de Reino Unido, conhecido(a) por misturar influências locais com sonoridades contemporâneas.', 'Reino Unido', 0.0359);
INSERT INTO ARTISTAS (IDartista, NomeArtistico, Biografia, PaisOrigem, TaxaRoyalty) VALUES (60, 'Juliana Ribeiro', 'Artista de Japão, conhecido(a) por misturar influências locais com sonoridades contemporâneas.', 'Japão', 0.0251);
INSERT INTO ARTISTAS (IDartista, NomeArtistico, Biografia, PaisOrigem, TaxaRoyalty) VALUES (61, 'The Blue Sound', 'Artista de Brasil, conhecido(a) por misturar influências locais com sonoridades contemporâneas.', 'Brasil', 0.0241);
INSERT INTO ARTISTAS (IDartista, NomeArtistico, Biografia, PaisOrigem, TaxaRoyalty) VALUES (62, 'The Solar Horizon', 'Artista de Brasil, conhecido(a) por misturar influências locais com sonoridades contemporâneas.', 'Brasil', 0.0083);
INSERT INTO ARTISTAS (IDartista, NomeArtistico, Biografia, PaisOrigem, TaxaRoyalty) VALUES (63, 'The Midnight Groove', 'Artista de México, conhecido(a) por misturar influências locais com sonoridades contemporâneas.', 'México', 0.0099);
INSERT INTO ARTISTAS (IDartista, NomeArtistico, Biografia, PaisOrigem, TaxaRoyalty) VALUES (64, 'Beatriz Rocha', 'Artista de Japão, conhecido(a) por misturar influências locais com sonoridades contemporâneas.', 'Japão', 0.0099);
INSERT INTO ARTISTAS (IDartista, NomeArtistico, Biografia, PaisOrigem, TaxaRoyalty) VALUES (65, 'The Neon Drift', 'Artista de México, conhecido(a) por misturar influências locais com sonoridades contemporâneas.', 'México', 0.0068);
INSERT INTO ARTISTAS (IDartista, NomeArtistico, Biografia, PaisOrigem, TaxaRoyalty) VALUES (66, 'Lucas Cardoso', 'Artista de Austrália, conhecido(a) por misturar influências locais com sonoridades contemporâneas.', 'Austrália', 0.0067);
INSERT INTO ARTISTAS (IDartista, NomeArtistico, Biografia, PaisOrigem, TaxaRoyalty) VALUES (67, 'The Neon Echo', 'Artista de Estados Unidos, conhecido(a) por misturar influências locais com sonoridades contemporâneas.', 'Estados Unidos', 0.0185);
INSERT INTO ARTISTAS (IDartista, NomeArtistico, Biografia, PaisOrigem, TaxaRoyalty) VALUES (68, 'Juliana Almeida', 'Artista de Portugal, conhecido(a) por misturar influências locais com sonoridades contemporâneas.', 'Portugal', 0.0406);
INSERT INTO ARTISTAS (IDartista, NomeArtistico, Biografia, PaisOrigem, TaxaRoyalty) VALUES (69, 'Ana Barbosa', 'Artista de Argentina, conhecido(a) por misturar influências locais com sonoridades contemporâneas.', 'Argentina', 0.0498);
INSERT INTO ARTISTAS (IDartista, NomeArtistico, Biografia, PaisOrigem, TaxaRoyalty) VALUES (70, 'The Electric Groove', 'Artista de Espanha, conhecido(a) por misturar influências locais com sonoridades contemporâneas.', 'Espanha', 0.0287);
INSERT INTO ARTISTAS (IDartista, NomeArtistico, Biografia, PaisOrigem, TaxaRoyalty) VALUES (71, 'Ana Carvalho', 'Artista de Coreia do Sul, conhecido(a) por misturar influências locais com sonoridades contemporâneas.', 'Coreia do Sul', 0.0342);
INSERT INTO ARTISTAS (IDartista, NomeArtistico, Biografia, PaisOrigem, TaxaRoyalty) VALUES (72, 'Ana Ferreira', 'Artista de Espanha, conhecido(a) por misturar influências locais com sonoridades contemporâneas.', 'Espanha', 0.0448);
INSERT INTO ARTISTAS (IDartista, NomeArtistico, Biografia, PaisOrigem, TaxaRoyalty) VALUES (73, 'The Neon Beat', 'Artista de Portugal, conhecido(a) por misturar influências locais com sonoridades contemporâneas.', 'Portugal', 0.035);
INSERT INTO ARTISTAS (IDartista, NomeArtistico, Biografia, PaisOrigem, TaxaRoyalty) VALUES (74, 'The Golden Horizon', 'Artista de Brasil, conhecido(a) por misturar influências locais com sonoridades contemporâneas.', 'Brasil', 0.0363);
INSERT INTO ARTISTAS (IDartista, NomeArtistico, Biografia, PaisOrigem, TaxaRoyalty) VALUES (75, 'The Electric Pulse', 'Artista de Portugal, conhecido(a) por misturar influências locais com sonoridades contemporâneas.', 'Portugal', 0.0053);
INSERT INTO ARTISTAS (IDartista, NomeArtistico, Biografia, PaisOrigem, TaxaRoyalty) VALUES (76, 'The Wild Echo', 'Artista de Portugal, conhecido(a) por misturar influências locais com sonoridades contemporâneas.', 'Portugal', 0.0273);
INSERT INTO ARTISTAS (IDartista, NomeArtistico, Biografia, PaisOrigem, TaxaRoyalty) VALUES (77, 'Rodrigo Ferreira', 'Artista de Portugal, conhecido(a) por misturar influências locais com sonoridades contemporâneas.', 'Portugal', 0.0259);
INSERT INTO ARTISTAS (IDartista, NomeArtistico, Biografia, PaisOrigem, TaxaRoyalty) VALUES (78, 'The Crimson Echo', 'Artista de Alemanha, conhecido(a) por misturar influências locais com sonoridades contemporâneas.', 'Alemanha', 0.0273);
INSERT INTO ARTISTAS (IDartista, NomeArtistico, Biografia, PaisOrigem, TaxaRoyalty) VALUES (79, 'Simone Rodrigues', 'Artista de Espanha, conhecido(a) por misturar influências locais com sonoridades contemporâneas.', 'Espanha', 0.0238);
INSERT INTO ARTISTAS (IDartista, NomeArtistico, Biografia, PaisOrigem, TaxaRoyalty) VALUES (80, 'The Blue Groove', 'Artista de Brasil, conhecido(a) por misturar influências locais com sonoridades contemporâneas.', 'Brasil', 0.0488);
INSERT INTO ARTISTAS (IDartista, NomeArtistico, Biografia, PaisOrigem, TaxaRoyalty) VALUES (81, 'Marcos Souza', 'Artista de Coreia do Sul, conhecido(a) por misturar influências locais com sonoridades contemporâneas.', 'Coreia do Sul', 0.0077);
INSERT INTO ARTISTAS (IDartista, NomeArtistico, Biografia, PaisOrigem, TaxaRoyalty) VALUES (82, 'The Midnight Vibe', 'Artista de Coreia do Sul, conhecido(a) por misturar influências locais com sonoridades contemporâneas.', 'Coreia do Sul', 0.0101);
INSERT INTO ARTISTAS (IDartista, NomeArtistico, Biografia, PaisOrigem, TaxaRoyalty) VALUES (83, 'Ricardo Costa', 'Artista de Colômbia, conhecido(a) por misturar influências locais com sonoridades contemporâneas.', 'Colômbia', 0.0136);
INSERT INTO ARTISTAS (IDartista, NomeArtistico, Biografia, PaisOrigem, TaxaRoyalty) VALUES (84, 'The Electric Vibe', 'Artista de Espanha, conhecido(a) por misturar influências locais com sonoridades contemporâneas.', 'Espanha', 0.0126);
INSERT INTO ARTISTAS (IDartista, NomeArtistico, Biografia, PaisOrigem, TaxaRoyalty) VALUES (85, 'Eduardo Carvalho', 'Artista de Austrália, conhecido(a) por misturar influências locais com sonoridades contemporâneas.', 'Austrália', 0.0106);
INSERT INTO ARTISTAS (IDartista, NomeArtistico, Biografia, PaisOrigem, TaxaRoyalty) VALUES (86, 'Juliana Araújo', 'Artista de México, conhecido(a) por misturar influências locais com sonoridades contemporâneas.', 'México', 0.042);
INSERT INTO ARTISTAS (IDartista, NomeArtistico, Biografia, PaisOrigem, TaxaRoyalty) VALUES (87, 'The Neon Wave', 'Artista de Coreia do Sul, conhecido(a) por misturar influências locais com sonoridades contemporâneas.', 'Coreia do Sul', 0.0263);
INSERT INTO ARTISTAS (IDartista, NomeArtistico, Biografia, PaisOrigem, TaxaRoyalty) VALUES (88, 'The Wild Horizon', 'Artista de Portugal, conhecido(a) por misturar influências locais com sonoridades contemporâneas.', 'Portugal', 0.0195);
INSERT INTO ARTISTAS (IDartista, NomeArtistico, Biografia, PaisOrigem, TaxaRoyalty) VALUES (89, 'The Blue Pulse', 'Artista de Portugal, conhecido(a) por misturar influências locais com sonoridades contemporâneas.', 'Portugal', 0.0415);
INSERT INTO ARTISTAS (IDartista, NomeArtistico, Biografia, PaisOrigem, TaxaRoyalty) VALUES (90, 'Larissa Oliveira', 'Artista de México, conhecido(a) por misturar influências locais com sonoridades contemporâneas.', 'México', 0.0464);
INSERT INTO ARTISTAS (IDartista, NomeArtistico, Biografia, PaisOrigem, TaxaRoyalty) VALUES (91, 'The Electric Beat', 'Artista de Colômbia, conhecido(a) por misturar influências locais com sonoridades contemporâneas.', 'Colômbia', 0.0481);
INSERT INTO ARTISTAS (IDartista, NomeArtistico, Biografia, PaisOrigem, TaxaRoyalty) VALUES (92, 'Camila Lima', 'Artista de Austrália, conhecido(a) por misturar influências locais com sonoridades contemporâneas.', 'Austrália', 0.0174);
INSERT INTO ARTISTAS (IDartista, NomeArtistico, Biografia, PaisOrigem, TaxaRoyalty) VALUES (93, 'Diego Teixeira', 'Artista de Austrália, conhecido(a) por misturar influências locais com sonoridades contemporâneas.', 'Austrália', 0.0413);
INSERT INTO ARTISTAS (IDartista, NomeArtistico, Biografia, PaisOrigem, TaxaRoyalty) VALUES (94, 'Ana Rodrigues', 'Artista de Estados Unidos, conhecido(a) por misturar influências locais com sonoridades contemporâneas.', 'Estados Unidos', 0.0264);
INSERT INTO ARTISTAS (IDartista, NomeArtistico, Biografia, PaisOrigem, TaxaRoyalty) VALUES (95, 'The Velvet Beat', 'Artista de Austrália, conhecido(a) por misturar influências locais com sonoridades contemporâneas.', 'Austrália', 0.0243);
INSERT INTO ARTISTAS (IDartista, NomeArtistico, Biografia, PaisOrigem, TaxaRoyalty) VALUES (96, 'The Silver Horizon', 'Artista de Reino Unido, conhecido(a) por misturar influências locais com sonoridades contemporâneas.', 'Reino Unido', 0.0054);
INSERT INTO ARTISTAS (IDartista, NomeArtistico, Biografia, PaisOrigem, TaxaRoyalty) VALUES (97, 'The Silver Static', 'Artista de Portugal, conhecido(a) por misturar influências locais com sonoridades contemporâneas.', 'Portugal', 0.0198);
INSERT INTO ARTISTAS (IDartista, NomeArtistico, Biografia, PaisOrigem, TaxaRoyalty) VALUES (98, 'Vanessa Ferreira', 'Artista de Canadá, conhecido(a) por misturar influências locais com sonoridades contemporâneas.', 'Canadá', 0.0389);
INSERT INTO ARTISTAS (IDartista, NomeArtistico, Biografia, PaisOrigem, TaxaRoyalty) VALUES (99, 'Marcos Oliveira', 'Artista de Japão, conhecido(a) por misturar influências locais com sonoridades contemporâneas.', 'Japão', 0.0065);
INSERT INTO ARTISTAS (IDartista, NomeArtistico, Biografia, PaisOrigem, TaxaRoyalty) VALUES (100, 'Fernanda Santos', 'Artista de Canadá, conhecido(a) por misturar influências locais com sonoridades contemporâneas.', 'Canadá', 0.0274);
 
-- ---------------- PLAYLISTS ----------------
INSERT INTO PLAYLISTS (IDplaylist, IDusuario, NomePlaylist, DataCriacao, E_Publica) VALUES (1, 91, 'Playlist Chuva 1', '2023-06-27', 1);
INSERT INTO PLAYLISTS (IDplaylist, IDusuario, NomePlaylist, DataCriacao, E_Publica) VALUES (2, 18, 'Playlist Road Trip 2', '2024-04-16', 1);
INSERT INTO PLAYLISTS (IDplaylist, IDusuario, NomePlaylist, DataCriacao, E_Publica) VALUES (3, 96, 'Playlist Verão 3', '2025-05-17', 1);
INSERT INTO PLAYLISTS (IDplaylist, IDusuario, NomePlaylist, DataCriacao, E_Publica) VALUES (4, 100, 'Playlist Foco 4', '2023-10-28', 0);
INSERT INTO PLAYLISTS (IDplaylist, IDusuario, NomePlaylist, DataCriacao, E_Publica) VALUES (5, 73, 'Playlist Foco 5', '2024-01-17', 0);
INSERT INTO PLAYLISTS (IDplaylist, IDusuario, NomePlaylist, DataCriacao, E_Publica) VALUES (6, 95, 'Playlist Foco 6', '2023-07-23', 0);
INSERT INTO PLAYLISTS (IDplaylist, IDusuario, NomePlaylist, DataCriacao, E_Publica) VALUES (7, 32, 'Playlist Treino 7', '2023-09-09', 1);
INSERT INTO PLAYLISTS (IDplaylist, IDusuario, NomePlaylist, DataCriacao, E_Publica) VALUES (8, 20, 'Playlist Foco 8', '2024-08-15', 1);
INSERT INTO PLAYLISTS (IDplaylist, IDusuario, NomePlaylist, DataCriacao, E_Publica) VALUES (9, 42, 'Playlist Noite 9', '2024-02-10', 0);
INSERT INTO PLAYLISTS (IDplaylist, IDusuario, NomePlaylist, DataCriacao, E_Publica) VALUES (10, 32, 'Playlist Verão 10', '2024-06-22', 1);
INSERT INTO PLAYLISTS (IDplaylist, IDusuario, NomePlaylist, DataCriacao, E_Publica) VALUES (11, 84, 'Playlist Noite 11', '2024-10-31', 0);
INSERT INTO PLAYLISTS (IDplaylist, IDusuario, NomePlaylist, DataCriacao, E_Publica) VALUES (12, 5, 'Playlist Noite 12', '2023-01-05', 0);
INSERT INTO PLAYLISTS (IDplaylist, IDusuario, NomePlaylist, DataCriacao, E_Publica) VALUES (13, 30, 'Playlist Chuva 13', '2024-01-18', 1);
INSERT INTO PLAYLISTS (IDplaylist, IDusuario, NomePlaylist, DataCriacao, E_Publica) VALUES (14, 38, 'Playlist Estudo 14', '2023-05-03', 1);
INSERT INTO PLAYLISTS (IDplaylist, IDusuario, NomePlaylist, DataCriacao, E_Publica) VALUES (15, 25, 'Playlist Relax 15', '2025-04-27', 1);
INSERT INTO PLAYLISTS (IDplaylist, IDusuario, NomePlaylist, DataCriacao, E_Publica) VALUES (16, 10, 'Playlist Festa 16', '2024-06-08', 1);
INSERT INTO PLAYLISTS (IDplaylist, IDusuario, NomePlaylist, DataCriacao, E_Publica) VALUES (17, 58, 'Playlist Relax 17', '2023-09-24', 1);
INSERT INTO PLAYLISTS (IDplaylist, IDusuario, NomePlaylist, DataCriacao, E_Publica) VALUES (18, 14, 'Playlist Relax 18', '2024-12-27', 0);
INSERT INTO PLAYLISTS (IDplaylist, IDusuario, NomePlaylist, DataCriacao, E_Publica) VALUES (19, 28, 'Playlist Manhã 19', '2024-01-13', 0);
INSERT INTO PLAYLISTS (IDplaylist, IDusuario, NomePlaylist, DataCriacao, E_Publica) VALUES (20, 19, 'Playlist Manhã 20', '2023-07-28', 0);
INSERT INTO PLAYLISTS (IDplaylist, IDusuario, NomePlaylist, DataCriacao, E_Publica) VALUES (21, 5, 'Playlist Relax 21', '2025-01-19', 1);
INSERT INTO PLAYLISTS (IDplaylist, IDusuario, NomePlaylist, DataCriacao, E_Publica) VALUES (22, 2, 'Playlist Festa 22', '2024-02-23', 0);
INSERT INTO PLAYLISTS (IDplaylist, IDusuario, NomePlaylist, DataCriacao, E_Publica) VALUES (23, 24, 'Playlist Relax 23', '2023-11-16', 1);
INSERT INTO PLAYLISTS (IDplaylist, IDusuario, NomePlaylist, DataCriacao, E_Publica) VALUES (24, 27, 'Playlist Manhã 24', '2025-03-25', 0);
INSERT INTO PLAYLISTS (IDplaylist, IDusuario, NomePlaylist, DataCriacao, E_Publica) VALUES (25, 71, 'Playlist Chuva 25', '2023-03-06', 0);
INSERT INTO PLAYLISTS (IDplaylist, IDusuario, NomePlaylist, DataCriacao, E_Publica) VALUES (26, 13, 'Playlist Road Trip 26', '2024-11-10', 1);
INSERT INTO PLAYLISTS (IDplaylist, IDusuario, NomePlaylist, DataCriacao, E_Publica) VALUES (27, 82, 'Playlist Verão 27', '2023-04-04', 1);
INSERT INTO PLAYLISTS (IDplaylist, IDusuario, NomePlaylist, DataCriacao, E_Publica) VALUES (28, 51, 'Playlist Foco 28', '2024-02-24', 0);
INSERT INTO PLAYLISTS (IDplaylist, IDusuario, NomePlaylist, DataCriacao, E_Publica) VALUES (29, 86, 'Playlist Foco 29', '2024-03-03', 1);
INSERT INTO PLAYLISTS (IDplaylist, IDusuario, NomePlaylist, DataCriacao, E_Publica) VALUES (30, 40, 'Playlist Relax 30', '2024-01-01', 0);
INSERT INTO PLAYLISTS (IDplaylist, IDusuario, NomePlaylist, DataCriacao, E_Publica) VALUES (31, 54, 'Playlist Manhã 31', '2025-06-03', 0);
INSERT INTO PLAYLISTS (IDplaylist, IDusuario, NomePlaylist, DataCriacao, E_Publica) VALUES (32, 83, 'Playlist Estudo 32', '2024-02-05', 0);
INSERT INTO PLAYLISTS (IDplaylist, IDusuario, NomePlaylist, DataCriacao, E_Publica) VALUES (33, 27, 'Playlist Manhã 33', '2024-03-20', 1);
INSERT INTO PLAYLISTS (IDplaylist, IDusuario, NomePlaylist, DataCriacao, E_Publica) VALUES (34, 55, 'Playlist Noite 34', '2025-04-20', 1);
INSERT INTO PLAYLISTS (IDplaylist, IDusuario, NomePlaylist, DataCriacao, E_Publica) VALUES (35, 52, 'Playlist Relax 35', '2024-01-09', 0);
INSERT INTO PLAYLISTS (IDplaylist, IDusuario, NomePlaylist, DataCriacao, E_Publica) VALUES (36, 99, 'Playlist Treino 36', '2023-05-14', 1);
INSERT INTO PLAYLISTS (IDplaylist, IDusuario, NomePlaylist, DataCriacao, E_Publica) VALUES (37, 7, 'Playlist Verão 37', '2023-05-26', 0);
INSERT INTO PLAYLISTS (IDplaylist, IDusuario, NomePlaylist, DataCriacao, E_Publica) VALUES (38, 12, 'Playlist Relax 38', '2024-09-29', 0);
INSERT INTO PLAYLISTS (IDplaylist, IDusuario, NomePlaylist, DataCriacao, E_Publica) VALUES (39, 95, 'Playlist Verão 39', '2023-06-25', 1);
INSERT INTO PLAYLISTS (IDplaylist, IDusuario, NomePlaylist, DataCriacao, E_Publica) VALUES (40, 45, 'Playlist Foco 40', '2023-06-15', 1);
INSERT INTO PLAYLISTS (IDplaylist, IDusuario, NomePlaylist, DataCriacao, E_Publica) VALUES (41, 9, 'Playlist Noite 41', '2024-01-28', 0);
INSERT INTO PLAYLISTS (IDplaylist, IDusuario, NomePlaylist, DataCriacao, E_Publica) VALUES (42, 97, 'Playlist Estudo 42', '2023-11-05', 1);
INSERT INTO PLAYLISTS (IDplaylist, IDusuario, NomePlaylist, DataCriacao, E_Publica) VALUES (43, 6, 'Playlist Chuva 43', '2023-11-19', 1);
INSERT INTO PLAYLISTS (IDplaylist, IDusuario, NomePlaylist, DataCriacao, E_Publica) VALUES (44, 78, 'Playlist Road Trip 44', '2023-03-30', 1);
INSERT INTO PLAYLISTS (IDplaylist, IDusuario, NomePlaylist, DataCriacao, E_Publica) VALUES (45, 82, 'Playlist Estudo 45', '2024-09-27', 0);
INSERT INTO PLAYLISTS (IDplaylist, IDusuario, NomePlaylist, DataCriacao, E_Publica) VALUES (46, 79, 'Playlist Estudo 46', '2025-04-29', 0);
INSERT INTO PLAYLISTS (IDplaylist, IDusuario, NomePlaylist, DataCriacao, E_Publica) VALUES (47, 24, 'Playlist Relax 47', '2023-08-12', 1);
INSERT INTO PLAYLISTS (IDplaylist, IDusuario, NomePlaylist, DataCriacao, E_Publica) VALUES (48, 52, 'Playlist Verão 48', '2023-06-10', 0);
INSERT INTO PLAYLISTS (IDplaylist, IDusuario, NomePlaylist, DataCriacao, E_Publica) VALUES (49, 46, 'Playlist Noite 49', '2023-06-03', 1);
INSERT INTO PLAYLISTS (IDplaylist, IDusuario, NomePlaylist, DataCriacao, E_Publica) VALUES (50, 93, 'Playlist Estudo 50', '2023-02-12', 1);
INSERT INTO PLAYLISTS (IDplaylist, IDusuario, NomePlaylist, DataCriacao, E_Publica) VALUES (51, 86, 'Playlist Festa 51', '2023-05-01', 0);
INSERT INTO PLAYLISTS (IDplaylist, IDusuario, NomePlaylist, DataCriacao, E_Publica) VALUES (52, 77, 'Playlist Chuva 52', '2024-07-17', 0);
INSERT INTO PLAYLISTS (IDplaylist, IDusuario, NomePlaylist, DataCriacao, E_Publica) VALUES (53, 84, 'Playlist Road Trip 53', '2023-11-12', 1);
INSERT INTO PLAYLISTS (IDplaylist, IDusuario, NomePlaylist, DataCriacao, E_Publica) VALUES (54, 55, 'Playlist Road Trip 54', '2024-11-05', 0);
INSERT INTO PLAYLISTS (IDplaylist, IDusuario, NomePlaylist, DataCriacao, E_Publica) VALUES (55, 58, 'Playlist Verão 55', '2024-03-24', 1);
INSERT INTO PLAYLISTS (IDplaylist, IDusuario, NomePlaylist, DataCriacao, E_Publica) VALUES (56, 3, 'Playlist Manhã 56', '2024-09-25', 0);
INSERT INTO PLAYLISTS (IDplaylist, IDusuario, NomePlaylist, DataCriacao, E_Publica) VALUES (57, 60, 'Playlist Estudo 57', '2024-04-02', 0);
INSERT INTO PLAYLISTS (IDplaylist, IDusuario, NomePlaylist, DataCriacao, E_Publica) VALUES (58, 23, 'Playlist Chuva 58', '2024-02-14', 1);
INSERT INTO PLAYLISTS (IDplaylist, IDusuario, NomePlaylist, DataCriacao, E_Publica) VALUES (59, 9, 'Playlist Treino 59', '2024-01-03', 0);
INSERT INTO PLAYLISTS (IDplaylist, IDusuario, NomePlaylist, DataCriacao, E_Publica) VALUES (60, 47, 'Playlist Noite 60', '2025-04-01', 0);
INSERT INTO PLAYLISTS (IDplaylist, IDusuario, NomePlaylist, DataCriacao, E_Publica) VALUES (61, 65, 'Playlist Verão 61', '2024-11-03', 1);
INSERT INTO PLAYLISTS (IDplaylist, IDusuario, NomePlaylist, DataCriacao, E_Publica) VALUES (62, 6, 'Playlist Treino 62', '2023-03-26', 0);
INSERT INTO PLAYLISTS (IDplaylist, IDusuario, NomePlaylist, DataCriacao, E_Publica) VALUES (63, 100, 'Playlist Verão 63', '2023-03-23', 1);
INSERT INTO PLAYLISTS (IDplaylist, IDusuario, NomePlaylist, DataCriacao, E_Publica) VALUES (64, 97, 'Playlist Verão 64', '2024-01-22', 1);
INSERT INTO PLAYLISTS (IDplaylist, IDusuario, NomePlaylist, DataCriacao, E_Publica) VALUES (65, 4, 'Playlist Noite 65', '2024-09-20', 1);
INSERT INTO PLAYLISTS (IDplaylist, IDusuario, NomePlaylist, DataCriacao, E_Publica) VALUES (66, 25, 'Playlist Treino 66', '2024-05-18', 0);
INSERT INTO PLAYLISTS (IDplaylist, IDusuario, NomePlaylist, DataCriacao, E_Publica) VALUES (67, 22, 'Playlist Estudo 67', '2023-03-09', 0);
INSERT INTO PLAYLISTS (IDplaylist, IDusuario, NomePlaylist, DataCriacao, E_Publica) VALUES (68, 79, 'Playlist Foco 68', '2023-06-12', 0);
INSERT INTO PLAYLISTS (IDplaylist, IDusuario, NomePlaylist, DataCriacao, E_Publica) VALUES (69, 79, 'Playlist Foco 69', '2025-04-15', 0);
INSERT INTO PLAYLISTS (IDplaylist, IDusuario, NomePlaylist, DataCriacao, E_Publica) VALUES (70, 19, 'Playlist Foco 70', '2024-05-29', 0);
INSERT INTO PLAYLISTS (IDplaylist, IDusuario, NomePlaylist, DataCriacao, E_Publica) VALUES (71, 27, 'Playlist Relax 71', '2023-09-27', 1);
INSERT INTO PLAYLISTS (IDplaylist, IDusuario, NomePlaylist, DataCriacao, E_Publica) VALUES (72, 41, 'Playlist Festa 72', '2023-02-07', 1);
INSERT INTO PLAYLISTS (IDplaylist, IDusuario, NomePlaylist, DataCriacao, E_Publica) VALUES (73, 24, 'Playlist Road Trip 73', '2023-06-15', 0);
INSERT INTO PLAYLISTS (IDplaylist, IDusuario, NomePlaylist, DataCriacao, E_Publica) VALUES (74, 87, 'Playlist Festa 74', '2024-01-21', 1);
INSERT INTO PLAYLISTS (IDplaylist, IDusuario, NomePlaylist, DataCriacao, E_Publica) VALUES (75, 34, 'Playlist Noite 75', '2025-02-25', 1);
INSERT INTO PLAYLISTS (IDplaylist, IDusuario, NomePlaylist, DataCriacao, E_Publica) VALUES (76, 82, 'Playlist Festa 76', '2025-06-12', 0);
INSERT INTO PLAYLISTS (IDplaylist, IDusuario, NomePlaylist, DataCriacao, E_Publica) VALUES (77, 72, 'Playlist Verão 77', '2024-08-16', 1);
INSERT INTO PLAYLISTS (IDplaylist, IDusuario, NomePlaylist, DataCriacao, E_Publica) VALUES (78, 33, 'Playlist Verão 78', '2024-10-06', 0);
INSERT INTO PLAYLISTS (IDplaylist, IDusuario, NomePlaylist, DataCriacao, E_Publica) VALUES (79, 95, 'Playlist Festa 79', '2023-09-29', 0);
INSERT INTO PLAYLISTS (IDplaylist, IDusuario, NomePlaylist, DataCriacao, E_Publica) VALUES (80, 48, 'Playlist Relax 80', '2023-05-30', 0);
INSERT INTO PLAYLISTS (IDplaylist, IDusuario, NomePlaylist, DataCriacao, E_Publica) VALUES (81, 43, 'Playlist Noite 81', '2024-03-28', 1);
INSERT INTO PLAYLISTS (IDplaylist, IDusuario, NomePlaylist, DataCriacao, E_Publica) VALUES (82, 23, 'Playlist Relax 82', '2025-01-31', 1);
INSERT INTO PLAYLISTS (IDplaylist, IDusuario, NomePlaylist, DataCriacao, E_Publica) VALUES (83, 38, 'Playlist Verão 83', '2023-09-17', 0);
INSERT INTO PLAYLISTS (IDplaylist, IDusuario, NomePlaylist, DataCriacao, E_Publica) VALUES (84, 82, 'Playlist Relax 84', '2024-11-10', 0);
INSERT INTO PLAYLISTS (IDplaylist, IDusuario, NomePlaylist, DataCriacao, E_Publica) VALUES (85, 94, 'Playlist Manhã 85', '2025-02-04', 1);
INSERT INTO PLAYLISTS (IDplaylist, IDusuario, NomePlaylist, DataCriacao, E_Publica) VALUES (86, 29, 'Playlist Treino 86', '2023-10-25', 0);
INSERT INTO PLAYLISTS (IDplaylist, IDusuario, NomePlaylist, DataCriacao, E_Publica) VALUES (87, 54, 'Playlist Verão 87', '2024-01-08', 1);
INSERT INTO PLAYLISTS (IDplaylist, IDusuario, NomePlaylist, DataCriacao, E_Publica) VALUES (88, 17, 'Playlist Chuva 88', '2023-08-21', 1);
INSERT INTO PLAYLISTS (IDplaylist, IDusuario, NomePlaylist, DataCriacao, E_Publica) VALUES (89, 3, 'Playlist Manhã 89', '2023-01-03', 0);
INSERT INTO PLAYLISTS (IDplaylist, IDusuario, NomePlaylist, DataCriacao, E_Publica) VALUES (90, 39, 'Playlist Noite 90', '2024-06-19', 0);
INSERT INTO PLAYLISTS (IDplaylist, IDusuario, NomePlaylist, DataCriacao, E_Publica) VALUES (91, 69, 'Playlist Estudo 91', '2024-02-28', 0);
INSERT INTO PLAYLISTS (IDplaylist, IDusuario, NomePlaylist, DataCriacao, E_Publica) VALUES (92, 76, 'Playlist Treino 92', '2023-07-29', 0);
INSERT INTO PLAYLISTS (IDplaylist, IDusuario, NomePlaylist, DataCriacao, E_Publica) VALUES (93, 80, 'Playlist Chuva 93', '2023-06-12', 1);
INSERT INTO PLAYLISTS (IDplaylist, IDusuario, NomePlaylist, DataCriacao, E_Publica) VALUES (94, 2, 'Playlist Estudo 94', '2024-12-25', 1);
INSERT INTO PLAYLISTS (IDplaylist, IDusuario, NomePlaylist, DataCriacao, E_Publica) VALUES (95, 58, 'Playlist Noite 95', '2023-03-07', 1);
INSERT INTO PLAYLISTS (IDplaylist, IDusuario, NomePlaylist, DataCriacao, E_Publica) VALUES (96, 86, 'Playlist Foco 96', '2024-02-16', 0);
INSERT INTO PLAYLISTS (IDplaylist, IDusuario, NomePlaylist, DataCriacao, E_Publica) VALUES (97, 2, 'Playlist Manhã 97', '2024-10-22', 0);
INSERT INTO PLAYLISTS (IDplaylist, IDusuario, NomePlaylist, DataCriacao, E_Publica) VALUES (98, 77, 'Playlist Relax 98', '2024-03-30', 0);
INSERT INTO PLAYLISTS (IDplaylist, IDusuario, NomePlaylist, DataCriacao, E_Publica) VALUES (99, 32, 'Playlist Treino 99', '2023-01-01', 1);
INSERT INTO PLAYLISTS (IDplaylist, IDusuario, NomePlaylist, DataCriacao, E_Publica) VALUES (100, 8, 'Playlist Verão 100', '2023-01-26', 0);
 
-- ---------------- ALBUNS ----------------
INSERT INTO ALBUNS (IDalbum, IDartista, Titulo, DataLancamento, TipoMidia) VALUES (1, 21, 'Silêncio das Cinzas', '2023-03-01', 'EP');
INSERT INTO ALBUNS (IDalbum, IDartista, Titulo, DataLancamento, TipoMidia) VALUES (2, 79, 'Eterno das Águas', '2024-07-18', 'Single');
INSERT INTO ALBUNS (IDalbum, IDartista, Titulo, DataLancamento, TipoMidia) VALUES (3, 53, 'Fogo de Cristal', '2023-07-24', 'Single');
INSERT INTO ALBUNS (IDalbum, IDartista, Titulo, DataLancamento, TipoMidia) VALUES (4, 79, 'Sonho dos Ventos', '2023-06-28', 'Single');
INSERT INTO ALBUNS (IDalbum, IDartista, Titulo, DataLancamento, TipoMidia) VALUES (5, 81, 'Última do Norte', '2023-02-19', 'Podcast');
INSERT INTO ALBUNS (IDalbum, IDartista, Titulo, DataLancamento, TipoMidia) VALUES (6, 1, 'Estrela Distante', '2024-01-20', 'EP');
INSERT INTO ALBUNS (IDalbum, IDartista, Titulo, DataLancamento, TipoMidia) VALUES (7, 95, 'Rio do Vento', '2024-11-02', 'Single');
INSERT INTO ALBUNS (IDalbum, IDartista, Titulo, DataLancamento, TipoMidia) VALUES (8, 34, 'Jardim Sem Volta', '2023-08-26', 'Single');
INSERT INTO ALBUNS (IDalbum, IDartista, Titulo, DataLancamento, TipoMidia) VALUES (9, 96, 'Eterno das Memórias', '2024-12-12', 'EP');
INSERT INTO ALBUNS (IDalbum, IDartista, Titulo, DataLancamento, TipoMidia) VALUES (10, 35, 'Labirinto da Montanha', '2024-10-13', 'Single');
INSERT INTO ALBUNS (IDalbum, IDartista, Titulo, DataLancamento, TipoMidia) VALUES (11, 34, 'Tempestade Escondido', '2023-10-30', 'Single');
INSERT INTO ALBUNS (IDalbum, IDartista, Titulo, DataLancamento, TipoMidia) VALUES (12, 65, 'Fogo do Vento', '2023-01-16', 'Album');
INSERT INTO ALBUNS (IDalbum, IDartista, Titulo, DataLancamento, TipoMidia) VALUES (13, 21, 'Jardim do Amanhã', '2025-02-03', 'EP');
INSERT INTO ALBUNS (IDalbum, IDartista, Titulo, DataLancamento, TipoMidia) VALUES (14, 43, 'Fogo da Lua Cheia', '2024-09-07', 'Album');
INSERT INTO ALBUNS (IDalbum, IDartista, Titulo, DataLancamento, TipoMidia) VALUES (15, 61, 'Enigma Proibido', '2025-05-09', 'Single');
INSERT INTO ALBUNS (IDalbum, IDartista, Titulo, DataLancamento, TipoMidia) VALUES (16, 56, 'Sombra das Águas', '2025-01-12', 'Album');
INSERT INTO ALBUNS (IDalbum, IDartista, Titulo, DataLancamento, TipoMidia) VALUES (17, 51, 'Espelho do Amanhã', '2024-09-29', 'Single');
INSERT INTO ALBUNS (IDalbum, IDartista, Titulo, DataLancamento, TipoMidia) VALUES (18, 5, 'Silêncio de Cristal', '2023-01-28', 'Album');
INSERT INTO ALBUNS (IDalbum, IDartista, Titulo, DataLancamento, TipoMidia) VALUES (19, 19, 'Silêncio do Deserto', '2024-12-18', 'Album');
INSERT INTO ALBUNS (IDalbum, IDartista, Titulo, DataLancamento, TipoMidia) VALUES (20, 89, 'Segredo de Cristal', '2024-10-20', 'Single');
INSERT INTO ALBUNS (IDalbum, IDartista, Titulo, DataLancamento, TipoMidia) VALUES (21, 9, 'Última da Montanha', '2025-05-27', 'Single');
INSERT INTO ALBUNS (IDalbum, IDartista, Titulo, DataLancamento, TipoMidia) VALUES (22, 69, 'Reino do Amanhã', '2024-11-11', 'Album');
INSERT INTO ALBUNS (IDalbum, IDartista, Titulo, DataLancamento, TipoMidia) VALUES (23, 32, 'Voz Sem Volta', '2023-07-30', 'Album');
INSERT INTO ALBUNS (IDalbum, IDartista, Titulo, DataLancamento, TipoMidia) VALUES (24, 97, 'Segredo da Montanha', '2024-10-11', 'Album');
INSERT INTO ALBUNS (IDalbum, IDartista, Titulo, DataLancamento, TipoMidia) VALUES (25, 13, 'Espelho Proibido', '2023-05-16', 'Album');
INSERT INTO ALBUNS (IDalbum, IDartista, Titulo, DataLancamento, TipoMidia) VALUES (26, 41, 'Fogo do Norte', '2023-12-11', 'Album');
INSERT INTO ALBUNS (IDalbum, IDartista, Titulo, DataLancamento, TipoMidia) VALUES (27, 33, 'Sombra do Deserto', '2023-10-17', 'Album');
INSERT INTO ALBUNS (IDalbum, IDartista, Titulo, DataLancamento, TipoMidia) VALUES (28, 99, 'Reino das Memórias', '2024-09-08', 'Single');
INSERT INTO ALBUNS (IDalbum, IDartista, Titulo, DataLancamento, TipoMidia) VALUES (29, 53, 'Espelho das Águas', '2023-02-01', 'Album');
INSERT INTO ALBUNS (IDalbum, IDartista, Titulo, DataLancamento, TipoMidia) VALUES (30, 61, 'Eterno do Deserto', '2024-12-22', 'Album');
INSERT INTO ALBUNS (IDalbum, IDartista, Titulo, DataLancamento, TipoMidia) VALUES (31, 56, 'Espelho da Meia-Noite', '2023-01-02', 'Single');
INSERT INTO ALBUNS (IDalbum, IDartista, Titulo, DataLancamento, TipoMidia) VALUES (32, 1, 'Espelho da Montanha', '2023-12-23', 'Single');
INSERT INTO ALBUNS (IDalbum, IDartista, Titulo, DataLancamento, TipoMidia) VALUES (33, 64, 'Estrela da Meia-Noite', '2024-08-29', 'Album');
INSERT INTO ALBUNS (IDalbum, IDartista, Titulo, DataLancamento, TipoMidia) VALUES (34, 74, 'Sonho da Cidade Velha', '2023-06-12', 'Album');
INSERT INTO ALBUNS (IDalbum, IDartista, Titulo, DataLancamento, TipoMidia) VALUES (35, 64, 'Fogo das Cinzas', '2023-06-19', 'Album');
INSERT INTO ALBUNS (IDalbum, IDartista, Titulo, DataLancamento, TipoMidia) VALUES (36, 90, 'Última Proibido', '2024-07-28', 'EP');
INSERT INTO ALBUNS (IDalbum, IDartista, Titulo, DataLancamento, TipoMidia) VALUES (37, 13, 'Caminho do Deserto', '2024-02-15', 'EP');
INSERT INTO ALBUNS (IDalbum, IDartista, Titulo, DataLancamento, TipoMidia) VALUES (38, 83, 'Última dos Ventos', '2023-01-26', 'Album');
INSERT INTO ALBUNS (IDalbum, IDartista, Titulo, DataLancamento, TipoMidia) VALUES (39, 55, 'Espelho da Cidade Velha', '2024-07-12', 'Single');
INSERT INTO ALBUNS (IDalbum, IDartista, Titulo, DataLancamento, TipoMidia) VALUES (40, 59, 'Voz das Cinzas', '2023-05-10', 'Single');
INSERT INTO ALBUNS (IDalbum, IDartista, Titulo, DataLancamento, TipoMidia) VALUES (41, 75, 'Segredo do Deserto', '2023-12-01', 'Single');
INSERT INTO ALBUNS (IDalbum, IDartista, Titulo, DataLancamento, TipoMidia) VALUES (42, 95, 'Rio Distante', '2023-11-28', 'Album');
INSERT INTO ALBUNS (IDalbum, IDartista, Titulo, DataLancamento, TipoMidia) VALUES (43, 75, 'Rio da Cidade Velha', '2023-08-25', 'Album');
INSERT INTO ALBUNS (IDalbum, IDartista, Titulo, DataLancamento, TipoMidia) VALUES (44, 65, 'Rio das Cinzas', '2023-07-16', 'Album');
INSERT INTO ALBUNS (IDalbum, IDartista, Titulo, DataLancamento, TipoMidia) VALUES (45, 32, 'Perdido de Cristal', '2025-01-10', 'Album');
INSERT INTO ALBUNS (IDalbum, IDartista, Titulo, DataLancamento, TipoMidia) VALUES (46, 21, 'Sonho do Deserto', '2023-08-30', 'Album');
INSERT INTO ALBUNS (IDalbum, IDartista, Titulo, DataLancamento, TipoMidia) VALUES (47, 94, 'Fogo da Cidade Velha', '2023-04-15', 'Album');
INSERT INTO ALBUNS (IDalbum, IDartista, Titulo, DataLancamento, TipoMidia) VALUES (48, 50, 'Eterno do Amanhã', '2023-06-04', 'Podcast');
INSERT INTO ALBUNS (IDalbum, IDartista, Titulo, DataLancamento, TipoMidia) VALUES (49, 56, 'Espelho do Norte', '2023-10-08', 'Album');
INSERT INTO ALBUNS (IDalbum, IDartista, Titulo, DataLancamento, TipoMidia) VALUES (50, 27, 'Eterno da Cidade Velha', '2024-02-02', 'Single');
INSERT INTO ALBUNS (IDalbum, IDartista, Titulo, DataLancamento, TipoMidia) VALUES (51, 56, 'Sombra da Lua Cheia', '2024-12-11', 'Album');
INSERT INTO ALBUNS (IDalbum, IDartista, Titulo, DataLancamento, TipoMidia) VALUES (52, 3, 'Espelho Encantado', '2023-05-26', 'Album');
INSERT INTO ALBUNS (IDalbum, IDartista, Titulo, DataLancamento, TipoMidia) VALUES (53, 95, 'Voz das Águas', '2023-09-06', 'EP');
INSERT INTO ALBUNS (IDalbum, IDartista, Titulo, DataLancamento, TipoMidia) VALUES (54, 76, 'Tempestade de Ferro', '2025-02-06', 'Single');
INSERT INTO ALBUNS (IDalbum, IDartista, Titulo, DataLancamento, TipoMidia) VALUES (55, 30, 'Jardim de Ferro', '2024-11-26', 'Album');
INSERT INTO ALBUNS (IDalbum, IDartista, Titulo, DataLancamento, TipoMidia) VALUES (56, 56, 'Eterno Encantado', '2023-11-17', 'Album');
INSERT INTO ALBUNS (IDalbum, IDartista, Titulo, DataLancamento, TipoMidia) VALUES (57, 32, 'Eterno dos Ventos', '2025-03-12', 'Album');
INSERT INTO ALBUNS (IDalbum, IDartista, Titulo, DataLancamento, TipoMidia) VALUES (58, 55, 'Silêncio da Cidade Velha', '2024-05-09', 'Single');
INSERT INTO ALBUNS (IDalbum, IDartista, Titulo, DataLancamento, TipoMidia) VALUES (59, 100, 'Silêncio das Memórias', '2023-01-11', 'Album');
INSERT INTO ALBUNS (IDalbum, IDartista, Titulo, DataLancamento, TipoMidia) VALUES (60, 5, 'Estrela Sem Volta', '2023-09-15', 'Single');
INSERT INTO ALBUNS (IDalbum, IDartista, Titulo, DataLancamento, TipoMidia) VALUES (61, 67, 'Silêncio do Amanhã', '2023-12-23', 'Album');
INSERT INTO ALBUNS (IDalbum, IDartista, Titulo, DataLancamento, TipoMidia) VALUES (62, 66, 'Fogo Proibido', '2023-01-17', 'Single');
INSERT INTO ALBUNS (IDalbum, IDartista, Titulo, DataLancamento, TipoMidia) VALUES (63, 44, 'Reino Escondido', '2024-02-25', 'Single');
INSERT INTO ALBUNS (IDalbum, IDartista, Titulo, DataLancamento, TipoMidia) VALUES (64, 88, 'Rio do Amanhã', '2023-07-08', 'Album');
INSERT INTO ALBUNS (IDalbum, IDartista, Titulo, DataLancamento, TipoMidia) VALUES (65, 36, 'Segredo da Cidade Velha', '2024-01-27', 'Album');
INSERT INTO ALBUNS (IDalbum, IDartista, Titulo, DataLancamento, TipoMidia) VALUES (66, 54, 'Sombra do Vento', '2024-03-06', 'Single');
INSERT INTO ALBUNS (IDalbum, IDartista, Titulo, DataLancamento, TipoMidia) VALUES (67, 34, 'Reino de Ferro', '2023-04-22', 'Album');
INSERT INTO ALBUNS (IDalbum, IDartista, Titulo, DataLancamento, TipoMidia) VALUES (68, 29, 'Voz Escondido', '2025-03-31', 'Podcast');
INSERT INTO ALBUNS (IDalbum, IDartista, Titulo, DataLancamento, TipoMidia) VALUES (69, 61, 'Última do Amanhã', '2024-10-19', 'Single');
INSERT INTO ALBUNS (IDalbum, IDartista, Titulo, DataLancamento, TipoMidia) VALUES (70, 46, 'Jardim de Cristal', '2024-11-13', 'Single');
INSERT INTO ALBUNS (IDalbum, IDartista, Titulo, DataLancamento, TipoMidia) VALUES (71, 38, 'Tempestade Encantado', '2025-02-17', 'Single');
INSERT INTO ALBUNS (IDalbum, IDartista, Titulo, DataLancamento, TipoMidia) VALUES (72, 46, 'Perdido Proibido', '2025-03-13', 'EP');
INSERT INTO ALBUNS (IDalbum, IDartista, Titulo, DataLancamento, TipoMidia) VALUES (73, 88, 'Labirinto da Lua Cheia', '2023-09-17', 'Podcast');
INSERT INTO ALBUNS (IDalbum, IDartista, Titulo, DataLancamento, TipoMidia) VALUES (74, 1, 'Silêncio Proibido', '2025-04-04', 'Single');
INSERT INTO ALBUNS (IDalbum, IDartista, Titulo, DataLancamento, TipoMidia) VALUES (75, 32, 'Labirinto do Deserto', '2024-11-01', 'Album');
INSERT INTO ALBUNS (IDalbum, IDartista, Titulo, DataLancamento, TipoMidia) VALUES (76, 55, 'Estrela Proibido', '2024-09-30', 'Single');
INSERT INTO ALBUNS (IDalbum, IDartista, Titulo, DataLancamento, TipoMidia) VALUES (77, 39, 'Reino de Cristal', '2025-05-24', 'Album');
INSERT INTO ALBUNS (IDalbum, IDartista, Titulo, DataLancamento, TipoMidia) VALUES (78, 42, 'Última de Ferro', '2025-03-13', 'EP');
INSERT INTO ALBUNS (IDalbum, IDartista, Titulo, DataLancamento, TipoMidia) VALUES (79, 19, 'Eterno de Ferro', '2025-05-24', 'Album');
INSERT INTO ALBUNS (IDalbum, IDartista, Titulo, DataLancamento, TipoMidia) VALUES (80, 20, 'Rio do Deserto', '2023-08-02', 'EP');
INSERT INTO ALBUNS (IDalbum, IDartista, Titulo, DataLancamento, TipoMidia) VALUES (81, 79, 'Enigma da Meia-Noite', '2024-12-05', 'Single');
INSERT INTO ALBUNS (IDalbum, IDartista, Titulo, DataLancamento, TipoMidia) VALUES (82, 82, 'Última Distante', '2025-05-08', 'Album');
INSERT INTO ALBUNS (IDalbum, IDartista, Titulo, DataLancamento, TipoMidia) VALUES (83, 68, 'Estrela do Amanhã', '2023-03-22', 'Single');
INSERT INTO ALBUNS (IDalbum, IDartista, Titulo, DataLancamento, TipoMidia) VALUES (84, 72, 'Rio Sem Volta', '2023-05-02', 'Album');
INSERT INTO ALBUNS (IDalbum, IDartista, Titulo, DataLancamento, TipoMidia) VALUES (85, 62, 'Enigma da Montanha', '2024-04-23', 'EP');
INSERT INTO ALBUNS (IDalbum, IDartista, Titulo, DataLancamento, TipoMidia) VALUES (86, 64, 'Estrela das Cinzas', '2023-06-18', 'Single');
INSERT INTO ALBUNS (IDalbum, IDartista, Titulo, DataLancamento, TipoMidia) VALUES (87, 42, 'Sombra da Meia-Noite', '2024-04-24', 'Single');
INSERT INTO ALBUNS (IDalbum, IDartista, Titulo, DataLancamento, TipoMidia) VALUES (88, 60, 'Estrela do Norte', '2024-01-19', 'Album');
INSERT INTO ALBUNS (IDalbum, IDartista, Titulo, DataLancamento, TipoMidia) VALUES (89, 82, 'Última da Meia-Noite', '2024-01-05', 'Single');
INSERT INTO ALBUNS (IDalbum, IDartista, Titulo, DataLancamento, TipoMidia) VALUES (90, 13, 'Segredo das Memórias', '2024-06-06', 'Single');
INSERT INTO ALBUNS (IDalbum, IDartista, Titulo, DataLancamento, TipoMidia) VALUES (91, 28, 'Perdido da Montanha', '2025-01-05', 'Album');
INSERT INTO ALBUNS (IDalbum, IDartista, Titulo, DataLancamento, TipoMidia) VALUES (92, 13, 'Perdido das Memórias', '2025-06-01', 'Single');
INSERT INTO ALBUNS (IDalbum, IDartista, Titulo, DataLancamento, TipoMidia) VALUES (93, 100, 'Caminho Proibido', '2024-06-22', 'Single');
INSERT INTO ALBUNS (IDalbum, IDartista, Titulo, DataLancamento, TipoMidia) VALUES (94, 55, 'Tempestade das Memórias', '2023-09-15', 'Single');
INSERT INTO ALBUNS (IDalbum, IDartista, Titulo, DataLancamento, TipoMidia) VALUES (95, 52, 'Reino Proibido', '2023-12-08', 'Single');
INSERT INTO ALBUNS (IDalbum, IDartista, Titulo, DataLancamento, TipoMidia) VALUES (96, 45, 'Labirinto Escondido', '2023-07-28', 'Single');
INSERT INTO ALBUNS (IDalbum, IDartista, Titulo, DataLancamento, TipoMidia) VALUES (97, 92, 'Fogo das Memórias', '2023-11-03', 'Album');
INSERT INTO ALBUNS (IDalbum, IDartista, Titulo, DataLancamento, TipoMidia) VALUES (98, 52, 'Voz Distante', '2024-07-12', 'Single');
INSERT INTO ALBUNS (IDalbum, IDartista, Titulo, DataLancamento, TipoMidia) VALUES (99, 14, 'Voz do Norte', '2023-01-07', 'Album');
INSERT INTO ALBUNS (IDalbum, IDartista, Titulo, DataLancamento, TipoMidia) VALUES (100, 65, 'Estrela da Montanha', '2024-07-10', 'Single');
 
-- ---------------- ROYALTIES ----------------
INSERT INTO ROYALTIES (IDroyalty, IDartista, PeriodoMesAno, TotalReproducoes, ValorTotalPago, StatusPagamento) VALUES (1, 79, '2024-05', 328731, 7823.8, 'Pago');
INSERT INTO ROYALTIES (IDroyalty, IDartista, PeriodoMesAno, TotalReproducoes, ValorTotalPago, StatusPagamento) VALUES (2, 89, '2025-08', 459545, 19071.12, 'Pago');
INSERT INTO ROYALTIES (IDroyalty, IDartista, PeriodoMesAno, TotalReproducoes, ValorTotalPago, StatusPagamento) VALUES (3, 28, '2024-02', 349801, 1958.89, 'Pago');
INSERT INTO ROYALTIES (IDroyalty, IDartista, PeriodoMesAno, TotalReproducoes, ValorTotalPago, StatusPagamento) VALUES (4, 81, '2024-06', 53242, 409.96, 'Pago');
INSERT INTO ROYALTIES (IDroyalty, IDartista, PeriodoMesAno, TotalReproducoes, ValorTotalPago, StatusPagamento) VALUES (5, 5, '2025-02', 406179, 4914.77, 'Pendente');
INSERT INTO ROYALTIES (IDroyalty, IDartista, PeriodoMesAno, TotalReproducoes, ValorTotalPago, StatusPagamento) VALUES (6, 84, '2024-01', 193493, 2438.01, 'Pago');
INSERT INTO ROYALTIES (IDroyalty, IDartista, PeriodoMesAno, TotalReproducoes, ValorTotalPago, StatusPagamento) VALUES (7, 18, '2024-10', 294803, 3242.83, 'Pago');
INSERT INTO ROYALTIES (IDroyalty, IDartista, PeriodoMesAno, TotalReproducoes, ValorTotalPago, StatusPagamento) VALUES (8, 39, '2024-06', 221236, 4336.23, 'Pendente');
INSERT INTO ROYALTIES (IDroyalty, IDartista, PeriodoMesAno, TotalReproducoes, ValorTotalPago, StatusPagamento) VALUES (9, 3, '2025-02', 297021, 2613.78, 'Pago');
INSERT INTO ROYALTIES (IDroyalty, IDartista, PeriodoMesAno, TotalReproducoes, ValorTotalPago, StatusPagamento) VALUES (10, 7, '2025-04', 297637, 5625.34, 'Pago');
INSERT INTO ROYALTIES (IDroyalty, IDartista, PeriodoMesAno, TotalReproducoes, ValorTotalPago, StatusPagamento) VALUES (11, 16, '2025-02', 301734, 8358.03, 'Pago');
INSERT INTO ROYALTIES (IDroyalty, IDartista, PeriodoMesAno, TotalReproducoes, ValorTotalPago, StatusPagamento) VALUES (12, 52, '2025-03', 35342, 802.26, 'Pendente');
INSERT INTO ROYALTIES (IDroyalty, IDartista, PeriodoMesAno, TotalReproducoes, ValorTotalPago, StatusPagamento) VALUES (13, 50, '2025-08', 310463, 6364.49, 'Pago');
INSERT INTO ROYALTIES (IDroyalty, IDartista, PeriodoMesAno, TotalReproducoes, ValorTotalPago, StatusPagamento) VALUES (14, 85, '2024-05', 249371, 2643.33, 'Pago');
INSERT INTO ROYALTIES (IDroyalty, IDartista, PeriodoMesAno, TotalReproducoes, ValorTotalPago, StatusPagamento) VALUES (15, 71, '2024-04', 43576, 1490.3, 'Pago');
INSERT INTO ROYALTIES (IDroyalty, IDartista, PeriodoMesAno, TotalReproducoes, ValorTotalPago, StatusPagamento) VALUES (16, 28, '2024-05', 328773, 1841.13, 'Pendente');
INSERT INTO ROYALTIES (IDroyalty, IDartista, PeriodoMesAno, TotalReproducoes, ValorTotalPago, StatusPagamento) VALUES (17, 1, '2024-01', 358587, 17750.06, 'Pago');
INSERT INTO ROYALTIES (IDroyalty, IDartista, PeriodoMesAno, TotalReproducoes, ValorTotalPago, StatusPagamento) VALUES (18, 12, '2024-07', 455994, 21933.31, 'Pendente');
INSERT INTO ROYALTIES (IDroyalty, IDartista, PeriodoMesAno, TotalReproducoes, ValorTotalPago, StatusPagamento) VALUES (19, 61, '2024-01', 144512, 3482.74, 'Pago');
INSERT INTO ROYALTIES (IDroyalty, IDartista, PeriodoMesAno, TotalReproducoes, ValorTotalPago, StatusPagamento) VALUES (20, 32, '2025-03', 384695, 10694.52, 'Pago');
INSERT INTO ROYALTIES (IDroyalty, IDartista, PeriodoMesAno, TotalReproducoes, ValorTotalPago, StatusPagamento) VALUES (21, 7, '2024-12', 405911, 7671.72, 'Pago');
INSERT INTO ROYALTIES (IDroyalty, IDartista, PeriodoMesAno, TotalReproducoes, ValorTotalPago, StatusPagamento) VALUES (22, 89, '2024-05', 382684, 15881.39, 'Pago');
INSERT INTO ROYALTIES (IDroyalty, IDartista, PeriodoMesAno, TotalReproducoes, ValorTotalPago, StatusPagamento) VALUES (23, 38, '2025-09', 292384, 6403.21, 'Pago');
INSERT INTO ROYALTIES (IDroyalty, IDartista, PeriodoMesAno, TotalReproducoes, ValorTotalPago, StatusPagamento) VALUES (24, 59, '2025-10', 488918, 17552.16, 'Pago');
INSERT INTO ROYALTIES (IDroyalty, IDartista, PeriodoMesAno, TotalReproducoes, ValorTotalPago, StatusPagamento) VALUES (25, 7, '2025-11', 16860, 318.65, 'Pendente');
INSERT INTO ROYALTIES (IDroyalty, IDartista, PeriodoMesAno, TotalReproducoes, ValorTotalPago, StatusPagamento) VALUES (26, 2, '2025-09', 360096, 2952.79, 'Pago');
INSERT INTO ROYALTIES (IDroyalty, IDartista, PeriodoMesAno, TotalReproducoes, ValorTotalPago, StatusPagamento) VALUES (27, 11, '2025-01', 163186, 979.12, 'Pendente');
INSERT INTO ROYALTIES (IDroyalty, IDartista, PeriodoMesAno, TotalReproducoes, ValorTotalPago, StatusPagamento) VALUES (28, 77, '2024-06', 451494, 11693.69, 'Pago');
INSERT INTO ROYALTIES (IDroyalty, IDartista, PeriodoMesAno, TotalReproducoes, ValorTotalPago, StatusPagamento) VALUES (29, 78, '2024-02', 165921, 4529.64, 'Pago');
INSERT INTO ROYALTIES (IDroyalty, IDartista, PeriodoMesAno, TotalReproducoes, ValorTotalPago, StatusPagamento) VALUES (30, 74, '2025-12', 230117, 8353.25, 'Pago');
INSERT INTO ROYALTIES (IDroyalty, IDartista, PeriodoMesAno, TotalReproducoes, ValorTotalPago, StatusPagamento) VALUES (31, 22, '2024-05', 418146, 12168.05, 'Pendente');
INSERT INTO ROYALTIES (IDroyalty, IDartista, PeriodoMesAno, TotalReproducoes, ValorTotalPago, StatusPagamento) VALUES (32, 83, '2024-06', 330247, 4491.36, 'Pago');
INSERT INTO ROYALTIES (IDroyalty, IDartista, PeriodoMesAno, TotalReproducoes, ValorTotalPago, StatusPagamento) VALUES (33, 62, '2025-01', 408044, 3386.77, 'Pago');
INSERT INTO ROYALTIES (IDroyalty, IDartista, PeriodoMesAno, TotalReproducoes, ValorTotalPago, StatusPagamento) VALUES (34, 35, '2025-07', 175152, 7338.87, 'Pendente');
INSERT INTO ROYALTIES (IDroyalty, IDartista, PeriodoMesAno, TotalReproducoes, ValorTotalPago, StatusPagamento) VALUES (35, 8, '2025-08', 341383, 7578.7, 'Pago');
INSERT INTO ROYALTIES (IDroyalty, IDartista, PeriodoMesAno, TotalReproducoes, ValorTotalPago, StatusPagamento) VALUES (36, 77, '2024-11', 455998, 11810.35, 'Pago');
INSERT INTO ROYALTIES (IDroyalty, IDartista, PeriodoMesAno, TotalReproducoes, ValorTotalPago, StatusPagamento) VALUES (37, 2, '2024-05', 315269, 2585.21, 'Pago');
INSERT INTO ROYALTIES (IDroyalty, IDartista, PeriodoMesAno, TotalReproducoes, ValorTotalPago, StatusPagamento) VALUES (38, 75, '2025-02', 465732, 2468.38, 'Pendente');
INSERT INTO ROYALTIES (IDroyalty, IDartista, PeriodoMesAno, TotalReproducoes, ValorTotalPago, StatusPagamento) VALUES (39, 50, '2025-10', 197337, 4045.41, 'Pago');
INSERT INTO ROYALTIES (IDroyalty, IDartista, PeriodoMesAno, TotalReproducoes, ValorTotalPago, StatusPagamento) VALUES (40, 30, '2025-03', 148635, 5871.08, 'Pago');
INSERT INTO ROYALTIES (IDroyalty, IDartista, PeriodoMesAno, TotalReproducoes, ValorTotalPago, StatusPagamento) VALUES (41, 42, '2024-09', 140621, 2981.17, 'Pago');
INSERT INTO ROYALTIES (IDroyalty, IDartista, PeriodoMesAno, TotalReproducoes, ValorTotalPago, StatusPagamento) VALUES (42, 76, '2024-02', 151368, 4132.35, 'Pago');
INSERT INTO ROYALTIES (IDroyalty, IDartista, PeriodoMesAno, TotalReproducoes, ValorTotalPago, StatusPagamento) VALUES (43, 74, '2024-05', 143675, 5215.4, 'Pago');
INSERT INTO ROYALTIES (IDroyalty, IDartista, PeriodoMesAno, TotalReproducoes, ValorTotalPago, StatusPagamento) VALUES (44, 71, '2025-10', 407495, 13936.33, 'Pago');
INSERT INTO ROYALTIES (IDroyalty, IDartista, PeriodoMesAno, TotalReproducoes, ValorTotalPago, StatusPagamento) VALUES (45, 45, '2025-06', 44697, 2145.46, 'Pago');
INSERT INTO ROYALTIES (IDroyalty, IDartista, PeriodoMesAno, TotalReproducoes, ValorTotalPago, StatusPagamento) VALUES (46, 63, '2025-01', 105183, 1041.31, 'Pago');
INSERT INTO ROYALTIES (IDroyalty, IDartista, PeriodoMesAno, TotalReproducoes, ValorTotalPago, StatusPagamento) VALUES (47, 93, '2024-08', 162351, 6705.1, 'Pago');
INSERT INTO ROYALTIES (IDroyalty, IDartista, PeriodoMesAno, TotalReproducoes, ValorTotalPago, StatusPagamento) VALUES (48, 87, '2025-01', 244063, 6418.86, 'Pago');
INSERT INTO ROYALTIES (IDroyalty, IDartista, PeriodoMesAno, TotalReproducoes, ValorTotalPago, StatusPagamento) VALUES (49, 33, '2025-07', 393910, 18198.64, 'Pendente');
INSERT INTO ROYALTIES (IDroyalty, IDartista, PeriodoMesAno, TotalReproducoes, ValorTotalPago, StatusPagamento) VALUES (50, 50, '2025-03', 283510, 5811.95, 'Pendente');
INSERT INTO ROYALTIES (IDroyalty, IDartista, PeriodoMesAno, TotalReproducoes, ValorTotalPago, StatusPagamento) VALUES (51, 46, '2024-03', 122189, 5425.19, 'Pago');
INSERT INTO ROYALTIES (IDroyalty, IDartista, PeriodoMesAno, TotalReproducoes, ValorTotalPago, StatusPagamento) VALUES (52, 67, '2024-09', 464144, 8586.66, 'Pago');
INSERT INTO ROYALTIES (IDroyalty, IDartista, PeriodoMesAno, TotalReproducoes, ValorTotalPago, StatusPagamento) VALUES (53, 42, '2025-04', 265478, 5628.13, 'Pago');
INSERT INTO ROYALTIES (IDroyalty, IDartista, PeriodoMesAno, TotalReproducoes, ValorTotalPago, StatusPagamento) VALUES (54, 25, '2024-07', 100927, 2684.66, 'Pendente');
INSERT INTO ROYALTIES (IDroyalty, IDartista, PeriodoMesAno, TotalReproducoes, ValorTotalPago, StatusPagamento) VALUES (55, 90, '2024-10', 190325, 8831.08, 'Pago');
INSERT INTO ROYALTIES (IDroyalty, IDartista, PeriodoMesAno, TotalReproducoes, ValorTotalPago, StatusPagamento) VALUES (56, 46, '2025-01', 408855, 18153.16, 'Pago');
INSERT INTO ROYALTIES (IDroyalty, IDartista, PeriodoMesAno, TotalReproducoes, ValorTotalPago, StatusPagamento) VALUES (57, 20, '2024-08', 23480, 678.57, 'Pago');
INSERT INTO ROYALTIES (IDroyalty, IDartista, PeriodoMesAno, TotalReproducoes, ValorTotalPago, StatusPagamento) VALUES (58, 64, '2024-12', 454328, 4497.85, 'Pendente');
INSERT INTO ROYALTIES (IDroyalty, IDartista, PeriodoMesAno, TotalReproducoes, ValorTotalPago, StatusPagamento) VALUES (59, 81, '2025-03', 412896, 3179.3, 'Pendente');
INSERT INTO ROYALTIES (IDroyalty, IDartista, PeriodoMesAno, TotalReproducoes, ValorTotalPago, StatusPagamento) VALUES (60, 41, '2025-08', 16016, 347.55, 'Pendente');
INSERT INTO ROYALTIES (IDroyalty, IDartista, PeriodoMesAno, TotalReproducoes, ValorTotalPago, StatusPagamento) VALUES (61, 67, '2025-08', 10884, 201.35, 'Pendente');
INSERT INTO ROYALTIES (IDroyalty, IDartista, PeriodoMesAno, TotalReproducoes, ValorTotalPago, StatusPagamento) VALUES (62, 27, '2025-07', 255069, 4183.13, 'Pago');
INSERT INTO ROYALTIES (IDroyalty, IDartista, PeriodoMesAno, TotalReproducoes, ValorTotalPago, StatusPagamento) VALUES (63, 28, '2024-09', 485326, 2717.83, 'Pago');
INSERT INTO ROYALTIES (IDroyalty, IDartista, PeriodoMesAno, TotalReproducoes, ValorTotalPago, StatusPagamento) VALUES (64, 55, '2024-04', 496338, 10125.3, 'Pago');
INSERT INTO ROYALTIES (IDroyalty, IDartista, PeriodoMesAno, TotalReproducoes, ValorTotalPago, StatusPagamento) VALUES (65, 76, '2025-08', 68731, 1876.36, 'Pendente');
INSERT INTO ROYALTIES (IDroyalty, IDartista, PeriodoMesAno, TotalReproducoes, ValorTotalPago, StatusPagamento) VALUES (66, 5, '2024-11', 105476, 1276.26, 'Pago');
INSERT INTO ROYALTIES (IDroyalty, IDartista, PeriodoMesAno, TotalReproducoes, ValorTotalPago, StatusPagamento) VALUES (67, 49, '2024-03', 14528, 678.46, 'Pendente');
INSERT INTO ROYALTIES (IDroyalty, IDartista, PeriodoMesAno, TotalReproducoes, ValorTotalPago, StatusPagamento) VALUES (68, 72, '2024-12', 456580, 20454.78, 'Pago');
INSERT INTO ROYALTIES (IDroyalty, IDartista, PeriodoMesAno, TotalReproducoes, ValorTotalPago, StatusPagamento) VALUES (69, 63, '2024-03', 452544, 4480.19, 'Pago');
INSERT INTO ROYALTIES (IDroyalty, IDartista, PeriodoMesAno, TotalReproducoes, ValorTotalPago, StatusPagamento) VALUES (70, 51, '2024-04', 370444, 12780.32, 'Pago');
INSERT INTO ROYALTIES (IDroyalty, IDartista, PeriodoMesAno, TotalReproducoes, ValorTotalPago, StatusPagamento) VALUES (71, 33, '2024-11', 296048, 13677.42, 'Pendente');
INSERT INTO ROYALTIES (IDroyalty, IDartista, PeriodoMesAno, TotalReproducoes, ValorTotalPago, StatusPagamento) VALUES (72, 12, '2025-10', 265652, 12777.86, 'Pago');
INSERT INTO ROYALTIES (IDroyalty, IDartista, PeriodoMesAno, TotalReproducoes, ValorTotalPago, StatusPagamento) VALUES (73, 58, '2024-06', 194564, 4280.41, 'Pago');
INSERT INTO ROYALTIES (IDroyalty, IDartista, PeriodoMesAno, TotalReproducoes, ValorTotalPago, StatusPagamento) VALUES (74, 93, '2024-08', 90342, 3731.12, 'Pendente');
INSERT INTO ROYALTIES (IDroyalty, IDartista, PeriodoMesAno, TotalReproducoes, ValorTotalPago, StatusPagamento) VALUES (75, 33, '2024-12', 31178, 1440.42, 'Pago');
INSERT INTO ROYALTIES (IDroyalty, IDartista, PeriodoMesAno, TotalReproducoes, ValorTotalPago, StatusPagamento) VALUES (76, 4, '2024-02', 135315, 2151.51, 'Pago');
INSERT INTO ROYALTIES (IDroyalty, IDartista, PeriodoMesAno, TotalReproducoes, ValorTotalPago, StatusPagamento) VALUES (77, 91, '2025-12', 339150, 16313.11, 'Pago');
INSERT INTO ROYALTIES (IDroyalty, IDartista, PeriodoMesAno, TotalReproducoes, ValorTotalPago, StatusPagamento) VALUES (78, 62, '2024-02', 53082, 440.58, 'Pendente');
INSERT INTO ROYALTIES (IDroyalty, IDartista, PeriodoMesAno, TotalReproducoes, ValorTotalPago, StatusPagamento) VALUES (79, 97, '2024-01', 492605, 9753.58, 'Pendente');
INSERT INTO ROYALTIES (IDroyalty, IDartista, PeriodoMesAno, TotalReproducoes, ValorTotalPago, StatusPagamento) VALUES (80, 96, '2024-10', 309317, 1670.31, 'Pago');
INSERT INTO ROYALTIES (IDroyalty, IDartista, PeriodoMesAno, TotalReproducoes, ValorTotalPago, StatusPagamento) VALUES (81, 98, '2025-09', 55370, 2153.89, 'Pago');
INSERT INTO ROYALTIES (IDroyalty, IDartista, PeriodoMesAno, TotalReproducoes, ValorTotalPago, StatusPagamento) VALUES (82, 48, '2024-09', 204597, 2291.49, 'Pendente');
INSERT INTO ROYALTIES (IDroyalty, IDartista, PeriodoMesAno, TotalReproducoes, ValorTotalPago, StatusPagamento) VALUES (83, 62, '2025-01', 88482, 734.4, 'Pago');
INSERT INTO ROYALTIES (IDroyalty, IDartista, PeriodoMesAno, TotalReproducoes, ValorTotalPago, StatusPagamento) VALUES (84, 19, '2025-10', 467853, 11836.68, 'Pendente');
INSERT INTO ROYALTIES (IDroyalty, IDartista, PeriodoMesAno, TotalReproducoes, ValorTotalPago, StatusPagamento) VALUES (85, 92, '2024-07', 418927, 7289.33, 'Pendente');
INSERT INTO ROYALTIES (IDroyalty, IDartista, PeriodoMesAno, TotalReproducoes, ValorTotalPago, StatusPagamento) VALUES (86, 29, '2024-03', 489772, 13223.84, 'Pago');
INSERT INTO ROYALTIES (IDroyalty, IDartista, PeriodoMesAno, TotalReproducoes, ValorTotalPago, StatusPagamento) VALUES (87, 48, '2025-12', 73375, 821.8, 'Pago');
INSERT INTO ROYALTIES (IDroyalty, IDartista, PeriodoMesAno, TotalReproducoes, ValorTotalPago, StatusPagamento) VALUES (88, 13, '2025-01', 441681, 17402.23, 'Pendente');
INSERT INTO ROYALTIES (IDroyalty, IDartista, PeriodoMesAno, TotalReproducoes, ValorTotalPago, StatusPagamento) VALUES (89, 10, '2025-03', 178242, 1604.18, 'Pendente');
INSERT INTO ROYALTIES (IDroyalty, IDartista, PeriodoMesAno, TotalReproducoes, ValorTotalPago, StatusPagamento) VALUES (90, 30, '2025-04', 60713, 2398.16, 'Pago');
INSERT INTO ROYALTIES (IDroyalty, IDartista, PeriodoMesAno, TotalReproducoes, ValorTotalPago, StatusPagamento) VALUES (91, 19, '2024-11', 116308, 2942.59, 'Pago');
INSERT INTO ROYALTIES (IDroyalty, IDartista, PeriodoMesAno, TotalReproducoes, ValorTotalPago, StatusPagamento) VALUES (92, 24, '2025-11', 236751, 9067.56, 'Pago');
INSERT INTO ROYALTIES (IDroyalty, IDartista, PeriodoMesAno, TotalReproducoes, ValorTotalPago, StatusPagamento) VALUES (93, 19, '2025-03', 456609, 11552.21, 'Pendente');
INSERT INTO ROYALTIES (IDroyalty, IDartista, PeriodoMesAno, TotalReproducoes, ValorTotalPago, StatusPagamento) VALUES (94, 54, '2025-02', 129471, 5929.77, 'Pendente');
INSERT INTO ROYALTIES (IDroyalty, IDartista, PeriodoMesAno, TotalReproducoes, ValorTotalPago, StatusPagamento) VALUES (95, 35, '2025-07', 440272, 18447.4, 'Pendente');
INSERT INTO ROYALTIES (IDroyalty, IDartista, PeriodoMesAno, TotalReproducoes, ValorTotalPago, StatusPagamento) VALUES (96, 22, '2024-09', 257529, 7494.09, 'Pendente');
INSERT INTO ROYALTIES (IDroyalty, IDartista, PeriodoMesAno, TotalReproducoes, ValorTotalPago, StatusPagamento) VALUES (97, 59, '2025-04', 59957, 2152.46, 'Pendente');
INSERT INTO ROYALTIES (IDroyalty, IDartista, PeriodoMesAno, TotalReproducoes, ValorTotalPago, StatusPagamento) VALUES (98, 66, '2024-02', 330926, 2217.2, 'Pago');
INSERT INTO ROYALTIES (IDroyalty, IDartista, PeriodoMesAno, TotalReproducoes, ValorTotalPago, StatusPagamento) VALUES (99, 86, '2024-07', 293671, 12334.18, 'Pago');
INSERT INTO ROYALTIES (IDroyalty, IDartista, PeriodoMesAno, TotalReproducoes, ValorTotalPago, StatusPagamento) VALUES (100, 37, '2024-04', 135257, 703.34, 'Pago');
 
-- ---------------- FAIXAS ----------------
INSERT INTO FAIXAS (IDfaixa, IDalbum, TituloFaixa, Duracao, ArquivoURL) VALUES (1, 34, 'Delírio #443', '3:59', 'https://cdn.tunestream.com/faixas/faixa_0001.mp3');
INSERT INTO FAIXAS (IDfaixa, IDalbum, TituloFaixa, Duracao, ArquivoURL) VALUES (2, 50, 'Recomeço #100', '4:26', 'https://cdn.tunestream.com/faixas/faixa_0002.mp3');
INSERT INTO FAIXAS (IDfaixa, IDalbum, TituloFaixa, Duracao, ArquivoURL) VALUES (3, 93, 'Fantasia #59', '4:09', 'https://cdn.tunestream.com/faixas/faixa_0003.mp3');
INSERT INTO FAIXAS (IDfaixa, IDalbum, TituloFaixa, Duracao, ArquivoURL) VALUES (4, 65, 'Amanhecer #453', '4:32', 'https://cdn.tunestream.com/faixas/faixa_0004.mp3');
INSERT INTO FAIXAS (IDfaixa, IDalbum, TituloFaixa, Duracao, ArquivoURL) VALUES (5, 1, 'Coragem #454', '6:18', 'https://cdn.tunestream.com/faixas/faixa_0005.mp3');
INSERT INTO FAIXAS (IDfaixa, IDalbum, TituloFaixa, Duracao, ArquivoURL) VALUES (6, 56, 'Fantasia #369', '2:58', 'https://cdn.tunestream.com/faixas/faixa_0006.mp3');
INSERT INTO FAIXAS (IDfaixa, IDalbum, TituloFaixa, Duracao, ArquivoURL) VALUES (7, 36, 'Batida #224', '6:11', 'https://cdn.tunestream.com/faixas/faixa_0007.mp3');
INSERT INTO FAIXAS (IDfaixa, IDalbum, TituloFaixa, Duracao, ArquivoURL) VALUES (8, 24, 'Coragem #864', '6:49', 'https://cdn.tunestream.com/faixas/faixa_0008.mp3');
INSERT INTO FAIXAS (IDfaixa, IDalbum, TituloFaixa, Duracao, ArquivoURL) VALUES (9, 23, 'Recomeço #729', '3:38', 'https://cdn.tunestream.com/faixas/faixa_0009.mp3');
INSERT INTO FAIXAS (IDfaixa, IDalbum, TituloFaixa, Duracao, ArquivoURL) VALUES (10, 12, 'Saudade #849', '6:46', 'https://cdn.tunestream.com/faixas/faixa_0010.mp3');
INSERT INTO FAIXAS (IDfaixa, IDalbum, TituloFaixa, Duracao, ArquivoURL) VALUES (11, 36, 'Ventania #780', '3:13', 'https://cdn.tunestream.com/faixas/faixa_0011.mp3');
INSERT INTO FAIXAS (IDfaixa, IDalbum, TituloFaixa, Duracao, ArquivoURL) VALUES (12, 86, 'Coragem #628', '3:37', 'https://cdn.tunestream.com/faixas/faixa_0012.mp3');
INSERT INTO FAIXAS (IDfaixa, IDalbum, TituloFaixa, Duracao, ArquivoURL) VALUES (13, 2, 'Horizonte #208', '2:44', 'https://cdn.tunestream.com/faixas/faixa_0013.mp3');
INSERT INTO FAIXAS (IDfaixa, IDalbum, TituloFaixa, Duracao, ArquivoURL) VALUES (14, 93, 'Constelação #418', '2:33', 'https://cdn.tunestream.com/faixas/faixa_0014.mp3');
INSERT INTO FAIXAS (IDfaixa, IDalbum, TituloFaixa, Duracao, ArquivoURL) VALUES (15, 37, 'Delírio #344', '5:05', 'https://cdn.tunestream.com/faixas/faixa_0015.mp3');
INSERT INTO FAIXAS (IDfaixa, IDalbum, TituloFaixa, Duracao, ArquivoURL) VALUES (16, 98, 'Amanhecer #420', '5:08', 'https://cdn.tunestream.com/faixas/faixa_0016.mp3');
INSERT INTO FAIXAS (IDfaixa, IDalbum, TituloFaixa, Duracao, ArquivoURL) VALUES (17, 24, 'Travessia #255', '6:53', 'https://cdn.tunestream.com/faixas/faixa_0017.mp3');
INSERT INTO FAIXAS (IDfaixa, IDalbum, TituloFaixa, Duracao, ArquivoURL) VALUES (18, 21, 'Delírio #38', '4:36', 'https://cdn.tunestream.com/faixas/faixa_0018.mp3');
INSERT INTO FAIXAS (IDfaixa, IDalbum, TituloFaixa, Duracao, ArquivoURL) VALUES (19, 1, 'Epifania #879', '4:33', 'https://cdn.tunestream.com/faixas/faixa_0019.mp3');
INSERT INTO FAIXAS (IDfaixa, IDalbum, TituloFaixa, Duracao, ArquivoURL) VALUES (20, 67, 'Aurora #992', '2:07', 'https://cdn.tunestream.com/faixas/faixa_0020.mp3');
INSERT INTO FAIXAS (IDfaixa, IDalbum, TituloFaixa, Duracao, ArquivoURL) VALUES (21, 32, 'Delírio #732', '4:49', 'https://cdn.tunestream.com/faixas/faixa_0021.mp3');
INSERT INTO FAIXAS (IDfaixa, IDalbum, TituloFaixa, Duracao, ArquivoURL) VALUES (22, 97, 'Refúgio #591', '2:18', 'https://cdn.tunestream.com/faixas/faixa_0022.mp3');
INSERT INTO FAIXAS (IDfaixa, IDalbum, TituloFaixa, Duracao, ArquivoURL) VALUES (23, 94, 'Ilusão #977', '5:28', 'https://cdn.tunestream.com/faixas/faixa_0023.mp3');
INSERT INTO FAIXAS (IDfaixa, IDalbum, TituloFaixa, Duracao, ArquivoURL) VALUES (24, 68, 'Constelação #27', '6:08', 'https://cdn.tunestream.com/faixas/faixa_0024.mp3');
INSERT INTO FAIXAS (IDfaixa, IDalbum, TituloFaixa, Duracao, ArquivoURL) VALUES (25, 12, 'Amanhecer #250', '3:39', 'https://cdn.tunestream.com/faixas/faixa_0025.mp3');
INSERT INTO FAIXAS (IDfaixa, IDalbum, TituloFaixa, Duracao, ArquivoURL) VALUES (26, 14, 'Fantasia #172', '4:16', 'https://cdn.tunestream.com/faixas/faixa_0026.mp3');
INSERT INTO FAIXAS (IDfaixa, IDalbum, TituloFaixa, Duracao, ArquivoURL) VALUES (27, 4, 'Vertigem #837', '2:06', 'https://cdn.tunestream.com/faixas/faixa_0027.mp3');
INSERT INTO FAIXAS (IDfaixa, IDalbum, TituloFaixa, Duracao, ArquivoURL) VALUES (28, 3, 'Paixão #268', '6:40', 'https://cdn.tunestream.com/faixas/faixa_0028.mp3');
INSERT INTO FAIXAS (IDfaixa, IDalbum, TituloFaixa, Duracao, ArquivoURL) VALUES (29, 67, 'Nostalgia #476', '3:44', 'https://cdn.tunestream.com/faixas/faixa_0029.mp3');
INSERT INTO FAIXAS (IDfaixa, IDalbum, TituloFaixa, Duracao, ArquivoURL) VALUES (30, 45, 'Aurora #106', '2:45', 'https://cdn.tunestream.com/faixas/faixa_0030.mp3');
INSERT INTO FAIXAS (IDfaixa, IDalbum, TituloFaixa, Duracao, ArquivoURL) VALUES (31, 35, 'Fantasia #47', '2:29', 'https://cdn.tunestream.com/faixas/faixa_0031.mp3');
INSERT INTO FAIXAS (IDfaixa, IDalbum, TituloFaixa, Duracao, ArquivoURL) VALUES (32, 65, 'Ventania #600', '4:07', 'https://cdn.tunestream.com/faixas/faixa_0032.mp3');
INSERT INTO FAIXAS (IDfaixa, IDalbum, TituloFaixa, Duracao, ArquivoURL) VALUES (33, 52, 'Ilusão #125', '3:34', 'https://cdn.tunestream.com/faixas/faixa_0033.mp3');
INSERT INTO FAIXAS (IDfaixa, IDalbum, TituloFaixa, Duracao, ArquivoURL) VALUES (34, 30, 'Nostalgia #233', '3:42', 'https://cdn.tunestream.com/faixas/faixa_0034.mp3');
INSERT INTO FAIXAS (IDfaixa, IDalbum, TituloFaixa, Duracao, ArquivoURL) VALUES (35, 96, 'Nostalgia #474', '5:10', 'https://cdn.tunestream.com/faixas/faixa_0035.mp3');
INSERT INTO FAIXAS (IDfaixa, IDalbum, TituloFaixa, Duracao, ArquivoURL) VALUES (36, 82, 'Amanhecer #961', '5:44', 'https://cdn.tunestream.com/faixas/faixa_0036.mp3');
INSERT INTO FAIXAS (IDfaixa, IDalbum, TituloFaixa, Duracao, ArquivoURL) VALUES (37, 78, 'Batida #612', '6:02', 'https://cdn.tunestream.com/faixas/faixa_0037.mp3');
INSERT INTO FAIXAS (IDfaixa, IDalbum, TituloFaixa, Duracao, ArquivoURL) VALUES (38, 7, 'Refúgio #994', '4:21', 'https://cdn.tunestream.com/faixas/faixa_0038.mp3');
INSERT INTO FAIXAS (IDfaixa, IDalbum, TituloFaixa, Duracao, ArquivoURL) VALUES (39, 43, 'Refúgio #247', '5:53', 'https://cdn.tunestream.com/faixas/faixa_0039.mp3');
INSERT INTO FAIXAS (IDfaixa, IDalbum, TituloFaixa, Duracao, ArquivoURL) VALUES (40, 42, 'Nostalgia #824', '5:54', 'https://cdn.tunestream.com/faixas/faixa_0040.mp3');
INSERT INTO FAIXAS (IDfaixa, IDalbum, TituloFaixa, Duracao, ArquivoURL) VALUES (41, 42, 'Vertigem #55', '6:09', 'https://cdn.tunestream.com/faixas/faixa_0041.mp3');
INSERT INTO FAIXAS (IDfaixa, IDalbum, TituloFaixa, Duracao, ArquivoURL) VALUES (42, 55, 'Delírio #256', '2:23', 'https://cdn.tunestream.com/faixas/faixa_0042.mp3');
INSERT INTO FAIXAS (IDfaixa, IDalbum, TituloFaixa, Duracao, ArquivoURL) VALUES (43, 24, 'Ilusão #544', '2:20', 'https://cdn.tunestream.com/faixas/faixa_0043.mp3');
INSERT INTO FAIXAS (IDfaixa, IDalbum, TituloFaixa, Duracao, ArquivoURL) VALUES (44, 65, 'Batida #206', '2:14', 'https://cdn.tunestream.com/faixas/faixa_0044.mp3');
INSERT INTO FAIXAS (IDfaixa, IDalbum, TituloFaixa, Duracao, ArquivoURL) VALUES (45, 51, 'Coragem #431', '5:40', 'https://cdn.tunestream.com/faixas/faixa_0045.mp3');
INSERT INTO FAIXAS (IDfaixa, IDalbum, TituloFaixa, Duracao, ArquivoURL) VALUES (46, 6, 'Liberdade #829', '2:55', 'https://cdn.tunestream.com/faixas/faixa_0046.mp3');
INSERT INTO FAIXAS (IDfaixa, IDalbum, TituloFaixa, Duracao, ArquivoURL) VALUES (47, 87, 'Epifania #273', '6:17', 'https://cdn.tunestream.com/faixas/faixa_0047.mp3');
INSERT INTO FAIXAS (IDfaixa, IDalbum, TituloFaixa, Duracao, ArquivoURL) VALUES (48, 5, 'Vertigem #826', '6:06', 'https://cdn.tunestream.com/faixas/faixa_0048.mp3');
INSERT INTO FAIXAS (IDfaixa, IDalbum, TituloFaixa, Duracao, ArquivoURL) VALUES (49, 67, 'Travessia #125', '2:27', 'https://cdn.tunestream.com/faixas/faixa_0049.mp3');
INSERT INTO FAIXAS (IDfaixa, IDalbum, TituloFaixa, Duracao, ArquivoURL) VALUES (50, 6, 'Recomeço #974', '4:07', 'https://cdn.tunestream.com/faixas/faixa_0050.mp3');
INSERT INTO FAIXAS (IDfaixa, IDalbum, TituloFaixa, Duracao, ArquivoURL) VALUES (51, 83, 'Horizonte #356', '3:07', 'https://cdn.tunestream.com/faixas/faixa_0051.mp3');
INSERT INTO FAIXAS (IDfaixa, IDalbum, TituloFaixa, Duracao, ArquivoURL) VALUES (52, 66, 'Liberdade #609', '4:05', 'https://cdn.tunestream.com/faixas/faixa_0052.mp3');
INSERT INTO FAIXAS (IDfaixa, IDalbum, TituloFaixa, Duracao, ArquivoURL) VALUES (53, 69, 'Aurora #605', '3:28', 'https://cdn.tunestream.com/faixas/faixa_0053.mp3');
INSERT INTO FAIXAS (IDfaixa, IDalbum, TituloFaixa, Duracao, ArquivoURL) VALUES (54, 17, 'Ilusão #524', '4:58', 'https://cdn.tunestream.com/faixas/faixa_0054.mp3');
INSERT INTO FAIXAS (IDfaixa, IDalbum, TituloFaixa, Duracao, ArquivoURL) VALUES (55, 37, 'Batida #592', '4:15', 'https://cdn.tunestream.com/faixas/faixa_0055.mp3');
INSERT INTO FAIXAS (IDfaixa, IDalbum, TituloFaixa, Duracao, ArquivoURL) VALUES (56, 70, 'Saudade #759', '4:53', 'https://cdn.tunestream.com/faixas/faixa_0056.mp3');
INSERT INTO FAIXAS (IDfaixa, IDalbum, TituloFaixa, Duracao, ArquivoURL) VALUES (57, 89, 'Aurora #625', '6:14', 'https://cdn.tunestream.com/faixas/faixa_0057.mp3');
INSERT INTO FAIXAS (IDfaixa, IDalbum, TituloFaixa, Duracao, ArquivoURL) VALUES (58, 71, 'Refúgio #207', '4:29', 'https://cdn.tunestream.com/faixas/faixa_0058.mp3');
INSERT INTO FAIXAS (IDfaixa, IDalbum, TituloFaixa, Duracao, ArquivoURL) VALUES (59, 79, 'Vertigem #311', '5:30', 'https://cdn.tunestream.com/faixas/faixa_0059.mp3');
INSERT INTO FAIXAS (IDfaixa, IDalbum, TituloFaixa, Duracao, ArquivoURL) VALUES (60, 32, 'Horizonte #32', '4:14', 'https://cdn.tunestream.com/faixas/faixa_0060.mp3');
INSERT INTO FAIXAS (IDfaixa, IDalbum, TituloFaixa, Duracao, ArquivoURL) VALUES (61, 70, 'Paixão #525', '5:37', 'https://cdn.tunestream.com/faixas/faixa_0061.mp3');
INSERT INTO FAIXAS (IDfaixa, IDalbum, TituloFaixa, Duracao, ArquivoURL) VALUES (62, 46, 'Refúgio #13', '3:55', 'https://cdn.tunestream.com/faixas/faixa_0062.mp3');
INSERT INTO FAIXAS (IDfaixa, IDalbum, TituloFaixa, Duracao, ArquivoURL) VALUES (63, 72, 'Recomeço #332', '4:31', 'https://cdn.tunestream.com/faixas/faixa_0063.mp3');
INSERT INTO FAIXAS (IDfaixa, IDalbum, TituloFaixa, Duracao, ArquivoURL) VALUES (64, 28, 'Travessia #292', '4:03', 'https://cdn.tunestream.com/faixas/faixa_0064.mp3');
INSERT INTO FAIXAS (IDfaixa, IDalbum, TituloFaixa, Duracao, ArquivoURL) VALUES (65, 71, 'Amanhecer #163', '2:38', 'https://cdn.tunestream.com/faixas/faixa_0065.mp3');
INSERT INTO FAIXAS (IDfaixa, IDalbum, TituloFaixa, Duracao, ArquivoURL) VALUES (66, 85, 'Delírio #451', '2:33', 'https://cdn.tunestream.com/faixas/faixa_0066.mp3');
INSERT INTO FAIXAS (IDfaixa, IDalbum, TituloFaixa, Duracao, ArquivoURL) VALUES (67, 57, 'Refúgio #855', '4:47', 'https://cdn.tunestream.com/faixas/faixa_0067.mp3');
INSERT INTO FAIXAS (IDfaixa, IDalbum, TituloFaixa, Duracao, ArquivoURL) VALUES (68, 29, 'Ilusão #534', '3:26', 'https://cdn.tunestream.com/faixas/faixa_0068.mp3');
INSERT INTO FAIXAS (IDfaixa, IDalbum, TituloFaixa, Duracao, ArquivoURL) VALUES (69, 46, 'Presságio #685', '3:43', 'https://cdn.tunestream.com/faixas/faixa_0069.mp3');
INSERT INTO FAIXAS (IDfaixa, IDalbum, TituloFaixa, Duracao, ArquivoURL) VALUES (70, 79, 'Paixão #632', '4:52', 'https://cdn.tunestream.com/faixas/faixa_0070.mp3');
INSERT INTO FAIXAS (IDfaixa, IDalbum, TituloFaixa, Duracao, ArquivoURL) VALUES (71, 95, 'Constelação #98', '5:17', 'https://cdn.tunestream.com/faixas/faixa_0071.mp3');
INSERT INTO FAIXAS (IDfaixa, IDalbum, TituloFaixa, Duracao, ArquivoURL) VALUES (72, 14, 'Coragem #423', '2:26', 'https://cdn.tunestream.com/faixas/faixa_0072.mp3');
INSERT INTO FAIXAS (IDfaixa, IDalbum, TituloFaixa, Duracao, ArquivoURL) VALUES (73, 16, 'Vertigem #600', '5:25', 'https://cdn.tunestream.com/faixas/faixa_0073.mp3');
INSERT INTO FAIXAS (IDfaixa, IDalbum, TituloFaixa, Duracao, ArquivoURL) VALUES (74, 54, 'Nostalgia #154', '4:55', 'https://cdn.tunestream.com/faixas/faixa_0074.mp3');
INSERT INTO FAIXAS (IDfaixa, IDalbum, TituloFaixa, Duracao, ArquivoURL) VALUES (75, 15, 'Epifania #622', '5:54', 'https://cdn.tunestream.com/faixas/faixa_0075.mp3');
INSERT INTO FAIXAS (IDfaixa, IDalbum, TituloFaixa, Duracao, ArquivoURL) VALUES (76, 59, 'Aurora #710', '4:46', 'https://cdn.tunestream.com/faixas/faixa_0076.mp3');
INSERT INTO FAIXAS (IDfaixa, IDalbum, TituloFaixa, Duracao, ArquivoURL) VALUES (77, 46, 'Delírio #300', '5:33', 'https://cdn.tunestream.com/faixas/faixa_0077.mp3');
INSERT INTO FAIXAS (IDfaixa, IDalbum, TituloFaixa, Duracao, ArquivoURL) VALUES (78, 50, 'Vertigem #610', '4:00', 'https://cdn.tunestream.com/faixas/faixa_0078.mp3');
INSERT INTO FAIXAS (IDfaixa, IDalbum, TituloFaixa, Duracao, ArquivoURL) VALUES (79, 57, 'Ventania #390', '4:11', 'https://cdn.tunestream.com/faixas/faixa_0079.mp3');
INSERT INTO FAIXAS (IDfaixa, IDalbum, TituloFaixa, Duracao, ArquivoURL) VALUES (80, 19, 'Vertigem #312', '5:36', 'https://cdn.tunestream.com/faixas/faixa_0080.mp3');
INSERT INTO FAIXAS (IDfaixa, IDalbum, TituloFaixa, Duracao, ArquivoURL) VALUES (81, 30, 'Refúgio #596', '2:52', 'https://cdn.tunestream.com/faixas/faixa_0081.mp3');
INSERT INTO FAIXAS (IDfaixa, IDalbum, TituloFaixa, Duracao, ArquivoURL) VALUES (82, 78, 'Presságio #332', '3:20', 'https://cdn.tunestream.com/faixas/faixa_0082.mp3');
INSERT INTO FAIXAS (IDfaixa, IDalbum, TituloFaixa, Duracao, ArquivoURL) VALUES (83, 55, 'Paixão #996', '2:01', 'https://cdn.tunestream.com/faixas/faixa_0083.mp3');
INSERT INTO FAIXAS (IDfaixa, IDalbum, TituloFaixa, Duracao, ArquivoURL) VALUES (84, 73, 'Liberdade #263', '5:19', 'https://cdn.tunestream.com/faixas/faixa_0084.mp3');
INSERT INTO FAIXAS (IDfaixa, IDalbum, TituloFaixa, Duracao, ArquivoURL) VALUES (85, 40, 'Vertigem #793', '6:39', 'https://cdn.tunestream.com/faixas/faixa_0085.mp3');
INSERT INTO FAIXAS (IDfaixa, IDalbum, TituloFaixa, Duracao, ArquivoURL) VALUES (86, 67, 'Batida #530', '5:24', 'https://cdn.tunestream.com/faixas/faixa_0086.mp3');
INSERT INTO FAIXAS (IDfaixa, IDalbum, TituloFaixa, Duracao, ArquivoURL) VALUES (87, 6, 'Aurora #367', '6:43', 'https://cdn.tunestream.com/faixas/faixa_0087.mp3');
INSERT INTO FAIXAS (IDfaixa, IDalbum, TituloFaixa, Duracao, ArquivoURL) VALUES (88, 2, 'Delírio #464', '2:33', 'https://cdn.tunestream.com/faixas/faixa_0088.mp3');
INSERT INTO FAIXAS (IDfaixa, IDalbum, TituloFaixa, Duracao, ArquivoURL) VALUES (89, 53, 'Recomeço #102', '4:32', 'https://cdn.tunestream.com/faixas/faixa_0089.mp3');
INSERT INTO FAIXAS (IDfaixa, IDalbum, TituloFaixa, Duracao, ArquivoURL) VALUES (90, 72, 'Refúgio #665', '6:09', 'https://cdn.tunestream.com/faixas/faixa_0090.mp3');
INSERT INTO FAIXAS (IDfaixa, IDalbum, TituloFaixa, Duracao, ArquivoURL) VALUES (91, 54, 'Paixão #988', '5:25', 'https://cdn.tunestream.com/faixas/faixa_0091.mp3');
INSERT INTO FAIXAS (IDfaixa, IDalbum, TituloFaixa, Duracao, ArquivoURL) VALUES (92, 80, 'Aurora #786', '6:21', 'https://cdn.tunestream.com/faixas/faixa_0092.mp3');
INSERT INTO FAIXAS (IDfaixa, IDalbum, TituloFaixa, Duracao, ArquivoURL) VALUES (93, 12, 'Constelação #765', '3:23', 'https://cdn.tunestream.com/faixas/faixa_0093.mp3');
INSERT INTO FAIXAS (IDfaixa, IDalbum, TituloFaixa, Duracao, ArquivoURL) VALUES (94, 10, 'Presságio #376', '4:32', 'https://cdn.tunestream.com/faixas/faixa_0094.mp3');
INSERT INTO FAIXAS (IDfaixa, IDalbum, TituloFaixa, Duracao, ArquivoURL) VALUES (95, 84, 'Fantasia #114', '4:44', 'https://cdn.tunestream.com/faixas/faixa_0095.mp3');
INSERT INTO FAIXAS (IDfaixa, IDalbum, TituloFaixa, Duracao, ArquivoURL) VALUES (96, 66, 'Presságio #841', '5:40', 'https://cdn.tunestream.com/faixas/faixa_0096.mp3');
INSERT INTO FAIXAS (IDfaixa, IDalbum, TituloFaixa, Duracao, ArquivoURL) VALUES (97, 38, 'Fantasia #537', '6:13', 'https://cdn.tunestream.com/faixas/faixa_0097.mp3');
INSERT INTO FAIXAS (IDfaixa, IDalbum, TituloFaixa, Duracao, ArquivoURL) VALUES (98, 25, 'Constelação #915', '5:11', 'https://cdn.tunestream.com/faixas/faixa_0098.mp3');
INSERT INTO FAIXAS (IDfaixa, IDalbum, TituloFaixa, Duracao, ArquivoURL) VALUES (99, 73, 'Liberdade #646', '6:06', 'https://cdn.tunestream.com/faixas/faixa_0099.mp3');
INSERT INTO FAIXAS (IDfaixa, IDalbum, TituloFaixa, Duracao, ArquivoURL) VALUES (100, 81, 'Delírio #584', '2:44', 'https://cdn.tunestream.com/faixas/faixa_0100.mp3');
 
-- ---------------- PLAYLIST_FAIXAS ----------------
INSERT INTO PLAYLIST_FAIXAS (IDplaylist, IDfaixa, DataAdicao) VALUES (53, 2, '2025-03-17');
INSERT INTO PLAYLIST_FAIXAS (IDplaylist, IDfaixa, DataAdicao) VALUES (1, 40, '2024-12-28');
INSERT INTO PLAYLIST_FAIXAS (IDplaylist, IDfaixa, DataAdicao) VALUES (89, 71, '2023-01-05');
INSERT INTO PLAYLIST_FAIXAS (IDplaylist, IDfaixa, DataAdicao) VALUES (39, 51, '2025-05-12');
INSERT INTO PLAYLIST_FAIXAS (IDplaylist, IDfaixa, DataAdicao) VALUES (13, 76, '2023-01-16');
INSERT INTO PLAYLIST_FAIXAS (IDplaylist, IDfaixa, DataAdicao) VALUES (86, 4, '2023-07-21');
INSERT INTO PLAYLIST_FAIXAS (IDplaylist, IDfaixa, DataAdicao) VALUES (23, 64, '2025-02-26');
INSERT INTO PLAYLIST_FAIXAS (IDplaylist, IDfaixa, DataAdicao) VALUES (71, 73, '2023-09-30');
INSERT INTO PLAYLIST_FAIXAS (IDplaylist, IDfaixa, DataAdicao) VALUES (83, 69, '2024-06-10');
INSERT INTO PLAYLIST_FAIXAS (IDplaylist, IDfaixa, DataAdicao) VALUES (19, 74, '2023-07-23');
INSERT INTO PLAYLIST_FAIXAS (IDplaylist, IDfaixa, DataAdicao) VALUES (53, 78, '2023-05-05');
INSERT INTO PLAYLIST_FAIXAS (IDplaylist, IDfaixa, DataAdicao) VALUES (19, 21, '2024-06-14');
INSERT INTO PLAYLIST_FAIXAS (IDplaylist, IDfaixa, DataAdicao) VALUES (98, 66, '2023-04-20');
INSERT INTO PLAYLIST_FAIXAS (IDplaylist, IDfaixa, DataAdicao) VALUES (4, 13, '2023-03-19');
INSERT INTO PLAYLIST_FAIXAS (IDplaylist, IDfaixa, DataAdicao) VALUES (22, 67, '2024-05-17');
INSERT INTO PLAYLIST_FAIXAS (IDplaylist, IDfaixa, DataAdicao) VALUES (60, 79, '2024-03-16');
INSERT INTO PLAYLIST_FAIXAS (IDplaylist, IDfaixa, DataAdicao) VALUES (8, 84, '2023-01-13');
INSERT INTO PLAYLIST_FAIXAS (IDplaylist, IDfaixa, DataAdicao) VALUES (88, 99, '2024-08-15');
INSERT INTO PLAYLIST_FAIXAS (IDplaylist, IDfaixa, DataAdicao) VALUES (42, 19, '2025-01-02');
INSERT INTO PLAYLIST_FAIXAS (IDplaylist, IDfaixa, DataAdicao) VALUES (31, 46, '2023-10-10');
INSERT INTO PLAYLIST_FAIXAS (IDplaylist, IDfaixa, DataAdicao) VALUES (22, 5, '2023-10-01');
INSERT INTO PLAYLIST_FAIXAS (IDplaylist, IDfaixa, DataAdicao) VALUES (81, 13, '2025-05-29');
INSERT INTO PLAYLIST_FAIXAS (IDplaylist, IDfaixa, DataAdicao) VALUES (75, 9, '2023-12-24');
INSERT INTO PLAYLIST_FAIXAS (IDplaylist, IDfaixa, DataAdicao) VALUES (25, 58, '2024-09-30');
INSERT INTO PLAYLIST_FAIXAS (IDplaylist, IDfaixa, DataAdicao) VALUES (50, 3, '2023-02-25');
INSERT INTO PLAYLIST_FAIXAS (IDplaylist, IDfaixa, DataAdicao) VALUES (29, 51, '2024-08-19');
INSERT INTO PLAYLIST_FAIXAS (IDplaylist, IDfaixa, DataAdicao) VALUES (98, 6, '2024-03-26');
INSERT INTO PLAYLIST_FAIXAS (IDplaylist, IDfaixa, DataAdicao) VALUES (7, 80, '2023-09-02');
INSERT INTO PLAYLIST_FAIXAS (IDplaylist, IDfaixa, DataAdicao) VALUES (32, 29, '2023-02-15');
INSERT INTO PLAYLIST_FAIXAS (IDplaylist, IDfaixa, DataAdicao) VALUES (21, 76, '2025-05-25');
INSERT INTO PLAYLIST_FAIXAS (IDplaylist, IDfaixa, DataAdicao) VALUES (23, 41, '2023-01-07');
INSERT INTO PLAYLIST_FAIXAS (IDplaylist, IDfaixa, DataAdicao) VALUES (59, 39, '2024-03-04');
INSERT INTO PLAYLIST_FAIXAS (IDplaylist, IDfaixa, DataAdicao) VALUES (78, 33, '2024-05-22');
INSERT INTO PLAYLIST_FAIXAS (IDplaylist, IDfaixa, DataAdicao) VALUES (9, 32, '2024-11-24');
INSERT INTO PLAYLIST_FAIXAS (IDplaylist, IDfaixa, DataAdicao) VALUES (50, 87, '2025-01-05');
INSERT INTO PLAYLIST_FAIXAS (IDplaylist, IDfaixa, DataAdicao) VALUES (75, 29, '2024-02-28');
INSERT INTO PLAYLIST_FAIXAS (IDplaylist, IDfaixa, DataAdicao) VALUES (40, 52, '2025-06-15');
INSERT INTO PLAYLIST_FAIXAS (IDplaylist, IDfaixa, DataAdicao) VALUES (92, 63, '2023-01-23');
INSERT INTO PLAYLIST_FAIXAS (IDplaylist, IDfaixa, DataAdicao) VALUES (32, 12, '2023-06-27');
INSERT INTO PLAYLIST_FAIXAS (IDplaylist, IDfaixa, DataAdicao) VALUES (22, 46, '2024-01-24');
INSERT INTO PLAYLIST_FAIXAS (IDplaylist, IDfaixa, DataAdicao) VALUES (24, 1, '2023-10-25');
INSERT INTO PLAYLIST_FAIXAS (IDplaylist, IDfaixa, DataAdicao) VALUES (51, 72, '2024-01-07');
INSERT INTO PLAYLIST_FAIXAS (IDplaylist, IDfaixa, DataAdicao) VALUES (15, 43, '2024-06-30');
INSERT INTO PLAYLIST_FAIXAS (IDplaylist, IDfaixa, DataAdicao) VALUES (50, 43, '2024-02-17');
INSERT INTO PLAYLIST_FAIXAS (IDplaylist, IDfaixa, DataAdicao) VALUES (84, 9, '2023-05-07');
INSERT INTO PLAYLIST_FAIXAS (IDplaylist, IDfaixa, DataAdicao) VALUES (55, 45, '2024-07-21');
INSERT INTO PLAYLIST_FAIXAS (IDplaylist, IDfaixa, DataAdicao) VALUES (32, 50, '2023-07-15');
INSERT INTO PLAYLIST_FAIXAS (IDplaylist, IDfaixa, DataAdicao) VALUES (60, 37, '2023-12-19');
INSERT INTO PLAYLIST_FAIXAS (IDplaylist, IDfaixa, DataAdicao) VALUES (31, 56, '2023-02-05');
INSERT INTO PLAYLIST_FAIXAS (IDplaylist, IDfaixa, DataAdicao) VALUES (36, 86, '2023-01-26');
INSERT INTO PLAYLIST_FAIXAS (IDplaylist, IDfaixa, DataAdicao) VALUES (44, 20, '2023-09-05');
INSERT INTO PLAYLIST_FAIXAS (IDplaylist, IDfaixa, DataAdicao) VALUES (91, 17, '2023-04-05');
INSERT INTO PLAYLIST_FAIXAS (IDplaylist, IDfaixa, DataAdicao) VALUES (26, 35, '2024-07-11');
INSERT INTO PLAYLIST_FAIXAS (IDplaylist, IDfaixa, DataAdicao) VALUES (17, 72, '2024-03-29');
INSERT INTO PLAYLIST_FAIXAS (IDplaylist, IDfaixa, DataAdicao) VALUES (60, 31, '2023-06-13');
INSERT INTO PLAYLIST_FAIXAS (IDplaylist, IDfaixa, DataAdicao) VALUES (48, 46, '2023-08-10');
INSERT INTO PLAYLIST_FAIXAS (IDplaylist, IDfaixa, DataAdicao) VALUES (93, 52, '2024-01-21');
INSERT INTO PLAYLIST_FAIXAS (IDplaylist, IDfaixa, DataAdicao) VALUES (81, 75, '2023-08-02');
INSERT INTO PLAYLIST_FAIXAS (IDplaylist, IDfaixa, DataAdicao) VALUES (39, 61, '2024-05-31');
INSERT INTO PLAYLIST_FAIXAS (IDplaylist, IDfaixa, DataAdicao) VALUES (27, 30, '2025-05-28');
INSERT INTO PLAYLIST_FAIXAS (IDplaylist, IDfaixa, DataAdicao) VALUES (58, 87, '2023-05-15');
INSERT INTO PLAYLIST_FAIXAS (IDplaylist, IDfaixa, DataAdicao) VALUES (91, 34, '2024-09-02');
INSERT INTO PLAYLIST_FAIXAS (IDplaylist, IDfaixa, DataAdicao) VALUES (57, 76, '2024-01-12');
INSERT INTO PLAYLIST_FAIXAS (IDplaylist, IDfaixa, DataAdicao) VALUES (69, 32, '2024-02-18');
INSERT INTO PLAYLIST_FAIXAS (IDplaylist, IDfaixa, DataAdicao) VALUES (78, 66, '2023-08-06');
INSERT INTO PLAYLIST_FAIXAS (IDplaylist, IDfaixa, DataAdicao) VALUES (17, 97, '2023-05-06');
INSERT INTO PLAYLIST_FAIXAS (IDplaylist, IDfaixa, DataAdicao) VALUES (87, 66, '2023-04-04');
INSERT INTO PLAYLIST_FAIXAS (IDplaylist, IDfaixa, DataAdicao) VALUES (70, 35, '2025-01-23');
INSERT INTO PLAYLIST_FAIXAS (IDplaylist, IDfaixa, DataAdicao) VALUES (99, 98, '2024-01-30');
INSERT INTO PLAYLIST_FAIXAS (IDplaylist, IDfaixa, DataAdicao) VALUES (4, 85, '2025-01-05');
INSERT INTO PLAYLIST_FAIXAS (IDplaylist, IDfaixa, DataAdicao) VALUES (73, 19, '2023-11-15');
INSERT INTO PLAYLIST_FAIXAS (IDplaylist, IDfaixa, DataAdicao) VALUES (2, 50, '2024-12-28');
INSERT INTO PLAYLIST_FAIXAS (IDplaylist, IDfaixa, DataAdicao) VALUES (12, 89, '2023-07-01');
INSERT INTO PLAYLIST_FAIXAS (IDplaylist, IDfaixa, DataAdicao) VALUES (100, 30, '2023-11-25');
INSERT INTO PLAYLIST_FAIXAS (IDplaylist, IDfaixa, DataAdicao) VALUES (25, 85, '2023-04-22');
INSERT INTO PLAYLIST_FAIXAS (IDplaylist, IDfaixa, DataAdicao) VALUES (9, 72, '2024-01-06');
INSERT INTO PLAYLIST_FAIXAS (IDplaylist, IDfaixa, DataAdicao) VALUES (65, 98, '2023-11-01');
INSERT INTO PLAYLIST_FAIXAS (IDplaylist, IDfaixa, DataAdicao) VALUES (25, 9, '2025-01-05');
INSERT INTO PLAYLIST_FAIXAS (IDplaylist, IDfaixa, DataAdicao) VALUES (40, 12, '2023-08-20');
INSERT INTO PLAYLIST_FAIXAS (IDplaylist, IDfaixa, DataAdicao) VALUES (37, 17, '2025-04-16');
INSERT INTO PLAYLIST_FAIXAS (IDplaylist, IDfaixa, DataAdicao) VALUES (92, 52, '2023-10-17');
INSERT INTO PLAYLIST_FAIXAS (IDplaylist, IDfaixa, DataAdicao) VALUES (46, 52, '2025-05-14');
INSERT INTO PLAYLIST_FAIXAS (IDplaylist, IDfaixa, DataAdicao) VALUES (60, 100, '2024-10-05');
INSERT INTO PLAYLIST_FAIXAS (IDplaylist, IDfaixa, DataAdicao) VALUES (81, 17, '2023-10-11');
INSERT INTO PLAYLIST_FAIXAS (IDplaylist, IDfaixa, DataAdicao) VALUES (23, 4, '2024-01-11');
INSERT INTO PLAYLIST_FAIXAS (IDplaylist, IDfaixa, DataAdicao) VALUES (87, 85, '2024-12-08');
INSERT INTO PLAYLIST_FAIXAS (IDplaylist, IDfaixa, DataAdicao) VALUES (45, 53, '2023-01-26');
INSERT INTO PLAYLIST_FAIXAS (IDplaylist, IDfaixa, DataAdicao) VALUES (85, 91, '2024-12-17');
INSERT INTO PLAYLIST_FAIXAS (IDplaylist, IDfaixa, DataAdicao) VALUES (60, 32, '2025-05-17');
INSERT INTO PLAYLIST_FAIXAS (IDplaylist, IDfaixa, DataAdicao) VALUES (52, 46, '2024-10-05');
INSERT INTO PLAYLIST_FAIXAS (IDplaylist, IDfaixa, DataAdicao) VALUES (13, 24, '2023-10-26');
INSERT INTO PLAYLIST_FAIXAS (IDplaylist, IDfaixa, DataAdicao) VALUES (15, 35, '2024-09-15');
INSERT INTO PLAYLIST_FAIXAS (IDplaylist, IDfaixa, DataAdicao) VALUES (94, 29, '2024-12-30');
INSERT INTO PLAYLIST_FAIXAS (IDplaylist, IDfaixa, DataAdicao) VALUES (87, 6, '2024-02-19');
INSERT INTO PLAYLIST_FAIXAS (IDplaylist, IDfaixa, DataAdicao) VALUES (6, 78, '2023-06-15');
INSERT INTO PLAYLIST_FAIXAS (IDplaylist, IDfaixa, DataAdicao) VALUES (56, 26, '2025-02-14');
INSERT INTO PLAYLIST_FAIXAS (IDplaylist, IDfaixa, DataAdicao) VALUES (39, 20, '2024-01-25');
INSERT INTO PLAYLIST_FAIXAS (IDplaylist, IDfaixa, DataAdicao) VALUES (95, 6, '2024-07-19');
INSERT INTO PLAYLIST_FAIXAS (IDplaylist, IDfaixa, DataAdicao) VALUES (40, 81, '2024-10-15');
INSERT INTO PLAYLIST_FAIXAS (IDplaylist, IDfaixa, DataAdicao) VALUES (23, 73, '2025-05-09');
 
-- ---------------- HISTORICO ----------------
INSERT INTO HISTORICO (IDhistorico, IDusuario, IDfaixa, DataHoraReproducao) VALUES (1, 30, 73, '2024-05-24 00:00:00');
INSERT INTO HISTORICO (IDhistorico, IDusuario, IDfaixa, DataHoraReproducao) VALUES (2, 56, 86, '2024-12-01 00:00:00');
INSERT INTO HISTORICO (IDhistorico, IDusuario, IDfaixa, DataHoraReproducao) VALUES (3, 1, 15, '2025-05-04 00:00:00');
INSERT INTO HISTORICO (IDhistorico, IDusuario, IDfaixa, DataHoraReproducao) VALUES (4, 6, 75, '2024-09-13 00:00:00');
INSERT INTO HISTORICO (IDhistorico, IDusuario, IDfaixa, DataHoraReproducao) VALUES (5, 88, 15, '2023-02-08 00:00:00');
INSERT INTO HISTORICO (IDhistorico, IDusuario, IDfaixa, DataHoraReproducao) VALUES (6, 45, 96, '2023-03-30 00:00:00');
INSERT INTO HISTORICO (IDhistorico, IDusuario, IDfaixa, DataHoraReproducao) VALUES (7, 51, 96, '2024-09-22 00:00:00');
INSERT INTO HISTORICO (IDhistorico, IDusuario, IDfaixa, DataHoraReproducao) VALUES (8, 12, 45, '2024-03-10 00:00:00');
INSERT INTO HISTORICO (IDhistorico, IDusuario, IDfaixa, DataHoraReproducao) VALUES (9, 89, 65, '2025-01-26 00:00:00');
INSERT INTO HISTORICO (IDhistorico, IDusuario, IDfaixa, DataHoraReproducao) VALUES (10, 81, 81, '2024-04-08 00:00:00');
INSERT INTO HISTORICO (IDhistorico, IDusuario, IDfaixa, DataHoraReproducao) VALUES (11, 90, 27, '2024-03-14 00:00:00');
INSERT INTO HISTORICO (IDhistorico, IDusuario, IDfaixa, DataHoraReproducao) VALUES (12, 100, 17, '2024-05-16 00:00:00');
INSERT INTO HISTORICO (IDhistorico, IDusuario, IDfaixa, DataHoraReproducao) VALUES (13, 72, 34, '2023-06-28 00:00:00');
INSERT INTO HISTORICO (IDhistorico, IDusuario, IDfaixa, DataHoraReproducao) VALUES (14, 82, 31, '2024-07-10 00:00:00');
INSERT INTO HISTORICO (IDhistorico, IDusuario, IDfaixa, DataHoraReproducao) VALUES (15, 22, 46, '2023-12-22 00:00:00');
INSERT INTO HISTORICO (IDhistorico, IDusuario, IDfaixa, DataHoraReproducao) VALUES (16, 82, 40, '2023-05-21 00:00:00');
INSERT INTO HISTORICO (IDhistorico, IDusuario, IDfaixa, DataHoraReproducao) VALUES (17, 63, 86, '2024-05-09 00:00:00');
INSERT INTO HISTORICO (IDhistorico, IDusuario, IDfaixa, DataHoraReproducao) VALUES (18, 1, 66, '2024-12-09 00:00:00');
INSERT INTO HISTORICO (IDhistorico, IDusuario, IDfaixa, DataHoraReproducao) VALUES (19, 83, 45, '2024-12-15 00:00:00');
INSERT INTO HISTORICO (IDhistorico, IDusuario, IDfaixa, DataHoraReproducao) VALUES (20, 91, 19, '2024-08-24 00:00:00');
INSERT INTO HISTORICO (IDhistorico, IDusuario, IDfaixa, DataHoraReproducao) VALUES (21, 81, 16, '2024-07-15 00:00:00');
INSERT INTO HISTORICO (IDhistorico, IDusuario, IDfaixa, DataHoraReproducao) VALUES (22, 87, 86, '2023-06-08 00:00:00');
INSERT INTO HISTORICO (IDhistorico, IDusuario, IDfaixa, DataHoraReproducao) VALUES (23, 99, 52, '2025-05-01 00:00:00');
INSERT INTO HISTORICO (IDhistorico, IDusuario, IDfaixa, DataHoraReproducao) VALUES (24, 38, 2, '2024-01-05 00:00:00');
INSERT INTO HISTORICO (IDhistorico, IDusuario, IDfaixa, DataHoraReproducao) VALUES (25, 8, 36, '2023-11-08 00:00:00');
INSERT INTO HISTORICO (IDhistorico, IDusuario, IDfaixa, DataHoraReproducao) VALUES (26, 40, 58, '2023-04-26 00:00:00');
INSERT INTO HISTORICO (IDhistorico, IDusuario, IDfaixa, DataHoraReproducao) VALUES (27, 60, 73, '2024-01-07 00:00:00');
INSERT INTO HISTORICO (IDhistorico, IDusuario, IDfaixa, DataHoraReproducao) VALUES (28, 10, 6, '2023-01-12 00:00:00');
INSERT INTO HISTORICO (IDhistorico, IDusuario, IDfaixa, DataHoraReproducao) VALUES (29, 11, 96, '2025-01-04 00:00:00');
INSERT INTO HISTORICO (IDhistorico, IDusuario, IDfaixa, DataHoraReproducao) VALUES (30, 34, 14, '2024-10-22 00:00:00');
INSERT INTO HISTORICO (IDhistorico, IDusuario, IDfaixa, DataHoraReproducao) VALUES (31, 25, 70, '2023-11-26 00:00:00');
INSERT INTO HISTORICO (IDhistorico, IDusuario, IDfaixa, DataHoraReproducao) VALUES (32, 12, 83, '2023-10-20 00:00:00');
INSERT INTO HISTORICO (IDhistorico, IDusuario, IDfaixa, DataHoraReproducao) VALUES (33, 94, 84, '2024-12-17 00:00:00');
INSERT INTO HISTORICO (IDhistorico, IDusuario, IDfaixa, DataHoraReproducao) VALUES (34, 11, 18, '2025-02-04 00:00:00');
INSERT INTO HISTORICO (IDhistorico, IDusuario, IDfaixa, DataHoraReproducao) VALUES (35, 51, 19, '2023-10-31 00:00:00');
INSERT INTO HISTORICO (IDhistorico, IDusuario, IDfaixa, DataHoraReproducao) VALUES (36, 68, 88, '2023-06-22 00:00:00');
INSERT INTO HISTORICO (IDhistorico, IDusuario, IDfaixa, DataHoraReproducao) VALUES (37, 40, 96, '2024-09-23 00:00:00');
INSERT INTO HISTORICO (IDhistorico, IDusuario, IDfaixa, DataHoraReproducao) VALUES (38, 83, 46, '2023-11-24 00:00:00');
INSERT INTO HISTORICO (IDhistorico, IDusuario, IDfaixa, DataHoraReproducao) VALUES (39, 71, 48, '2025-05-07 00:00:00');
INSERT INTO HISTORICO (IDhistorico, IDusuario, IDfaixa, DataHoraReproducao) VALUES (40, 6, 14, '2024-08-03 00:00:00');
INSERT INTO HISTORICO (IDhistorico, IDusuario, IDfaixa, DataHoraReproducao) VALUES (41, 91, 52, '2023-02-21 00:00:00');
INSERT INTO HISTORICO (IDhistorico, IDusuario, IDfaixa, DataHoraReproducao) VALUES (42, 64, 94, '2023-06-11 00:00:00');
INSERT INTO HISTORICO (IDhistorico, IDusuario, IDfaixa, DataHoraReproducao) VALUES (43, 81, 11, '2023-05-26 00:00:00');
INSERT INTO HISTORICO (IDhistorico, IDusuario, IDfaixa, DataHoraReproducao) VALUES (44, 18, 57, '2024-10-14 00:00:00');
INSERT INTO HISTORICO (IDhistorico, IDusuario, IDfaixa, DataHoraReproducao) VALUES (45, 57, 62, '2023-07-15 00:00:00');
INSERT INTO HISTORICO (IDhistorico, IDusuario, IDfaixa, DataHoraReproducao) VALUES (46, 1, 5, '2025-05-11 00:00:00');
INSERT INTO HISTORICO (IDhistorico, IDusuario, IDfaixa, DataHoraReproducao) VALUES (47, 66, 55, '2023-05-27 00:00:00');
INSERT INTO HISTORICO (IDhistorico, IDusuario, IDfaixa, DataHoraReproducao) VALUES (48, 8, 66, '2024-12-28 00:00:00');
INSERT INTO HISTORICO (IDhistorico, IDusuario, IDfaixa, DataHoraReproducao) VALUES (49, 9, 57, '2023-01-10 00:00:00');
INSERT INTO HISTORICO (IDhistorico, IDusuario, IDfaixa, DataHoraReproducao) VALUES (50, 93, 22, '2024-01-23 00:00:00');
INSERT INTO HISTORICO (IDhistorico, IDusuario, IDfaixa, DataHoraReproducao) VALUES (51, 73, 87, '2023-12-23 00:00:00');
INSERT INTO HISTORICO (IDhistorico, IDusuario, IDfaixa, DataHoraReproducao) VALUES (52, 11, 70, '2023-11-28 00:00:00');
INSERT INTO HISTORICO (IDhistorico, IDusuario, IDfaixa, DataHoraReproducao) VALUES (53, 69, 81, '2025-06-05 00:00:00');
INSERT INTO HISTORICO (IDhistorico, IDusuario, IDfaixa, DataHoraReproducao) VALUES (54, 80, 11, '2025-04-10 00:00:00');
INSERT INTO HISTORICO (IDhistorico, IDusuario, IDfaixa, DataHoraReproducao) VALUES (55, 43, 78, '2024-11-05 00:00:00');
INSERT INTO HISTORICO (IDhistorico, IDusuario, IDfaixa, DataHoraReproducao) VALUES (56, 54, 48, '2024-05-07 00:00:00');
INSERT INTO HISTORICO (IDhistorico, IDusuario, IDfaixa, DataHoraReproducao) VALUES (57, 39, 44, '2024-06-27 00:00:00');
INSERT INTO HISTORICO (IDhistorico, IDusuario, IDfaixa, DataHoraReproducao) VALUES (58, 25, 29, '2024-11-25 00:00:00');
INSERT INTO HISTORICO (IDhistorico, IDusuario, IDfaixa, DataHoraReproducao) VALUES (59, 11, 19, '2024-11-07 00:00:00');
INSERT INTO HISTORICO (IDhistorico, IDusuario, IDfaixa, DataHoraReproducao) VALUES (60, 75, 54, '2024-01-04 00:00:00');
INSERT INTO HISTORICO (IDhistorico, IDusuario, IDfaixa, DataHoraReproducao) VALUES (61, 57, 51, '2023-09-25 00:00:00');
INSERT INTO HISTORICO (IDhistorico, IDusuario, IDfaixa, DataHoraReproducao) VALUES (62, 26, 71, '2025-02-06 00:00:00');
INSERT INTO HISTORICO (IDhistorico, IDusuario, IDfaixa, DataHoraReproducao) VALUES (63, 33, 84, '2023-04-08 00:00:00');
INSERT INTO HISTORICO (IDhistorico, IDusuario, IDfaixa, DataHoraReproducao) VALUES (64, 33, 91, '2024-05-16 00:00:00');
INSERT INTO HISTORICO (IDhistorico, IDusuario, IDfaixa, DataHoraReproducao) VALUES (65, 29, 70, '2024-08-09 00:00:00');
INSERT INTO HISTORICO (IDhistorico, IDusuario, IDfaixa, DataHoraReproducao) VALUES (66, 66, 76, '2024-08-03 00:00:00');
INSERT INTO HISTORICO (IDhistorico, IDusuario, IDfaixa, DataHoraReproducao) VALUES (67, 87, 10, '2025-03-30 00:00:00');
INSERT INTO HISTORICO (IDhistorico, IDusuario, IDfaixa, DataHoraReproducao) VALUES (68, 65, 71, '2024-06-03 00:00:00');
INSERT INTO HISTORICO (IDhistorico, IDusuario, IDfaixa, DataHoraReproducao) VALUES (69, 15, 81, '2025-01-08 00:00:00');
INSERT INTO HISTORICO (IDhistorico, IDusuario, IDfaixa, DataHoraReproducao) VALUES (70, 88, 51, '2024-07-11 00:00:00');
INSERT INTO HISTORICO (IDhistorico, IDusuario, IDfaixa, DataHoraReproducao) VALUES (71, 61, 100, '2023-04-06 00:00:00');
INSERT INTO HISTORICO (IDhistorico, IDusuario, IDfaixa, DataHoraReproducao) VALUES (72, 80, 8, '2024-02-19 00:00:00');
INSERT INTO HISTORICO (IDhistorico, IDusuario, IDfaixa, DataHoraReproducao) VALUES (73, 6, 2, '2024-12-19 00:00:00');
INSERT INTO HISTORICO (IDhistorico, IDusuario, IDfaixa, DataHoraReproducao) VALUES (74, 39, 16, '2024-12-25 00:00:00');
INSERT INTO HISTORICO (IDhistorico, IDusuario, IDfaixa, DataHoraReproducao) VALUES (75, 12, 80, '2025-06-12 00:00:00');
INSERT INTO HISTORICO (IDhistorico, IDusuario, IDfaixa, DataHoraReproducao) VALUES (76, 94, 46, '2023-06-22 00:00:00');
INSERT INTO HISTORICO (IDhistorico, IDusuario, IDfaixa, DataHoraReproducao) VALUES (77, 44, 98, '2025-01-23 00:00:00');
INSERT INTO HISTORICO (IDhistorico, IDusuario, IDfaixa, DataHoraReproducao) VALUES (78, 33, 16, '2023-09-03 00:00:00');
INSERT INTO HISTORICO (IDhistorico, IDusuario, IDfaixa, DataHoraReproducao) VALUES (79, 68, 46, '2025-01-09 00:00:00');
INSERT INTO HISTORICO (IDhistorico, IDusuario, IDfaixa, DataHoraReproducao) VALUES (80, 78, 46, '2023-04-13 00:00:00');
INSERT INTO HISTORICO (IDhistorico, IDusuario, IDfaixa, DataHoraReproducao) VALUES (81, 78, 15, '2023-02-04 00:00:00');
INSERT INTO HISTORICO (IDhistorico, IDusuario, IDfaixa, DataHoraReproducao) VALUES (82, 46, 25, '2024-12-11 00:00:00');
INSERT INTO HISTORICO (IDhistorico, IDusuario, IDfaixa, DataHoraReproducao) VALUES (83, 75, 57, '2023-04-27 00:00:00');
INSERT INTO HISTORICO (IDhistorico, IDusuario, IDfaixa, DataHoraReproducao) VALUES (84, 10, 34, '2023-07-09 00:00:00');
INSERT INTO HISTORICO (IDhistorico, IDusuario, IDfaixa, DataHoraReproducao) VALUES (85, 38, 88, '2024-11-16 00:00:00');
INSERT INTO HISTORICO (IDhistorico, IDusuario, IDfaixa, DataHoraReproducao) VALUES (86, 76, 33, '2024-07-05 00:00:00');
INSERT INTO HISTORICO (IDhistorico, IDusuario, IDfaixa, DataHoraReproducao) VALUES (87, 35, 57, '2023-01-15 00:00:00');
INSERT INTO HISTORICO (IDhistorico, IDusuario, IDfaixa, DataHoraReproducao) VALUES (88, 63, 65, '2024-05-10 00:00:00');
INSERT INTO HISTORICO (IDhistorico, IDusuario, IDfaixa, DataHoraReproducao) VALUES (89, 5, 10, '2023-07-06 00:00:00');
INSERT INTO HISTORICO (IDhistorico, IDusuario, IDfaixa, DataHoraReproducao) VALUES (90, 87, 77, '2024-02-06 00:00:00');
INSERT INTO HISTORICO (IDhistorico, IDusuario, IDfaixa, DataHoraReproducao) VALUES (91, 58, 51, '2023-08-23 00:00:00');
INSERT INTO HISTORICO (IDhistorico, IDusuario, IDfaixa, DataHoraReproducao) VALUES (92, 47, 43, '2024-06-24 00:00:00');
INSERT INTO HISTORICO (IDhistorico, IDusuario, IDfaixa, DataHoraReproducao) VALUES (93, 17, 76, '2024-10-01 00:00:00');
INSERT INTO HISTORICO (IDhistorico, IDusuario, IDfaixa, DataHoraReproducao) VALUES (94, 47, 94, '2024-04-23 00:00:00');
INSERT INTO HISTORICO (IDhistorico, IDusuario, IDfaixa, DataHoraReproducao) VALUES (95, 50, 46, '2023-11-18 00:00:00');
INSERT INTO HISTORICO (IDhistorico, IDusuario, IDfaixa, DataHoraReproducao) VALUES (96, 62, 43, '2023-08-21 00:00:00');
INSERT INTO HISTORICO (IDhistorico, IDusuario, IDfaixa, DataHoraReproducao) VALUES (97, 78, 6, '2024-10-08 00:00:00');
INSERT INTO HISTORICO (IDhistorico, IDusuario, IDfaixa, DataHoraReproducao) VALUES (98, 19, 35, '2024-01-29 00:00:00');
INSERT INTO HISTORICO (IDhistorico, IDusuario, IDfaixa, DataHoraReproducao) VALUES (99, 34, 46, '2024-08-05 00:00:00');
INSERT INTO HISTORICO (IDhistorico, IDusuario, IDfaixa, DataHoraReproducao) VALUES (100, 18, 90, '2023-02-04 00:00:00');
