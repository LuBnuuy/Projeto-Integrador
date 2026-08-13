CREATE DATABASE bibliotech
	DEFAULT CHARACTER SET utf8mb4
    DEFAULT COLLATE utf8mb4_unicode_ci;
USE bibliotech;

CREATE TABLE Clientes(
IDcliente INT PRIMARY KEY,
NomeCliente VARCHAR(100),
Email VARCHAR(100),
Telefone VARCHAR(20),
CPF VARCHAR(14),
Endereço VARCHAR(255)
);
CREATE TABLE Categorias(
IDcategoria INT PRIMARY KEY,
NomeCategoria VARCHAR(100),
Descricao VARCHAR(255)
);
CREATE TABLE Livros(
IDlivro INT PRIMARY KEY,
IDcategoria INT,
NomeLivro VARCHAR(255),
Autor VARCHAR(100),
Tipo VARCHAR(50),
FOREIGN KEY (IDcategoria) REFERENCES Categorias (IDcategoria)
);
CREATE TABLE Exemplares(
IDexemplar INT PRIMARY KEY,
IDlivro INT,
EstadoConservado VARCHAR(50),
Status VARCHAR(50),
FOREIGN KEY (IDlivro) REFERENCES Livros (IDlivro)
);
CREATE TABLE Emprestimos(
IDemprestimo INT PRIMARY KEY,
IDcliente INT,
IDexemplar INT,
DataDeEmprestimo DATE,
DevoluçaoPrevista DATE,
DevoluçaoReal DATE,
Status VARCHAR(50),
FOREIGN KEY (IDcliente) REFERENCES Clientes (IDcliente),
FOREIGN KEY (IDexemplar) REFERENCES Exemplares (IDexemplar)
);
CREATE TABLE Multas(
IDmulta INT PRIMARY KEY,
IDemprestimo INT,
ValorMulta DECIMAL(10,2),
StatusMulta VARCHAR(50),
FOREIGN KEY (IDemprestimo) REFERENCES Emprestimos (IDemprestimo)
);
CREATE TABLE Pagamentos(
IDpagamento INT PRIMARY KEY,
IDmulta INT,
MetodoPagamento VARCHAR(50),
Status VARCHAR(50),
DataPagamento DATE,
FOREIGN KEY (IDmulta) REFERENCES Multas (IDmulta)
);
ALTER TABLE Clientes
ADD COLUMN SenhaHash VARCHAR(255) NOT NULL DEFAULT '';

ALTER TABLE Categorias
ADD COLUMN Ativa BOOLEAN NOT NULL DEFAULT TRUE;

ALTER TABLE Livros
ADD COLUMN AnoPublicacao INT;

ALTER TABLE Exemplares
ADD COLUMN Localizacao VARCHAR(50);

ALTER TABLE Emprestimos
ADD COLUMN QtdRenovacoes INT NOT NULL DEFAULT 0;

ALTER TABLE Multas
ADD COLUMN DataGeracao DATE;

ALTER TABLE Pagamentos
ADD COLUMN CodigoTransacao VARCHAR(100);

-- Store Procedure da Tabela Clientes
DELIMITER //
CREATE PROCEDURE sp_Cadastro(
	IN p_IDcliente INT,
	IN p_NomeCliente VARCHAR(100),
	IN p_Email VARCHAR(100),
	IN p_Telefone VARCHAR(20),
	IN p_CPF VARCHAR(14),
	IN p_Endereço VARCHAR(255),
	OUT p_Resultado VARCHAR(100))
BEGIN 
	DECLARE v_existe INT;

	SELECT COUNT(*) INTO v_existe
	FROM clientes
	WHERE CPF = p_CPF OR email = p_email;

	IF v_existe > 0 THEN
		SET p_Resultado = 'CPF ou EMAIL ja cadastrado.';
	ELSE INSERT INTO clientes (IDcliente,NomeCliente,Email,Telefone,CPF,Endereço)
		VALUES (p_IDcliente,p_NomeCliente,p_Email,p_Telefone,p_CPF,p_Endereço);
		SET p_Resultado = 'Cliente cadastrado com sucesso';
	END IF;
END //
DELIMITER ;

-- Store Procedure da Tabela Categorias
DELIMITER //
CREATE PROCEDURE sp_DesativarCategoria(
	IN p_IDcategoria INT,
    IN p_Ativa VARCHAR(100),
    OUT p_Resultado VARCHAR(100))
BEGIN
DECLARE v_QtdDeLivros INT;
	SELECT COUNT(*) INTO v_QtdDeLivros
    FROM livros
    WHERE IDcategoria = p_IDcategoria;
    
    IF v_QtdDeLivros = 0 THEN
		UPDATE categorias
		SET Ativa = FALSE
        WHERE IDcategoria = p_IDcategoria;
        ELSE
        SET p_Resultado = 'Não é possivel desativar';
    END IF;
END //
DELIMITER ;

-- Store Procedure da Tabela Livros
-- Cadastra um livro, mas só permite se a categoria existir e estiver ativa
DELIMITER //
CREATE PROCEDURE sp_CadastrarLivro(
    IN p_IDlivro INT,
    IN p_IDcategoria INT,
    IN p_NomeLivro VARCHAR(255),
    IN p_Autor VARCHAR(100),
    IN p_Tipo VARCHAR(50),
    IN p_AnoPublicacao INT,
    OUT p_Resultado VARCHAR(100))
BEGIN
    DECLARE v_CategoriaAtiva INT;
 
    SELECT COUNT(*) INTO v_CategoriaAtiva
    FROM categorias
    WHERE IDcategoria = p_IDcategoria AND Ativa = TRUE;
 
    IF v_CategoriaAtiva = 0 THEN
        SET p_Resultado = 'Categoria inexistente ou inativa';
    ELSE
        INSERT INTO livros (IDlivro, IDcategoria, NomeLivro, Autor, Tipo, AnoPublicacao)
        VALUES (p_IDlivro, p_IDcategoria, p_NomeLivro, p_Autor, p_Tipo, p_AnoPublicacao);
        SET p_Resultado = 'Livro cadastrado com sucesso';
    END IF;
END //
DELIMITER ;

-- Store Procedure da Tabela Exemplares
-- Cadastra um exemplar de um livro já existente, com status inicial "Disponivel"
DELIMITER //
CREATE PROCEDURE sp_CadastrarExemplar(
    IN p_IDexemplar INT,
    IN p_IDlivro INT,
    IN p_EstadoConservado VARCHAR(50),
    IN p_Localizacao VARCHAR(50),
    OUT p_Resultado VARCHAR(100))
BEGIN
    DECLARE v_LivroExiste INT;
 
    SELECT COUNT(*) INTO v_LivroExiste
    FROM livros
    WHERE IDlivro = p_IDlivro;
 
    IF v_LivroExiste = 0 THEN
        SET p_Resultado = 'Livro não encontrado';
    ELSE
        INSERT INTO exemplares (IDexemplar, IDlivro, EstadoConservado, Status, Localizacao)
        VALUES (p_IDexemplar, p_IDlivro, p_EstadoConservado, 'Disponivel', p_Localizacao);
        SET p_Resultado = 'Exemplar cadastrado com sucesso';
    END IF;
END //
DELIMITER ;

-- Store Procedure da Tabela Emprestimos
-- Realiza um empréstimo somente se o cliente existir e o exemplar
-- estiver disponível; atualiza o status do exemplar para "Emprestado"
DELIMITER //
CREATE PROCEDURE sp_RealizarEmprestimo(
    IN p_IDemprestimo INT,
    IN p_IDcliente INT,
    IN p_IDexemplar INT,
    IN p_DataDeEmprestimo DATE,
    IN p_DevolucaoPrevista DATE,
    OUT p_Resultado VARCHAR(100))
BEGIN
    DECLARE v_ClienteExiste INT;
    DECLARE v_StatusExemplar VARCHAR(50);
 
    SELECT COUNT(*) INTO v_ClienteExiste
    FROM clientes
    WHERE IDcliente = p_IDcliente;
 
    SELECT Status INTO v_StatusExemplar
    FROM exemplares
    WHERE IDexemplar = p_IDexemplar;
 
    IF v_ClienteExiste = 0 THEN
        SET p_Resultado = 'Cliente não encontrado';
    ELSEIF v_StatusExemplar IS NULL THEN
        SET p_Resultado = 'Exemplar não encontrado';
    ELSEIF v_StatusExemplar <> 'Disponivel' THEN
        SET p_Resultado = 'Exemplar indisponível para empréstimo';
    ELSE
        INSERT INTO emprestimos (IDemprestimo, IDcliente, IDexemplar, DataDeEmprestimo, DevoluçaoPrevista, Status)
        VALUES (p_IDemprestimo, p_IDcliente, p_IDexemplar, p_DataDeEmprestimo, p_DevolucaoPrevista, 'Ativo');
 
        UPDATE exemplares
        SET Status = 'Emprestado'
        WHERE IDexemplar = p_IDexemplar;
 
        SET p_Resultado = 'Empréstimo realizado com sucesso';
    END IF;
END //
DELIMITER ;

-- Store Procedure da Tabela Multas
-- Gera uma multa automaticamente calculando os dias de atraso
-- do empréstimo (valor por dia informado como parâmetro)
DELIMITER //
CREATE PROCEDURE sp_GerarMulta(
    IN p_IDmulta INT,
    IN p_IDemprestimo INT,
    IN p_ValorPorDia DECIMAL(10,2),
    OUT p_Resultado VARCHAR(100))
BEGIN
    DECLARE v_DevolucaoPrevista DATE;
    DECLARE v_DevolucaoReal DATE;
    DECLARE v_MultaExiste INT;
    DECLARE v_DiasAtraso INT;
    DECLARE v_ValorMulta DECIMAL(10,2);
 
    SELECT DevoluçaoPrevista, DevoluçaoReal
    INTO v_DevolucaoPrevista, v_DevolucaoReal
    FROM emprestimos
    WHERE IDemprestimo = p_IDemprestimo;
 
    SELECT COUNT(*) INTO v_MultaExiste
    FROM multas
    WHERE IDemprestimo = p_IDemprestimo;
 
    IF v_DevolucaoPrevista IS NULL THEN
        SET p_Resultado = 'Empréstimo não encontrado';
    ELSEIF v_MultaExiste > 0 THEN
        SET p_Resultado = 'Multa já gerada para este empréstimo';
    ELSE
        SET v_DiasAtraso = DATEDIFF(IFNULL(v_DevolucaoReal, CURDATE()), v_DevolucaoPrevista);
 
        IF v_DiasAtraso <= 0 THEN
            SET p_Resultado = 'Não há atraso, multa não gerada';
        ELSE
            SET v_ValorMulta = v_DiasAtraso * p_ValorPorDia;
 
            INSERT INTO multas (IDmulta, IDemprestimo, ValorMulta, StatusMulta, DataGeracao)
            VALUES (p_IDmulta, p_IDemprestimo, v_ValorMulta, 'Pendente', CURDATE());
 
            SET p_Resultado = CONCAT('Multa gerada no valor de R$ ', v_ValorMulta);
        END IF;
    END IF;
END //
DELIMITER ;

-- Store Procedure da Tabela Pagamentos
-- Registra o pagamento de uma multa pendente e atualiza o
-- status da multa para "Paga"
DELIMITER //
CREATE PROCEDURE sp_RegistrarPagamento(
    IN p_IDpagamento INT,
    IN p_IDmulta INT,
    IN p_MetodoPagamento VARCHAR(50),
    IN p_CodigoTransacao VARCHAR(100),
    OUT p_Resultado VARCHAR(100))
BEGIN
    DECLARE v_StatusMulta VARCHAR(50);
 
    SELECT StatusMulta INTO v_StatusMulta
    FROM multas
    WHERE IDmulta = p_IDmulta;
 
    IF v_StatusMulta IS NULL THEN
        SET p_Resultado = 'Multa não encontrada';
    ELSEIF v_StatusMulta = 'Paga' THEN
        SET p_Resultado = 'Multa já foi paga';
    ELSE
        INSERT INTO pagamentos (IDpagamento, IDmulta, MetodoPagamento, Status, DataPagamento, CodigoTransacao)
        VALUES (p_IDpagamento, p_IDmulta, p_MetodoPagamento, 'Confirmado', CURDATE(), p_CodigoTransacao);
 
        UPDATE multas
        SET StatusMulta = 'Paga'
        WHERE IDmulta = p_IDmulta;
 
        SET p_Resultado = 'Pagamento registrado com sucesso';
    END IF;
END //
DELIMITER ;

-- ---------------- Categorias ----------------
INSERT INTO Categorias (IDcategoria, NomeCategoria, Descricao) VALUES (1, 'Ficção', 'Livros do gênero Ficção');
INSERT INTO Categorias (IDcategoria, NomeCategoria, Descricao) VALUES (2, 'Romance', 'Livros do gênero Romance');
INSERT INTO Categorias (IDcategoria, NomeCategoria, Descricao) VALUES (3, 'Terror', 'Livros do gênero Terror');
INSERT INTO Categorias (IDcategoria, NomeCategoria, Descricao) VALUES (4, 'Suspense', 'Livros do gênero Suspense');
INSERT INTO Categorias (IDcategoria, NomeCategoria, Descricao) VALUES (5, 'Fantasia', 'Livros do gênero Fantasia');
INSERT INTO Categorias (IDcategoria, NomeCategoria, Descricao) VALUES (6, 'Ficção Científica', 'Livros do gênero Ficção Científica');
INSERT INTO Categorias (IDcategoria, NomeCategoria, Descricao) VALUES (7, 'Biografia', 'Livros do gênero Biografia');
INSERT INTO Categorias (IDcategoria, NomeCategoria, Descricao) VALUES (8, 'Autoajuda', 'Livros do gênero Autoajuda');
INSERT INTO Categorias (IDcategoria, NomeCategoria, Descricao) VALUES (9, 'História', 'Livros do gênero História');
INSERT INTO Categorias (IDcategoria, NomeCategoria, Descricao) VALUES (10, 'Poesia', 'Livros do gênero Poesia');
INSERT INTO Categorias (IDcategoria, NomeCategoria, Descricao) VALUES (11, 'Drama', 'Livros do gênero Drama');
INSERT INTO Categorias (IDcategoria, NomeCategoria, Descricao) VALUES (12, 'Aventura', 'Livros do gênero Aventura');
INSERT INTO Categorias (IDcategoria, NomeCategoria, Descricao) VALUES (13, 'Policial', 'Livros do gênero Policial');
INSERT INTO Categorias (IDcategoria, NomeCategoria, Descricao) VALUES (14, 'Fábula', 'Livros do gênero Fábula');
INSERT INTO Categorias (IDcategoria, NomeCategoria, Descricao) VALUES (15, 'Mistério', 'Livros do gênero Mistério');
INSERT INTO Categorias (IDcategoria, NomeCategoria, Descricao) VALUES (16, 'Distopia', 'Livros do gênero Distopia');
INSERT INTO Categorias (IDcategoria, NomeCategoria, Descricao) VALUES (17, 'Realismo Mágico', 'Livros do gênero Realismo Mágico');
INSERT INTO Categorias (IDcategoria, NomeCategoria, Descricao) VALUES (18, 'Clássicos', 'Livros do gênero Clássicos');
INSERT INTO Categorias (IDcategoria, NomeCategoria, Descricao) VALUES (19, 'Infantil', 'Livros do gênero Infantil');
INSERT INTO Categorias (IDcategoria, NomeCategoria, Descricao) VALUES (20, 'Juvenil', 'Livros do gênero Juvenil');
INSERT INTO Categorias (IDcategoria, NomeCategoria, Descricao) VALUES (21, 'Quadrinhos', 'Livros do gênero Quadrinhos');
INSERT INTO Categorias (IDcategoria, NomeCategoria, Descricao) VALUES (22, 'Mangá', 'Livros do gênero Mangá');
INSERT INTO Categorias (IDcategoria, NomeCategoria, Descricao) VALUES (23, 'Religião', 'Livros do gênero Religião');
INSERT INTO Categorias (IDcategoria, NomeCategoria, Descricao) VALUES (24, 'Filosofia', 'Livros do gênero Filosofia');
INSERT INTO Categorias (IDcategoria, NomeCategoria, Descricao) VALUES (25, 'Psicologia', 'Livros do gênero Psicologia');
INSERT INTO Categorias (IDcategoria, NomeCategoria, Descricao) VALUES (26, 'Negócios', 'Livros do gênero Negócios');
INSERT INTO Categorias (IDcategoria, NomeCategoria, Descricao) VALUES (27, 'Culinária', 'Livros do gênero Culinária');
INSERT INTO Categorias (IDcategoria, NomeCategoria, Descricao) VALUES (28, 'Viagem', 'Livros do gênero Viagem');
INSERT INTO Categorias (IDcategoria, NomeCategoria, Descricao) VALUES (29, 'Saúde', 'Livros do gênero Saúde');
INSERT INTO Categorias (IDcategoria, NomeCategoria, Descricao) VALUES (30, 'Tecnologia', 'Livros do gênero Tecnologia');
INSERT INTO Categorias (IDcategoria, NomeCategoria, Descricao) VALUES (31, 'Ciência', 'Livros do gênero Ciência');
INSERT INTO Categorias (IDcategoria, NomeCategoria, Descricao) VALUES (32, 'Educação', 'Livros do gênero Educação');
INSERT INTO Categorias (IDcategoria, NomeCategoria, Descricao) VALUES (33, 'Arte', 'Livros do gênero Arte');
INSERT INTO Categorias (IDcategoria, NomeCategoria, Descricao) VALUES (34, 'Música', 'Livros do gênero Música');
INSERT INTO Categorias (IDcategoria, NomeCategoria, Descricao) VALUES (35, 'Esportes', 'Livros do gênero Esportes');
INSERT INTO Categorias (IDcategoria, NomeCategoria, Descricao) VALUES (36, 'Política', 'Livros do gênero Política');
INSERT INTO Categorias (IDcategoria, NomeCategoria, Descricao) VALUES (37, 'Direito', 'Livros do gênero Direito');
INSERT INTO Categorias (IDcategoria, NomeCategoria, Descricao) VALUES (38, 'Medicina', 'Livros do gênero Medicina');
INSERT INTO Categorias (IDcategoria, NomeCategoria, Descricao) VALUES (39, 'Engenharia', 'Livros do gênero Engenharia');
INSERT INTO Categorias (IDcategoria, NomeCategoria, Descricao) VALUES (40, 'Matemática', 'Livros do gênero Matemática');
INSERT INTO Categorias (IDcategoria, NomeCategoria, Descricao) VALUES (41, 'Ficção - Contemporânea', 'Subcategoria de Ficção, vertente contemporânea');
INSERT INTO Categorias (IDcategoria, NomeCategoria, Descricao) VALUES (42, 'Romance - Contemporânea', 'Subcategoria de Romance, vertente contemporânea');
INSERT INTO Categorias (IDcategoria, NomeCategoria, Descricao) VALUES (43, 'Terror - Contemporânea', 'Subcategoria de Terror, vertente contemporânea');
INSERT INTO Categorias (IDcategoria, NomeCategoria, Descricao) VALUES (44, 'Suspense - Contemporânea', 'Subcategoria de Suspense, vertente contemporânea');
INSERT INTO Categorias (IDcategoria, NomeCategoria, Descricao) VALUES (45, 'Fantasia - Contemporânea', 'Subcategoria de Fantasia, vertente contemporânea');
INSERT INTO Categorias (IDcategoria, NomeCategoria, Descricao) VALUES (46, 'Ficção Científica - Contemporânea', 'Subcategoria de Ficção Científica, vertente contemporânea');
INSERT INTO Categorias (IDcategoria, NomeCategoria, Descricao) VALUES (47, 'Biografia - Contemporânea', 'Subcategoria de Biografia, vertente contemporânea');
INSERT INTO Categorias (IDcategoria, NomeCategoria, Descricao) VALUES (48, 'Autoajuda - Contemporânea', 'Subcategoria de Autoajuda, vertente contemporânea');
INSERT INTO Categorias (IDcategoria, NomeCategoria, Descricao) VALUES (49, 'História - Contemporânea', 'Subcategoria de História, vertente contemporânea');
INSERT INTO Categorias (IDcategoria, NomeCategoria, Descricao) VALUES (50, 'Poesia - Contemporânea', 'Subcategoria de Poesia, vertente contemporânea');
INSERT INTO Categorias (IDcategoria, NomeCategoria, Descricao) VALUES (51, 'Drama - Contemporânea', 'Subcategoria de Drama, vertente contemporânea');
INSERT INTO Categorias (IDcategoria, NomeCategoria, Descricao) VALUES (52, 'Aventura - Contemporânea', 'Subcategoria de Aventura, vertente contemporânea');
INSERT INTO Categorias (IDcategoria, NomeCategoria, Descricao) VALUES (53, 'Policial - Contemporânea', 'Subcategoria de Policial, vertente contemporânea');
INSERT INTO Categorias (IDcategoria, NomeCategoria, Descricao) VALUES (54, 'Fábula - Contemporânea', 'Subcategoria de Fábula, vertente contemporânea');
INSERT INTO Categorias (IDcategoria, NomeCategoria, Descricao) VALUES (55, 'Mistério - Contemporânea', 'Subcategoria de Mistério, vertente contemporânea');
INSERT INTO Categorias (IDcategoria, NomeCategoria, Descricao) VALUES (56, 'Distopia - Contemporânea', 'Subcategoria de Distopia, vertente contemporânea');
INSERT INTO Categorias (IDcategoria, NomeCategoria, Descricao) VALUES (57, 'Realismo Mágico - Contemporânea', 'Subcategoria de Realismo Mágico, vertente contemporânea');
INSERT INTO Categorias (IDcategoria, NomeCategoria, Descricao) VALUES (58, 'Clássicos - Contemporânea', 'Subcategoria de Clássicos, vertente contemporânea');
INSERT INTO Categorias (IDcategoria, NomeCategoria, Descricao) VALUES (59, 'Infantil - Contemporânea', 'Subcategoria de Infantil, vertente contemporânea');
INSERT INTO Categorias (IDcategoria, NomeCategoria, Descricao) VALUES (60, 'Juvenil - Contemporânea', 'Subcategoria de Juvenil, vertente contemporânea');
INSERT INTO Categorias (IDcategoria, NomeCategoria, Descricao) VALUES (61, 'Quadrinhos - Contemporânea', 'Subcategoria de Quadrinhos, vertente contemporânea');
INSERT INTO Categorias (IDcategoria, NomeCategoria, Descricao) VALUES (62, 'Mangá - Contemporânea', 'Subcategoria de Mangá, vertente contemporânea');
INSERT INTO Categorias (IDcategoria, NomeCategoria, Descricao) VALUES (63, 'Religião - Contemporânea', 'Subcategoria de Religião, vertente contemporânea');
INSERT INTO Categorias (IDcategoria, NomeCategoria, Descricao) VALUES (64, 'Filosofia - Contemporânea', 'Subcategoria de Filosofia, vertente contemporânea');
INSERT INTO Categorias (IDcategoria, NomeCategoria, Descricao) VALUES (65, 'Psicologia - Contemporânea', 'Subcategoria de Psicologia, vertente contemporânea');
INSERT INTO Categorias (IDcategoria, NomeCategoria, Descricao) VALUES (66, 'Negócios - Contemporânea', 'Subcategoria de Negócios, vertente contemporânea');
INSERT INTO Categorias (IDcategoria, NomeCategoria, Descricao) VALUES (67, 'Culinária - Contemporânea', 'Subcategoria de Culinária, vertente contemporânea');
INSERT INTO Categorias (IDcategoria, NomeCategoria, Descricao) VALUES (68, 'Viagem - Contemporânea', 'Subcategoria de Viagem, vertente contemporânea');
INSERT INTO Categorias (IDcategoria, NomeCategoria, Descricao) VALUES (69, 'Saúde - Contemporânea', 'Subcategoria de Saúde, vertente contemporânea');
INSERT INTO Categorias (IDcategoria, NomeCategoria, Descricao) VALUES (70, 'Tecnologia - Contemporânea', 'Subcategoria de Tecnologia, vertente contemporânea');
INSERT INTO Categorias (IDcategoria, NomeCategoria, Descricao) VALUES (71, 'Ciência - Contemporânea', 'Subcategoria de Ciência, vertente contemporânea');
INSERT INTO Categorias (IDcategoria, NomeCategoria, Descricao) VALUES (72, 'Educação - Contemporânea', 'Subcategoria de Educação, vertente contemporânea');
INSERT INTO Categorias (IDcategoria, NomeCategoria, Descricao) VALUES (73, 'Arte - Contemporânea', 'Subcategoria de Arte, vertente contemporânea');
INSERT INTO Categorias (IDcategoria, NomeCategoria, Descricao) VALUES (74, 'Música - Contemporânea', 'Subcategoria de Música, vertente contemporânea');
INSERT INTO Categorias (IDcategoria, NomeCategoria, Descricao) VALUES (75, 'Esportes - Contemporânea', 'Subcategoria de Esportes, vertente contemporânea');
INSERT INTO Categorias (IDcategoria, NomeCategoria, Descricao) VALUES (76, 'Política - Contemporânea', 'Subcategoria de Política, vertente contemporânea');
INSERT INTO Categorias (IDcategoria, NomeCategoria, Descricao) VALUES (77, 'Direito - Contemporânea', 'Subcategoria de Direito, vertente contemporânea');
INSERT INTO Categorias (IDcategoria, NomeCategoria, Descricao) VALUES (78, 'Medicina - Contemporânea', 'Subcategoria de Medicina, vertente contemporânea');
INSERT INTO Categorias (IDcategoria, NomeCategoria, Descricao) VALUES (79, 'Engenharia - Contemporânea', 'Subcategoria de Engenharia, vertente contemporânea');
INSERT INTO Categorias (IDcategoria, NomeCategoria, Descricao) VALUES (80, 'Matemática - Contemporânea', 'Subcategoria de Matemática, vertente contemporânea');
INSERT INTO Categorias (IDcategoria, NomeCategoria, Descricao) VALUES (81, 'Ficção - Clássica', 'Subcategoria de Ficção, vertente clássica');
INSERT INTO Categorias (IDcategoria, NomeCategoria, Descricao) VALUES (82, 'Romance - Clássica', 'Subcategoria de Romance, vertente clássica');
INSERT INTO Categorias (IDcategoria, NomeCategoria, Descricao) VALUES (83, 'Terror - Clássica', 'Subcategoria de Terror, vertente clássica');
INSERT INTO Categorias (IDcategoria, NomeCategoria, Descricao) VALUES (84, 'Suspense - Clássica', 'Subcategoria de Suspense, vertente clássica');
INSERT INTO Categorias (IDcategoria, NomeCategoria, Descricao) VALUES (85, 'Fantasia - Clássica', 'Subcategoria de Fantasia, vertente clássica');
INSERT INTO Categorias (IDcategoria, NomeCategoria, Descricao) VALUES (86, 'Ficção Científica - Clássica', 'Subcategoria de Ficção Científica, vertente clássica');
INSERT INTO Categorias (IDcategoria, NomeCategoria, Descricao) VALUES (87, 'Biografia - Clássica', 'Subcategoria de Biografia, vertente clássica');
INSERT INTO Categorias (IDcategoria, NomeCategoria, Descricao) VALUES (88, 'Autoajuda - Clássica', 'Subcategoria de Autoajuda, vertente clássica');
INSERT INTO Categorias (IDcategoria, NomeCategoria, Descricao) VALUES (89, 'História - Clássica', 'Subcategoria de História, vertente clássica');
INSERT INTO Categorias (IDcategoria, NomeCategoria, Descricao) VALUES (90, 'Poesia - Clássica', 'Subcategoria de Poesia, vertente clássica');
INSERT INTO Categorias (IDcategoria, NomeCategoria, Descricao) VALUES (91, 'Drama - Clássica', 'Subcategoria de Drama, vertente clássica');
INSERT INTO Categorias (IDcategoria, NomeCategoria, Descricao) VALUES (92, 'Aventura - Clássica', 'Subcategoria de Aventura, vertente clássica');
INSERT INTO Categorias (IDcategoria, NomeCategoria, Descricao) VALUES (93, 'Policial - Clássica', 'Subcategoria de Policial, vertente clássica');
INSERT INTO Categorias (IDcategoria, NomeCategoria, Descricao) VALUES (94, 'Fábula - Clássica', 'Subcategoria de Fábula, vertente clássica');
INSERT INTO Categorias (IDcategoria, NomeCategoria, Descricao) VALUES (95, 'Mistério - Clássica', 'Subcategoria de Mistério, vertente clássica');
INSERT INTO Categorias (IDcategoria, NomeCategoria, Descricao) VALUES (96, 'Distopia - Clássica', 'Subcategoria de Distopia, vertente clássica');
INSERT INTO Categorias (IDcategoria, NomeCategoria, Descricao) VALUES (97, 'Realismo Mágico - Clássica', 'Subcategoria de Realismo Mágico, vertente clássica');
INSERT INTO Categorias (IDcategoria, NomeCategoria, Descricao) VALUES (98, 'Clássicos - Clássica', 'Subcategoria de Clássicos, vertente clássica');
INSERT INTO Categorias (IDcategoria, NomeCategoria, Descricao) VALUES (99, 'Infantil - Clássica', 'Subcategoria de Infantil, vertente clássica');
INSERT INTO Categorias (IDcategoria, NomeCategoria, Descricao) VALUES (100, 'Juvenil - Clássica', 'Subcategoria de Juvenil, vertente clássica');
 
-- ---------------- Livros ----------------
INSERT INTO Livros (IDlivro, IDcategoria, NomeLivro, Autor, Tipo) VALUES (1, 32, 'Eterno das Águas', 'Diego Almeida', 'E-book');
INSERT INTO Livros (IDlivro, IDcategoria, NomeLivro, Autor, Tipo) VALUES (2, 12, 'Perdido Sem Volta', 'André Barbosa', 'Capa Dura');
INSERT INTO Livros (IDlivro, IDcategoria, NomeLivro, Autor, Tipo) VALUES (3, 28, 'Tempestade da Montanha', 'Ana Oliveira', 'E-book');
INSERT INTO Livros (IDlivro, IDcategoria, NomeLivro, Autor, Tipo) VALUES (4, 26, 'Rio de Ferro', 'Ana Barbosa', 'Capa Dura');
INSERT INTO Livros (IDlivro, IDcategoria, NomeLivro, Autor, Tipo) VALUES (5, 36, 'Tempestade Perdido no Tempo', 'Larissa Cardoso', 'Físico');
INSERT INTO Livros (IDlivro, IDcategoria, NomeLivro, Autor, Tipo) VALUES (6, 20, 'Silêncio da Lua Cheia', 'Patrícia Almeida', 'E-book');
INSERT INTO Livros (IDlivro, IDcategoria, NomeLivro, Autor, Tipo) VALUES (7, 13, 'Caminho Sem Volta', 'Mariana Ribeiro', 'Audiobook');
INSERT INTO Livros (IDlivro, IDcategoria, NomeLivro, Autor, Tipo) VALUES (8, 94, 'Reino de Ferro', 'Camila Souza', 'Edição Especial');
INSERT INTO Livros (IDlivro, IDcategoria, NomeLivro, Autor, Tipo) VALUES (9, 11, 'Estrela Sem Volta', 'Ricardo Ribeiro', 'Capa Dura');
INSERT INTO Livros (IDlivro, IDcategoria, NomeLivro, Autor, Tipo) VALUES (10, 74, 'Espelho de Ferro', 'Simone Araújo', 'E-book');
INSERT INTO Livros (IDlivro, IDcategoria, NomeLivro, Autor, Tipo) VALUES (11, 99, 'Última da Montanha', 'André Rodrigues', 'Audiobook');
INSERT INTO Livros (IDlivro, IDcategoria, NomeLivro, Autor, Tipo) VALUES (12, 49, 'Última Perdido no Tempo', 'Leonardo Santos', 'Audiobook');
INSERT INTO Livros (IDlivro, IDcategoria, NomeLivro, Autor, Tipo) VALUES (13, 46, 'Menina das Memórias', 'Rafael Araújo', 'E-book');
INSERT INTO Livros (IDlivro, IDcategoria, NomeLivro, Autor, Tipo) VALUES (14, 69, 'Labirinto do Vento', 'Bruno Costa', 'E-book');
INSERT INTO Livros (IDlivro, IDcategoria, NomeLivro, Autor, Tipo) VALUES (15, 82, 'Silêncio dos Ventos', 'Juliana Almeida', 'Capa Dura');
INSERT INTO Livros (IDlivro, IDcategoria, NomeLivro, Autor, Tipo) VALUES (16, 30, 'Jardim do Norte', 'Tatiane Souza', 'Físico');
INSERT INTO Livros (IDlivro, IDcategoria, NomeLivro, Autor, Tipo) VALUES (17, 28, 'Caminho do Deserto', 'Camila Oliveira', 'Capa Dura');
INSERT INTO Livros (IDlivro, IDcategoria, NomeLivro, Autor, Tipo) VALUES (18, 51, 'Caminho do Amanhã', 'Débora Martins', 'Edição Especial');
INSERT INTO Livros (IDlivro, IDcategoria, NomeLivro, Autor, Tipo) VALUES (19, 96, 'Perdido das Cinzas', 'Beatriz Rodrigues', 'Capa Dura');
INSERT INTO Livros (IDlivro, IDcategoria, NomeLivro, Autor, Tipo) VALUES (20, 55, 'Estrela das Cinzas', 'Diego Cardoso', 'Capa Dura');
INSERT INTO Livros (IDlivro, IDcategoria, NomeLivro, Autor, Tipo) VALUES (21, 66, 'Voz das Memórias', 'Lucas Pereira', 'Edição Especial');
INSERT INTO Livros (IDlivro, IDcategoria, NomeLivro, Autor, Tipo) VALUES (22, 88, 'Eterno de Cristal', 'Débora Costa', 'Edição Especial');
INSERT INTO Livros (IDlivro, IDcategoria, NomeLivro, Autor, Tipo) VALUES (23, 77, 'Enigma do Vento', 'Juliana Ribeiro', 'Edição Especial');
INSERT INTO Livros (IDlivro, IDcategoria, NomeLivro, Autor, Tipo) VALUES (24, 88, 'Rio das Cinzas', 'Thiago Silva', 'Físico');
INSERT INTO Livros (IDlivro, IDcategoria, NomeLivro, Autor, Tipo) VALUES (25, 1, 'Espelho da Lua Cheia', 'Rafael Gomes', 'Audiobook');
INSERT INTO Livros (IDlivro, IDcategoria, NomeLivro, Autor, Tipo) VALUES (26, 81, 'Rio da Meia-Noite', 'Vanessa Santos', 'Audiobook');
INSERT INTO Livros (IDlivro, IDcategoria, NomeLivro, Autor, Tipo) VALUES (27, 70, 'Fogo de Cristal', 'Eduardo Costa', 'Capa Dura');
INSERT INTO Livros (IDlivro, IDcategoria, NomeLivro, Autor, Tipo) VALUES (28, 3, 'Sombra de Ferro', 'Patrícia Martins', 'Físico');
INSERT INTO Livros (IDlivro, IDcategoria, NomeLivro, Autor, Tipo) VALUES (29, 31, 'Reino da Cidade Velha', 'Lucas Souza', 'Capa Dura');
INSERT INTO Livros (IDlivro, IDcategoria, NomeLivro, Autor, Tipo) VALUES (30, 9, 'Última do Vento', 'Diego Martins', 'Capa Dura');
INSERT INTO Livros (IDlivro, IDcategoria, NomeLivro, Autor, Tipo) VALUES (31, 71, 'Perdido de Cristal', 'André Martins', 'E-book');
INSERT INTO Livros (IDlivro, IDcategoria, NomeLivro, Autor, Tipo) VALUES (32, 55, 'Labirinto Proibido', 'Leonardo Teixeira', 'E-book');
INSERT INTO Livros (IDlivro, IDcategoria, NomeLivro, Autor, Tipo) VALUES (33, 52, 'Estrela do Amanhã', 'Priscila Nascimento', 'Audiobook');
INSERT INTO Livros (IDlivro, IDcategoria, NomeLivro, Autor, Tipo) VALUES (34, 32, 'Menina Proibido', 'Larissa Santos', 'E-book');
INSERT INTO Livros (IDlivro, IDcategoria, NomeLivro, Autor, Tipo) VALUES (35, 71, 'Última do Norte', 'Ana Cardoso', 'E-book');
INSERT INTO Livros (IDlivro, IDcategoria, NomeLivro, Autor, Tipo) VALUES (36, 91, 'Sonho Perdido no Tempo', 'Ana Oliveira', 'Físico');
INSERT INTO Livros (IDlivro, IDcategoria, NomeLivro, Autor, Tipo) VALUES (37, 43, 'Jardim do Vento', 'Simone Souza', 'Físico');
INSERT INTO Livros (IDlivro, IDcategoria, NomeLivro, Autor, Tipo) VALUES (38, 28, 'Rio Perdido no Tempo', 'Camila Martins', 'Capa Dura');
INSERT INTO Livros (IDlivro, IDcategoria, NomeLivro, Autor, Tipo) VALUES (39, 32, 'Perdido Distante', 'Renata Martins', 'Edição Especial');
INSERT INTO Livros (IDlivro, IDcategoria, NomeLivro, Autor, Tipo) VALUES (40, 85, 'Tempestade do Amanhã', 'João Santos', 'Edição Especial');
INSERT INTO Livros (IDlivro, IDcategoria, NomeLivro, Autor, Tipo) VALUES (41, 94, 'Reino da Lua Cheia', 'Marcos Gomes', 'Físico');
INSERT INTO Livros (IDlivro, IDcategoria, NomeLivro, Autor, Tipo) VALUES (42, 14, 'Eterno da Montanha', 'Juliana Lima', 'E-book');
INSERT INTO Livros (IDlivro, IDcategoria, NomeLivro, Autor, Tipo) VALUES (43, 18, 'Fogo do Amanhã', 'Thiago Gomes', 'Edição Especial');
INSERT INTO Livros (IDlivro, IDcategoria, NomeLivro, Autor, Tipo) VALUES (44, 10, 'Silêncio das Cinzas', 'Larissa Rodrigues', 'Edição Especial');
INSERT INTO Livros (IDlivro, IDcategoria, NomeLivro, Autor, Tipo) VALUES (45, 12, 'Segredo Escondido', 'Tatiane Silva', 'E-book');
INSERT INTO Livros (IDlivro, IDcategoria, NomeLivro, Autor, Tipo) VALUES (46, 8, 'Menino Encantado', 'Fernanda Ribeiro', 'E-book');
INSERT INTO Livros (IDlivro, IDcategoria, NomeLivro, Autor, Tipo) VALUES (47, 59, 'Voz das Águas', 'Juliana Almeida', 'Audiobook');
INSERT INTO Livros (IDlivro, IDcategoria, NomeLivro, Autor, Tipo) VALUES (48, 20, 'Tempestade Escondido', 'André Martins', 'E-book');
INSERT INTO Livros (IDlivro, IDcategoria, NomeLivro, Autor, Tipo) VALUES (49, 95, 'Espelho do Amanhã', 'Carlos Cardoso', 'Capa Dura');
INSERT INTO Livros (IDlivro, IDcategoria, NomeLivro, Autor, Tipo) VALUES (50, 75, 'Segredo do Norte', 'Carlos Souza', 'Edição Especial');
INSERT INTO Livros (IDlivro, IDcategoria, NomeLivro, Autor, Tipo) VALUES (51, 66, 'Rio Proibido', 'Rafael Souza', 'Físico');
INSERT INTO Livros (IDlivro, IDcategoria, NomeLivro, Autor, Tipo) VALUES (52, 87, 'Silêncio do Vento', 'Bruno Oliveira', 'E-book');
INSERT INTO Livros (IDlivro, IDcategoria, NomeLivro, Autor, Tipo) VALUES (53, 32, 'Voz Sem Volta', 'Simone Cardoso', 'Capa Dura');
INSERT INTO Livros (IDlivro, IDcategoria, NomeLivro, Autor, Tipo) VALUES (54, 54, 'Enigma da Montanha', 'Bruno Oliveira', 'Capa Dura');
INSERT INTO Livros (IDlivro, IDcategoria, NomeLivro, Autor, Tipo) VALUES (55, 27, 'Sonho Proibido', 'Patrícia Almeida', 'Audiobook');
INSERT INTO Livros (IDlivro, IDcategoria, NomeLivro, Autor, Tipo) VALUES (56, 86, 'Jardim das Cinzas', 'Juliana Pereira', 'Audiobook');
INSERT INTO Livros (IDlivro, IDcategoria, NomeLivro, Autor, Tipo) VALUES (57, 2, 'Menina do Norte', 'Ricardo Oliveira', 'Edição Especial');
INSERT INTO Livros (IDlivro, IDcategoria, NomeLivro, Autor, Tipo) VALUES (58, 69, 'Enigma Distante', 'João Oliveira', 'E-book');
INSERT INTO Livros (IDlivro, IDcategoria, NomeLivro, Autor, Tipo) VALUES (59, 32, 'Perdido das Memórias', 'Simone Oliveira', 'Audiobook');
INSERT INTO Livros (IDlivro, IDcategoria, NomeLivro, Autor, Tipo) VALUES (60, 91, 'Espelho da Meia-Noite', 'Larissa Barbosa', 'Audiobook');
INSERT INTO Livros (IDlivro, IDcategoria, NomeLivro, Autor, Tipo) VALUES (61, 39, 'Enigma Proibido', 'Ana Barbosa', 'Físico');
INSERT INTO Livros (IDlivro, IDcategoria, NomeLivro, Autor, Tipo) VALUES (62, 20, 'Eterno Sem Volta', 'Diego Barbosa', 'Audiobook');
INSERT INTO Livros (IDlivro, IDcategoria, NomeLivro, Autor, Tipo) VALUES (63, 65, 'Fogo do Norte', 'Fernanda Almeida', 'Edição Especial');
INSERT INTO Livros (IDlivro, IDcategoria, NomeLivro, Autor, Tipo) VALUES (64, 36, 'Labirinto da Montanha', 'Mariana Carvalho', 'Físico');
INSERT INTO Livros (IDlivro, IDcategoria, NomeLivro, Autor, Tipo) VALUES (65, 82, 'Sombra do Norte', 'Aline Pereira', 'Audiobook');
INSERT INTO Livros (IDlivro, IDcategoria, NomeLivro, Autor, Tipo) VALUES (66, 15, 'Estrela da Lua Cheia', 'Thiago Silva', 'Físico');
INSERT INTO Livros (IDlivro, IDcategoria, NomeLivro, Autor, Tipo) VALUES (67, 75, 'Perdido Escondido', 'Carlos Araújo', 'Capa Dura');
INSERT INTO Livros (IDlivro, IDcategoria, NomeLivro, Autor, Tipo) VALUES (68, 40, 'Perdido da Lua Cheia', 'Beatriz Souza', 'Audiobook');
INSERT INTO Livros (IDlivro, IDcategoria, NomeLivro, Autor, Tipo) VALUES (69, 86, 'Segredo das Memórias', 'Fernanda Rodrigues', 'Físico');
INSERT INTO Livros (IDlivro, IDcategoria, NomeLivro, Autor, Tipo) VALUES (70, 80, 'Reino Escondido', 'Simone Carvalho', 'E-book');
INSERT INTO Livros (IDlivro, IDcategoria, NomeLivro, Autor, Tipo) VALUES (71, 53, 'Jardim da Meia-Noite', 'Gustavo Costa', 'Físico');
INSERT INTO Livros (IDlivro, IDcategoria, NomeLivro, Autor, Tipo) VALUES (72, 86, 'Silêncio do Norte', 'Gustavo Carvalho', 'E-book');
INSERT INTO Livros (IDlivro, IDcategoria, NomeLivro, Autor, Tipo) VALUES (73, 49, 'Labirinto da Meia-Noite', 'Gustavo Santos', 'Físico');
INSERT INTO Livros (IDlivro, IDcategoria, NomeLivro, Autor, Tipo) VALUES (74, 45, 'Menino Perdido no Tempo', 'Fernanda Gomes', 'Audiobook');
INSERT INTO Livros (IDlivro, IDcategoria, NomeLivro, Autor, Tipo) VALUES (75, 52, 'Jardim Perdido no Tempo', 'Ana Ferreira', 'Audiobook');
INSERT INTO Livros (IDlivro, IDcategoria, NomeLivro, Autor, Tipo) VALUES (76, 52, 'Labirinto das Memórias', 'Débora Rocha', 'Capa Dura');
INSERT INTO Livros (IDlivro, IDcategoria, NomeLivro, Autor, Tipo) VALUES (77, 23, 'Caminho das Águas', 'João Almeida', 'Capa Dura');
INSERT INTO Livros (IDlivro, IDcategoria, NomeLivro, Autor, Tipo) VALUES (78, 94, 'Eterno de Ferro', 'Marcos Araújo', 'Audiobook');
INSERT INTO Livros (IDlivro, IDcategoria, NomeLivro, Autor, Tipo) VALUES (79, 50, 'Tempestade de Ferro', 'Vanessa Santos', 'Capa Dura');
INSERT INTO Livros (IDlivro, IDcategoria, NomeLivro, Autor, Tipo) VALUES (80, 1, 'Fogo das Cinzas', 'Carlos Carvalho', 'Capa Dura');
INSERT INTO Livros (IDlivro, IDcategoria, NomeLivro, Autor, Tipo) VALUES (81, 93, 'Enigma do Norte', 'André Santos', 'Audiobook');
INSERT INTO Livros (IDlivro, IDcategoria, NomeLivro, Autor, Tipo) VALUES (82, 42, 'Rio da Cidade Velha', 'André Carvalho', 'Edição Especial');
INSERT INTO Livros (IDlivro, IDcategoria, NomeLivro, Autor, Tipo) VALUES (83, 54, 'Espelho Escondido', 'Beatriz Ferreira', 'Edição Especial');
INSERT INTO Livros (IDlivro, IDcategoria, NomeLivro, Autor, Tipo) VALUES (84, 52, 'Silêncio de Ferro', 'Renata Nascimento', 'Capa Dura');
INSERT INTO Livros (IDlivro, IDcategoria, NomeLivro, Autor, Tipo) VALUES (85, 56, 'Sombra da Cidade Velha', 'Rodrigo Ferreira', 'Capa Dura');
INSERT INTO Livros (IDlivro, IDcategoria, NomeLivro, Autor, Tipo) VALUES (86, 66, 'Menina dos Ventos', 'Larissa Ferreira', 'Edição Especial');
INSERT INTO Livros (IDlivro, IDcategoria, NomeLivro, Autor, Tipo) VALUES (87, 43, 'Espelho Proibido', 'André Teixeira', 'Físico');
INSERT INTO Livros (IDlivro, IDcategoria, NomeLivro, Autor, Tipo) VALUES (88, 19, 'Jardim da Cidade Velha', 'Lucas Ferreira', 'Físico');
INSERT INTO Livros (IDlivro, IDcategoria, NomeLivro, Autor, Tipo) VALUES (89, 99, 'Segredo Perdido no Tempo', 'Felipe Teixeira', 'Físico');
INSERT INTO Livros (IDlivro, IDcategoria, NomeLivro, Autor, Tipo) VALUES (90, 25, 'Menina da Lua Cheia', 'Simone Cardoso', 'Edição Especial');
INSERT INTO Livros (IDlivro, IDcategoria, NomeLivro, Autor, Tipo) VALUES (91, 84, 'Menino do Deserto', 'Lucas Pereira', 'Físico');
INSERT INTO Livros (IDlivro, IDcategoria, NomeLivro, Autor, Tipo) VALUES (92, 90, 'Eterno da Lua Cheia', 'Lucas Costa', 'Capa Dura');
INSERT INTO Livros (IDlivro, IDcategoria, NomeLivro, Autor, Tipo) VALUES (93, 16, 'Menina da Montanha', 'Thiago Rodrigues', 'Edição Especial');
INSERT INTO Livros (IDlivro, IDcategoria, NomeLivro, Autor, Tipo) VALUES (94, 72, 'Perdido dos Ventos', 'André Rocha', 'Capa Dura');
INSERT INTO Livros (IDlivro, IDcategoria, NomeLivro, Autor, Tipo) VALUES (95, 55, 'Caminho dos Ventos', 'Bruno Rocha', 'Capa Dura');
INSERT INTO Livros (IDlivro, IDcategoria, NomeLivro, Autor, Tipo) VALUES (96, 58, 'Menina da Meia-Noite', 'Diego Martins', 'Audiobook');
INSERT INTO Livros (IDlivro, IDcategoria, NomeLivro, Autor, Tipo) VALUES (97, 36, 'Rio Encantado', 'Débora Rodrigues', 'Edição Especial');
INSERT INTO Livros (IDlivro, IDcategoria, NomeLivro, Autor, Tipo) VALUES (98, 43, 'Última da Cidade Velha', 'Lucas Almeida', 'Audiobook');
INSERT INTO Livros (IDlivro, IDcategoria, NomeLivro, Autor, Tipo) VALUES (99, 30, 'Estrela do Vento', 'Beatriz Pereira', 'Edição Especial');
INSERT INTO Livros (IDlivro, IDcategoria, NomeLivro, Autor, Tipo) VALUES (100, 53, 'Perdido do Amanhã', 'Mariana Carvalho', 'Audiobook');
 
-- ---------------- Exemplares ----------------
INSERT INTO Exemplares (IDexemplar, IDlivro, EstadoConservado, Status) VALUES (1, 70, 'Desgastado', 'Extraviado');
INSERT INTO Exemplares (IDexemplar, IDlivro, EstadoConservado, Status) VALUES (2, 8, 'Bom', 'Extraviado');
INSERT INTO Exemplares (IDexemplar, IDlivro, EstadoConservado, Status) VALUES (3, 50, 'Danificado', 'Disponível');
INSERT INTO Exemplares (IDexemplar, IDlivro, EstadoConservado, Status) VALUES (4, 98, 'Danificado', 'Extraviado');
INSERT INTO Exemplares (IDexemplar, IDlivro, EstadoConservado, Status) VALUES (5, 62, 'Novo', 'Em Manutenção');
INSERT INTO Exemplares (IDexemplar, IDlivro, EstadoConservado, Status) VALUES (6, 39, 'Desgastado', 'Extraviado');
INSERT INTO Exemplares (IDexemplar, IDlivro, EstadoConservado, Status) VALUES (7, 69, 'Danificado', 'Emprestado');
INSERT INTO Exemplares (IDexemplar, IDlivro, EstadoConservado, Status) VALUES (8, 63, 'Bom', 'Em Manutenção');
INSERT INTO Exemplares (IDexemplar, IDlivro, EstadoConservado, Status) VALUES (9, 56, 'Desgastado', 'Disponível');
INSERT INTO Exemplares (IDexemplar, IDlivro, EstadoConservado, Status) VALUES (10, 50, 'Regular', 'Extraviado');
INSERT INTO Exemplares (IDexemplar, IDlivro, EstadoConservado, Status) VALUES (11, 93, 'Bom', 'Extraviado');
INSERT INTO Exemplares (IDexemplar, IDlivro, EstadoConservado, Status) VALUES (12, 17, 'Danificado', 'Disponível');
INSERT INTO Exemplares (IDexemplar, IDlivro, EstadoConservado, Status) VALUES (13, 51, 'Danificado', 'Disponível');
INSERT INTO Exemplares (IDexemplar, IDlivro, EstadoConservado, Status) VALUES (14, 11, 'Desgastado', 'Emprestado');
INSERT INTO Exemplares (IDexemplar, IDlivro, EstadoConservado, Status) VALUES (15, 60, 'Bom', 'Disponível');
INSERT INTO Exemplares (IDexemplar, IDlivro, EstadoConservado, Status) VALUES (16, 34, 'Desgastado', 'Em Manutenção');
INSERT INTO Exemplares (IDexemplar, IDlivro, EstadoConservado, Status) VALUES (17, 28, 'Desgastado', 'Em Manutenção');
INSERT INTO Exemplares (IDexemplar, IDlivro, EstadoConservado, Status) VALUES (18, 44, 'Desgastado', 'Em Manutenção');
INSERT INTO Exemplares (IDexemplar, IDlivro, EstadoConservado, Status) VALUES (19, 97, 'Desgastado', 'Em Manutenção');
INSERT INTO Exemplares (IDexemplar, IDlivro, EstadoConservado, Status) VALUES (20, 11, 'Desgastado', 'Disponível');
INSERT INTO Exemplares (IDexemplar, IDlivro, EstadoConservado, Status) VALUES (21, 96, 'Danificado', 'Disponível');
INSERT INTO Exemplares (IDexemplar, IDlivro, EstadoConservado, Status) VALUES (22, 45, 'Bom', 'Disponível');
INSERT INTO Exemplares (IDexemplar, IDlivro, EstadoConservado, Status) VALUES (23, 100, 'Novo', 'Disponível');
INSERT INTO Exemplares (IDexemplar, IDlivro, EstadoConservado, Status) VALUES (24, 32, 'Bom', 'Disponível');
INSERT INTO Exemplares (IDexemplar, IDlivro, EstadoConservado, Status) VALUES (25, 80, 'Bom', 'Emprestado');
INSERT INTO Exemplares (IDexemplar, IDlivro, EstadoConservado, Status) VALUES (26, 17, 'Desgastado', 'Disponível');
INSERT INTO Exemplares (IDexemplar, IDlivro, EstadoConservado, Status) VALUES (27, 73, 'Bom', 'Extraviado');
INSERT INTO Exemplares (IDexemplar, IDlivro, EstadoConservado, Status) VALUES (28, 90, 'Regular', 'Em Manutenção');
INSERT INTO Exemplares (IDexemplar, IDlivro, EstadoConservado, Status) VALUES (29, 22, 'Danificado', 'Disponível');
INSERT INTO Exemplares (IDexemplar, IDlivro, EstadoConservado, Status) VALUES (30, 100, 'Bom', 'Em Manutenção');
INSERT INTO Exemplares (IDexemplar, IDlivro, EstadoConservado, Status) VALUES (31, 14, 'Danificado', 'Disponível');
INSERT INTO Exemplares (IDexemplar, IDlivro, EstadoConservado, Status) VALUES (32, 40, 'Danificado', 'Extraviado');
INSERT INTO Exemplares (IDexemplar, IDlivro, EstadoConservado, Status) VALUES (33, 51, 'Bom', 'Disponível');
INSERT INTO Exemplares (IDexemplar, IDlivro, EstadoConservado, Status) VALUES (34, 76, 'Bom', 'Disponível');
INSERT INTO Exemplares (IDexemplar, IDlivro, EstadoConservado, Status) VALUES (35, 90, 'Regular', 'Disponível');
INSERT INTO Exemplares (IDexemplar, IDlivro, EstadoConservado, Status) VALUES (36, 73, 'Novo', 'Em Manutenção');
INSERT INTO Exemplares (IDexemplar, IDlivro, EstadoConservado, Status) VALUES (37, 69, 'Desgastado', 'Em Manutenção');
INSERT INTO Exemplares (IDexemplar, IDlivro, EstadoConservado, Status) VALUES (38, 9, 'Danificado', 'Em Manutenção');
INSERT INTO Exemplares (IDexemplar, IDlivro, EstadoConservado, Status) VALUES (39, 2, 'Desgastado', 'Extraviado');
INSERT INTO Exemplares (IDexemplar, IDlivro, EstadoConservado, Status) VALUES (40, 14, 'Desgastado', 'Em Manutenção');
INSERT INTO Exemplares (IDexemplar, IDlivro, EstadoConservado, Status) VALUES (41, 82, 'Desgastado', 'Emprestado');
INSERT INTO Exemplares (IDexemplar, IDlivro, EstadoConservado, Status) VALUES (42, 56, 'Bom', 'Em Manutenção');
INSERT INTO Exemplares (IDexemplar, IDlivro, EstadoConservado, Status) VALUES (43, 79, 'Danificado', 'Extraviado');
INSERT INTO Exemplares (IDexemplar, IDlivro, EstadoConservado, Status) VALUES (44, 60, 'Desgastado', 'Em Manutenção');
INSERT INTO Exemplares (IDexemplar, IDlivro, EstadoConservado, Status) VALUES (45, 42, 'Bom', 'Disponível');
INSERT INTO Exemplares (IDexemplar, IDlivro, EstadoConservado, Status) VALUES (46, 36, 'Desgastado', 'Emprestado');
INSERT INTO Exemplares (IDexemplar, IDlivro, EstadoConservado, Status) VALUES (47, 97, 'Desgastado', 'Extraviado');
INSERT INTO Exemplares (IDexemplar, IDlivro, EstadoConservado, Status) VALUES (48, 44, 'Novo', 'Extraviado');
INSERT INTO Exemplares (IDexemplar, IDlivro, EstadoConservado, Status) VALUES (49, 42, 'Bom', 'Extraviado');
INSERT INTO Exemplares (IDexemplar, IDlivro, EstadoConservado, Status) VALUES (50, 28, 'Regular', 'Em Manutenção');
INSERT INTO Exemplares (IDexemplar, IDlivro, EstadoConservado, Status) VALUES (51, 44, 'Regular', 'Em Manutenção');
INSERT INTO Exemplares (IDexemplar, IDlivro, EstadoConservado, Status) VALUES (52, 72, 'Novo', 'Emprestado');
INSERT INTO Exemplares (IDexemplar, IDlivro, EstadoConservado, Status) VALUES (53, 11, 'Bom', 'Extraviado');
INSERT INTO Exemplares (IDexemplar, IDlivro, EstadoConservado, Status) VALUES (54, 63, 'Danificado', 'Emprestado');
INSERT INTO Exemplares (IDexemplar, IDlivro, EstadoConservado, Status) VALUES (55, 89, 'Desgastado', 'Extraviado');
INSERT INTO Exemplares (IDexemplar, IDlivro, EstadoConservado, Status) VALUES (56, 58, 'Novo', 'Disponível');
INSERT INTO Exemplares (IDexemplar, IDlivro, EstadoConservado, Status) VALUES (57, 38, 'Bom', 'Extraviado');
INSERT INTO Exemplares (IDexemplar, IDlivro, EstadoConservado, Status) VALUES (58, 89, 'Bom', 'Em Manutenção');
INSERT INTO Exemplares (IDexemplar, IDlivro, EstadoConservado, Status) VALUES (59, 85, 'Danificado', 'Em Manutenção');
INSERT INTO Exemplares (IDexemplar, IDlivro, EstadoConservado, Status) VALUES (60, 61, 'Danificado', 'Em Manutenção');
INSERT INTO Exemplares (IDexemplar, IDlivro, EstadoConservado, Status) VALUES (61, 55, 'Danificado', 'Em Manutenção');
INSERT INTO Exemplares (IDexemplar, IDlivro, EstadoConservado, Status) VALUES (62, 46, 'Desgastado', 'Em Manutenção');
INSERT INTO Exemplares (IDexemplar, IDlivro, EstadoConservado, Status) VALUES (63, 40, 'Regular', 'Emprestado');
INSERT INTO Exemplares (IDexemplar, IDlivro, EstadoConservado, Status) VALUES (64, 16, 'Bom', 'Em Manutenção');
INSERT INTO Exemplares (IDexemplar, IDlivro, EstadoConservado, Status) VALUES (65, 16, 'Danificado', 'Emprestado');
INSERT INTO Exemplares (IDexemplar, IDlivro, EstadoConservado, Status) VALUES (66, 25, 'Bom', 'Extraviado');
INSERT INTO Exemplares (IDexemplar, IDlivro, EstadoConservado, Status) VALUES (67, 36, 'Danificado', 'Em Manutenção');
INSERT INTO Exemplares (IDexemplar, IDlivro, EstadoConservado, Status) VALUES (68, 13, 'Bom', 'Em Manutenção');
INSERT INTO Exemplares (IDexemplar, IDlivro, EstadoConservado, Status) VALUES (69, 30, 'Regular', 'Emprestado');
INSERT INTO Exemplares (IDexemplar, IDlivro, EstadoConservado, Status) VALUES (70, 39, 'Novo', 'Emprestado');
INSERT INTO Exemplares (IDexemplar, IDlivro, EstadoConservado, Status) VALUES (71, 36, 'Novo', 'Disponível');
INSERT INTO Exemplares (IDexemplar, IDlivro, EstadoConservado, Status) VALUES (72, 71, 'Regular', 'Emprestado');
INSERT INTO Exemplares (IDexemplar, IDlivro, EstadoConservado, Status) VALUES (73, 82, 'Desgastado', 'Disponível');
INSERT INTO Exemplares (IDexemplar, IDlivro, EstadoConservado, Status) VALUES (74, 2, 'Danificado', 'Em Manutenção');
INSERT INTO Exemplares (IDexemplar, IDlivro, EstadoConservado, Status) VALUES (75, 61, 'Desgastado', 'Extraviado');
INSERT INTO Exemplares (IDexemplar, IDlivro, EstadoConservado, Status) VALUES (76, 44, 'Bom', 'Disponível');
INSERT INTO Exemplares (IDexemplar, IDlivro, EstadoConservado, Status) VALUES (77, 33, 'Desgastado', 'Disponível');
INSERT INTO Exemplares (IDexemplar, IDlivro, EstadoConservado, Status) VALUES (78, 9, 'Desgastado', 'Extraviado');
INSERT INTO Exemplares (IDexemplar, IDlivro, EstadoConservado, Status) VALUES (79, 10, 'Danificado', 'Disponível');
INSERT INTO Exemplares (IDexemplar, IDlivro, EstadoConservado, Status) VALUES (80, 20, 'Bom', 'Em Manutenção');
INSERT INTO Exemplares (IDexemplar, IDlivro, EstadoConservado, Status) VALUES (81, 11, 'Bom', 'Disponível');
INSERT INTO Exemplares (IDexemplar, IDlivro, EstadoConservado, Status) VALUES (82, 72, 'Desgastado', 'Emprestado');
INSERT INTO Exemplares (IDexemplar, IDlivro, EstadoConservado, Status) VALUES (83, 100, 'Danificado', 'Extraviado');
INSERT INTO Exemplares (IDexemplar, IDlivro, EstadoConservado, Status) VALUES (84, 58, 'Desgastado', 'Em Manutenção');
INSERT INTO Exemplares (IDexemplar, IDlivro, EstadoConservado, Status) VALUES (85, 76, 'Desgastado', 'Em Manutenção');
INSERT INTO Exemplares (IDexemplar, IDlivro, EstadoConservado, Status) VALUES (86, 73, 'Danificado', 'Disponível');
INSERT INTO Exemplares (IDexemplar, IDlivro, EstadoConservado, Status) VALUES (87, 79, 'Novo', 'Emprestado');
INSERT INTO Exemplares (IDexemplar, IDlivro, EstadoConservado, Status) VALUES (88, 81, 'Bom', 'Em Manutenção');
INSERT INTO Exemplares (IDexemplar, IDlivro, EstadoConservado, Status) VALUES (89, 85, 'Novo', 'Emprestado');
INSERT INTO Exemplares (IDexemplar, IDlivro, EstadoConservado, Status) VALUES (90, 31, 'Bom', 'Disponível');
INSERT INTO Exemplares (IDexemplar, IDlivro, EstadoConservado, Status) VALUES (91, 21, 'Novo', 'Extraviado');
INSERT INTO Exemplares (IDexemplar, IDlivro, EstadoConservado, Status) VALUES (92, 58, 'Danificado', 'Extraviado');
INSERT INTO Exemplares (IDexemplar, IDlivro, EstadoConservado, Status) VALUES (93, 38, 'Novo', 'Emprestado');
INSERT INTO Exemplares (IDexemplar, IDlivro, EstadoConservado, Status) VALUES (94, 37, 'Regular', 'Extraviado');
INSERT INTO Exemplares (IDexemplar, IDlivro, EstadoConservado, Status) VALUES (95, 10, 'Bom', 'Em Manutenção');
INSERT INTO Exemplares (IDexemplar, IDlivro, EstadoConservado, Status) VALUES (96, 81, 'Danificado', 'Emprestado');
INSERT INTO Exemplares (IDexemplar, IDlivro, EstadoConservado, Status) VALUES (97, 55, 'Novo', 'Emprestado');
INSERT INTO Exemplares (IDexemplar, IDlivro, EstadoConservado, Status) VALUES (98, 83, 'Bom', 'Em Manutenção');
INSERT INTO Exemplares (IDexemplar, IDlivro, EstadoConservado, Status) VALUES (99, 19, 'Novo', 'Disponível');
INSERT INTO Exemplares (IDexemplar, IDlivro, EstadoConservado, Status) VALUES (100, 22, 'Regular', 'Em Manutenção');
 
-- ---------------- Clientes ----------------
INSERT INTO Clientes (IDcliente, NomeCliente, Email, Telefone, CPF, Endereço, SenhaHash) VALUES (1, 'Larissa Santos', 'cliente1@email.com', '(31) 98679-5982', '000.000.001-07', 'Av. Getúlio Vargas, 1931 - Rio de Janeiro/RJ', '$2b$12$hash000001fakehashvalueexample');
INSERT INTO Clientes (IDcliente, NomeCliente, Email, Telefone, CPF, Endereço, SenhaHash) VALUES (2, 'Vanessa Barbosa', 'cliente2@email.com', '(31) 99090-8172', '000.000.002-14', 'Av. Brasil, 1225 - Betim/MG', '$2b$12$hash000002fakehashvalueexample');
INSERT INTO Clientes (IDcliente, NomeCliente, Email, Telefone, CPF, Endereço, SenhaHash) VALUES (3, 'Simone Carvalho', 'cliente3@email.com', '(31) 96280-5102', '000.000.003-21', 'Rua das Flores, 188 - São Paulo/SP', '$2b$12$hash000003fakehashvalueexample');
INSERT INTO Clientes (IDcliente, NomeCliente, Email, Telefone, CPF, Endereço, SenhaHash) VALUES (4, 'André Cardoso', 'cliente4@email.com', '(31) 91339-5415', '000.000.004-28', 'Av. Rio Branco, 83 - Contagem/MG', '$2b$12$hash000004fakehashvalueexample');
INSERT INTO Clientes (IDcliente, NomeCliente, Email, Telefone, CPF, Endereço, SenhaHash) VALUES (5, 'Felipe Rocha', 'cliente5@email.com', '(31) 98245-5557', '000.000.005-35', 'Rua Sete de Setembro, 1199 - Porto Alegre/RS', '$2b$12$hash000005fakehashvalueexample');
INSERT INTO Clientes (IDcliente, NomeCliente, Email, Telefone, CPF, Endereço, SenhaHash) VALUES (6, 'Débora Martins', 'cliente6@email.com', '(31) 92494-8700', '000.000.006-42', 'Rua Minas Gerais, 837 - Curitiba/PR', '$2b$12$hash000006fakehashvalueexample');
INSERT INTO Clientes (IDcliente, NomeCliente, Email, Telefone, CPF, Endereço, SenhaHash) VALUES (7, 'Patrícia Santos', 'cliente7@email.com', '(31) 93634-6403', '000.000.007-49', 'Av. Getúlio Vargas, 1421 - Salvador/BA', '$2b$12$hash000007fakehashvalueexample');
INSERT INTO Clientes (IDcliente, NomeCliente, Email, Telefone, CPF, Endereço, SenhaHash) VALUES (8, 'Rodrigo Ribeiro', 'cliente8@email.com', '(31) 91601-8451', '000.000.008-56', 'Av. Brasil, 645 - Rio de Janeiro/RJ', '$2b$12$hash000008fakehashvalueexample');
INSERT INTO Clientes (IDcliente, NomeCliente, Email, Telefone, CPF, Endereço, SenhaHash) VALUES (9, 'Patrícia Santos', 'cliente9@email.com', '(31) 97622-9431', '000.000.009-63', 'Rua das Flores, 1347 - Recife/PE', '$2b$12$hash000009fakehashvalueexample');
INSERT INTO Clientes (IDcliente, NomeCliente, Email, Telefone, CPF, Endereço, SenhaHash) VALUES (10, 'Larissa Carvalho', 'cliente10@email.com', '(31) 91888-4073', '000.000.010-70', 'Rua Bahia, 741 - Fortaleza/CE', '$2b$12$hash000010fakehashvalueexample');
INSERT INTO Clientes (IDcliente, NomeCliente, Email, Telefone, CPF, Endereço, SenhaHash) VALUES (11, 'Aline Martins', 'cliente11@email.com', '(31) 98242-1845', '000.000.011-77', 'Av. Paulista, 547 - Recife/PE', '$2b$12$hash000011fakehashvalueexample');
INSERT INTO Clientes (IDcliente, NomeCliente, Email, Telefone, CPF, Endereço, SenhaHash) VALUES (12, 'Beatriz Nascimento', 'cliente12@email.com', '(31) 98178-8941', '000.000.012-84', 'Av. Brasil, 60 - Fortaleza/CE', '$2b$12$hash000012fakehashvalueexample');
INSERT INTO Clientes (IDcliente, NomeCliente, Email, Telefone, CPF, Endereço, SenhaHash) VALUES (13, 'Gustavo Rodrigues', 'cliente13@email.com', '(31) 93594-6091', '000.000.013-91', 'Rua Bahia, 29 - Recife/PE', '$2b$12$hash000013fakehashvalueexample');
INSERT INTO Clientes (IDcliente, NomeCliente, Email, Telefone, CPF, Endereço, SenhaHash) VALUES (14, 'Marcos Oliveira', 'cliente14@email.com', '(31) 94681-2858', '000.000.014-98', 'Rua São Paulo, 1940 - Belo Horizonte/MG', '$2b$12$hash000014fakehashvalueexample');
INSERT INTO Clientes (IDcliente, NomeCliente, Email, Telefone, CPF, Endereço, SenhaHash) VALUES (15, 'Débora Pereira', 'cliente15@email.com', '(31) 99165-5781', '000.000.015-05', 'Rua Bahia, 1445 - Rio de Janeiro/RJ', '$2b$12$hash000015fakehashvalueexample');
INSERT INTO Clientes (IDcliente, NomeCliente, Email, Telefone, CPF, Endereço, SenhaHash) VALUES (16, 'Marcos Martins', 'cliente16@email.com', '(31) 98736-4993', '000.000.016-12', 'Rua São Paulo, 1129 - Contagem/MG', '$2b$12$hash000016fakehashvalueexample');
INSERT INTO Clientes (IDcliente, NomeCliente, Email, Telefone, CPF, Endereço, SenhaHash) VALUES (17, 'Juliana Ferreira', 'cliente17@email.com', '(31) 99327-3236', '000.000.017-19', 'Av. Brasil, 566 - Porto Alegre/RS', '$2b$12$hash000017fakehashvalueexample');
INSERT INTO Clientes (IDcliente, NomeCliente, Email, Telefone, CPF, Endereço, SenhaHash) VALUES (18, 'Patrícia Rocha', 'cliente18@email.com', '(31) 95377-1042', '000.000.018-26', 'Rua XV de Novembro, 1487 - Rio de Janeiro/RJ', '$2b$12$hash000018fakehashvalueexample');
INSERT INTO Clientes (IDcliente, NomeCliente, Email, Telefone, CPF, Endereço, SenhaHash) VALUES (19, 'Tatiane Cardoso', 'cliente19@email.com', '(31) 99022-3434', '000.000.019-33', 'Rua São Paulo, 1104 - Salvador/BA', '$2b$12$hash000019fakehashvalueexample');
INSERT INTO Clientes (IDcliente, NomeCliente, Email, Telefone, CPF, Endereço, SenhaHash) VALUES (20, 'Eduardo Lima', 'cliente20@email.com', '(31) 99903-7180', '000.000.020-40', 'Rua São Paulo, 1911 - Curitiba/PR', '$2b$12$hash000020fakehashvalueexample');
INSERT INTO Clientes (IDcliente, NomeCliente, Email, Telefone, CPF, Endereço, SenhaHash) VALUES (21, 'Leonardo Ferreira', 'cliente21@email.com', '(31) 94912-7274', '000.000.021-47', 'Av. Paulista, 1754 - Porto Alegre/RS', '$2b$12$hash000021fakehashvalueexample');
INSERT INTO Clientes (IDcliente, NomeCliente, Email, Telefone, CPF, Endereço, SenhaHash) VALUES (22, 'Carlos Lima', 'cliente22@email.com', '(31) 98749-7246', '000.000.022-54', 'Av. Getúlio Vargas, 1360 - Contagem/MG', '$2b$12$hash000022fakehashvalueexample');
INSERT INTO Clientes (IDcliente, NomeCliente, Email, Telefone, CPF, Endereço, SenhaHash) VALUES (23, 'Felipe Souza', 'cliente23@email.com', '(31) 93068-9229', '000.000.023-61', 'Av. Rio Branco, 680 - Belo Horizonte/MG', '$2b$12$hash000023fakehashvalueexample');
INSERT INTO Clientes (IDcliente, NomeCliente, Email, Telefone, CPF, Endereço, SenhaHash) VALUES (24, 'Leonardo Gomes', 'cliente24@email.com', '(31) 92633-9617', '000.000.024-68', 'Rua São Paulo, 32 - Contagem/MG', '$2b$12$hash000024fakehashvalueexample');
INSERT INTO Clientes (IDcliente, NomeCliente, Email, Telefone, CPF, Endereço, SenhaHash) VALUES (25, 'Marcos Pereira', 'cliente25@email.com', '(31) 92225-8692', '000.000.025-75', 'Rua XV de Novembro, 694 - Fortaleza/CE', '$2b$12$hash000025fakehashvalueexample');
INSERT INTO Clientes (IDcliente, NomeCliente, Email, Telefone, CPF, Endereço, SenhaHash) VALUES (26, 'Priscila Ribeiro', 'cliente26@email.com', '(31) 92315-6383', '000.000.026-82', 'Rua Bahia, 779 - Curitiba/PR', '$2b$12$hash000026fakehashvalueexample');
INSERT INTO Clientes (IDcliente, NomeCliente, Email, Telefone, CPF, Endereço, SenhaHash) VALUES (27, 'Débora Martins', 'cliente27@email.com', '(31) 99864-1588', '000.000.027-89', 'Av. Rio Branco, 141 - São Paulo/SP', '$2b$12$hash000027fakehashvalueexample');
INSERT INTO Clientes (IDcliente, NomeCliente, Email, Telefone, CPF, Endereço, SenhaHash) VALUES (28, 'Débora Nascimento', 'cliente28@email.com', '(31) 94727-2480', '000.000.028-96', 'Av. Getúlio Vargas, 202 - Belo Horizonte/MG', '$2b$12$hash000028fakehashvalueexample');
INSERT INTO Clientes (IDcliente, NomeCliente, Email, Telefone, CPF, Endereço, SenhaHash) VALUES (29, 'Larissa Costa', 'cliente29@email.com', '(31) 95906-1474', '000.000.029-03', 'Rua das Flores, 665 - Betim/MG', '$2b$12$hash000029fakehashvalueexample');
INSERT INTO Clientes (IDcliente, NomeCliente, Email, Telefone, CPF, Endereço, SenhaHash) VALUES (30, 'Rodrigo Araújo', 'cliente30@email.com', '(31) 97141-8056', '000.000.030-10', 'Rua Sete de Setembro, 501 - Recife/PE', '$2b$12$hash000030fakehashvalueexample');
INSERT INTO Clientes (IDcliente, NomeCliente, Email, Telefone, CPF, Endereço, SenhaHash) VALUES (31, 'Marcos Cardoso', 'cliente31@email.com', '(31) 93950-3785', '000.000.031-17', 'Rua Sete de Setembro, 162 - Fortaleza/CE', '$2b$12$hash000031fakehashvalueexample');
INSERT INTO Clientes (IDcliente, NomeCliente, Email, Telefone, CPF, Endereço, SenhaHash) VALUES (32, 'Leonardo Ribeiro', 'cliente32@email.com', '(31) 94945-9153', '000.000.032-24', 'Av. Rio Branco, 294 - São Paulo/SP', '$2b$12$hash000032fakehashvalueexample');
INSERT INTO Clientes (IDcliente, NomeCliente, Email, Telefone, CPF, Endereço, SenhaHash) VALUES (33, 'Larissa Almeida', 'cliente33@email.com', '(31) 98529-5183', '000.000.033-31', 'Rua das Flores, 1841 - Salvador/BA', '$2b$12$hash000033fakehashvalueexample');
INSERT INTO Clientes (IDcliente, NomeCliente, Email, Telefone, CPF, Endereço, SenhaHash) VALUES (34, 'Simone Nascimento', 'cliente34@email.com', '(31) 99955-3588', '000.000.034-38', 'Av. Brasil, 905 - Curitiba/PR', '$2b$12$hash000034fakehashvalueexample');
INSERT INTO Clientes (IDcliente, NomeCliente, Email, Telefone, CPF, Endereço, SenhaHash) VALUES (35, 'Renata Nascimento', 'cliente35@email.com', '(31) 97951-5097', '000.000.035-45', 'Rua São Paulo, 1732 - Rio de Janeiro/RJ', '$2b$12$hash000035fakehashvalueexample');
INSERT INTO Clientes (IDcliente, NomeCliente, Email, Telefone, CPF, Endereço, SenhaHash) VALUES (36, 'Fernanda Ribeiro', 'cliente36@email.com', '(31) 98916-2747', '000.000.036-52', 'Av. Paulista, 782 - Fortaleza/CE', '$2b$12$hash000036fakehashvalueexample');
INSERT INTO Clientes (IDcliente, NomeCliente, Email, Telefone, CPF, Endereço, SenhaHash) VALUES (37, 'Eduardo Cardoso', 'cliente37@email.com', '(31) 95847-5837', '000.000.037-59', 'Rua das Flores, 1700 - Porto Alegre/RS', '$2b$12$hash000037fakehashvalueexample');
INSERT INTO Clientes (IDcliente, NomeCliente, Email, Telefone, CPF, Endereço, SenhaHash) VALUES (38, 'Camila Silva', 'cliente38@email.com', '(31) 91803-9138', '000.000.038-66', 'Rua XV de Novembro, 1589 - São Paulo/SP', '$2b$12$hash000038fakehashvalueexample');
INSERT INTO Clientes (IDcliente, NomeCliente, Email, Telefone, CPF, Endereço, SenhaHash) VALUES (39, 'Bruno Araújo', 'cliente39@email.com', '(31) 94588-4115', '000.000.039-73', 'Av. Rio Branco, 514 - Contagem/MG', '$2b$12$hash000039fakehashvalueexample');
INSERT INTO Clientes (IDcliente, NomeCliente, Email, Telefone, CPF, Endereço, SenhaHash) VALUES (40, 'Débora Santos', 'cliente40@email.com', '(31) 91645-6061', '000.000.040-80', 'Rua São Paulo, 69 - Fortaleza/CE', '$2b$12$hash000040fakehashvalueexample');
INSERT INTO Clientes (IDcliente, NomeCliente, Email, Telefone, CPF, Endereço, SenhaHash) VALUES (41, 'Eduardo Pereira', 'cliente41@email.com', '(31) 92476-5835', '000.000.041-87', 'Rua Minas Gerais, 1531 - Porto Alegre/RS', '$2b$12$hash000041fakehashvalueexample');
INSERT INTO Clientes (IDcliente, NomeCliente, Email, Telefone, CPF, Endereço, SenhaHash) VALUES (42, 'Rafael Ferreira', 'cliente42@email.com', '(31) 93165-9837', '000.000.042-94', 'Rua Minas Gerais, 1088 - Recife/PE', '$2b$12$hash000042fakehashvalueexample');
INSERT INTO Clientes (IDcliente, NomeCliente, Email, Telefone, CPF, Endereço, SenhaHash) VALUES (43, 'Ricardo Almeida', 'cliente43@email.com', '(31) 93695-5210', '000.000.043-01', 'Rua São Paulo, 1982 - Rio de Janeiro/RJ', '$2b$12$hash000043fakehashvalueexample');
INSERT INTO Clientes (IDcliente, NomeCliente, Email, Telefone, CPF, Endereço, SenhaHash) VALUES (44, 'Diego Lima', 'cliente44@email.com', '(31) 92886-8673', '000.000.044-08', 'Av. Brasil, 289 - São Paulo/SP', '$2b$12$hash000044fakehashvalueexample');
INSERT INTO Clientes (IDcliente, NomeCliente, Email, Telefone, CPF, Endereço, SenhaHash) VALUES (45, 'Leonardo Ribeiro', 'cliente45@email.com', '(31) 96992-2479', '000.000.045-15', 'Av. Getúlio Vargas, 29 - Rio de Janeiro/RJ', '$2b$12$hash000045fakehashvalueexample');
INSERT INTO Clientes (IDcliente, NomeCliente, Email, Telefone, CPF, Endereço, SenhaHash) VALUES (46, 'Thiago Santos', 'cliente46@email.com', '(31) 98451-7038', '000.000.046-22', 'Rua XV de Novembro, 1198 - Porto Alegre/RS', '$2b$12$hash000046fakehashvalueexample');
INSERT INTO Clientes (IDcliente, NomeCliente, Email, Telefone, CPF, Endereço, SenhaHash) VALUES (47, 'Tatiane Araújo', 'cliente47@email.com', '(31) 92775-4830', '000.000.047-29', 'Rua São Paulo, 52 - Fortaleza/CE', '$2b$12$hash000047fakehashvalueexample');
INSERT INTO Clientes (IDcliente, NomeCliente, Email, Telefone, CPF, Endereço, SenhaHash) VALUES (48, 'Simone Barbosa', 'cliente48@email.com', '(31) 96374-4626', '000.000.048-36', 'Av. Brasil, 1302 - Salvador/BA', '$2b$12$hash000048fakehashvalueexample');
INSERT INTO Clientes (IDcliente, NomeCliente, Email, Telefone, CPF, Endereço, SenhaHash) VALUES (49, 'Ricardo Nascimento', 'cliente49@email.com', '(31) 97689-2911', '000.000.049-43', 'Rua Sete de Setembro, 93 - Betim/MG', '$2b$12$hash000049fakehashvalueexample');
INSERT INTO Clientes (IDcliente, NomeCliente, Email, Telefone, CPF, Endereço, SenhaHash) VALUES (50, 'Rodrigo Martins', 'cliente50@email.com', '(31) 92902-2592', '000.000.050-50', 'Av. Paulista, 1818 - Recife/PE', '$2b$12$hash000050fakehashvalueexample');
INSERT INTO Clientes (IDcliente, NomeCliente, Email, Telefone, CPF, Endereço, SenhaHash) VALUES (51, 'Beatriz Ribeiro', 'cliente51@email.com', '(31) 98432-7078', '000.000.051-57', 'Rua Bahia, 859 - Fortaleza/CE', '$2b$12$hash000051fakehashvalueexample');
INSERT INTO Clientes (IDcliente, NomeCliente, Email, Telefone, CPF, Endereço, SenhaHash) VALUES (52, 'Diego Pereira', 'cliente52@email.com', '(31) 97797-2622', '000.000.052-64', 'Rua São Paulo, 1261 - Porto Alegre/RS', '$2b$12$hash000052fakehashvalueexample');
INSERT INTO Clientes (IDcliente, NomeCliente, Email, Telefone, CPF, Endereço, SenhaHash) VALUES (53, 'Camila Souza', 'cliente53@email.com', '(31) 97070-4559', '000.000.053-71', 'Rua São Paulo, 911 - São Paulo/SP', '$2b$12$hash000053fakehashvalueexample');
INSERT INTO Clientes (IDcliente, NomeCliente, Email, Telefone, CPF, Endereço, SenhaHash) VALUES (54, 'Leonardo Araújo', 'cliente54@email.com', '(31) 92627-7018', '000.000.054-78', 'Rua Bahia, 1847 - Curitiba/PR', '$2b$12$hash000054fakehashvalueexample');
INSERT INTO Clientes (IDcliente, NomeCliente, Email, Telefone, CPF, Endereço, SenhaHash) VALUES (55, 'Carlos Ribeiro', 'cliente55@email.com', '(31) 95520-4109', '000.000.055-85', 'Av. Brasil, 1944 - Salvador/BA', '$2b$12$hash000055fakehashvalueexample');
INSERT INTO Clientes (IDcliente, NomeCliente, Email, Telefone, CPF, Endereço, SenhaHash) VALUES (56, 'Mariana Ferreira', 'cliente56@email.com', '(31) 91349-1828', '000.000.056-92', 'Rua Minas Gerais, 499 - Contagem/MG', '$2b$12$hash000056fakehashvalueexample');
INSERT INTO Clientes (IDcliente, NomeCliente, Email, Telefone, CPF, Endereço, SenhaHash) VALUES (57, 'Gustavo Cardoso', 'cliente57@email.com', '(31) 94362-2124', '000.000.057-99', 'Rua Bahia, 425 - Fortaleza/CE', '$2b$12$hash000057fakehashvalueexample');
INSERT INTO Clientes (IDcliente, NomeCliente, Email, Telefone, CPF, Endereço, SenhaHash) VALUES (58, 'Fernanda Rodrigues', 'cliente58@email.com', '(31) 96383-3417', '000.000.058-06', 'Av. Rio Branco, 6 - Rio de Janeiro/RJ', '$2b$12$hash000058fakehashvalueexample');
INSERT INTO Clientes (IDcliente, NomeCliente, Email, Telefone, CPF, Endereço, SenhaHash) VALUES (59, 'Leonardo Pereira', 'cliente59@email.com', '(31) 93129-9850', '000.000.059-13', 'Rua XV de Novembro, 1636 - Contagem/MG', '$2b$12$hash000059fakehashvalueexample');
INSERT INTO Clientes (IDcliente, NomeCliente, Email, Telefone, CPF, Endereço, SenhaHash) VALUES (60, 'João Silva', 'cliente60@email.com', '(31) 93159-1243', '000.000.060-20', 'Rua Minas Gerais, 1618 - São Paulo/SP', '$2b$12$hash000060fakehashvalueexample');
INSERT INTO Clientes (IDcliente, NomeCliente, Email, Telefone, CPF, Endereço, SenhaHash) VALUES (61, 'Renata Lima', 'cliente61@email.com', '(31) 91258-3854', '000.000.061-27', 'Rua XV de Novembro, 108 - Contagem/MG', '$2b$12$hash000061fakehashvalueexample');
INSERT INTO Clientes (IDcliente, NomeCliente, Email, Telefone, CPF, Endereço, SenhaHash) VALUES (62, 'Diego Carvalho', 'cliente62@email.com', '(31) 99619-2862', '000.000.062-34', 'Av. Brasil, 976 - Salvador/BA', '$2b$12$hash000062fakehashvalueexample');
INSERT INTO Clientes (IDcliente, NomeCliente, Email, Telefone, CPF, Endereço, SenhaHash) VALUES (63, 'Aline Araújo', 'cliente63@email.com', '(31) 99408-2786', '000.000.063-41', 'Rua São Paulo, 1032 - São Paulo/SP', '$2b$12$hash000063fakehashvalueexample');
INSERT INTO Clientes (IDcliente, NomeCliente, Email, Telefone, CPF, Endereço, SenhaHash) VALUES (64, 'Bruno Souza', 'cliente64@email.com', '(31) 99543-5941', '000.000.064-48', 'Rua São Paulo, 1318 - Betim/MG', '$2b$12$hash000064fakehashvalueexample');
INSERT INTO Clientes (IDcliente, NomeCliente, Email, Telefone, CPF, Endereço, SenhaHash) VALUES (65, 'Carlos Martins', 'cliente65@email.com', '(31) 97580-7984', '000.000.065-55', 'Av. Brasil, 1005 - Salvador/BA', '$2b$12$hash000065fakehashvalueexample');
INSERT INTO Clientes (IDcliente, NomeCliente, Email, Telefone, CPF, Endereço, SenhaHash) VALUES (66, 'Mariana Oliveira', 'cliente66@email.com', '(31) 96277-3430', '000.000.066-62', 'Av. Brasil, 259 - Rio de Janeiro/RJ', '$2b$12$hash000066fakehashvalueexample');
INSERT INTO Clientes (IDcliente, NomeCliente, Email, Telefone, CPF, Endereço, SenhaHash) VALUES (67, 'Bruno Cardoso', 'cliente67@email.com', '(31) 99984-6327', '000.000.067-69', 'Av. Getúlio Vargas, 1224 - Recife/PE', '$2b$12$hash000067fakehashvalueexample');
INSERT INTO Clientes (IDcliente, NomeCliente, Email, Telefone, CPF, Endereço, SenhaHash) VALUES (68, 'Rodrigo Gomes', 'cliente68@email.com', '(31) 99282-8048', '000.000.068-76', 'Av. Brasil, 1625 - Belo Horizonte/MG', '$2b$12$hash000068fakehashvalueexample');
INSERT INTO Clientes (IDcliente, NomeCliente, Email, Telefone, CPF, Endereço, SenhaHash) VALUES (69, 'Leonardo Barbosa', 'cliente69@email.com', '(31) 94522-8046', '000.000.069-83', 'Rua São Paulo, 1819 - São Paulo/SP', '$2b$12$hash000069fakehashvalueexample');
INSERT INTO Clientes (IDcliente, NomeCliente, Email, Telefone, CPF, Endereço, SenhaHash) VALUES (70, 'Marcos Lima', 'cliente70@email.com', '(31) 98430-7532', '000.000.070-90', 'Av. Getúlio Vargas, 1495 - Belo Horizonte/MG', '$2b$12$hash000070fakehashvalueexample');
INSERT INTO Clientes (IDcliente, NomeCliente, Email, Telefone, CPF, Endereço, SenhaHash) VALUES (71, 'Patrícia Carvalho', 'cliente71@email.com', '(31) 96120-5176', '000.000.071-97', 'Rua Minas Gerais, 1953 - Contagem/MG', '$2b$12$hash000071fakehashvalueexample');
INSERT INTO Clientes (IDcliente, NomeCliente, Email, Telefone, CPF, Endereço, SenhaHash) VALUES (72, 'André Martins', 'cliente72@email.com', '(31) 92099-2494', '000.000.072-04', 'Av. Brasil, 191 - Porto Alegre/RS', '$2b$12$hash000072fakehashvalueexample');
INSERT INTO Clientes (IDcliente, NomeCliente, Email, Telefone, CPF, Endereço, SenhaHash) VALUES (73, 'João Araújo', 'cliente73@email.com', '(31) 93131-1982', '000.000.073-11', 'Av. Rio Branco, 1960 - Recife/PE', '$2b$12$hash000073fakehashvalueexample');
INSERT INTO Clientes (IDcliente, NomeCliente, Email, Telefone, CPF, Endereço, SenhaHash) VALUES (74, 'Thiago Lima', 'cliente74@email.com', '(31) 93002-7730', '000.000.074-18', 'Rua Minas Gerais, 1790 - Porto Alegre/RS', '$2b$12$hash000074fakehashvalueexample');
INSERT INTO Clientes (IDcliente, NomeCliente, Email, Telefone, CPF, Endereço, SenhaHash) VALUES (75, 'Leonardo Souza', 'cliente75@email.com', '(31) 95712-6119', '000.000.075-25', 'Rua Minas Gerais, 213 - Fortaleza/CE', '$2b$12$hash000075fakehashvalueexample');
INSERT INTO Clientes (IDcliente, NomeCliente, Email, Telefone, CPF, Endereço, SenhaHash) VALUES (76, 'Vanessa Ferreira', 'cliente76@email.com', '(31) 93535-8900', '000.000.076-32', 'Av. Paulista, 1736 - Belo Horizonte/MG', '$2b$12$hash000076fakehashvalueexample');
INSERT INTO Clientes (IDcliente, NomeCliente, Email, Telefone, CPF, Endereço, SenhaHash) VALUES (77, 'Eduardo Barbosa', 'cliente77@email.com', '(31) 97022-2882', '000.000.077-39', 'Rua XV de Novembro, 1176 - São Paulo/SP', '$2b$12$hash000077fakehashvalueexample');
INSERT INTO Clientes (IDcliente, NomeCliente, Email, Telefone, CPF, Endereço, SenhaHash) VALUES (78, 'Gustavo Carvalho', 'cliente78@email.com', '(31) 91430-5381', '000.000.078-46', 'Rua das Flores, 370 - Rio de Janeiro/RJ', '$2b$12$hash000078fakehashvalueexample');
INSERT INTO Clientes (IDcliente, NomeCliente, Email, Telefone, CPF, Endereço, SenhaHash) VALUES (79, 'Priscila Nascimento', 'cliente79@email.com', '(31) 96567-6751', '000.000.079-53', 'Rua das Flores, 372 - Contagem/MG', '$2b$12$hash000079fakehashvalueexample');
INSERT INTO Clientes (IDcliente, NomeCliente, Email, Telefone, CPF, Endereço, SenhaHash) VALUES (80, 'Renata Ribeiro', 'cliente80@email.com', '(31) 92140-3324', '000.000.080-60', 'Rua das Flores, 188 - Recife/PE', '$2b$12$hash000080fakehashvalueexample');
INSERT INTO Clientes (IDcliente, NomeCliente, Email, Telefone, CPF, Endereço, SenhaHash) VALUES (81, 'Fernanda Ribeiro', 'cliente81@email.com', '(31) 97878-8432', '000.000.081-67', 'Rua Minas Gerais, 323 - Curitiba/PR', '$2b$12$hash000081fakehashvalueexample');
INSERT INTO Clientes (IDcliente, NomeCliente, Email, Telefone, CPF, Endereço, SenhaHash) VALUES (82, 'Rodrigo Lima', 'cliente82@email.com', '(31) 92391-1861', '000.000.082-74', 'Rua Sete de Setembro, 323 - Fortaleza/CE', '$2b$12$hash000082fakehashvalueexample');
INSERT INTO Clientes (IDcliente, NomeCliente, Email, Telefone, CPF, Endereço, SenhaHash) VALUES (83, 'Carlos Oliveira', 'cliente83@email.com', '(31) 95458-8259', '000.000.083-81', 'Av. Getúlio Vargas, 995 - Fortaleza/CE', '$2b$12$hash000083fakehashvalueexample');
INSERT INTO Clientes (IDcliente, NomeCliente, Email, Telefone, CPF, Endereço, SenhaHash) VALUES (84, 'Larissa Carvalho', 'cliente84@email.com', '(31) 95475-4531', '000.000.084-88', 'Rua Bahia, 234 - Curitiba/PR', '$2b$12$hash000084fakehashvalueexample');
INSERT INTO Clientes (IDcliente, NomeCliente, Email, Telefone, CPF, Endereço, SenhaHash) VALUES (85, 'Marcos Santos', 'cliente85@email.com', '(31) 95640-8972', '000.000.085-95', 'Rua Bahia, 1367 - Rio de Janeiro/RJ', '$2b$12$hash000085fakehashvalueexample');
INSERT INTO Clientes (IDcliente, NomeCliente, Email, Telefone, CPF, Endereço, SenhaHash) VALUES (86, 'Carlos Rodrigues', 'cliente86@email.com', '(31) 97475-1897', '000.000.086-02', 'Rua das Flores, 419 - Rio de Janeiro/RJ', '$2b$12$hash000086fakehashvalueexample');
INSERT INTO Clientes (IDcliente, NomeCliente, Email, Telefone, CPF, Endereço, SenhaHash) VALUES (87, 'Fernanda Pereira', 'cliente87@email.com', '(31) 95186-5742', '000.000.087-09', 'Rua Minas Gerais, 246 - Betim/MG', '$2b$12$hash000087fakehashvalueexample');
INSERT INTO Clientes (IDcliente, NomeCliente, Email, Telefone, CPF, Endereço, SenhaHash) VALUES (88, 'Felipe Carvalho', 'cliente88@email.com', '(31) 93878-3116', '000.000.088-16', 'Av. Getúlio Vargas, 1091 - São Paulo/SP', '$2b$12$hash000088fakehashvalueexample');
INSERT INTO Clientes (IDcliente, NomeCliente, Email, Telefone, CPF, Endereço, SenhaHash) VALUES (89, 'Vanessa Barbosa', 'cliente89@email.com', '(31) 96802-2180', '000.000.089-23', 'Av. Getúlio Vargas, 1765 - Betim/MG', '$2b$12$hash000089fakehashvalueexample');
INSERT INTO Clientes (IDcliente, NomeCliente, Email, Telefone, CPF, Endereço, SenhaHash) VALUES (90, 'Marcos Silva', 'cliente90@email.com', '(31) 98532-2275', '000.000.090-30', 'Rua Minas Gerais, 1180 - Porto Alegre/RS', '$2b$12$hash000090fakehashvalueexample');
INSERT INTO Clientes (IDcliente, NomeCliente, Email, Telefone, CPF, Endereço, SenhaHash) VALUES (91, 'Renata Ribeiro', 'cliente91@email.com', '(31) 97843-5743', '000.000.091-37', 'Av. Brasil, 830 - Betim/MG', '$2b$12$hash000091fakehashvalueexample');
INSERT INTO Clientes (IDcliente, NomeCliente, Email, Telefone, CPF, Endereço, SenhaHash) VALUES (92, 'Patrícia Costa', 'cliente92@email.com', '(31) 98538-6928', '000.000.092-44', 'Av. Brasil, 895 - Belo Horizonte/MG', '$2b$12$hash000092fakehashvalueexample');
INSERT INTO Clientes (IDcliente, NomeCliente, Email, Telefone, CPF, Endereço, SenhaHash) VALUES (93, 'Lucas Carvalho', 'cliente93@email.com', '(31) 97560-9584', '000.000.093-51', 'Av. Brasil, 811 - Rio de Janeiro/RJ', '$2b$12$hash000093fakehashvalueexample');
INSERT INTO Clientes (IDcliente, NomeCliente, Email, Telefone, CPF, Endereço, SenhaHash) VALUES (94, 'Diego Lima', 'cliente94@email.com', '(31) 94630-6456', '000.000.094-58', 'Rua Sete de Setembro, 157 - Recife/PE', '$2b$12$hash000094fakehashvalueexample');
INSERT INTO Clientes (IDcliente, NomeCliente, Email, Telefone, CPF, Endereço, SenhaHash) VALUES (95, 'Débora Santos', 'cliente95@email.com', '(31) 99693-9355', '000.000.095-65', 'Av. Paulista, 1856 - Curitiba/PR', '$2b$12$hash000095fakehashvalueexample');
INSERT INTO Clientes (IDcliente, NomeCliente, Email, Telefone, CPF, Endereço, SenhaHash) VALUES (96, 'Eduardo Pereira', 'cliente96@email.com', '(31) 94871-2684', '000.000.096-72', 'Rua Sete de Setembro, 525 - São Paulo/SP', '$2b$12$hash000096fakehashvalueexample');
INSERT INTO Clientes (IDcliente, NomeCliente, Email, Telefone, CPF, Endereço, SenhaHash) VALUES (97, 'Rafael Teixeira', 'cliente97@email.com', '(31) 93504-2234', '000.000.097-79', 'Rua Sete de Setembro, 1949 - Salvador/BA', '$2b$12$hash000097fakehashvalueexample');
INSERT INTO Clientes (IDcliente, NomeCliente, Email, Telefone, CPF, Endereço, SenhaHash) VALUES (98, 'Larissa Cardoso', 'cliente98@email.com', '(31) 98354-6295', '000.000.098-86', 'Rua Minas Gerais, 310 - Salvador/BA', '$2b$12$hash000098fakehashvalueexample');
INSERT INTO Clientes (IDcliente, NomeCliente, Email, Telefone, CPF, Endereço, SenhaHash) VALUES (99, 'Mariana Martins', 'cliente99@email.com', '(31) 98245-5961', '000.000.099-93', 'Rua XV de Novembro, 1212 - Betim/MG', '$2b$12$hash000099fakehashvalueexample');
INSERT INTO Clientes (IDcliente, NomeCliente, Email, Telefone, CPF, Endereço, SenhaHash) VALUES (100, 'Eduardo Rocha', 'cliente100@email.com', '(31) 92215-6085', '000.000.100-00', 'Rua São Paulo, 926 - Betim/MG', '$2b$12$hash000100fakehashvalueexample');
 
-- ---------------- Emprestimos ----------------
INSERT INTO Emprestimos (IDemprestimo, IDcliente, IDexemplar, DataDeEmprestimo, DevoluçaoPrevista, DevoluçaoReal, Status) VALUES (1, 8, 48, '2026-03-02', '2026-03-16', '2026-03-16', 'Devolvido');
INSERT INTO Emprestimos (IDemprestimo, IDcliente, IDexemplar, DataDeEmprestimo, DevoluçaoPrevista, DevoluçaoReal, Status) VALUES (2, 83, 12, '2025-11-11', '2025-11-25', NULL, 'Atrasado');
INSERT INTO Emprestimos (IDemprestimo, IDcliente, IDexemplar, DataDeEmprestimo, DevoluçaoPrevista, DevoluçaoReal, Status) VALUES (3, 65, 50, '2025-08-25', '2025-09-08', NULL, 'Atrasado');
INSERT INTO Emprestimos (IDemprestimo, IDcliente, IDexemplar, DataDeEmprestimo, DevoluçaoPrevista, DevoluçaoReal, Status) VALUES (4, 71, 95, '2026-04-04', '2026-04-18', NULL, 'Em Andamento');
INSERT INTO Emprestimos (IDemprestimo, IDcliente, IDexemplar, DataDeEmprestimo, DevoluçaoPrevista, DevoluçaoReal, Status) VALUES (5, 58, 74, '2025-11-30', '2025-12-14', NULL, 'Em Andamento');
INSERT INTO Emprestimos (IDemprestimo, IDcliente, IDexemplar, DataDeEmprestimo, DevoluçaoPrevista, DevoluçaoReal, Status) VALUES (6, 42, 78, '2025-09-01', '2025-09-15', NULL, 'Atrasado');
INSERT INTO Emprestimos (IDemprestimo, IDcliente, IDexemplar, DataDeEmprestimo, DevoluçaoPrevista, DevoluçaoReal, Status) VALUES (7, 20, 8, '2025-08-19', '2025-09-02', NULL, 'Em Andamento');
INSERT INTO Emprestimos (IDemprestimo, IDcliente, IDexemplar, DataDeEmprestimo, DevoluçaoPrevista, DevoluçaoReal, Status) VALUES (8, 44, 92, '2025-02-13', '2025-02-27', NULL, 'Atrasado');
INSERT INTO Emprestimos (IDemprestimo, IDcliente, IDexemplar, DataDeEmprestimo, DevoluçaoPrevista, DevoluçaoReal, Status) VALUES (9, 83, 23, '2025-01-21', '2025-02-04', NULL, 'Em Andamento');
INSERT INTO Emprestimos (IDemprestimo, IDcliente, IDexemplar, DataDeEmprestimo, DevoluçaoPrevista, DevoluçaoReal, Status) VALUES (10, 91, 57, '2025-08-13', '2025-08-27', NULL, 'Atrasado');
INSERT INTO Emprestimos (IDemprestimo, IDcliente, IDexemplar, DataDeEmprestimo, DevoluçaoPrevista, DevoluçaoReal, Status) VALUES (11, 67, 79, '2025-03-23', '2025-04-06', '2025-04-04', 'Devolvido');
INSERT INTO Emprestimos (IDemprestimo, IDcliente, IDexemplar, DataDeEmprestimo, DevoluçaoPrevista, DevoluçaoReal, Status) VALUES (12, 37, 50, '2025-07-29', '2025-08-12', '2025-08-07', 'Devolvido');
INSERT INTO Emprestimos (IDemprestimo, IDcliente, IDexemplar, DataDeEmprestimo, DevoluçaoPrevista, DevoluçaoReal, Status) VALUES (13, 77, 7, '2026-02-09', '2026-02-23', NULL, 'Atrasado');
INSERT INTO Emprestimos (IDemprestimo, IDcliente, IDexemplar, DataDeEmprestimo, DevoluçaoPrevista, DevoluçaoReal, Status) VALUES (14, 83, 43, '2025-02-03', '2025-02-17', '2025-02-17', 'Devolvido');
INSERT INTO Emprestimos (IDemprestimo, IDcliente, IDexemplar, DataDeEmprestimo, DevoluçaoPrevista, DevoluçaoReal, Status) VALUES (15, 72, 87, '2025-07-17', '2025-07-31', '2025-07-29', 'Devolvido');
INSERT INTO Emprestimos (IDemprestimo, IDcliente, IDexemplar, DataDeEmprestimo, DevoluçaoPrevista, DevoluçaoReal, Status) VALUES (16, 93, 85, '2026-05-09', '2026-05-23', NULL, 'Atrasado');
INSERT INTO Emprestimos (IDemprestimo, IDcliente, IDexemplar, DataDeEmprestimo, DevoluçaoPrevista, DevoluçaoReal, Status) VALUES (17, 20, 43, '2025-02-11', '2025-02-25', NULL, 'Atrasado');
INSERT INTO Emprestimos (IDemprestimo, IDcliente, IDexemplar, DataDeEmprestimo, DevoluçaoPrevista, DevoluçaoReal, Status) VALUES (18, 85, 19, '2026-04-15', '2026-04-29', '2026-04-27', 'Devolvido');
INSERT INTO Emprestimos (IDemprestimo, IDcliente, IDexemplar, DataDeEmprestimo, DevoluçaoPrevista, DevoluçaoReal, Status) VALUES (19, 84, 90, '2025-12-06', '2025-12-20', '2025-12-19', 'Devolvido');
INSERT INTO Emprestimos (IDemprestimo, IDcliente, IDexemplar, DataDeEmprestimo, DevoluçaoPrevista, DevoluçaoReal, Status) VALUES (20, 77, 91, '2026-04-26', '2026-05-10', NULL, 'Em Andamento');
INSERT INTO Emprestimos (IDemprestimo, IDcliente, IDexemplar, DataDeEmprestimo, DevoluçaoPrevista, DevoluçaoReal, Status) VALUES (21, 40, 72, '2025-07-12', '2025-07-26', NULL, 'Atrasado');
INSERT INTO Emprestimos (IDemprestimo, IDcliente, IDexemplar, DataDeEmprestimo, DevoluçaoPrevista, DevoluçaoReal, Status) VALUES (22, 43, 17, '2025-12-10', '2025-12-24', NULL, 'Atrasado');
INSERT INTO Emprestimos (IDemprestimo, IDcliente, IDexemplar, DataDeEmprestimo, DevoluçaoPrevista, DevoluçaoReal, Status) VALUES (23, 95, 88, '2026-04-13', '2026-04-27', NULL, 'Atrasado');
INSERT INTO Emprestimos (IDemprestimo, IDcliente, IDexemplar, DataDeEmprestimo, DevoluçaoPrevista, DevoluçaoReal, Status) VALUES (24, 12, 83, '2025-12-10', '2025-12-24', '2025-12-20', 'Devolvido');
INSERT INTO Emprestimos (IDemprestimo, IDcliente, IDexemplar, DataDeEmprestimo, DevoluçaoPrevista, DevoluçaoReal, Status) VALUES (25, 47, 3, '2025-07-05', '2025-07-19', '2025-07-18', 'Devolvido');
INSERT INTO Emprestimos (IDemprestimo, IDcliente, IDexemplar, DataDeEmprestimo, DevoluçaoPrevista, DevoluçaoReal, Status) VALUES (26, 28, 44, '2026-05-01', '2026-05-15', '2026-05-14', 'Devolvido');
INSERT INTO Emprestimos (IDemprestimo, IDcliente, IDexemplar, DataDeEmprestimo, DevoluçaoPrevista, DevoluçaoReal, Status) VALUES (27, 29, 18, '2025-03-21', '2025-04-04', NULL, 'Em Andamento');
INSERT INTO Emprestimos (IDemprestimo, IDcliente, IDexemplar, DataDeEmprestimo, DevoluçaoPrevista, DevoluçaoReal, Status) VALUES (28, 38, 13, '2025-09-17', '2025-10-01', NULL, 'Atrasado');
INSERT INTO Emprestimos (IDemprestimo, IDcliente, IDexemplar, DataDeEmprestimo, DevoluçaoPrevista, DevoluçaoReal, Status) VALUES (29, 95, 68, '2025-01-20', '2025-02-03', NULL, 'Atrasado');
INSERT INTO Emprestimos (IDemprestimo, IDcliente, IDexemplar, DataDeEmprestimo, DevoluçaoPrevista, DevoluçaoReal, Status) VALUES (30, 44, 99, '2025-11-13', '2025-11-27', NULL, 'Em Andamento');
INSERT INTO Emprestimos (IDemprestimo, IDcliente, IDexemplar, DataDeEmprestimo, DevoluçaoPrevista, DevoluçaoReal, Status) VALUES (31, 77, 49, '2025-03-20', '2025-04-03', NULL, 'Em Andamento');
INSERT INTO Emprestimos (IDemprestimo, IDcliente, IDexemplar, DataDeEmprestimo, DevoluçaoPrevista, DevoluçaoReal, Status) VALUES (32, 24, 89, '2026-01-30', '2026-02-13', NULL, 'Atrasado');
INSERT INTO Emprestimos (IDemprestimo, IDcliente, IDexemplar, DataDeEmprestimo, DevoluçaoPrevista, DevoluçaoReal, Status) VALUES (33, 22, 93, '2025-08-13', '2025-08-27', NULL, 'Em Andamento');
INSERT INTO Emprestimos (IDemprestimo, IDcliente, IDexemplar, DataDeEmprestimo, DevoluçaoPrevista, DevoluçaoReal, Status) VALUES (34, 53, 47, '2025-12-13', '2025-12-27', NULL, 'Atrasado');
INSERT INTO Emprestimos (IDemprestimo, IDcliente, IDexemplar, DataDeEmprestimo, DevoluçaoPrevista, DevoluçaoReal, Status) VALUES (35, 31, 57, '2025-11-09', '2025-11-23', '2025-11-18', 'Devolvido');
INSERT INTO Emprestimos (IDemprestimo, IDcliente, IDexemplar, DataDeEmprestimo, DevoluçaoPrevista, DevoluçaoReal, Status) VALUES (36, 58, 30, '2025-10-01', '2025-10-15', NULL, 'Em Andamento');
INSERT INTO Emprestimos (IDemprestimo, IDcliente, IDexemplar, DataDeEmprestimo, DevoluçaoPrevista, DevoluçaoReal, Status) VALUES (37, 40, 61, '2026-04-08', '2026-04-22', NULL, 'Em Andamento');
INSERT INTO Emprestimos (IDemprestimo, IDcliente, IDexemplar, DataDeEmprestimo, DevoluçaoPrevista, DevoluçaoReal, Status) VALUES (38, 48, 87, '2026-04-30', '2026-05-14', NULL, 'Atrasado');
INSERT INTO Emprestimos (IDemprestimo, IDcliente, IDexemplar, DataDeEmprestimo, DevoluçaoPrevista, DevoluçaoReal, Status) VALUES (39, 57, 60, '2026-01-29', '2026-02-12', '2026-02-09', 'Devolvido');
INSERT INTO Emprestimos (IDemprestimo, IDcliente, IDexemplar, DataDeEmprestimo, DevoluçaoPrevista, DevoluçaoReal, Status) VALUES (40, 65, 68, '2025-08-03', '2025-08-17', NULL, 'Em Andamento');
INSERT INTO Emprestimos (IDemprestimo, IDcliente, IDexemplar, DataDeEmprestimo, DevoluçaoPrevista, DevoluçaoReal, Status) VALUES (41, 26, 78, '2025-03-12', '2025-03-26', '2025-03-26', 'Devolvido');
INSERT INTO Emprestimos (IDemprestimo, IDcliente, IDexemplar, DataDeEmprestimo, DevoluçaoPrevista, DevoluçaoReal, Status) VALUES (42, 83, 62, '2026-03-24', '2026-04-07', '2026-04-03', 'Devolvido');
INSERT INTO Emprestimos (IDemprestimo, IDcliente, IDexemplar, DataDeEmprestimo, DevoluçaoPrevista, DevoluçaoReal, Status) VALUES (43, 14, 92, '2026-03-10', '2026-03-24', NULL, 'Atrasado');
INSERT INTO Emprestimos (IDemprestimo, IDcliente, IDexemplar, DataDeEmprestimo, DevoluçaoPrevista, DevoluçaoReal, Status) VALUES (44, 16, 37, '2025-02-12', '2025-02-26', NULL, 'Em Andamento');
INSERT INTO Emprestimos (IDemprestimo, IDcliente, IDexemplar, DataDeEmprestimo, DevoluçaoPrevista, DevoluçaoReal, Status) VALUES (45, 35, 58, '2026-04-09', '2026-04-23', NULL, 'Atrasado');
INSERT INTO Emprestimos (IDemprestimo, IDcliente, IDexemplar, DataDeEmprestimo, DevoluçaoPrevista, DevoluçaoReal, Status) VALUES (46, 19, 56, '2025-02-16', '2025-03-02', NULL, 'Em Andamento');
INSERT INTO Emprestimos (IDemprestimo, IDcliente, IDexemplar, DataDeEmprestimo, DevoluçaoPrevista, DevoluçaoReal, Status) VALUES (47, 58, 45, '2026-04-22', '2026-05-06', NULL, 'Em Andamento');
INSERT INTO Emprestimos (IDemprestimo, IDcliente, IDexemplar, DataDeEmprestimo, DevoluçaoPrevista, DevoluçaoReal, Status) VALUES (48, 54, 7, '2025-07-22', '2025-08-05', NULL, 'Atrasado');
INSERT INTO Emprestimos (IDemprestimo, IDcliente, IDexemplar, DataDeEmprestimo, DevoluçaoPrevista, DevoluçaoReal, Status) VALUES (49, 48, 31, '2025-07-17', '2025-07-31', NULL, 'Em Andamento');
INSERT INTO Emprestimos (IDemprestimo, IDcliente, IDexemplar, DataDeEmprestimo, DevoluçaoPrevista, DevoluçaoReal, Status) VALUES (50, 48, 29, '2025-01-15', '2025-01-29', '2025-01-29', 'Devolvido');
INSERT INTO Emprestimos (IDemprestimo, IDcliente, IDexemplar, DataDeEmprestimo, DevoluçaoPrevista, DevoluçaoReal, Status) VALUES (51, 92, 84, '2025-06-21', '2025-07-05', NULL, 'Em Andamento');
INSERT INTO Emprestimos (IDemprestimo, IDcliente, IDexemplar, DataDeEmprestimo, DevoluçaoPrevista, DevoluçaoReal, Status) VALUES (52, 18, 5, '2025-05-27', '2025-06-10', '2025-06-05', 'Devolvido');
INSERT INTO Emprestimos (IDemprestimo, IDcliente, IDexemplar, DataDeEmprestimo, DevoluçaoPrevista, DevoluçaoReal, Status) VALUES (53, 18, 98, '2025-12-28', '2026-01-11', '2026-01-08', 'Devolvido');
INSERT INTO Emprestimos (IDemprestimo, IDcliente, IDexemplar, DataDeEmprestimo, DevoluçaoPrevista, DevoluçaoReal, Status) VALUES (54, 79, 1, '2026-04-09', '2026-04-23', NULL, 'Em Andamento');
INSERT INTO Emprestimos (IDemprestimo, IDcliente, IDexemplar, DataDeEmprestimo, DevoluçaoPrevista, DevoluçaoReal, Status) VALUES (55, 3, 33, '2025-04-21', '2025-05-05', NULL, 'Em Andamento');
INSERT INTO Emprestimos (IDemprestimo, IDcliente, IDexemplar, DataDeEmprestimo, DevoluçaoPrevista, DevoluçaoReal, Status) VALUES (56, 71, 94, '2025-11-08', '2025-11-22', NULL, 'Atrasado');
INSERT INTO Emprestimos (IDemprestimo, IDcliente, IDexemplar, DataDeEmprestimo, DevoluçaoPrevista, DevoluçaoReal, Status) VALUES (57, 55, 15, '2026-02-02', '2026-02-16', '2026-02-15', 'Devolvido');
INSERT INTO Emprestimos (IDemprestimo, IDcliente, IDexemplar, DataDeEmprestimo, DevoluçaoPrevista, DevoluçaoReal, Status) VALUES (58, 39, 16, '2025-01-25', '2025-02-08', NULL, 'Em Andamento');
INSERT INTO Emprestimos (IDemprestimo, IDcliente, IDexemplar, DataDeEmprestimo, DevoluçaoPrevista, DevoluçaoReal, Status) VALUES (59, 54, 82, '2026-02-11', '2026-02-25', NULL, 'Atrasado');
INSERT INTO Emprestimos (IDemprestimo, IDcliente, IDexemplar, DataDeEmprestimo, DevoluçaoPrevista, DevoluçaoReal, Status) VALUES (60, 59, 9, '2025-02-26', '2025-03-12', '2025-03-08', 'Devolvido');
INSERT INTO Emprestimos (IDemprestimo, IDcliente, IDexemplar, DataDeEmprestimo, DevoluçaoPrevista, DevoluçaoReal, Status) VALUES (61, 69, 3, '2025-11-20', '2025-12-04', NULL, 'Atrasado');
INSERT INTO Emprestimos (IDemprestimo, IDcliente, IDexemplar, DataDeEmprestimo, DevoluçaoPrevista, DevoluçaoReal, Status) VALUES (62, 74, 31, '2026-01-03', '2026-01-17', NULL, 'Em Andamento');
INSERT INTO Emprestimos (IDemprestimo, IDcliente, IDexemplar, DataDeEmprestimo, DevoluçaoPrevista, DevoluçaoReal, Status) VALUES (63, 38, 55, '2025-01-01', '2025-01-15', NULL, 'Atrasado');
INSERT INTO Emprestimos (IDemprestimo, IDcliente, IDexemplar, DataDeEmprestimo, DevoluçaoPrevista, DevoluçaoReal, Status) VALUES (64, 46, 31, '2025-10-20', '2025-11-03', '2025-11-02', 'Devolvido');
INSERT INTO Emprestimos (IDemprestimo, IDcliente, IDexemplar, DataDeEmprestimo, DevoluçaoPrevista, DevoluçaoReal, Status) VALUES (65, 86, 86, '2025-02-13', '2025-02-27', NULL, 'Atrasado');
INSERT INTO Emprestimos (IDemprestimo, IDcliente, IDexemplar, DataDeEmprestimo, DevoluçaoPrevista, DevoluçaoReal, Status) VALUES (66, 47, 9, '2026-05-04', '2026-05-18', NULL, 'Atrasado');
INSERT INTO Emprestimos (IDemprestimo, IDcliente, IDexemplar, DataDeEmprestimo, DevoluçaoPrevista, DevoluçaoReal, Status) VALUES (67, 70, 65, '2026-02-07', '2026-02-21', NULL, 'Atrasado');
INSERT INTO Emprestimos (IDemprestimo, IDcliente, IDexemplar, DataDeEmprestimo, DevoluçaoPrevista, DevoluçaoReal, Status) VALUES (68, 71, 3, '2025-07-19', '2025-08-02', '2025-08-02', 'Devolvido');
INSERT INTO Emprestimos (IDemprestimo, IDcliente, IDexemplar, DataDeEmprestimo, DevoluçaoPrevista, DevoluçaoReal, Status) VALUES (69, 82, 50, '2025-07-11', '2025-07-25', '2025-07-20', 'Devolvido');
INSERT INTO Emprestimos (IDemprestimo, IDcliente, IDexemplar, DataDeEmprestimo, DevoluçaoPrevista, DevoluçaoReal, Status) VALUES (70, 3, 46, '2026-02-08', '2026-02-22', NULL, 'Em Andamento');
INSERT INTO Emprestimos (IDemprestimo, IDcliente, IDexemplar, DataDeEmprestimo, DevoluçaoPrevista, DevoluçaoReal, Status) VALUES (71, 45, 31, '2026-01-11', '2026-01-25', NULL, 'Atrasado');
INSERT INTO Emprestimos (IDemprestimo, IDcliente, IDexemplar, DataDeEmprestimo, DevoluçaoPrevista, DevoluçaoReal, Status) VALUES (72, 81, 14, '2026-01-31', '2026-02-14', NULL, 'Atrasado');
INSERT INTO Emprestimos (IDemprestimo, IDcliente, IDexemplar, DataDeEmprestimo, DevoluçaoPrevista, DevoluçaoReal, Status) VALUES (73, 95, 97, '2025-06-20', '2025-07-04', NULL, 'Em Andamento');
INSERT INTO Emprestimos (IDemprestimo, IDcliente, IDexemplar, DataDeEmprestimo, DevoluçaoPrevista, DevoluçaoReal, Status) VALUES (74, 6, 46, '2025-10-07', '2025-10-21', '2025-10-16', 'Devolvido');
INSERT INTO Emprestimos (IDemprestimo, IDcliente, IDexemplar, DataDeEmprestimo, DevoluçaoPrevista, DevoluçaoReal, Status) VALUES (75, 23, 100, '2025-12-17', '2025-12-31', '2025-12-26', 'Devolvido');
INSERT INTO Emprestimos (IDemprestimo, IDcliente, IDexemplar, DataDeEmprestimo, DevoluçaoPrevista, DevoluçaoReal, Status) VALUES (76, 62, 81, '2025-04-04', '2025-04-18', NULL, 'Em Andamento');
INSERT INTO Emprestimos (IDemprestimo, IDcliente, IDexemplar, DataDeEmprestimo, DevoluçaoPrevista, DevoluçaoReal, Status) VALUES (77, 9, 92, '2026-02-02', '2026-02-16', '2026-02-16', 'Devolvido');
INSERT INTO Emprestimos (IDemprestimo, IDcliente, IDexemplar, DataDeEmprestimo, DevoluçaoPrevista, DevoluçaoReal, Status) VALUES (78, 38, 26, '2025-01-23', '2025-02-06', NULL, 'Em Andamento');
INSERT INTO Emprestimos (IDemprestimo, IDcliente, IDexemplar, DataDeEmprestimo, DevoluçaoPrevista, DevoluçaoReal, Status) VALUES (79, 6, 41, '2026-04-23', '2026-05-07', '2026-05-03', 'Devolvido');
INSERT INTO Emprestimos (IDemprestimo, IDcliente, IDexemplar, DataDeEmprestimo, DevoluçaoPrevista, DevoluçaoReal, Status) VALUES (80, 51, 70, '2025-08-31', '2025-09-14', '2025-09-14', 'Devolvido');
INSERT INTO Emprestimos (IDemprestimo, IDcliente, IDexemplar, DataDeEmprestimo, DevoluçaoPrevista, DevoluçaoReal, Status) VALUES (81, 97, 83, '2025-04-08', '2025-04-22', '2025-04-20', 'Devolvido');
INSERT INTO Emprestimos (IDemprestimo, IDcliente, IDexemplar, DataDeEmprestimo, DevoluçaoPrevista, DevoluçaoReal, Status) VALUES (82, 100, 7, '2026-03-20', '2026-04-03', NULL, 'Atrasado');
INSERT INTO Emprestimos (IDemprestimo, IDcliente, IDexemplar, DataDeEmprestimo, DevoluçaoPrevista, DevoluçaoReal, Status) VALUES (83, 43, 35, '2025-03-05', '2025-03-19', '2025-03-16', 'Devolvido');
INSERT INTO Emprestimos (IDemprestimo, IDcliente, IDexemplar, DataDeEmprestimo, DevoluçaoPrevista, DevoluçaoReal, Status) VALUES (84, 52, 96, '2025-08-14', '2025-08-28', '2025-08-26', 'Devolvido');
INSERT INTO Emprestimos (IDemprestimo, IDcliente, IDexemplar, DataDeEmprestimo, DevoluçaoPrevista, DevoluçaoReal, Status) VALUES (85, 24, 64, '2025-12-21', '2026-01-04', '2026-01-02', 'Devolvido');
INSERT INTO Emprestimos (IDemprestimo, IDcliente, IDexemplar, DataDeEmprestimo, DevoluçaoPrevista, DevoluçaoReal, Status) VALUES (86, 67, 35, '2026-02-15', '2026-03-01', NULL, 'Em Andamento');
INSERT INTO Emprestimos (IDemprestimo, IDcliente, IDexemplar, DataDeEmprestimo, DevoluçaoPrevista, DevoluçaoReal, Status) VALUES (87, 94, 55, '2025-02-10', '2025-02-24', '2025-02-20', 'Devolvido');
INSERT INTO Emprestimos (IDemprestimo, IDcliente, IDexemplar, DataDeEmprestimo, DevoluçaoPrevista, DevoluçaoReal, Status) VALUES (88, 24, 70, '2025-05-31', '2025-06-14', '2025-06-14', 'Devolvido');
INSERT INTO Emprestimos (IDemprestimo, IDcliente, IDexemplar, DataDeEmprestimo, DevoluçaoPrevista, DevoluçaoReal, Status) VALUES (89, 11, 42, '2025-12-05', '2025-12-19', '2025-12-17', 'Devolvido');
INSERT INTO Emprestimos (IDemprestimo, IDcliente, IDexemplar, DataDeEmprestimo, DevoluçaoPrevista, DevoluçaoReal, Status) VALUES (90, 58, 78, '2026-01-03', '2026-01-17', '2026-01-16', 'Devolvido');
INSERT INTO Emprestimos (IDemprestimo, IDcliente, IDexemplar, DataDeEmprestimo, DevoluçaoPrevista, DevoluçaoReal, Status) VALUES (91, 89, 57, '2025-06-29', '2025-07-13', '2025-07-13', 'Devolvido');
INSERT INTO Emprestimos (IDemprestimo, IDcliente, IDexemplar, DataDeEmprestimo, DevoluçaoPrevista, DevoluçaoReal, Status) VALUES (92, 94, 46, '2025-11-11', '2025-11-25', '2025-11-23', 'Devolvido');
INSERT INTO Emprestimos (IDemprestimo, IDcliente, IDexemplar, DataDeEmprestimo, DevoluçaoPrevista, DevoluçaoReal, Status) VALUES (93, 82, 8, '2025-02-08', '2025-02-22', NULL, 'Atrasado');
INSERT INTO Emprestimos (IDemprestimo, IDcliente, IDexemplar, DataDeEmprestimo, DevoluçaoPrevista, DevoluçaoReal, Status) VALUES (94, 82, 52, '2025-07-06', '2025-07-20', NULL, 'Atrasado');
INSERT INTO Emprestimos (IDemprestimo, IDcliente, IDexemplar, DataDeEmprestimo, DevoluçaoPrevista, DevoluçaoReal, Status) VALUES (95, 96, 87, '2025-03-23', '2025-04-06', NULL, 'Em Andamento');
INSERT INTO Emprestimos (IDemprestimo, IDcliente, IDexemplar, DataDeEmprestimo, DevoluçaoPrevista, DevoluçaoReal, Status) VALUES (96, 19, 78, '2025-12-14', '2025-12-28', '2025-12-28', 'Devolvido');
INSERT INTO Emprestimos (IDemprestimo, IDcliente, IDexemplar, DataDeEmprestimo, DevoluçaoPrevista, DevoluçaoReal, Status) VALUES (97, 17, 9, '2025-05-01', '2025-05-15', NULL, 'Atrasado');
INSERT INTO Emprestimos (IDemprestimo, IDcliente, IDexemplar, DataDeEmprestimo, DevoluçaoPrevista, DevoluçaoReal, Status) VALUES (98, 47, 47, '2025-07-16', '2025-07-30', NULL, 'Atrasado');
INSERT INTO Emprestimos (IDemprestimo, IDcliente, IDexemplar, DataDeEmprestimo, DevoluçaoPrevista, DevoluçaoReal, Status) VALUES (99, 5, 78, '2025-03-20', '2025-04-03', NULL, 'Atrasado');
INSERT INTO Emprestimos (IDemprestimo, IDcliente, IDexemplar, DataDeEmprestimo, DevoluçaoPrevista, DevoluçaoReal, Status) VALUES (100, 58, 48, '2025-07-10', '2025-07-24', '2025-07-24', 'Devolvido');
 
-- ---------------- Multas ----------------
INSERT INTO Multas (IDmulta, IDemprestimo, ValorMulta, StatusMulta) VALUES (1, 1, 48.04, 'Cancelada');
INSERT INTO Multas (IDmulta, IDemprestimo, ValorMulta, StatusMulta) VALUES (2, 2, 32.52, 'Paga');
INSERT INTO Multas (IDmulta, IDemprestimo, ValorMulta, StatusMulta) VALUES (3, 3, 53.72, 'Pendente');
INSERT INTO Multas (IDmulta, IDemprestimo, ValorMulta, StatusMulta) VALUES (4, 4, 77.04, 'Pendente');
INSERT INTO Multas (IDmulta, IDemprestimo, ValorMulta, StatusMulta) VALUES (5, 5, 60.18, 'Paga');
INSERT INTO Multas (IDmulta, IDemprestimo, ValorMulta, StatusMulta) VALUES (6, 6, 43.83, 'Cancelada');
INSERT INTO Multas (IDmulta, IDemprestimo, ValorMulta, StatusMulta) VALUES (7, 7, 13.83, 'Paga');
INSERT INTO Multas (IDmulta, IDemprestimo, ValorMulta, StatusMulta) VALUES (8, 8, 57.80, 'Pendente');
INSERT INTO Multas (IDmulta, IDemprestimo, ValorMulta, StatusMulta) VALUES (9, 9, 79.73, 'Paga');
INSERT INTO Multas (IDmulta, IDemprestimo, ValorMulta, StatusMulta) VALUES (10, 10, 57.05, 'Paga');
INSERT INTO Multas (IDmulta, IDemprestimo, ValorMulta, StatusMulta) VALUES (11, 11, 20.01, 'Pendente');
INSERT INTO Multas (IDmulta, IDemprestimo, ValorMulta, StatusMulta) VALUES (12, 12, 68.96, 'Paga');
INSERT INTO Multas (IDmulta, IDemprestimo, ValorMulta, StatusMulta) VALUES (13, 13, 17.95, 'Cancelada');
INSERT INTO Multas (IDmulta, IDemprestimo, ValorMulta, StatusMulta) VALUES (14, 14, 38.38, 'Pendente');
INSERT INTO Multas (IDmulta, IDemprestimo, ValorMulta, StatusMulta) VALUES (15, 15, 65.79, 'Paga');
INSERT INTO Multas (IDmulta, IDemprestimo, ValorMulta, StatusMulta) VALUES (16, 16, 55.09, 'Cancelada');
INSERT INTO Multas (IDmulta, IDemprestimo, ValorMulta, StatusMulta) VALUES (17, 17, 9.87, 'Cancelada');
INSERT INTO Multas (IDmulta, IDemprestimo, ValorMulta, StatusMulta) VALUES (18, 18, 26.78, 'Paga');
INSERT INTO Multas (IDmulta, IDemprestimo, ValorMulta, StatusMulta) VALUES (19, 19, 68.85, 'Cancelada');
INSERT INTO Multas (IDmulta, IDemprestimo, ValorMulta, StatusMulta) VALUES (20, 20, 58.22, 'Cancelada');
INSERT INTO Multas (IDmulta, IDemprestimo, ValorMulta, StatusMulta) VALUES (21, 21, 52.83, 'Paga');
INSERT INTO Multas (IDmulta, IDemprestimo, ValorMulta, StatusMulta) VALUES (22, 22, 43.16, 'Pendente');
INSERT INTO Multas (IDmulta, IDemprestimo, ValorMulta, StatusMulta) VALUES (23, 23, 78.88, 'Pendente');
INSERT INTO Multas (IDmulta, IDemprestimo, ValorMulta, StatusMulta) VALUES (24, 24, 22.76, 'Paga');
INSERT INTO Multas (IDmulta, IDemprestimo, ValorMulta, StatusMulta) VALUES (25, 25, 6.97, 'Cancelada');
INSERT INTO Multas (IDmulta, IDemprestimo, ValorMulta, StatusMulta) VALUES (26, 26, 47.92, 'Paga');
INSERT INTO Multas (IDmulta, IDemprestimo, ValorMulta, StatusMulta) VALUES (27, 27, 65.27, 'Cancelada');
INSERT INTO Multas (IDmulta, IDemprestimo, ValorMulta, StatusMulta) VALUES (28, 28, 14.73, 'Pendente');
INSERT INTO Multas (IDmulta, IDemprestimo, ValorMulta, StatusMulta) VALUES (29, 29, 9.93, 'Paga');
INSERT INTO Multas (IDmulta, IDemprestimo, ValorMulta, StatusMulta) VALUES (30, 30, 79.97, 'Cancelada');
INSERT INTO Multas (IDmulta, IDemprestimo, ValorMulta, StatusMulta) VALUES (31, 31, 40.90, 'Paga');
INSERT INTO Multas (IDmulta, IDemprestimo, ValorMulta, StatusMulta) VALUES (32, 32, 62.69, 'Cancelada');
INSERT INTO Multas (IDmulta, IDemprestimo, ValorMulta, StatusMulta) VALUES (33, 33, 10.53, 'Paga');
INSERT INTO Multas (IDmulta, IDemprestimo, ValorMulta, StatusMulta) VALUES (34, 34, 53.18, 'Paga');
INSERT INTO Multas (IDmulta, IDemprestimo, ValorMulta, StatusMulta) VALUES (35, 35, 39.94, 'Cancelada');
INSERT INTO Multas (IDmulta, IDemprestimo, ValorMulta, StatusMulta) VALUES (36, 36, 30.84, 'Cancelada');
INSERT INTO Multas (IDmulta, IDemprestimo, ValorMulta, StatusMulta) VALUES (37, 37, 52.98, 'Pendente');
INSERT INTO Multas (IDmulta, IDemprestimo, ValorMulta, StatusMulta) VALUES (38, 38, 62.58, 'Pendente');
INSERT INTO Multas (IDmulta, IDemprestimo, ValorMulta, StatusMulta) VALUES (39, 39, 37.45, 'Pendente');
INSERT INTO Multas (IDmulta, IDemprestimo, ValorMulta, StatusMulta) VALUES (40, 40, 67.35, 'Cancelada');
INSERT INTO Multas (IDmulta, IDemprestimo, ValorMulta, StatusMulta) VALUES (41, 41, 16.48, 'Pendente');
INSERT INTO Multas (IDmulta, IDemprestimo, ValorMulta, StatusMulta) VALUES (42, 42, 17.15, 'Cancelada');
INSERT INTO Multas (IDmulta, IDemprestimo, ValorMulta, StatusMulta) VALUES (43, 43, 21.91, 'Cancelada');
INSERT INTO Multas (IDmulta, IDemprestimo, ValorMulta, StatusMulta) VALUES (44, 44, 72.12, 'Pendente');
INSERT INTO Multas (IDmulta, IDemprestimo, ValorMulta, StatusMulta) VALUES (45, 45, 23.80, 'Cancelada');
INSERT INTO Multas (IDmulta, IDemprestimo, ValorMulta, StatusMulta) VALUES (46, 46, 76.73, 'Paga');
INSERT INTO Multas (IDmulta, IDemprestimo, ValorMulta, StatusMulta) VALUES (47, 47, 14.39, 'Paga');
INSERT INTO Multas (IDmulta, IDemprestimo, ValorMulta, StatusMulta) VALUES (48, 48, 51.08, 'Pendente');
INSERT INTO Multas (IDmulta, IDemprestimo, ValorMulta, StatusMulta) VALUES (49, 49, 42.69, 'Pendente');
INSERT INTO Multas (IDmulta, IDemprestimo, ValorMulta, StatusMulta) VALUES (50, 50, 49.39, 'Cancelada');
INSERT INTO Multas (IDmulta, IDemprestimo, ValorMulta, StatusMulta) VALUES (51, 51, 16.56, 'Cancelada');
INSERT INTO Multas (IDmulta, IDemprestimo, ValorMulta, StatusMulta) VALUES (52, 52, 51.84, 'Cancelada');
INSERT INTO Multas (IDmulta, IDemprestimo, ValorMulta, StatusMulta) VALUES (53, 53, 30.32, 'Cancelada');
INSERT INTO Multas (IDmulta, IDemprestimo, ValorMulta, StatusMulta) VALUES (54, 54, 8.09, 'Pendente');
INSERT INTO Multas (IDmulta, IDemprestimo, ValorMulta, StatusMulta) VALUES (55, 55, 11.09, 'Cancelada');
INSERT INTO Multas (IDmulta, IDemprestimo, ValorMulta, StatusMulta) VALUES (56, 56, 62.83, 'Paga');
INSERT INTO Multas (IDmulta, IDemprestimo, ValorMulta, StatusMulta) VALUES (57, 57, 53.83, 'Cancelada');
INSERT INTO Multas (IDmulta, IDemprestimo, ValorMulta, StatusMulta) VALUES (58, 58, 36.24, 'Cancelada');
INSERT INTO Multas (IDmulta, IDemprestimo, ValorMulta, StatusMulta) VALUES (59, 59, 7.27, 'Cancelada');
INSERT INTO Multas (IDmulta, IDemprestimo, ValorMulta, StatusMulta) VALUES (60, 60, 45.92, 'Cancelada');
INSERT INTO Multas (IDmulta, IDemprestimo, ValorMulta, StatusMulta) VALUES (61, 61, 76.75, 'Paga');
INSERT INTO Multas (IDmulta, IDemprestimo, ValorMulta, StatusMulta) VALUES (62, 62, 23.37, 'Cancelada');
INSERT INTO Multas (IDmulta, IDemprestimo, ValorMulta, StatusMulta) VALUES (63, 63, 35.46, 'Paga');
INSERT INTO Multas (IDmulta, IDemprestimo, ValorMulta, StatusMulta) VALUES (64, 64, 10.47, 'Pendente');
INSERT INTO Multas (IDmulta, IDemprestimo, ValorMulta, StatusMulta) VALUES (65, 65, 16.86, 'Paga');
INSERT INTO Multas (IDmulta, IDemprestimo, ValorMulta, StatusMulta) VALUES (66, 66, 41.32, 'Pendente');
INSERT INTO Multas (IDmulta, IDemprestimo, ValorMulta, StatusMulta) VALUES (67, 67, 30.51, 'Pendente');
INSERT INTO Multas (IDmulta, IDemprestimo, ValorMulta, StatusMulta) VALUES (68, 68, 28.44, 'Cancelada');
INSERT INTO Multas (IDmulta, IDemprestimo, ValorMulta, StatusMulta) VALUES (69, 69, 28.95, 'Paga');
INSERT INTO Multas (IDmulta, IDemprestimo, ValorMulta, StatusMulta) VALUES (70, 70, 78.15, 'Pendente');
INSERT INTO Multas (IDmulta, IDemprestimo, ValorMulta, StatusMulta) VALUES (71, 71, 62.05, 'Cancelada');
INSERT INTO Multas (IDmulta, IDemprestimo, ValorMulta, StatusMulta) VALUES (72, 72, 47.12, 'Paga');
INSERT INTO Multas (IDmulta, IDemprestimo, ValorMulta, StatusMulta) VALUES (73, 73, 23.13, 'Pendente');
INSERT INTO Multas (IDmulta, IDemprestimo, ValorMulta, StatusMulta) VALUES (74, 74, 25.06, 'Pendente');
INSERT INTO Multas (IDmulta, IDemprestimo, ValorMulta, StatusMulta) VALUES (75, 75, 15.57, 'Pendente');
INSERT INTO Multas (IDmulta, IDemprestimo, ValorMulta, StatusMulta) VALUES (76, 76, 26.77, 'Paga');
INSERT INTO Multas (IDmulta, IDemprestimo, ValorMulta, StatusMulta) VALUES (77, 77, 69.81, 'Paga');
INSERT INTO Multas (IDmulta, IDemprestimo, ValorMulta, StatusMulta) VALUES (78, 78, 23.62, 'Pendente');
INSERT INTO Multas (IDmulta, IDemprestimo, ValorMulta, StatusMulta) VALUES (79, 79, 66.01, 'Cancelada');
INSERT INTO Multas (IDmulta, IDemprestimo, ValorMulta, StatusMulta) VALUES (80, 80, 59.08, 'Pendente');
INSERT INTO Multas (IDmulta, IDemprestimo, ValorMulta, StatusMulta) VALUES (81, 81, 62.23, 'Paga');
INSERT INTO Multas (IDmulta, IDemprestimo, ValorMulta, StatusMulta) VALUES (82, 82, 79.70, 'Paga');
INSERT INTO Multas (IDmulta, IDemprestimo, ValorMulta, StatusMulta) VALUES (83, 83, 42.41, 'Paga');
INSERT INTO Multas (IDmulta, IDemprestimo, ValorMulta, StatusMulta) VALUES (84, 84, 42.30, 'Pendente');
INSERT INTO Multas (IDmulta, IDemprestimo, ValorMulta, StatusMulta) VALUES (85, 85, 75.89, 'Cancelada');
INSERT INTO Multas (IDmulta, IDemprestimo, ValorMulta, StatusMulta) VALUES (86, 86, 39.29, 'Pendente');
INSERT INTO Multas (IDmulta, IDemprestimo, ValorMulta, StatusMulta) VALUES (87, 87, 21.14, 'Paga');
INSERT INTO Multas (IDmulta, IDemprestimo, ValorMulta, StatusMulta) VALUES (88, 88, 8.65, 'Paga');
INSERT INTO Multas (IDmulta, IDemprestimo, ValorMulta, StatusMulta) VALUES (89, 89, 42.12, 'Cancelada');
INSERT INTO Multas (IDmulta, IDemprestimo, ValorMulta, StatusMulta) VALUES (90, 90, 55.44, 'Paga');
INSERT INTO Multas (IDmulta, IDemprestimo, ValorMulta, StatusMulta) VALUES (91, 91, 45.25, 'Pendente');
INSERT INTO Multas (IDmulta, IDemprestimo, ValorMulta, StatusMulta) VALUES (92, 92, 37.32, 'Paga');
INSERT INTO Multas (IDmulta, IDemprestimo, ValorMulta, StatusMulta) VALUES (93, 93, 59.56, 'Paga');
INSERT INTO Multas (IDmulta, IDemprestimo, ValorMulta, StatusMulta) VALUES (94, 94, 32.45, 'Paga');
INSERT INTO Multas (IDmulta, IDemprestimo, ValorMulta, StatusMulta) VALUES (95, 95, 8.84, 'Cancelada');
INSERT INTO Multas (IDmulta, IDemprestimo, ValorMulta, StatusMulta) VALUES (96, 96, 19.60, 'Cancelada');
INSERT INTO Multas (IDmulta, IDemprestimo, ValorMulta, StatusMulta) VALUES (97, 97, 26.65, 'Paga');
INSERT INTO Multas (IDmulta, IDemprestimo, ValorMulta, StatusMulta) VALUES (98, 98, 42.82, 'Cancelada');
INSERT INTO Multas (IDmulta, IDemprestimo, ValorMulta, StatusMulta) VALUES (99, 99, 25.98, 'Cancelada');
INSERT INTO Multas (IDmulta, IDemprestimo, ValorMulta, StatusMulta) VALUES (100, 100, 56.03, 'Pendente');
 
-- ---------------- Pagamentos ----------------
INSERT INTO Pagamentos (IDpagamento, IDmulta, MetodoPagamento, Status, DataPagamento) VALUES (1, 1, 'Cartão de Débito', 'Confirmado', '2025-07-21');
INSERT INTO Pagamentos (IDpagamento, IDmulta, MetodoPagamento, Status, DataPagamento) VALUES (2, 2, 'Pix', 'Pendente', '2025-10-13');
INSERT INTO Pagamentos (IDpagamento, IDmulta, MetodoPagamento, Status, DataPagamento) VALUES (3, 3, 'Pix', 'Confirmado', '2025-04-12');
INSERT INTO Pagamentos (IDpagamento, IDmulta, MetodoPagamento, Status, DataPagamento) VALUES (4, 4, 'Dinheiro', 'Cancelado', '2025-07-25');
INSERT INTO Pagamentos (IDpagamento, IDmulta, MetodoPagamento, Status, DataPagamento) VALUES (5, 5, 'Dinheiro', 'Confirmado', '2025-01-24');
INSERT INTO Pagamentos (IDpagamento, IDmulta, MetodoPagamento, Status, DataPagamento) VALUES (6, 6, 'Cartão de Crédito', 'Confirmado', '2026-01-01');
INSERT INTO Pagamentos (IDpagamento, IDmulta, MetodoPagamento, Status, DataPagamento) VALUES (7, 7, 'Pix', 'Pendente', '2025-09-23');
INSERT INTO Pagamentos (IDpagamento, IDmulta, MetodoPagamento, Status, DataPagamento) VALUES (8, 8, 'Boleto', 'Confirmado', '2025-11-07');
INSERT INTO Pagamentos (IDpagamento, IDmulta, MetodoPagamento, Status, DataPagamento) VALUES (9, 9, 'Dinheiro', 'Confirmado', '2025-06-17');
INSERT INTO Pagamentos (IDpagamento, IDmulta, MetodoPagamento, Status, DataPagamento) VALUES (10, 10, 'Dinheiro', 'Pendente', '2025-03-25');
INSERT INTO Pagamentos (IDpagamento, IDmulta, MetodoPagamento, Status, DataPagamento) VALUES (11, 11, 'Boleto', 'Cancelado', '2026-01-14');
INSERT INTO Pagamentos (IDpagamento, IDmulta, MetodoPagamento, Status, DataPagamento) VALUES (12, 12, 'Pix', 'Cancelado', '2025-06-22');
INSERT INTO Pagamentos (IDpagamento, IDmulta, MetodoPagamento, Status, DataPagamento) VALUES (13, 13, 'Dinheiro', 'Cancelado', '2025-09-30');
INSERT INTO Pagamentos (IDpagamento, IDmulta, MetodoPagamento, Status, DataPagamento) VALUES (14, 14, 'Boleto', 'Cancelado', '2025-10-16');
INSERT INTO Pagamentos (IDpagamento, IDmulta, MetodoPagamento, Status, DataPagamento) VALUES (15, 15, 'Pix', 'Pendente', '2026-02-22');
INSERT INTO Pagamentos (IDpagamento, IDmulta, MetodoPagamento, Status, DataPagamento) VALUES (16, 16, 'Cartão de Crédito', 'Pendente', '2025-06-19');
INSERT INTO Pagamentos (IDpagamento, IDmulta, MetodoPagamento, Status, DataPagamento) VALUES (17, 17, 'Cartão de Crédito', 'Pendente', '2025-10-26');
INSERT INTO Pagamentos (IDpagamento, IDmulta, MetodoPagamento, Status, DataPagamento) VALUES (18, 18, 'Pix', 'Cancelado', '2026-03-23');
INSERT INTO Pagamentos (IDpagamento, IDmulta, MetodoPagamento, Status, DataPagamento) VALUES (19, 19, 'Cartão de Crédito', 'Cancelado', '2025-08-31');
INSERT INTO Pagamentos (IDpagamento, IDmulta, MetodoPagamento, Status, DataPagamento) VALUES (20, 20, 'Pix', 'Cancelado', '2026-02-05');
INSERT INTO Pagamentos (IDpagamento, IDmulta, MetodoPagamento, Status, DataPagamento) VALUES (21, 21, 'Dinheiro', 'Cancelado', '2025-04-27');
INSERT INTO Pagamentos (IDpagamento, IDmulta, MetodoPagamento, Status, DataPagamento) VALUES (22, 22, 'Cartão de Crédito', 'Cancelado', '2025-09-03');
INSERT INTO Pagamentos (IDpagamento, IDmulta, MetodoPagamento, Status, DataPagamento) VALUES (23, 23, 'Cartão de Débito', 'Cancelado', '2025-11-19');
INSERT INTO Pagamentos (IDpagamento, IDmulta, MetodoPagamento, Status, DataPagamento) VALUES (24, 24, 'Dinheiro', 'Pendente', '2025-03-17');
INSERT INTO Pagamentos (IDpagamento, IDmulta, MetodoPagamento, Status, DataPagamento) VALUES (25, 25, 'Cartão de Débito', 'Confirmado', '2025-10-21');
INSERT INTO Pagamentos (IDpagamento, IDmulta, MetodoPagamento, Status, DataPagamento) VALUES (26, 26, 'Cartão de Crédito', 'Confirmado', '2025-01-10');
INSERT INTO Pagamentos (IDpagamento, IDmulta, MetodoPagamento, Status, DataPagamento) VALUES (27, 27, 'Boleto', 'Pendente', '2025-08-03');
INSERT INTO Pagamentos (IDpagamento, IDmulta, MetodoPagamento, Status, DataPagamento) VALUES (28, 28, 'Cartão de Débito', 'Pendente', '2025-12-20');
INSERT INTO Pagamentos (IDpagamento, IDmulta, MetodoPagamento, Status, DataPagamento) VALUES (29, 29, 'Cartão de Débito', 'Pendente', '2025-09-14');
INSERT INTO Pagamentos (IDpagamento, IDmulta, MetodoPagamento, Status, DataPagamento) VALUES (30, 30, 'Dinheiro', 'Pendente', '2026-03-23');
INSERT INTO Pagamentos (IDpagamento, IDmulta, MetodoPagamento, Status, DataPagamento) VALUES (31, 31, 'Cartão de Crédito', 'Cancelado', '2025-03-12');
INSERT INTO Pagamentos (IDpagamento, IDmulta, MetodoPagamento, Status, DataPagamento) VALUES (32, 32, 'Dinheiro', 'Confirmado', '2025-10-15');
INSERT INTO Pagamentos (IDpagamento, IDmulta, MetodoPagamento, Status, DataPagamento) VALUES (33, 33, 'Pix', 'Cancelado', '2025-09-02');
INSERT INTO Pagamentos (IDpagamento, IDmulta, MetodoPagamento, Status, DataPagamento) VALUES (34, 34, 'Dinheiro', 'Pendente', '2025-06-10');
INSERT INTO Pagamentos (IDpagamento, IDmulta, MetodoPagamento, Status, DataPagamento) VALUES (35, 35, 'Cartão de Débito', 'Pendente', '2026-04-13');
INSERT INTO Pagamentos (IDpagamento, IDmulta, MetodoPagamento, Status, DataPagamento) VALUES (36, 36, 'Dinheiro', 'Pendente', '2025-10-07');
INSERT INTO Pagamentos (IDpagamento, IDmulta, MetodoPagamento, Status, DataPagamento) VALUES (37, 37, 'Pix', 'Cancelado', '2026-01-31');
INSERT INTO Pagamentos (IDpagamento, IDmulta, MetodoPagamento, Status, DataPagamento) VALUES (38, 38, 'Pix', 'Cancelado', '2025-09-05');
INSERT INTO Pagamentos (IDpagamento, IDmulta, MetodoPagamento, Status, DataPagamento) VALUES (39, 39, 'Cartão de Débito', 'Confirmado', '2025-05-23');
INSERT INTO Pagamentos (IDpagamento, IDmulta, MetodoPagamento, Status, DataPagamento) VALUES (40, 40, 'Dinheiro', 'Pendente', '2025-04-26');
INSERT INTO Pagamentos (IDpagamento, IDmulta, MetodoPagamento, Status, DataPagamento) VALUES (41, 41, 'Pix', 'Pendente', '2025-12-27');
INSERT INTO Pagamentos (IDpagamento, IDmulta, MetodoPagamento, Status, DataPagamento) VALUES (42, 42, 'Cartão de Débito', 'Cancelado', '2025-12-27');
INSERT INTO Pagamentos (IDpagamento, IDmulta, MetodoPagamento, Status, DataPagamento) VALUES (43, 43, 'Boleto', 'Pendente', '2025-09-03');
INSERT INTO Pagamentos (IDpagamento, IDmulta, MetodoPagamento, Status, DataPagamento) VALUES (44, 44, 'Pix', 'Cancelado', '2026-04-24');
INSERT INTO Pagamentos (IDpagamento, IDmulta, MetodoPagamento, Status, DataPagamento) VALUES (45, 45, 'Pix', 'Pendente', '2025-03-04');
INSERT INTO Pagamentos (IDpagamento, IDmulta, MetodoPagamento, Status, DataPagamento) VALUES (46, 46, 'Dinheiro', 'Cancelado', '2025-10-06');
INSERT INTO Pagamentos (IDpagamento, IDmulta, MetodoPagamento, Status, DataPagamento) VALUES (47, 47, 'Boleto', 'Pendente', '2026-02-24');
INSERT INTO Pagamentos (IDpagamento, IDmulta, MetodoPagamento, Status, DataPagamento) VALUES (48, 48, 'Pix', 'Confirmado', '2025-05-29');
INSERT INTO Pagamentos (IDpagamento, IDmulta, MetodoPagamento, Status, DataPagamento) VALUES (49, 49, 'Cartão de Crédito', 'Pendente', '2026-05-05');
INSERT INTO Pagamentos (IDpagamento, IDmulta, MetodoPagamento, Status, DataPagamento) VALUES (50, 50, 'Cartão de Crédito', 'Pendente', '2026-04-19');
INSERT INTO Pagamentos (IDpagamento, IDmulta, MetodoPagamento, Status, DataPagamento) VALUES (51, 51, 'Boleto', 'Cancelado', '2025-05-12');
INSERT INTO Pagamentos (IDpagamento, IDmulta, MetodoPagamento, Status, DataPagamento) VALUES (52, 52, 'Boleto', 'Confirmado', '2025-04-14');
INSERT INTO Pagamentos (IDpagamento, IDmulta, MetodoPagamento, Status, DataPagamento) VALUES (53, 53, 'Dinheiro', 'Pendente', '2026-04-23');
INSERT INTO Pagamentos (IDpagamento, IDmulta, MetodoPagamento, Status, DataPagamento) VALUES (54, 54, 'Dinheiro', 'Cancelado', '2025-05-20');
INSERT INTO Pagamentos (IDpagamento, IDmulta, MetodoPagamento, Status, DataPagamento) VALUES (55, 55, 'Cartão de Débito', 'Confirmado', '2025-11-12');
INSERT INTO Pagamentos (IDpagamento, IDmulta, MetodoPagamento, Status, DataPagamento) VALUES (56, 56, 'Dinheiro', 'Confirmado', '2025-05-05');
INSERT INTO Pagamentos (IDpagamento, IDmulta, MetodoPagamento, Status, DataPagamento) VALUES (57, 57, 'Cartão de Crédito', 'Cancelado', '2026-04-09');
INSERT INTO Pagamentos (IDpagamento, IDmulta, MetodoPagamento, Status, DataPagamento) VALUES (58, 58, 'Dinheiro', 'Confirmado', '2025-11-23');
INSERT INTO Pagamentos (IDpagamento, IDmulta, MetodoPagamento, Status, DataPagamento) VALUES (59, 59, 'Cartão de Débito', 'Confirmado', '2025-02-21');
INSERT INTO Pagamentos (IDpagamento, IDmulta, MetodoPagamento, Status, DataPagamento) VALUES (60, 60, 'Boleto', 'Pendente', '2026-01-03');
INSERT INTO Pagamentos (IDpagamento, IDmulta, MetodoPagamento, Status, DataPagamento) VALUES (61, 61, 'Boleto', 'Confirmado', '2025-12-15');
INSERT INTO Pagamentos (IDpagamento, IDmulta, MetodoPagamento, Status, DataPagamento) VALUES (62, 62, 'Cartão de Débito', 'Confirmado', '2026-05-09');
INSERT INTO Pagamentos (IDpagamento, IDmulta, MetodoPagamento, Status, DataPagamento) VALUES (63, 63, 'Dinheiro', 'Confirmado', '2025-07-28');
INSERT INTO Pagamentos (IDpagamento, IDmulta, MetodoPagamento, Status, DataPagamento) VALUES (64, 64, 'Boleto', 'Pendente', '2025-11-30');
INSERT INTO Pagamentos (IDpagamento, IDmulta, MetodoPagamento, Status, DataPagamento) VALUES (65, 65, 'Cartão de Débito', 'Pendente', '2025-06-14');
INSERT INTO Pagamentos (IDpagamento, IDmulta, MetodoPagamento, Status, DataPagamento) VALUES (66, 66, 'Pix', 'Cancelado', '2025-01-31');
INSERT INTO Pagamentos (IDpagamento, IDmulta, MetodoPagamento, Status, DataPagamento) VALUES (67, 67, 'Cartão de Crédito', 'Cancelado', '2025-10-21');
INSERT INTO Pagamentos (IDpagamento, IDmulta, MetodoPagamento, Status, DataPagamento) VALUES (68, 68, 'Cartão de Débito', 'Cancelado', '2026-01-14');
INSERT INTO Pagamentos (IDpagamento, IDmulta, MetodoPagamento, Status, DataPagamento) VALUES (69, 69, 'Cartão de Crédito', 'Confirmado', '2025-08-02');
INSERT INTO Pagamentos (IDpagamento, IDmulta, MetodoPagamento, Status, DataPagamento) VALUES (70, 70, 'Cartão de Débito', 'Confirmado', '2026-03-05');
INSERT INTO Pagamentos (IDpagamento, IDmulta, MetodoPagamento, Status, DataPagamento) VALUES (71, 71, 'Boleto', 'Pendente', '2025-04-06');
INSERT INTO Pagamentos (IDpagamento, IDmulta, MetodoPagamento, Status, DataPagamento) VALUES (72, 72, 'Pix', 'Confirmado', '2025-01-05');
INSERT INTO Pagamentos (IDpagamento, IDmulta, MetodoPagamento, Status, DataPagamento) VALUES (73, 73, 'Pix', 'Cancelado', '2025-11-05');
INSERT INTO Pagamentos (IDpagamento, IDmulta, MetodoPagamento, Status, DataPagamento) VALUES (74, 74, 'Cartão de Crédito', 'Pendente', '2025-05-26');
INSERT INTO Pagamentos (IDpagamento, IDmulta, MetodoPagamento, Status, DataPagamento) VALUES (75, 75, 'Boleto', 'Cancelado', '2025-10-06');
INSERT INTO Pagamentos (IDpagamento, IDmulta, MetodoPagamento, Status, DataPagamento) VALUES (76, 76, 'Dinheiro', 'Pendente', '2026-04-01');
INSERT INTO Pagamentos (IDpagamento, IDmulta, MetodoPagamento, Status, DataPagamento) VALUES (77, 77, 'Cartão de Débito', 'Cancelado', '2025-08-28');
INSERT INTO Pagamentos (IDpagamento, IDmulta, MetodoPagamento, Status, DataPagamento) VALUES (78, 78, 'Pix', 'Confirmado', '2026-02-19');
INSERT INTO Pagamentos (IDpagamento, IDmulta, MetodoPagamento, Status, DataPagamento) VALUES (79, 79, 'Cartão de Crédito', 'Pendente', '2025-03-25');
INSERT INTO Pagamentos (IDpagamento, IDmulta, MetodoPagamento, Status, DataPagamento) VALUES (80, 80, 'Boleto', 'Cancelado', '2025-05-12');
INSERT INTO Pagamentos (IDpagamento, IDmulta, MetodoPagamento, Status, DataPagamento) VALUES (81, 81, 'Cartão de Débito', 'Confirmado', '2026-01-13');
INSERT INTO Pagamentos (IDpagamento, IDmulta, MetodoPagamento, Status, DataPagamento) VALUES (82, 82, 'Pix', 'Pendente', '2025-10-18');
INSERT INTO Pagamentos (IDpagamento, IDmulta, MetodoPagamento, Status, DataPagamento) VALUES (83, 83, 'Cartão de Débito', 'Confirmado', '2025-11-09');
INSERT INTO Pagamentos (IDpagamento, IDmulta, MetodoPagamento, Status, DataPagamento) VALUES (84, 84, 'Boleto', 'Pendente', '2025-09-21');
INSERT INTO Pagamentos (IDpagamento, IDmulta, MetodoPagamento, Status, DataPagamento) VALUES (85, 85, 'Pix', 'Confirmado', '2025-07-25');
INSERT INTO Pagamentos (IDpagamento, IDmulta, MetodoPagamento, Status, DataPagamento) VALUES (86, 86, 'Cartão de Crédito', 'Confirmado', '2025-03-13');
INSERT INTO Pagamentos (IDpagamento, IDmulta, MetodoPagamento, Status, DataPagamento) VALUES (87, 87, 'Boleto', 'Pendente', '2026-04-25');
INSERT INTO Pagamentos (IDpagamento, IDmulta, MetodoPagamento, Status, DataPagamento) VALUES (88, 88, 'Cartão de Débito', 'Confirmado', '2025-05-14');
INSERT INTO Pagamentos (IDpagamento, IDmulta, MetodoPagamento, Status, DataPagamento) VALUES (89, 89, 'Boleto', 'Confirmado', '2025-08-17');
INSERT INTO Pagamentos (IDpagamento, IDmulta, MetodoPagamento, Status, DataPagamento) VALUES (90, 90, 'Pix', 'Pendente', '2025-06-04');
INSERT INTO Pagamentos (IDpagamento, IDmulta, MetodoPagamento, Status, DataPagamento) VALUES (91, 91, 'Dinheiro', 'Cancelado', '2025-10-21');
INSERT INTO Pagamentos (IDpagamento, IDmulta, MetodoPagamento, Status, DataPagamento) VALUES (92, 92, 'Cartão de Crédito', 'Pendente', '2025-12-01');
INSERT INTO Pagamentos (IDpagamento, IDmulta, MetodoPagamento, Status, DataPagamento) VALUES (93, 93, 'Pix', 'Cancelado', '2025-05-01');
INSERT INTO Pagamentos (IDpagamento, IDmulta, MetodoPagamento, Status, DataPagamento) VALUES (94, 94, 'Cartão de Crédito', 'Cancelado', '2025-03-02');
INSERT INTO Pagamentos (IDpagamento, IDmulta, MetodoPagamento, Status, DataPagamento) VALUES (95, 95, 'Boleto', 'Pendente', '2025-03-23');
INSERT INTO Pagamentos (IDpagamento, IDmulta, MetodoPagamento, Status, DataPagamento) VALUES (96, 96, 'Boleto', 'Cancelado', '2025-09-15');
INSERT INTO Pagamentos (IDpagamento, IDmulta, MetodoPagamento, Status, DataPagamento) VALUES (97, 97, 'Pix', 'Cancelado', '2025-03-02');
INSERT INTO Pagamentos (IDpagamento, IDmulta, MetodoPagamento, Status, DataPagamento) VALUES (98, 98, 'Pix', 'Pendente', '2025-11-11');
INSERT INTO Pagamentos (IDpagamento, IDmulta, MetodoPagamento, Status, DataPagamento) VALUES (99, 99, 'Cartão de Débito', 'Confirmado', '2026-05-06');
INSERT INTO Pagamentos (IDpagamento, IDmulta, MetodoPagamento, Status, DataPagamento) VALUES (100, 100, 'Cartão de Débito', 'Pendente', '2025-03-20');
