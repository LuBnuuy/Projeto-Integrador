CREATE DATABASE edugest
	DEFAULT CHARACTER SET utf8mb4
    DEFAULT COLLATE utf8mb4_unicode_ci;
USE edugest;

CREATE TABLE CURSO (
    IDcurso INT AUTO_INCREMENT PRIMARY KEY,
    NomeCurso VARCHAR(255) NOT NULL,
    Grau VARCHAR(100) NOT NULL,
    Duracao_semestres INT NOT NULL
);

CREATE TABLE PROFESSOR (
    IDprofessor INT AUTO_INCREMENT PRIMARY KEY,
    NomeProfessor VARCHAR(255) NOT NULL,
    Email VARCHAR(255) UNIQUE NOT NULL,
    Telefone VARCHAR(20),
    Titulacao VARCHAR(100) NOT NULL
);

CREATE TABLE PERIODO_LETIVO (
    IDperiodo INT AUTO_INCREMENT PRIMARY KEY,
    Ano INT NOT NULL,
    Semestre INT NOT NULL,
    Data_Inicio DATE NOT NULL,
    Data_Fim DATE NOT NULL
);

CREATE TABLE ALUNO (
    IDaluno INT AUTO_INCREMENT PRIMARY KEY,
    curso_id INT NOT NULL,
    NomeAluno VARCHAR(255) NOT NULL,
    Numero_Documento VARCHAR(50) UNIQUE NOT NULL,
    Data_Nascimento DATE NOT NULL,
    Email VARCHAR(255) UNIQUE NOT NULL,
    Telefone VARCHAR(20),
    Estado VARCHAR(50) NOT NULL,
    FOREIGN KEY (curso_id) REFERENCES CURSO(IDcurso)
);

CREATE TABLE DISCIPLINA (
    IDdisciplina INT AUTO_INCREMENT PRIMARY KEY,
    IDcurso INT NOT NULL,
    NomeDisciplina VARCHAR(255) NOT NULL,
    Creditos INT NOT NULL,
    Carga_horaria INT NOT NULL,
    FOREIGN KEY (IDcurso) REFERENCES CURSO(IDcurso)
);

CREATE TABLE MENSALIDADE (
    IDmensalidade INT AUTO_INCREMENT PRIMARY KEY,
    IDaluno INT NOT NULL,
    IDperiodo INT NOT NULL,
    Competencia VARCHAR(50) NOT NULL,
    valor FLOAT NOT NULL,
    vencimento DATE NOT NULL,
    Data_Pagamento DATE,
    Estado_Pagamento VARCHAR(50) NOT NULL,
    Metodo_Pagamento VARCHAR(50),
    FOREIGN KEY (IDaluno) REFERENCES ALUNO(IDaluno),
    FOREIGN KEY (IDperiodo) REFERENCES PERIODO_LETIVO(IDperiodo)
);

CREATE TABLE TURMA (
    IDturma INT AUTO_INCREMENT PRIMARY KEY,
    IDdisciplina INT NOT NULL,
    IDprofessor INT NOT NULL,
    IDperiodo INT NOT NULL,
    Horario VARCHAR(100) NOT NULL,
    Sala VARCHAR(50),
    Vagas INT NOT NULL,
    FOREIGN KEY (IDdisciplina) REFERENCES DISCIPLINA(IDdisciplina),
    FOREIGN KEY (IDprofessor) REFERENCES PROFESSOR(IDprofessor),
    FOREIGN KEY (IDperiodo) REFERENCES PERIODO_LETIVO(IDperiodo)
);

CREATE TABLE MATRICULA (
    IDmatricula INT AUTO_INCREMENT PRIMARY KEY,
    IDaluno INT NOT NULL,
    IDturma INT NOT NULL,
    Data_Matricula DATE NOT NULL,
    Estado VARCHAR(50) NOT NULL,
    FOREIGN KEY (IDaluno) REFERENCES ALUNO(IDaluno),
    FOREIGN KEY (IDturma) REFERENCES TURMA(IDturma)
);

CREATE TABLE FREQUENCIA (
    IDfrequencia INT AUTO_INCREMENT PRIMARY KEY,
    IDmatricula INT NOT NULL,
    Data_Aula DATE NOT NULL,
    Presente BOOLEAN NOT NULL,
    Justificacao VARCHAR(255),
    FOREIGN KEY (IDmatricula) REFERENCES MATRICULA(IDmatricula)
);

CREATE TABLE NOTA (
    IDnota INT AUTO_INCREMENT PRIMARY KEY,
    IDmatricula INT NOT NULL,
    Tipo_Avaliacao VARCHAR(100) NOT NULL,
    Data_Avaliacao DATE NOT NULL,
    Valor FLOAT NOT NULL,
    FOREIGN KEY (IDmatricula) REFERENCES MATRICULA(IDmatricula)
);

ALTER TABLE CURSO
ADD COLUMN Ativo BOOLEAN NOT NULL DEFAULT TRUE;

ALTER TABLE PROFESSOR
ADD COLUMN Data_Contratacao DATE;

ALTER TABLE PERIODO_LETIVO
ADD COLUMN Status VARCHAR(50) NOT NULL DEFAULT 'Planejado';

ALTER TABLE ALUNO
ADD COLUMN SenhaHash VARCHAR(255) NOT NULL DEFAULT '';

ALTER TABLE DISCIPLINA
ADD COLUMN Ementa TEXT;

ALTER TABLE MENSALIDADE
ADD COLUMN Desconto FLOAT NOT NULL DEFAULT 0;

ALTER TABLE TURMA
ADD COLUMN Modalidade VARCHAR(50) NOT NULL DEFAULT 'Presencial';

ALTER TABLE MATRICULA
ADD COLUMN Observacoes VARCHAR(255);

ALTER TABLE FREQUENCIA
ADD COLUMN Registrado_Por VARCHAR(100);

ALTER TABLE NOTA
ADD COLUMN Peso FLOAT NOT NULL DEFAULT 1.0;

-- Store Procedure da Tabela CURSO
-- Cadastra um curso, evitando duplicidade (mesmo nome + grau)
DELIMITER //
CREATE PROCEDURE sp_CadastrarCurso(
    IN p_NomeCurso VARCHAR(255),
    IN p_Grau VARCHAR(100),
    IN p_Duracao_semestres INT,
    OUT p_Resultado VARCHAR(100))
BEGIN
    DECLARE v_existe INT;
 
    SELECT COUNT(*) INTO v_existe
    FROM curso
    WHERE NomeCurso = p_NomeCurso AND Grau = p_Grau;
 
    IF v_existe > 0 THEN
        SET p_Resultado = 'Curso já cadastrado';
    ELSE
        INSERT INTO curso (NomeCurso, Grau, Duracao_semestres)
        VALUES (p_NomeCurso, p_Grau, p_Duracao_semestres);
        SET p_Resultado = 'Curso cadastrado com sucesso';
    END IF;
END //
DELIMITER ;

-- Store Procedure da Tabela PROFESSOR
-- Cadastra um professor, impedindo e-mail duplicado
DELIMITER //
CREATE PROCEDURE sp_CadastrarProfessor(
    IN p_NomeProfessor VARCHAR(255),
    IN p_Email VARCHAR(255),
    IN p_Telefone VARCHAR(20),
    IN p_Titulacao VARCHAR(100),
    IN p_Data_Contratacao DATE,
    OUT p_Resultado VARCHAR(100))
BEGIN
    DECLARE v_existe INT;
 
    SELECT COUNT(*) INTO v_existe
    FROM professor
    WHERE Email = p_Email;
 
    IF v_existe > 0 THEN
        SET p_Resultado = 'Email já cadastrado';
    ELSE
        INSERT INTO professor (NomeProfessor, Email, Telefone, Titulacao, Data_Contratacao)
        VALUES (p_NomeProfessor, p_Email, p_Telefone, p_Titulacao, p_Data_Contratacao);
        SET p_Resultado = 'Professor cadastrado com sucesso';
    END IF;
END //
DELIMITER ;

-- Store Procedure da Tabela PERIODO_LETIVO
-- Cadastra um período letivo, validando as datas e evitando
-- duplicar Ano+Semestre
DELIMITER //
CREATE PROCEDURE sp_CadastrarPeriodoLetivo(
    IN p_Ano INT,
    IN p_Semestre INT,
    IN p_Data_Inicio DATE,
    IN p_Data_Fim DATE,
    OUT p_Resultado VARCHAR(100))
BEGIN
    DECLARE v_existe INT;
 
    SELECT COUNT(*) INTO v_existe
    FROM periodo_letivo
    WHERE Ano = p_Ano AND Semestre = p_Semestre;
 
    IF p_Data_Fim <= p_Data_Inicio THEN
        SET p_Resultado = 'Data de fim deve ser posterior à data de início';
    ELSEIF v_existe > 0 THEN
        SET p_Resultado = 'Período letivo já cadastrado';
    ELSE
        INSERT INTO periodo_letivo (Ano, Semestre, Data_Inicio, Data_Fim)
        VALUES (p_Ano, p_Semestre, p_Data_Inicio, p_Data_Fim);
        SET p_Resultado = 'Período letivo cadastrado com sucesso';
    END IF;
END //
DELIMITER ;

-- Store Procedure da Tabela ALUNO
-- Cadastra um aluno, validando curso ativo e evitando
-- duplicidade de documento/e-mail
DELIMITER //
CREATE PROCEDURE sp_CadastrarAluno(
    IN p_curso_id INT,
    IN p_NomeAluno VARCHAR(255),
    IN p_Numero_Documento VARCHAR(50),
    IN p_Data_Nascimento DATE,
    IN p_Email VARCHAR(255),
    IN p_Telefone VARCHAR(20),
    IN p_Estado VARCHAR(50),
    IN p_SenhaHash VARCHAR(255),
    OUT p_Resultado VARCHAR(100))
BEGIN
    DECLARE v_CursoAtivo INT;
    DECLARE v_DocExiste INT;
    DECLARE v_EmailExiste INT;
 
    SELECT COUNT(*) INTO v_CursoAtivo FROM curso WHERE IDcurso = p_curso_id AND Ativo = TRUE;
    SELECT COUNT(*) INTO v_DocExiste FROM aluno WHERE Numero_Documento = p_Numero_Documento;
    SELECT COUNT(*) INTO v_EmailExiste FROM aluno WHERE Email = p_Email;
 
    IF v_CursoAtivo = 0 THEN
        SET p_Resultado = 'Curso inexistente ou inativo';
    ELSEIF v_DocExiste > 0 THEN
        SET p_Resultado = 'Documento já cadastrado';
    ELSEIF v_EmailExiste > 0 THEN
        SET p_Resultado = 'Email já cadastrado';
    ELSE
        INSERT INTO aluno (curso_id, NomeAluno, Numero_Documento, Data_Nascimento, Email, Telefone, Estado, SenhaHash)
        VALUES (p_curso_id, p_NomeAluno, p_Numero_Documento, p_Data_Nascimento, p_Email, p_Telefone, p_Estado, p_SenhaHash);
        SET p_Resultado = 'Aluno cadastrado com sucesso';
    END IF;
END //
DELIMITER ;

-- Store Procedure da Tabela DISCIPLINA
-- Cadastra uma disciplina somente se o curso existir
DELIMITER //
CREATE PROCEDURE sp_CadastrarDisciplina(
    IN p_IDcurso INT,
    IN p_NomeDisciplina VARCHAR(255),
    IN p_Creditos INT,
    IN p_Carga_horaria INT,
    IN p_Ementa TEXT,
    OUT p_Resultado VARCHAR(100))
BEGIN
    DECLARE v_CursoExiste INT;
 
    SELECT COUNT(*) INTO v_CursoExiste
    FROM curso
    WHERE IDcurso = p_IDcurso;
 
    IF v_CursoExiste = 0 THEN
        SET p_Resultado = 'Curso não encontrado';
    ELSE
        INSERT INTO disciplina (IDcurso, NomeDisciplina, Creditos, Carga_horaria, Ementa)
        VALUES (p_IDcurso, p_NomeDisciplina, p_Creditos, p_Carga_horaria, p_Ementa);
        SET p_Resultado = 'Disciplina cadastrada com sucesso';
    END IF;
END //
DELIMITER ;

-- Store Procedure da Tabela MENSALIDADE
-- Gera a mensalidade de um aluno/período, aplicando o desconto
-- e evitando duplicar a mesma competência
DELIMITER //
CREATE PROCEDURE sp_GerarMensalidade(
    IN p_IDaluno INT,
    IN p_IDperiodo INT,
    IN p_Competencia VARCHAR(50),
    IN p_valor FLOAT,
    IN p_vencimento DATE,
    IN p_Desconto FLOAT,
    OUT p_Resultado VARCHAR(100))
BEGIN
    DECLARE v_AlunoExiste INT;
    DECLARE v_PeriodoExiste INT;
    DECLARE v_JaExiste INT;
    DECLARE v_ValorFinal FLOAT;
 
    SELECT COUNT(*) INTO v_AlunoExiste FROM aluno WHERE IDaluno = p_IDaluno;
    SELECT COUNT(*) INTO v_PeriodoExiste FROM periodo_letivo WHERE IDperiodo = p_IDperiodo;
    SELECT COUNT(*) INTO v_JaExiste
    FROM mensalidade
    WHERE IDaluno = p_IDaluno AND IDperiodo = p_IDperiodo AND Competencia = p_Competencia;
 
    IF v_AlunoExiste = 0 THEN
        SET p_Resultado = 'Aluno não encontrado';
    ELSEIF v_PeriodoExiste = 0 THEN
        SET p_Resultado = 'Período letivo não encontrado';
    ELSEIF v_JaExiste > 0 THEN
        SET p_Resultado = 'Mensalidade já gerada para esta competência';
    ELSE
        SET v_ValorFinal = p_valor - (p_valor * p_Desconto / 100);
 
        INSERT INTO mensalidade (IDaluno, IDperiodo, Competencia, valor, vencimento, Estado_Pagamento, Desconto)
        VALUES (p_IDaluno, p_IDperiodo, p_Competencia, v_ValorFinal, p_vencimento, 'Pendente', p_Desconto);
 
        SET p_Resultado = 'Mensalidade gerada com sucesso';
    END IF;
END //
DELIMITER ;

-- Store Procedure da Tabela TURMA
-- Cria uma turma, validando existência de disciplina, professor
-- e período, além de exigir número de vagas positivo
DELIMITER //
CREATE PROCEDURE sp_CriarTurma(
    IN p_IDdisciplina INT,
    IN p_IDprofessor INT,
    IN p_IDperiodo INT,
    IN p_Horario VARCHAR(100),
    IN p_Sala VARCHAR(50),
    IN p_Vagas INT,
    IN p_Modalidade VARCHAR(50),
    OUT p_Resultado VARCHAR(100))
BEGIN
    DECLARE v_DisciplinaExiste INT;
    DECLARE v_ProfessorExiste INT;
    DECLARE v_PeriodoExiste INT;
 
    SELECT COUNT(*) INTO v_DisciplinaExiste FROM disciplina WHERE IDdisciplina = p_IDdisciplina;
    SELECT COUNT(*) INTO v_ProfessorExiste FROM professor WHERE IDprofessor = p_IDprofessor;
    SELECT COUNT(*) INTO v_PeriodoExiste FROM periodo_letivo WHERE IDperiodo = p_IDperiodo;
 
    IF v_DisciplinaExiste = 0 THEN
        SET p_Resultado = 'Disciplina não encontrada';
    ELSEIF v_ProfessorExiste = 0 THEN
        SET p_Resultado = 'Professor não encontrado';
    ELSEIF v_PeriodoExiste = 0 THEN
        SET p_Resultado = 'Período letivo não encontrado';
    ELSEIF p_Vagas <= 0 THEN
        SET p_Resultado = 'Número de vagas deve ser maior que zero';
    ELSE
        INSERT INTO turma (IDdisciplina, IDprofessor, IDperiodo, Horario, Sala, Vagas, Modalidade)
        VALUES (p_IDdisciplina, p_IDprofessor, p_IDperiodo, p_Horario, p_Sala, p_Vagas, p_Modalidade);
        SET p_Resultado = 'Turma criada com sucesso';
    END IF;
END //
DELIMITER ;

-- Store Procedure da Tabela MATRICULA
-- Matricula um aluno em uma turma, verificando vagas
-- disponíveis e evitando matrícula duplicada
DELIMITER //
CREATE PROCEDURE sp_MatricularAlunoTurma(
    IN p_IDaluno INT,
    IN p_IDturma INT,
    IN p_Data_Matricula DATE,
    OUT p_Resultado VARCHAR(100))
BEGIN
    DECLARE v_AlunoExiste INT;
    DECLARE v_Vagas INT;
    DECLARE v_MatriculasAtivas INT;
    DECLARE v_JaMatriculado INT;
 
    SELECT COUNT(*) INTO v_AlunoExiste FROM aluno WHERE IDaluno = p_IDaluno;
    SELECT Vagas INTO v_Vagas FROM turma WHERE IDturma = p_IDturma;
 
    SELECT COUNT(*) INTO v_MatriculasAtivas
    FROM matricula
    WHERE IDturma = p_IDturma AND Estado = 'Ativa';
 
    SELECT COUNT(*) INTO v_JaMatriculado
    FROM matricula
    WHERE IDaluno = p_IDaluno AND IDturma = p_IDturma AND Estado = 'Ativa';
 
    IF v_AlunoExiste = 0 THEN
        SET p_Resultado = 'Aluno não encontrado';
    ELSEIF v_Vagas IS NULL THEN
        SET p_Resultado = 'Turma não encontrada';
    ELSEIF v_JaMatriculado > 0 THEN
        SET p_Resultado = 'Aluno já matriculado nesta turma';
    ELSEIF v_MatriculasAtivas >= v_Vagas THEN
        SET p_Resultado = 'Turma sem vagas disponíveis';
    ELSE
        INSERT INTO matricula (IDaluno, IDturma, Data_Matricula, Estado)
        VALUES (p_IDaluno, p_IDturma, p_Data_Matricula, 'Ativa');
        SET p_Resultado = 'Matrícula realizada com sucesso';
    END IF;
END //
DELIMITER ;

-- Store Procedure da Tabela FREQUENCIA
-- Registra a frequência de uma aula, validando matrícula ativa
-- e evitando duplicar o registro na mesma data
DELIMITER //
CREATE PROCEDURE sp_RegistrarFrequencia(
    IN p_IDmatricula INT,
    IN p_Data_Aula DATE,
    IN p_Presente BOOLEAN,
    IN p_Justificacao VARCHAR(255),
    IN p_Registrado_Por VARCHAR(100),
    OUT p_Resultado VARCHAR(100))
BEGIN
    DECLARE v_MatriculaAtiva INT;
    DECLARE v_JaRegistrado INT;
 
    SELECT COUNT(*) INTO v_MatriculaAtiva
    FROM matricula
    WHERE IDmatricula = p_IDmatricula AND Estado = 'Ativa';
 
    SELECT COUNT(*) INTO v_JaRegistrado
    FROM frequencia
    WHERE IDmatricula = p_IDmatricula AND Data_Aula = p_Data_Aula;
 
    IF v_MatriculaAtiva = 0 THEN
        SET p_Resultado = 'Matrícula não encontrada ou inativa';
    ELSEIF v_JaRegistrado > 0 THEN
        SET p_Resultado = 'Frequência já registrada para esta data';
    ELSE
        INSERT INTO frequencia (IDmatricula, Data_Aula, Presente, Justificacao, Registrado_Por)
        VALUES (p_IDmatricula, p_Data_Aula, p_Presente, p_Justificacao, p_Registrado_Por);
        SET p_Resultado = 'Frequência registrada com sucesso';
    END IF;
END //
DELIMITER ;

-- Store Procedure da Tabela NOTA
-- Lança uma nota, validando matrícula ativa e faixa de valor (0 a 10)
DELIMITER //
CREATE PROCEDURE sp_LancarNota(
    IN p_IDmatricula INT,
    IN p_Tipo_Avaliacao VARCHAR(100),
    IN p_Data_Avaliacao DATE,
    IN p_Valor FLOAT,
    IN p_Peso FLOAT,
    OUT p_Resultado VARCHAR(100))
BEGIN
    DECLARE v_MatriculaAtiva INT;
 
    SELECT COUNT(*) INTO v_MatriculaAtiva
    FROM matricula
    WHERE IDmatricula = p_IDmatricula AND Estado = 'Ativa';
 
    IF v_MatriculaAtiva = 0 THEN
        SET p_Resultado = 'Matrícula não encontrada ou inativa';
    ELSEIF p_Valor < 0 OR p_Valor > 10 THEN
        SET p_Resultado = 'Valor da nota inválido (deve estar entre 0 e 10)';
    ELSE
        INSERT INTO nota (IDmatricula, Tipo_Avaliacao, Data_Avaliacao, Valor, Peso)
        VALUES (p_IDmatricula, p_Tipo_Avaliacao, p_Data_Avaliacao, p_Valor, p_Peso);
        SET p_Resultado = 'Nota lançada com sucesso';
    END IF;
END //
DELIMITER ;

-- ---------------- CURSO ----------------
INSERT INTO CURSO (IDcurso, NomeCurso, Grau, Duracao_semestres) VALUES (1, 'Engenharia de Software', 'Bacharelado', 10);
INSERT INTO CURSO (IDcurso, NomeCurso, Grau, Duracao_semestres) VALUES (2, 'Engenharia Elétrica', 'Tecnólogo', 10);
INSERT INTO CURSO (IDcurso, NomeCurso, Grau, Duracao_semestres) VALUES (3, 'Engenharia Mecânica', 'Tecnólogo', 8);
INSERT INTO CURSO (IDcurso, NomeCurso, Grau, Duracao_semestres) VALUES (4, 'Administração', 'Licenciatura', 6);
INSERT INTO CURSO (IDcurso, NomeCurso, Grau, Duracao_semestres) VALUES (5, 'Ciências Contábeis', 'Licenciatura', 6);
INSERT INTO CURSO (IDcurso, NomeCurso, Grau, Duracao_semestres) VALUES (6, 'Direito', 'Tecnólogo', 6);
INSERT INTO CURSO (IDcurso, NomeCurso, Grau, Duracao_semestres) VALUES (7, 'Medicina', 'Bacharelado', 4);
INSERT INTO CURSO (IDcurso, NomeCurso, Grau, Duracao_semestres) VALUES (8, 'Enfermagem', 'Licenciatura', 10);
INSERT INTO CURSO (IDcurso, NomeCurso, Grau, Duracao_semestres) VALUES (9, 'Psicologia', 'Bacharelado', 6);
INSERT INTO CURSO (IDcurso, NomeCurso, Grau, Duracao_semestres) VALUES (10, 'Pedagogia', 'Bacharelado', 6);
INSERT INTO CURSO (IDcurso, NomeCurso, Grau, Duracao_semestres) VALUES (11, 'Arquitetura e Urbanismo', 'Tecnólogo', 4);
INSERT INTO CURSO (IDcurso, NomeCurso, Grau, Duracao_semestres) VALUES (12, 'Ciência da Computação', 'Licenciatura', 10);
INSERT INTO CURSO (IDcurso, NomeCurso, Grau, Duracao_semestres) VALUES (13, 'Sistemas de Informação', 'Tecnólogo', 10);
INSERT INTO CURSO (IDcurso, NomeCurso, Grau, Duracao_semestres) VALUES (14, 'Design Gráfico', 'Bacharelado', 8);
INSERT INTO CURSO (IDcurso, NomeCurso, Grau, Duracao_semestres) VALUES (15, 'Nutrição', 'Tecnólogo', 10);
INSERT INTO CURSO (IDcurso, NomeCurso, Grau, Duracao_semestres) VALUES (16, 'Fisioterapia', 'Tecnólogo', 4);
INSERT INTO CURSO (IDcurso, NomeCurso, Grau, Duracao_semestres) VALUES (17, 'Odontologia', 'Tecnólogo', 8);
INSERT INTO CURSO (IDcurso, NomeCurso, Grau, Duracao_semestres) VALUES (18, 'Biomedicina', 'Bacharelado', 6);
INSERT INTO CURSO (IDcurso, NomeCurso, Grau, Duracao_semestres) VALUES (19, 'Farmácia', 'Tecnólogo', 4);
INSERT INTO CURSO (IDcurso, NomeCurso, Grau, Duracao_semestres) VALUES (20, 'Publicidade e Propaganda', 'Bacharelado', 4);
INSERT INTO CURSO (IDcurso, NomeCurso, Grau, Duracao_semestres) VALUES (21, 'Jornalismo', 'Licenciatura', 6);
INSERT INTO CURSO (IDcurso, NomeCurso, Grau, Duracao_semestres) VALUES (22, 'Relações Internacionais', 'Tecnólogo', 8);
INSERT INTO CURSO (IDcurso, NomeCurso, Grau, Duracao_semestres) VALUES (23, 'Economia', 'Licenciatura', 10);
INSERT INTO CURSO (IDcurso, NomeCurso, Grau, Duracao_semestres) VALUES (24, 'Matemática', 'Bacharelado', 6);
INSERT INTO CURSO (IDcurso, NomeCurso, Grau, Duracao_semestres) VALUES (25, 'Física', 'Tecnólogo', 4);
INSERT INTO CURSO (IDcurso, NomeCurso, Grau, Duracao_semestres) VALUES (26, 'Química', 'Licenciatura', 6);
INSERT INTO CURSO (IDcurso, NomeCurso, Grau, Duracao_semestres) VALUES (27, 'Biologia', 'Bacharelado', 6);
INSERT INTO CURSO (IDcurso, NomeCurso, Grau, Duracao_semestres) VALUES (28, 'História', 'Bacharelado', 4);
INSERT INTO CURSO (IDcurso, NomeCurso, Grau, Duracao_semestres) VALUES (29, 'Geografia', 'Bacharelado', 10);
INSERT INTO CURSO (IDcurso, NomeCurso, Grau, Duracao_semestres) VALUES (30, 'Letras', 'Tecnólogo', 10);
INSERT INTO CURSO (IDcurso, NomeCurso, Grau, Duracao_semestres) VALUES (31, 'Educação Física', 'Bacharelado', 8);
INSERT INTO CURSO (IDcurso, NomeCurso, Grau, Duracao_semestres) VALUES (32, 'Serviço Social', 'Bacharelado', 10);
INSERT INTO CURSO (IDcurso, NomeCurso, Grau, Duracao_semestres) VALUES (33, 'Gastronomia', 'Licenciatura', 8);
INSERT INTO CURSO (IDcurso, NomeCurso, Grau, Duracao_semestres) VALUES (34, 'Turismo', 'Licenciatura', 10);
INSERT INTO CURSO (IDcurso, NomeCurso, Grau, Duracao_semestres) VALUES (35, 'Marketing', 'Licenciatura', 10);
INSERT INTO CURSO (IDcurso, NomeCurso, Grau, Duracao_semestres) VALUES (36, 'Logística', 'Licenciatura', 8);
INSERT INTO CURSO (IDcurso, NomeCurso, Grau, Duracao_semestres) VALUES (37, 'Gestão Ambiental', 'Bacharelado', 4);
INSERT INTO CURSO (IDcurso, NomeCurso, Grau, Duracao_semestres) VALUES (38, 'Ciência de Dados', 'Bacharelado', 10);
INSERT INTO CURSO (IDcurso, NomeCurso, Grau, Duracao_semestres) VALUES (39, 'Redes de Computadores', 'Bacharelado', 10);
INSERT INTO CURSO (IDcurso, NomeCurso, Grau, Duracao_semestres) VALUES (40, 'Engenharia Civil (Bacharelado)', 'Bacharelado', 6);
INSERT INTO CURSO (IDcurso, NomeCurso, Grau, Duracao_semestres) VALUES (41, 'Engenharia de Software (Tecnólogo)', 'Tecnólogo', 8);
INSERT INTO CURSO (IDcurso, NomeCurso, Grau, Duracao_semestres) VALUES (42, 'Engenharia Elétrica (Tecnólogo)', 'Tecnólogo', 4);
INSERT INTO CURSO (IDcurso, NomeCurso, Grau, Duracao_semestres) VALUES (43, 'Engenharia Mecânica (Bacharelado)', 'Bacharelado', 6);
INSERT INTO CURSO (IDcurso, NomeCurso, Grau, Duracao_semestres) VALUES (44, 'Administração (Tecnólogo)', 'Tecnólogo', 8);
INSERT INTO CURSO (IDcurso, NomeCurso, Grau, Duracao_semestres) VALUES (45, 'Ciências Contábeis (Licenciatura)', 'Licenciatura', 8);
INSERT INTO CURSO (IDcurso, NomeCurso, Grau, Duracao_semestres) VALUES (46, 'Direito (Tecnólogo)', 'Tecnólogo', 8);
INSERT INTO CURSO (IDcurso, NomeCurso, Grau, Duracao_semestres) VALUES (47, 'Medicina (Bacharelado)', 'Bacharelado', 4);
INSERT INTO CURSO (IDcurso, NomeCurso, Grau, Duracao_semestres) VALUES (48, 'Enfermagem (Bacharelado)', 'Bacharelado', 4);
INSERT INTO CURSO (IDcurso, NomeCurso, Grau, Duracao_semestres) VALUES (49, 'Psicologia (Bacharelado)', 'Bacharelado', 10);
INSERT INTO CURSO (IDcurso, NomeCurso, Grau, Duracao_semestres) VALUES (50, 'Pedagogia (Licenciatura)', 'Licenciatura', 6);
INSERT INTO CURSO (IDcurso, NomeCurso, Grau, Duracao_semestres) VALUES (51, 'Arquitetura e Urbanismo (Tecnólogo)', 'Tecnólogo', 4);
INSERT INTO CURSO (IDcurso, NomeCurso, Grau, Duracao_semestres) VALUES (52, 'Ciência da Computação (Tecnólogo)', 'Tecnólogo', 6);
INSERT INTO CURSO (IDcurso, NomeCurso, Grau, Duracao_semestres) VALUES (53, 'Sistemas de Informação (Licenciatura)', 'Licenciatura', 6);
INSERT INTO CURSO (IDcurso, NomeCurso, Grau, Duracao_semestres) VALUES (54, 'Design Gráfico (Tecnólogo)', 'Tecnólogo', 4);
INSERT INTO CURSO (IDcurso, NomeCurso, Grau, Duracao_semestres) VALUES (55, 'Nutrição (Licenciatura)', 'Licenciatura', 10);
INSERT INTO CURSO (IDcurso, NomeCurso, Grau, Duracao_semestres) VALUES (56, 'Fisioterapia (Tecnólogo)', 'Tecnólogo', 10);
INSERT INTO CURSO (IDcurso, NomeCurso, Grau, Duracao_semestres) VALUES (57, 'Odontologia (Tecnólogo)', 'Tecnólogo', 6);
INSERT INTO CURSO (IDcurso, NomeCurso, Grau, Duracao_semestres) VALUES (58, 'Biomedicina (Bacharelado)', 'Bacharelado', 6);
INSERT INTO CURSO (IDcurso, NomeCurso, Grau, Duracao_semestres) VALUES (59, 'Farmácia (Tecnólogo)', 'Tecnólogo', 4);
INSERT INTO CURSO (IDcurso, NomeCurso, Grau, Duracao_semestres) VALUES (60, 'Publicidade e Propaganda (Licenciatura)', 'Licenciatura', 10);
INSERT INTO CURSO (IDcurso, NomeCurso, Grau, Duracao_semestres) VALUES (61, 'Jornalismo (Tecnólogo)', 'Tecnólogo', 10);
INSERT INTO CURSO (IDcurso, NomeCurso, Grau, Duracao_semestres) VALUES (62, 'Relações Internacionais (Bacharelado)', 'Bacharelado', 8);
INSERT INTO CURSO (IDcurso, NomeCurso, Grau, Duracao_semestres) VALUES (63, 'Economia (Bacharelado)', 'Bacharelado', 8);
INSERT INTO CURSO (IDcurso, NomeCurso, Grau, Duracao_semestres) VALUES (64, 'Matemática (Tecnólogo)', 'Tecnólogo', 8);
INSERT INTO CURSO (IDcurso, NomeCurso, Grau, Duracao_semestres) VALUES (65, 'Física (Bacharelado)', 'Bacharelado', 10);
INSERT INTO CURSO (IDcurso, NomeCurso, Grau, Duracao_semestres) VALUES (66, 'Química (Bacharelado)', 'Bacharelado', 6);
INSERT INTO CURSO (IDcurso, NomeCurso, Grau, Duracao_semestres) VALUES (67, 'Biologia (Licenciatura)', 'Licenciatura', 4);
INSERT INTO CURSO (IDcurso, NomeCurso, Grau, Duracao_semestres) VALUES (68, 'História (Licenciatura)', 'Licenciatura', 6);
INSERT INTO CURSO (IDcurso, NomeCurso, Grau, Duracao_semestres) VALUES (69, 'Geografia (Bacharelado)', 'Bacharelado', 10);
INSERT INTO CURSO (IDcurso, NomeCurso, Grau, Duracao_semestres) VALUES (70, 'Letras (Bacharelado)', 'Bacharelado', 8);
INSERT INTO CURSO (IDcurso, NomeCurso, Grau, Duracao_semestres) VALUES (71, 'Educação Física (Bacharelado)', 'Bacharelado', 10);
INSERT INTO CURSO (IDcurso, NomeCurso, Grau, Duracao_semestres) VALUES (72, 'Serviço Social (Bacharelado)', 'Bacharelado', 6);
INSERT INTO CURSO (IDcurso, NomeCurso, Grau, Duracao_semestres) VALUES (73, 'Gastronomia (Licenciatura)', 'Licenciatura', 6);
INSERT INTO CURSO (IDcurso, NomeCurso, Grau, Duracao_semestres) VALUES (74, 'Turismo (Licenciatura)', 'Licenciatura', 10);
INSERT INTO CURSO (IDcurso, NomeCurso, Grau, Duracao_semestres) VALUES (75, 'Marketing (Licenciatura)', 'Licenciatura', 10);
INSERT INTO CURSO (IDcurso, NomeCurso, Grau, Duracao_semestres) VALUES (76, 'Logística (Licenciatura)', 'Licenciatura', 6);
INSERT INTO CURSO (IDcurso, NomeCurso, Grau, Duracao_semestres) VALUES (77, 'Gestão Ambiental (Tecnólogo)', 'Tecnólogo', 8);
INSERT INTO CURSO (IDcurso, NomeCurso, Grau, Duracao_semestres) VALUES (78, 'Ciência de Dados (Bacharelado)', 'Bacharelado', 4);
INSERT INTO CURSO (IDcurso, NomeCurso, Grau, Duracao_semestres) VALUES (79, 'Redes de Computadores (Licenciatura)', 'Licenciatura', 6);
INSERT INTO CURSO (IDcurso, NomeCurso, Grau, Duracao_semestres) VALUES (80, 'Engenharia Civil (Tecnólogo)', 'Tecnólogo', 4);
INSERT INTO CURSO (IDcurso, NomeCurso, Grau, Duracao_semestres) VALUES (81, 'Engenharia de Software (Licenciatura)', 'Licenciatura', 8);
INSERT INTO CURSO (IDcurso, NomeCurso, Grau, Duracao_semestres) VALUES (82, 'Engenharia Elétrica (Tecnólogo)', 'Tecnólogo', 6);
INSERT INTO CURSO (IDcurso, NomeCurso, Grau, Duracao_semestres) VALUES (83, 'Engenharia Mecânica (Tecnólogo)', 'Tecnólogo', 10);
INSERT INTO CURSO (IDcurso, NomeCurso, Grau, Duracao_semestres) VALUES (84, 'Administração (Licenciatura)', 'Licenciatura', 10);
INSERT INTO CURSO (IDcurso, NomeCurso, Grau, Duracao_semestres) VALUES (85, 'Ciências Contábeis (Bacharelado)', 'Bacharelado', 6);
INSERT INTO CURSO (IDcurso, NomeCurso, Grau, Duracao_semestres) VALUES (86, 'Direito (Bacharelado)', 'Bacharelado', 4);
INSERT INTO CURSO (IDcurso, NomeCurso, Grau, Duracao_semestres) VALUES (87, 'Medicina (Licenciatura)', 'Licenciatura', 4);
INSERT INTO CURSO (IDcurso, NomeCurso, Grau, Duracao_semestres) VALUES (88, 'Enfermagem (Bacharelado)', 'Bacharelado', 4);
INSERT INTO CURSO (IDcurso, NomeCurso, Grau, Duracao_semestres) VALUES (89, 'Psicologia (Tecnólogo)', 'Tecnólogo', 10);
INSERT INTO CURSO (IDcurso, NomeCurso, Grau, Duracao_semestres) VALUES (90, 'Pedagogia (Bacharelado)', 'Bacharelado', 4);
INSERT INTO CURSO (IDcurso, NomeCurso, Grau, Duracao_semestres) VALUES (91, 'Arquitetura e Urbanismo (Bacharelado)', 'Bacharelado', 8);
INSERT INTO CURSO (IDcurso, NomeCurso, Grau, Duracao_semestres) VALUES (92, 'Ciência da Computação (Bacharelado)', 'Bacharelado', 8);
INSERT INTO CURSO (IDcurso, NomeCurso, Grau, Duracao_semestres) VALUES (93, 'Sistemas de Informação (Tecnólogo)', 'Tecnólogo', 8);
INSERT INTO CURSO (IDcurso, NomeCurso, Grau, Duracao_semestres) VALUES (94, 'Design Gráfico (Licenciatura)', 'Licenciatura', 10);
INSERT INTO CURSO (IDcurso, NomeCurso, Grau, Duracao_semestres) VALUES (95, 'Nutrição (Bacharelado)', 'Bacharelado', 6);
INSERT INTO CURSO (IDcurso, NomeCurso, Grau, Duracao_semestres) VALUES (96, 'Fisioterapia (Bacharelado)', 'Bacharelado', 6);
INSERT INTO CURSO (IDcurso, NomeCurso, Grau, Duracao_semestres) VALUES (97, 'Odontologia (Licenciatura)', 'Licenciatura', 6);
INSERT INTO CURSO (IDcurso, NomeCurso, Grau, Duracao_semestres) VALUES (98, 'Biomedicina (Tecnólogo)', 'Tecnólogo', 4);
INSERT INTO CURSO (IDcurso, NomeCurso, Grau, Duracao_semestres) VALUES (99, 'Farmácia (Tecnólogo)', 'Tecnólogo', 4);
INSERT INTO CURSO (IDcurso, NomeCurso, Grau, Duracao_semestres) VALUES (100, 'Publicidade e Propaganda (Bacharelado)', 'Bacharelado', 10);
 
-- ---------------- PROFESSOR ----------------
INSERT INTO PROFESSOR (IDprofessor, NomeProfessor, Email, Telefone, Titulacao) VALUES (1, 'Ricardo Batista', 'professor1@edugest.edu.br', '(31) 92040-7519', 'Doutor');
INSERT INTO PROFESSOR (IDprofessor, NomeProfessor, Email, Telefone, Titulacao) VALUES (2, 'Eduardo Batista', 'professor2@edugest.edu.br', '(31) 94822-5143', 'Pós-Doutor');
INSERT INTO PROFESSOR (IDprofessor, NomeProfessor, Email, Telefone, Titulacao) VALUES (3, 'Adriana Lima', 'professor3@edugest.edu.br', '(31) 91686-5009', 'Mestre');
INSERT INTO PROFESSOR (IDprofessor, NomeProfessor, Email, Telefone, Titulacao) VALUES (4, 'Bruno Moreira', 'professor4@edugest.edu.br', '(31) 95833-9243', 'Doutor');
INSERT INTO PROFESSOR (IDprofessor, NomeProfessor, Email, Telefone, Titulacao) VALUES (5, 'Fábio Cardoso', 'professor5@edugest.edu.br', '(31) 92614-9936', 'Doutor');
INSERT INTO PROFESSOR (IDprofessor, NomeProfessor, Email, Telefone, Titulacao) VALUES (6, 'Cristina Teixeira', 'professor6@edugest.edu.br', '(31) 96307-9468', 'Mestre');
INSERT INTO PROFESSOR (IDprofessor, NomeProfessor, Email, Telefone, Titulacao) VALUES (7, 'Otávio Rocha', 'professor7@edugest.edu.br', '(31) 94105-2044', 'Doutor');
INSERT INTO PROFESSOR (IDprofessor, NomeProfessor, Email, Telefone, Titulacao) VALUES (8, 'Débora Ferreira', 'professor8@edugest.edu.br', '(31) 96820-2070', 'Mestre');
INSERT INTO PROFESSOR (IDprofessor, NomeProfessor, Email, Telefone, Titulacao) VALUES (9, 'Tatiane Santos', 'professor9@edugest.edu.br', '(31) 92246-2201', 'Doutor');
INSERT INTO PROFESSOR (IDprofessor, NomeProfessor, Email, Telefone, Titulacao) VALUES (10, 'Simone Rocha', 'professor10@edugest.edu.br', '(31) 91324-8252', 'Mestre');
INSERT INTO PROFESSOR (IDprofessor, NomeProfessor, Email, Telefone, Titulacao) VALUES (11, 'Cristina Ribeiro', 'professor11@edugest.edu.br', '(31) 97578-2152', 'Mestre');
INSERT INTO PROFESSOR (IDprofessor, NomeProfessor, Email, Telefone, Titulacao) VALUES (12, 'João Melo', 'professor12@edugest.edu.br', '(31) 98109-1688', 'Mestre');
INSERT INTO PROFESSOR (IDprofessor, NomeProfessor, Email, Telefone, Titulacao) VALUES (13, 'Márcio Freitas', 'professor13@edugest.edu.br', '(31) 97628-7996', 'Mestre');
INSERT INTO PROFESSOR (IDprofessor, NomeProfessor, Email, Telefone, Titulacao) VALUES (14, 'Felipe Ribeiro', 'professor14@edugest.edu.br', '(31) 97314-6365', 'Mestre');
INSERT INTO PROFESSOR (IDprofessor, NomeProfessor, Email, Telefone, Titulacao) VALUES (15, 'Rafael Souza', 'professor15@edugest.edu.br', '(31) 98859-3831', 'Mestre');
INSERT INTO PROFESSOR (IDprofessor, NomeProfessor, Email, Telefone, Titulacao) VALUES (16, 'Adriana Nunes', 'professor16@edugest.edu.br', '(31) 94537-8368', 'Doutor');
INSERT INTO PROFESSOR (IDprofessor, NomeProfessor, Email, Telefone, Titulacao) VALUES (17, 'Otávio Melo', 'professor17@edugest.edu.br', '(31) 95295-5019', 'Mestre');
INSERT INTO PROFESSOR (IDprofessor, NomeProfessor, Email, Telefone, Titulacao) VALUES (18, 'Fábio Ribeiro', 'professor18@edugest.edu.br', '(31) 96012-7256', 'Doutor');
INSERT INTO PROFESSOR (IDprofessor, NomeProfessor, Email, Telefone, Titulacao) VALUES (19, 'Ana Costa', 'professor19@edugest.edu.br', '(31) 96121-4310', 'Mestre');
INSERT INTO PROFESSOR (IDprofessor, NomeProfessor, Email, Telefone, Titulacao) VALUES (20, 'Gustavo Dias', 'professor20@edugest.edu.br', '(31) 93382-2485', 'Doutor');
INSERT INTO PROFESSOR (IDprofessor, NomeProfessor, Email, Telefone, Titulacao) VALUES (21, 'Rafael Rocha', 'professor21@edugest.edu.br', '(31) 95957-7150', 'Doutor');
INSERT INTO PROFESSOR (IDprofessor, NomeProfessor, Email, Telefone, Titulacao) VALUES (22, 'Ricardo Santos', 'professor22@edugest.edu.br', '(31) 93726-8098', 'Mestre');
INSERT INTO PROFESSOR (IDprofessor, NomeProfessor, Email, Telefone, Titulacao) VALUES (23, 'André Araújo', 'professor23@edugest.edu.br', '(31) 94093-5274', 'Especialista');
INSERT INTO PROFESSOR (IDprofessor, NomeProfessor, Email, Telefone, Titulacao) VALUES (24, 'Carlos Lima', 'professor24@edugest.edu.br', '(31) 99432-5165', 'Pós-Doutor');
INSERT INTO PROFESSOR (IDprofessor, NomeProfessor, Email, Telefone, Titulacao) VALUES (25, 'Rodrigo Nunes', 'professor25@edugest.edu.br', '(31) 99307-4274', 'Mestre');
INSERT INTO PROFESSOR (IDprofessor, NomeProfessor, Email, Telefone, Titulacao) VALUES (26, 'Thiago Dias', 'professor26@edugest.edu.br', '(31) 97209-3574', 'Pós-Doutor');
INSERT INTO PROFESSOR (IDprofessor, NomeProfessor, Email, Telefone, Titulacao) VALUES (27, 'Ricardo Ribeiro', 'professor27@edugest.edu.br', '(31) 98157-8548', 'Doutor');
INSERT INTO PROFESSOR (IDprofessor, NomeProfessor, Email, Telefone, Titulacao) VALUES (28, 'Thiago Melo', 'professor28@edugest.edu.br', '(31) 93856-7301', 'Doutor');
INSERT INTO PROFESSOR (IDprofessor, NomeProfessor, Email, Telefone, Titulacao) VALUES (29, 'Fernanda Ferreira', 'professor29@edugest.edu.br', '(31) 94525-1563', 'Mestre');
INSERT INTO PROFESSOR (IDprofessor, NomeProfessor, Email, Telefone, Titulacao) VALUES (30, 'Diego Silva', 'professor30@edugest.edu.br', '(31) 92226-9211', 'Doutor');
INSERT INTO PROFESSOR (IDprofessor, NomeProfessor, Email, Telefone, Titulacao) VALUES (31, 'Gustavo Teixeira', 'professor31@edugest.edu.br', '(31) 98229-8366', 'Mestre');
INSERT INTO PROFESSOR (IDprofessor, NomeProfessor, Email, Telefone, Titulacao) VALUES (32, 'Ana Barbosa', 'professor32@edugest.edu.br', '(31) 93422-2548', 'Pós-Doutor');
INSERT INTO PROFESSOR (IDprofessor, NomeProfessor, Email, Telefone, Titulacao) VALUES (33, 'Juliana Gomes', 'professor33@edugest.edu.br', '(31) 97071-1049', 'Mestre');
INSERT INTO PROFESSOR (IDprofessor, NomeProfessor, Email, Telefone, Titulacao) VALUES (34, 'Camila Cardoso', 'professor34@edugest.edu.br', '(31) 98080-9673', 'Doutor');
INSERT INTO PROFESSOR (IDprofessor, NomeProfessor, Email, Telefone, Titulacao) VALUES (35, 'Bruno Ferreira', 'professor35@edugest.edu.br', '(31) 97834-7602', 'Doutor');
INSERT INTO PROFESSOR (IDprofessor, NomeProfessor, Email, Telefone, Titulacao) VALUES (36, 'Felipe Rodrigues', 'professor36@edugest.edu.br', '(31) 98663-1288', 'Doutor');
INSERT INTO PROFESSOR (IDprofessor, NomeProfessor, Email, Telefone, Titulacao) VALUES (37, 'Beatriz Oliveira', 'professor37@edugest.edu.br', '(31) 98139-4085', 'Mestre');
INSERT INTO PROFESSOR (IDprofessor, NomeProfessor, Email, Telefone, Titulacao) VALUES (38, 'Fábio Freitas', 'professor38@edugest.edu.br', '(31) 99627-9774', 'Doutor');
INSERT INTO PROFESSOR (IDprofessor, NomeProfessor, Email, Telefone, Titulacao) VALUES (39, 'Paula Melo', 'professor39@edugest.edu.br', '(31) 96537-3501', 'Mestre');
INSERT INTO PROFESSOR (IDprofessor, NomeProfessor, Email, Telefone, Titulacao) VALUES (40, 'Priscila Nascimento', 'professor40@edugest.edu.br', '(31) 95882-1151', 'Doutor');
INSERT INTO PROFESSOR (IDprofessor, NomeProfessor, Email, Telefone, Titulacao) VALUES (41, 'Beatriz Melo', 'professor41@edugest.edu.br', '(31) 92108-4053', 'Doutor');
INSERT INTO PROFESSOR (IDprofessor, NomeProfessor, Email, Telefone, Titulacao) VALUES (42, 'Juliana Araújo', 'professor42@edugest.edu.br', '(31) 95421-6773', 'Especialista');
INSERT INTO PROFESSOR (IDprofessor, NomeProfessor, Email, Telefone, Titulacao) VALUES (43, 'Mariana Cardoso', 'professor43@edugest.edu.br', '(31) 99111-5509', 'Doutor');
INSERT INTO PROFESSOR (IDprofessor, NomeProfessor, Email, Telefone, Titulacao) VALUES (44, 'Gustavo Costa', 'professor44@edugest.edu.br', '(31) 91531-2705', 'Mestre');
INSERT INTO PROFESSOR (IDprofessor, NomeProfessor, Email, Telefone, Titulacao) VALUES (45, 'Priscila Barbosa', 'professor45@edugest.edu.br', '(31) 95103-7691', 'Mestre');
INSERT INTO PROFESSOR (IDprofessor, NomeProfessor, Email, Telefone, Titulacao) VALUES (46, 'Juliana Moreira', 'professor46@edugest.edu.br', '(31) 99594-7938', 'Especialista');
INSERT INTO PROFESSOR (IDprofessor, NomeProfessor, Email, Telefone, Titulacao) VALUES (47, 'Larissa Ferreira', 'professor47@edugest.edu.br', '(31) 99237-1663', 'Doutor');
INSERT INTO PROFESSOR (IDprofessor, NomeProfessor, Email, Telefone, Titulacao) VALUES (48, 'Adriana Barbosa', 'professor48@edugest.edu.br', '(31) 93852-1344', 'Doutor');
INSERT INTO PROFESSOR (IDprofessor, NomeProfessor, Email, Telefone, Titulacao) VALUES (49, 'Fábio Martins', 'professor49@edugest.edu.br', '(31) 93654-8233', 'Doutor');
INSERT INTO PROFESSOR (IDprofessor, NomeProfessor, Email, Telefone, Titulacao) VALUES (50, 'Thiago Melo', 'professor50@edugest.edu.br', '(31) 91911-4560', 'Doutor');
INSERT INTO PROFESSOR (IDprofessor, NomeProfessor, Email, Telefone, Titulacao) VALUES (51, 'Otávio Barbosa', 'professor51@edugest.edu.br', '(31) 92830-6086', 'Mestre');
INSERT INTO PROFESSOR (IDprofessor, NomeProfessor, Email, Telefone, Titulacao) VALUES (52, 'Ricardo Monteiro', 'professor52@edugest.edu.br', '(31) 97012-1184', 'Pós-Doutor');
INSERT INTO PROFESSOR (IDprofessor, NomeProfessor, Email, Telefone, Titulacao) VALUES (53, 'Eduardo Teixeira', 'professor53@edugest.edu.br', '(31) 95344-1409', 'Doutor');
INSERT INTO PROFESSOR (IDprofessor, NomeProfessor, Email, Telefone, Titulacao) VALUES (54, 'Patrícia Costa', 'professor54@edugest.edu.br', '(31) 99785-9200', 'Doutor');
INSERT INTO PROFESSOR (IDprofessor, NomeProfessor, Email, Telefone, Titulacao) VALUES (55, 'Marcos Rodrigues', 'professor55@edugest.edu.br', '(31) 99432-5685', 'Doutor');
INSERT INTO PROFESSOR (IDprofessor, NomeProfessor, Email, Telefone, Titulacao) VALUES (56, 'Diego Monteiro', 'professor56@edugest.edu.br', '(31) 92356-4930', 'Mestre');
INSERT INTO PROFESSOR (IDprofessor, NomeProfessor, Email, Telefone, Titulacao) VALUES (57, 'Eduardo Araújo', 'professor57@edugest.edu.br', '(31) 99844-6934', 'Doutor');
INSERT INTO PROFESSOR (IDprofessor, NomeProfessor, Email, Telefone, Titulacao) VALUES (58, 'Carlos Monteiro', 'professor58@edugest.edu.br', '(31) 97929-1430', 'Pós-Doutor');
INSERT INTO PROFESSOR (IDprofessor, NomeProfessor, Email, Telefone, Titulacao) VALUES (59, 'Marcos Moreira', 'professor59@edugest.edu.br', '(31) 92753-4484', 'Pós-Doutor');
INSERT INTO PROFESSOR (IDprofessor, NomeProfessor, Email, Telefone, Titulacao) VALUES (60, 'Rogério Araújo', 'professor60@edugest.edu.br', '(31) 99420-5851', 'Especialista');
INSERT INTO PROFESSOR (IDprofessor, NomeProfessor, Email, Telefone, Titulacao) VALUES (61, 'Felipe Melo', 'professor61@edugest.edu.br', '(31) 97951-8611', 'Doutor');
INSERT INTO PROFESSOR (IDprofessor, NomeProfessor, Email, Telefone, Titulacao) VALUES (62, 'Juliana Correia', 'professor62@edugest.edu.br', '(31) 94476-5144', 'Mestre');
INSERT INTO PROFESSOR (IDprofessor, NomeProfessor, Email, Telefone, Titulacao) VALUES (63, 'Aline Rodrigues', 'professor63@edugest.edu.br', '(31) 99021-8818', 'Mestre');
INSERT INTO PROFESSOR (IDprofessor, NomeProfessor, Email, Telefone, Titulacao) VALUES (64, 'Sandra Batista', 'professor64@edugest.edu.br', '(31) 98516-4372', 'Especialista');
INSERT INTO PROFESSOR (IDprofessor, NomeProfessor, Email, Telefone, Titulacao) VALUES (65, 'André Cardoso', 'professor65@edugest.edu.br', '(31) 98213-5946', 'Doutor');
INSERT INTO PROFESSOR (IDprofessor, NomeProfessor, Email, Telefone, Titulacao) VALUES (66, 'Larissa Costa', 'professor66@edugest.edu.br', '(31) 97174-3331', 'Mestre');
INSERT INTO PROFESSOR (IDprofessor, NomeProfessor, Email, Telefone, Titulacao) VALUES (67, 'Ana Pinto', 'professor67@edugest.edu.br', '(31) 95859-8501', 'Mestre');
INSERT INTO PROFESSOR (IDprofessor, NomeProfessor, Email, Telefone, Titulacao) VALUES (68, 'Larissa Batista', 'professor68@edugest.edu.br', '(31) 98910-1900', 'Especialista');
INSERT INTO PROFESSOR (IDprofessor, NomeProfessor, Email, Telefone, Titulacao) VALUES (69, 'Camila Martins', 'professor69@edugest.edu.br', '(31) 96468-8561', 'Mestre');
INSERT INTO PROFESSOR (IDprofessor, NomeProfessor, Email, Telefone, Titulacao) VALUES (70, 'Letícia Correia', 'professor70@edugest.edu.br', '(31) 98339-2158', 'Doutor');
INSERT INTO PROFESSOR (IDprofessor, NomeProfessor, Email, Telefone, Titulacao) VALUES (71, 'Fernanda Araújo', 'professor71@edugest.edu.br', '(31) 95102-8516', 'Doutor');
INSERT INTO PROFESSOR (IDprofessor, NomeProfessor, Email, Telefone, Titulacao) VALUES (72, 'Juliana Teixeira', 'professor72@edugest.edu.br', '(31) 96459-2265', 'Doutor');
INSERT INTO PROFESSOR (IDprofessor, NomeProfessor, Email, Telefone, Titulacao) VALUES (73, 'Felipe Correia', 'professor73@edugest.edu.br', '(31) 93128-3394', 'Doutor');
INSERT INTO PROFESSOR (IDprofessor, NomeProfessor, Email, Telefone, Titulacao) VALUES (74, 'Vanessa Santos', 'professor74@edugest.edu.br', '(31) 95846-4575', 'Doutor');
INSERT INTO PROFESSOR (IDprofessor, NomeProfessor, Email, Telefone, Titulacao) VALUES (75, 'Camila Martins', 'professor75@edugest.edu.br', '(31) 99113-4569', 'Especialista');
INSERT INTO PROFESSOR (IDprofessor, NomeProfessor, Email, Telefone, Titulacao) VALUES (76, 'André Monteiro', 'professor76@edugest.edu.br', '(31) 99562-7032', 'Especialista');
INSERT INTO PROFESSOR (IDprofessor, NomeProfessor, Email, Telefone, Titulacao) VALUES (77, 'Rodrigo Nascimento', 'professor77@edugest.edu.br', '(31) 91946-5299', 'Doutor');
INSERT INTO PROFESSOR (IDprofessor, NomeProfessor, Email, Telefone, Titulacao) VALUES (78, 'Tatiane Souza', 'professor78@edugest.edu.br', '(31) 93019-9371', 'Especialista');
INSERT INTO PROFESSOR (IDprofessor, NomeProfessor, Email, Telefone, Titulacao) VALUES (79, 'Larissa Teixeira', 'professor79@edugest.edu.br', '(31) 98270-8994', 'Doutor');
INSERT INTO PROFESSOR (IDprofessor, NomeProfessor, Email, Telefone, Titulacao) VALUES (80, 'Vinícius Araújo', 'professor80@edugest.edu.br', '(31) 98086-1348', 'Doutor');
INSERT INTO PROFESSOR (IDprofessor, NomeProfessor, Email, Telefone, Titulacao) VALUES (81, 'Diego Pereira', 'professor81@edugest.edu.br', '(31) 96675-7583', 'Doutor');
INSERT INTO PROFESSOR (IDprofessor, NomeProfessor, Email, Telefone, Titulacao) VALUES (82, 'Ricardo Moreira', 'professor82@edugest.edu.br', '(31) 99417-4661', 'Mestre');
INSERT INTO PROFESSOR (IDprofessor, NomeProfessor, Email, Telefone, Titulacao) VALUES (83, 'Larissa Silva', 'professor83@edugest.edu.br', '(31) 98453-4627', 'Doutor');
INSERT INTO PROFESSOR (IDprofessor, NomeProfessor, Email, Telefone, Titulacao) VALUES (84, 'Márcio Moreira', 'professor84@edugest.edu.br', '(31) 92421-6650', 'Mestre');
INSERT INTO PROFESSOR (IDprofessor, NomeProfessor, Email, Telefone, Titulacao) VALUES (85, 'Patrícia Silva', 'professor85@edugest.edu.br', '(31) 95441-6356', 'Doutor');
INSERT INTO PROFESSOR (IDprofessor, NomeProfessor, Email, Telefone, Titulacao) VALUES (86, 'Bruno Ferreira', 'professor86@edugest.edu.br', '(31) 91788-8483', 'Mestre');
INSERT INTO PROFESSOR (IDprofessor, NomeProfessor, Email, Telefone, Titulacao) VALUES (87, 'Rodrigo Silva', 'professor87@edugest.edu.br', '(31) 93589-3508', 'Mestre');
INSERT INTO PROFESSOR (IDprofessor, NomeProfessor, Email, Telefone, Titulacao) VALUES (88, 'Lucas Costa', 'professor88@edugest.edu.br', '(31) 99756-2894', 'Doutor');
INSERT INTO PROFESSOR (IDprofessor, NomeProfessor, Email, Telefone, Titulacao) VALUES (89, 'Lucas Pinto', 'professor89@edugest.edu.br', '(31) 93030-4328', 'Doutor');
INSERT INTO PROFESSOR (IDprofessor, NomeProfessor, Email, Telefone, Titulacao) VALUES (90, 'Marcos Barbosa', 'professor90@edugest.edu.br', '(31) 91294-2392', 'Doutor');
INSERT INTO PROFESSOR (IDprofessor, NomeProfessor, Email, Telefone, Titulacao) VALUES (91, 'Larissa Teixeira', 'professor91@edugest.edu.br', '(31) 92577-5009', 'Mestre');
INSERT INTO PROFESSOR (IDprofessor, NomeProfessor, Email, Telefone, Titulacao) VALUES (92, 'Letícia Cavalcanti', 'professor92@edugest.edu.br', '(31) 99526-1148', 'Mestre');
INSERT INTO PROFESSOR (IDprofessor, NomeProfessor, Email, Telefone, Titulacao) VALUES (93, 'Débora Cavalcanti', 'professor93@edugest.edu.br', '(31) 96857-7844', 'Especialista');
INSERT INTO PROFESSOR (IDprofessor, NomeProfessor, Email, Telefone, Titulacao) VALUES (94, 'Fábio Souza', 'professor94@edugest.edu.br', '(31) 97620-8899', 'Mestre');
INSERT INTO PROFESSOR (IDprofessor, NomeProfessor, Email, Telefone, Titulacao) VALUES (95, 'Rafael Pinto', 'professor95@edugest.edu.br', '(31) 95209-8729', 'Doutor');
INSERT INTO PROFESSOR (IDprofessor, NomeProfessor, Email, Telefone, Titulacao) VALUES (96, 'Rogério Freitas', 'professor96@edugest.edu.br', '(31) 93686-5736', 'Mestre');
INSERT INTO PROFESSOR (IDprofessor, NomeProfessor, Email, Telefone, Titulacao) VALUES (97, 'Fábio Correia', 'professor97@edugest.edu.br', '(31) 95326-7378', 'Pós-Doutor');
INSERT INTO PROFESSOR (IDprofessor, NomeProfessor, Email, Telefone, Titulacao) VALUES (98, 'Renata Souza', 'professor98@edugest.edu.br', '(31) 92891-5706', 'Doutor');
INSERT INTO PROFESSOR (IDprofessor, NomeProfessor, Email, Telefone, Titulacao) VALUES (99, 'Fábio Lima', 'professor99@edugest.edu.br', '(31) 93260-3447', 'Mestre');
INSERT INTO PROFESSOR (IDprofessor, NomeProfessor, Email, Telefone, Titulacao) VALUES (100, 'Aline Santos', 'professor100@edugest.edu.br', '(31) 95418-8251', 'Pós-Doutor');
 
-- ---------------- PERIODO_LETIVO ----------------
INSERT INTO PERIODO_LETIVO (IDperiodo, Ano, Semestre, Data_Inicio, Data_Fim) VALUES (1, 2015, 1, '2015-02-01', '2015-07-15');
INSERT INTO PERIODO_LETIVO (IDperiodo, Ano, Semestre, Data_Inicio, Data_Fim) VALUES (2, 2015, 2, '2015-08-01', '2015-12-20');
INSERT INTO PERIODO_LETIVO (IDperiodo, Ano, Semestre, Data_Inicio, Data_Fim) VALUES (3, 2016, 1, '2016-02-01', '2016-07-15');
INSERT INTO PERIODO_LETIVO (IDperiodo, Ano, Semestre, Data_Inicio, Data_Fim) VALUES (4, 2016, 2, '2016-08-01', '2016-12-20');
INSERT INTO PERIODO_LETIVO (IDperiodo, Ano, Semestre, Data_Inicio, Data_Fim) VALUES (5, 2017, 1, '2017-02-01', '2017-07-15');
INSERT INTO PERIODO_LETIVO (IDperiodo, Ano, Semestre, Data_Inicio, Data_Fim) VALUES (6, 2017, 2, '2017-08-01', '2017-12-20');
INSERT INTO PERIODO_LETIVO (IDperiodo, Ano, Semestre, Data_Inicio, Data_Fim) VALUES (7, 2018, 1, '2018-02-01', '2018-07-15');
INSERT INTO PERIODO_LETIVO (IDperiodo, Ano, Semestre, Data_Inicio, Data_Fim) VALUES (8, 2018, 2, '2018-08-01', '2018-12-20');
INSERT INTO PERIODO_LETIVO (IDperiodo, Ano, Semestre, Data_Inicio, Data_Fim) VALUES (9, 2019, 1, '2019-02-01', '2019-07-15');
INSERT INTO PERIODO_LETIVO (IDperiodo, Ano, Semestre, Data_Inicio, Data_Fim) VALUES (10, 2019, 2, '2019-08-01', '2019-12-20');
INSERT INTO PERIODO_LETIVO (IDperiodo, Ano, Semestre, Data_Inicio, Data_Fim) VALUES (11, 2020, 1, '2020-02-01', '2020-07-15');
INSERT INTO PERIODO_LETIVO (IDperiodo, Ano, Semestre, Data_Inicio, Data_Fim) VALUES (12, 2020, 2, '2020-08-01', '2020-12-20');
INSERT INTO PERIODO_LETIVO (IDperiodo, Ano, Semestre, Data_Inicio, Data_Fim) VALUES (13, 2021, 1, '2021-02-01', '2021-07-15');
INSERT INTO PERIODO_LETIVO (IDperiodo, Ano, Semestre, Data_Inicio, Data_Fim) VALUES (14, 2021, 2, '2021-08-01', '2021-12-20');
INSERT INTO PERIODO_LETIVO (IDperiodo, Ano, Semestre, Data_Inicio, Data_Fim) VALUES (15, 2022, 1, '2022-02-01', '2022-07-15');
INSERT INTO PERIODO_LETIVO (IDperiodo, Ano, Semestre, Data_Inicio, Data_Fim) VALUES (16, 2022, 2, '2022-08-01', '2022-12-20');
INSERT INTO PERIODO_LETIVO (IDperiodo, Ano, Semestre, Data_Inicio, Data_Fim) VALUES (17, 2023, 1, '2023-02-01', '2023-07-15');
INSERT INTO PERIODO_LETIVO (IDperiodo, Ano, Semestre, Data_Inicio, Data_Fim) VALUES (18, 2023, 2, '2023-08-01', '2023-12-20');
INSERT INTO PERIODO_LETIVO (IDperiodo, Ano, Semestre, Data_Inicio, Data_Fim) VALUES (19, 2024, 1, '2024-02-01', '2024-07-15');
INSERT INTO PERIODO_LETIVO (IDperiodo, Ano, Semestre, Data_Inicio, Data_Fim) VALUES (20, 2024, 2, '2024-08-01', '2024-12-20');
INSERT INTO PERIODO_LETIVO (IDperiodo, Ano, Semestre, Data_Inicio, Data_Fim) VALUES (21, 2025, 1, '2025-02-01', '2025-07-15');
INSERT INTO PERIODO_LETIVO (IDperiodo, Ano, Semestre, Data_Inicio, Data_Fim) VALUES (22, 2025, 2, '2025-08-01', '2025-12-20');
INSERT INTO PERIODO_LETIVO (IDperiodo, Ano, Semestre, Data_Inicio, Data_Fim) VALUES (23, 2026, 1, '2026-02-01', '2026-07-15');
INSERT INTO PERIODO_LETIVO (IDperiodo, Ano, Semestre, Data_Inicio, Data_Fim) VALUES (24, 2026, 2, '2026-08-01', '2026-12-20');
INSERT INTO PERIODO_LETIVO (IDperiodo, Ano, Semestre, Data_Inicio, Data_Fim) VALUES (25, 2027, 1, '2027-02-01', '2027-07-15');
INSERT INTO PERIODO_LETIVO (IDperiodo, Ano, Semestre, Data_Inicio, Data_Fim) VALUES (26, 2027, 2, '2027-08-01', '2027-12-20');
INSERT INTO PERIODO_LETIVO (IDperiodo, Ano, Semestre, Data_Inicio, Data_Fim) VALUES (27, 2028, 1, '2028-02-01', '2028-07-15');
INSERT INTO PERIODO_LETIVO (IDperiodo, Ano, Semestre, Data_Inicio, Data_Fim) VALUES (28, 2028, 2, '2028-08-01', '2028-12-20');
INSERT INTO PERIODO_LETIVO (IDperiodo, Ano, Semestre, Data_Inicio, Data_Fim) VALUES (29, 2029, 1, '2029-02-01', '2029-07-15');
INSERT INTO PERIODO_LETIVO (IDperiodo, Ano, Semestre, Data_Inicio, Data_Fim) VALUES (30, 2029, 2, '2029-08-01', '2029-12-20');
INSERT INTO PERIODO_LETIVO (IDperiodo, Ano, Semestre, Data_Inicio, Data_Fim) VALUES (31, 2030, 1, '2030-02-01', '2030-07-15');
INSERT INTO PERIODO_LETIVO (IDperiodo, Ano, Semestre, Data_Inicio, Data_Fim) VALUES (32, 2030, 2, '2030-08-01', '2030-12-20');
INSERT INTO PERIODO_LETIVO (IDperiodo, Ano, Semestre, Data_Inicio, Data_Fim) VALUES (33, 2031, 1, '2031-02-01', '2031-07-15');
INSERT INTO PERIODO_LETIVO (IDperiodo, Ano, Semestre, Data_Inicio, Data_Fim) VALUES (34, 2031, 2, '2031-08-01', '2031-12-20');
INSERT INTO PERIODO_LETIVO (IDperiodo, Ano, Semestre, Data_Inicio, Data_Fim) VALUES (35, 2032, 1, '2032-02-01', '2032-07-15');
INSERT INTO PERIODO_LETIVO (IDperiodo, Ano, Semestre, Data_Inicio, Data_Fim) VALUES (36, 2032, 2, '2032-08-01', '2032-12-20');
INSERT INTO PERIODO_LETIVO (IDperiodo, Ano, Semestre, Data_Inicio, Data_Fim) VALUES (37, 2033, 1, '2033-02-01', '2033-07-15');
INSERT INTO PERIODO_LETIVO (IDperiodo, Ano, Semestre, Data_Inicio, Data_Fim) VALUES (38, 2033, 2, '2033-08-01', '2033-12-20');
INSERT INTO PERIODO_LETIVO (IDperiodo, Ano, Semestre, Data_Inicio, Data_Fim) VALUES (39, 2034, 1, '2034-02-01', '2034-07-15');
INSERT INTO PERIODO_LETIVO (IDperiodo, Ano, Semestre, Data_Inicio, Data_Fim) VALUES (40, 2034, 2, '2034-08-01', '2034-12-20');
INSERT INTO PERIODO_LETIVO (IDperiodo, Ano, Semestre, Data_Inicio, Data_Fim) VALUES (41, 2035, 1, '2035-02-01', '2035-07-15');
INSERT INTO PERIODO_LETIVO (IDperiodo, Ano, Semestre, Data_Inicio, Data_Fim) VALUES (42, 2035, 2, '2035-08-01', '2035-12-20');
INSERT INTO PERIODO_LETIVO (IDperiodo, Ano, Semestre, Data_Inicio, Data_Fim) VALUES (43, 2036, 1, '2036-02-01', '2036-07-15');
INSERT INTO PERIODO_LETIVO (IDperiodo, Ano, Semestre, Data_Inicio, Data_Fim) VALUES (44, 2036, 2, '2036-08-01', '2036-12-20');
INSERT INTO PERIODO_LETIVO (IDperiodo, Ano, Semestre, Data_Inicio, Data_Fim) VALUES (45, 2037, 1, '2037-02-01', '2037-07-15');
INSERT INTO PERIODO_LETIVO (IDperiodo, Ano, Semestre, Data_Inicio, Data_Fim) VALUES (46, 2037, 2, '2037-08-01', '2037-12-20');
INSERT INTO PERIODO_LETIVO (IDperiodo, Ano, Semestre, Data_Inicio, Data_Fim) VALUES (47, 2038, 1, '2038-02-01', '2038-07-15');
INSERT INTO PERIODO_LETIVO (IDperiodo, Ano, Semestre, Data_Inicio, Data_Fim) VALUES (48, 2038, 2, '2038-08-01', '2038-12-20');
INSERT INTO PERIODO_LETIVO (IDperiodo, Ano, Semestre, Data_Inicio, Data_Fim) VALUES (49, 2039, 1, '2039-02-01', '2039-07-15');
INSERT INTO PERIODO_LETIVO (IDperiodo, Ano, Semestre, Data_Inicio, Data_Fim) VALUES (50, 2039, 2, '2039-08-01', '2039-12-20');
INSERT INTO PERIODO_LETIVO (IDperiodo, Ano, Semestre, Data_Inicio, Data_Fim) VALUES (51, 2040, 1, '2040-02-01', '2040-07-15');
INSERT INTO PERIODO_LETIVO (IDperiodo, Ano, Semestre, Data_Inicio, Data_Fim) VALUES (52, 2040, 2, '2040-08-01', '2040-12-20');
INSERT INTO PERIODO_LETIVO (IDperiodo, Ano, Semestre, Data_Inicio, Data_Fim) VALUES (53, 2041, 1, '2041-02-01', '2041-07-15');
INSERT INTO PERIODO_LETIVO (IDperiodo, Ano, Semestre, Data_Inicio, Data_Fim) VALUES (54, 2041, 2, '2041-08-01', '2041-12-20');
INSERT INTO PERIODO_LETIVO (IDperiodo, Ano, Semestre, Data_Inicio, Data_Fim) VALUES (55, 2042, 1, '2042-02-01', '2042-07-15');
INSERT INTO PERIODO_LETIVO (IDperiodo, Ano, Semestre, Data_Inicio, Data_Fim) VALUES (56, 2042, 2, '2042-08-01', '2042-12-20');
INSERT INTO PERIODO_LETIVO (IDperiodo, Ano, Semestre, Data_Inicio, Data_Fim) VALUES (57, 2043, 1, '2043-02-01', '2043-07-15');
INSERT INTO PERIODO_LETIVO (IDperiodo, Ano, Semestre, Data_Inicio, Data_Fim) VALUES (58, 2043, 2, '2043-08-01', '2043-12-20');
INSERT INTO PERIODO_LETIVO (IDperiodo, Ano, Semestre, Data_Inicio, Data_Fim) VALUES (59, 2044, 1, '2044-02-01', '2044-07-15');
INSERT INTO PERIODO_LETIVO (IDperiodo, Ano, Semestre, Data_Inicio, Data_Fim) VALUES (60, 2044, 2, '2044-08-01', '2044-12-20');
INSERT INTO PERIODO_LETIVO (IDperiodo, Ano, Semestre, Data_Inicio, Data_Fim) VALUES (61, 2045, 1, '2045-02-01', '2045-07-15');
INSERT INTO PERIODO_LETIVO (IDperiodo, Ano, Semestre, Data_Inicio, Data_Fim) VALUES (62, 2045, 2, '2045-08-01', '2045-12-20');
INSERT INTO PERIODO_LETIVO (IDperiodo, Ano, Semestre, Data_Inicio, Data_Fim) VALUES (63, 2046, 1, '2046-02-01', '2046-07-15');
INSERT INTO PERIODO_LETIVO (IDperiodo, Ano, Semestre, Data_Inicio, Data_Fim) VALUES (64, 2046, 2, '2046-08-01', '2046-12-20');
INSERT INTO PERIODO_LETIVO (IDperiodo, Ano, Semestre, Data_Inicio, Data_Fim) VALUES (65, 2047, 1, '2047-02-01', '2047-07-15');
INSERT INTO PERIODO_LETIVO (IDperiodo, Ano, Semestre, Data_Inicio, Data_Fim) VALUES (66, 2047, 2, '2047-08-01', '2047-12-20');
INSERT INTO PERIODO_LETIVO (IDperiodo, Ano, Semestre, Data_Inicio, Data_Fim) VALUES (67, 2048, 1, '2048-02-01', '2048-07-15');
INSERT INTO PERIODO_LETIVO (IDperiodo, Ano, Semestre, Data_Inicio, Data_Fim) VALUES (68, 2048, 2, '2048-08-01', '2048-12-20');
INSERT INTO PERIODO_LETIVO (IDperiodo, Ano, Semestre, Data_Inicio, Data_Fim) VALUES (69, 2049, 1, '2049-02-01', '2049-07-15');
INSERT INTO PERIODO_LETIVO (IDperiodo, Ano, Semestre, Data_Inicio, Data_Fim) VALUES (70, 2049, 2, '2049-08-01', '2049-12-20');
INSERT INTO PERIODO_LETIVO (IDperiodo, Ano, Semestre, Data_Inicio, Data_Fim) VALUES (71, 2050, 1, '2050-02-01', '2050-07-15');
INSERT INTO PERIODO_LETIVO (IDperiodo, Ano, Semestre, Data_Inicio, Data_Fim) VALUES (72, 2050, 2, '2050-08-01', '2050-12-20');
INSERT INTO PERIODO_LETIVO (IDperiodo, Ano, Semestre, Data_Inicio, Data_Fim) VALUES (73, 2051, 1, '2051-02-01', '2051-07-15');
INSERT INTO PERIODO_LETIVO (IDperiodo, Ano, Semestre, Data_Inicio, Data_Fim) VALUES (74, 2051, 2, '2051-08-01', '2051-12-20');
INSERT INTO PERIODO_LETIVO (IDperiodo, Ano, Semestre, Data_Inicio, Data_Fim) VALUES (75, 2052, 1, '2052-02-01', '2052-07-15');
INSERT INTO PERIODO_LETIVO (IDperiodo, Ano, Semestre, Data_Inicio, Data_Fim) VALUES (76, 2052, 2, '2052-08-01', '2052-12-20');
INSERT INTO PERIODO_LETIVO (IDperiodo, Ano, Semestre, Data_Inicio, Data_Fim) VALUES (77, 2053, 1, '2053-02-01', '2053-07-15');
INSERT INTO PERIODO_LETIVO (IDperiodo, Ano, Semestre, Data_Inicio, Data_Fim) VALUES (78, 2053, 2, '2053-08-01', '2053-12-20');
INSERT INTO PERIODO_LETIVO (IDperiodo, Ano, Semestre, Data_Inicio, Data_Fim) VALUES (79, 2054, 1, '2054-02-01', '2054-07-15');
INSERT INTO PERIODO_LETIVO (IDperiodo, Ano, Semestre, Data_Inicio, Data_Fim) VALUES (80, 2054, 2, '2054-08-01', '2054-12-20');
INSERT INTO PERIODO_LETIVO (IDperiodo, Ano, Semestre, Data_Inicio, Data_Fim) VALUES (81, 2055, 1, '2055-02-01', '2055-07-15');
INSERT INTO PERIODO_LETIVO (IDperiodo, Ano, Semestre, Data_Inicio, Data_Fim) VALUES (82, 2055, 2, '2055-08-01', '2055-12-20');
INSERT INTO PERIODO_LETIVO (IDperiodo, Ano, Semestre, Data_Inicio, Data_Fim) VALUES (83, 2056, 1, '2056-02-01', '2056-07-15');
INSERT INTO PERIODO_LETIVO (IDperiodo, Ano, Semestre, Data_Inicio, Data_Fim) VALUES (84, 2056, 2, '2056-08-01', '2056-12-20');
INSERT INTO PERIODO_LETIVO (IDperiodo, Ano, Semestre, Data_Inicio, Data_Fim) VALUES (85, 2057, 1, '2057-02-01', '2057-07-15');
INSERT INTO PERIODO_LETIVO (IDperiodo, Ano, Semestre, Data_Inicio, Data_Fim) VALUES (86, 2057, 2, '2057-08-01', '2057-12-20');
INSERT INTO PERIODO_LETIVO (IDperiodo, Ano, Semestre, Data_Inicio, Data_Fim) VALUES (87, 2058, 1, '2058-02-01', '2058-07-15');
INSERT INTO PERIODO_LETIVO (IDperiodo, Ano, Semestre, Data_Inicio, Data_Fim) VALUES (88, 2058, 2, '2058-08-01', '2058-12-20');
INSERT INTO PERIODO_LETIVO (IDperiodo, Ano, Semestre, Data_Inicio, Data_Fim) VALUES (89, 2059, 1, '2059-02-01', '2059-07-15');
INSERT INTO PERIODO_LETIVO (IDperiodo, Ano, Semestre, Data_Inicio, Data_Fim) VALUES (90, 2059, 2, '2059-08-01', '2059-12-20');
INSERT INTO PERIODO_LETIVO (IDperiodo, Ano, Semestre, Data_Inicio, Data_Fim) VALUES (91, 2060, 1, '2060-02-01', '2060-07-15');
INSERT INTO PERIODO_LETIVO (IDperiodo, Ano, Semestre, Data_Inicio, Data_Fim) VALUES (92, 2060, 2, '2060-08-01', '2060-12-20');
INSERT INTO PERIODO_LETIVO (IDperiodo, Ano, Semestre, Data_Inicio, Data_Fim) VALUES (93, 2061, 1, '2061-02-01', '2061-07-15');
INSERT INTO PERIODO_LETIVO (IDperiodo, Ano, Semestre, Data_Inicio, Data_Fim) VALUES (94, 2061, 2, '2061-08-01', '2061-12-20');
INSERT INTO PERIODO_LETIVO (IDperiodo, Ano, Semestre, Data_Inicio, Data_Fim) VALUES (95, 2062, 1, '2062-02-01', '2062-07-15');
INSERT INTO PERIODO_LETIVO (IDperiodo, Ano, Semestre, Data_Inicio, Data_Fim) VALUES (96, 2062, 2, '2062-08-01', '2062-12-20');
INSERT INTO PERIODO_LETIVO (IDperiodo, Ano, Semestre, Data_Inicio, Data_Fim) VALUES (97, 2063, 1, '2063-02-01', '2063-07-15');
INSERT INTO PERIODO_LETIVO (IDperiodo, Ano, Semestre, Data_Inicio, Data_Fim) VALUES (98, 2063, 2, '2063-08-01', '2063-12-20');
INSERT INTO PERIODO_LETIVO (IDperiodo, Ano, Semestre, Data_Inicio, Data_Fim) VALUES (99, 2064, 1, '2064-02-01', '2064-07-15');
INSERT INTO PERIODO_LETIVO (IDperiodo, Ano, Semestre, Data_Inicio, Data_Fim) VALUES (100, 2064, 2, '2064-08-01', '2064-12-20');
 
-- ---------------- ALUNO ----------------
INSERT INTO ALUNO (IDaluno, curso_id, NomeAluno, Numero_Documento, Data_Nascimento, Email, Telefone, Estado) VALUES (1, 7, 'Diego Moreira', '000.000.001-03', '1998-09-23', 'aluno1@edugest.edu.br', '(31) 92741-8759', 'Ativo');
INSERT INTO ALUNO (IDaluno, curso_id, NomeAluno, Numero_Documento, Data_Nascimento, Email, Telefone, Estado) VALUES (2, 47, 'Juliana Souza', '000.000.002-06', '2000-11-10', 'aluno2@edugest.edu.br', '(31) 96408-8125', 'Ativo');
INSERT INTO ALUNO (IDaluno, curso_id, NomeAluno, Numero_Documento, Data_Nascimento, Email, Telefone, Estado) VALUES (3, 3, 'Leonardo Rocha', '000.000.003-09', '1991-03-02', 'aluno3@edugest.edu.br', '(31) 94566-4510', 'Ativo');
INSERT INTO ALUNO (IDaluno, curso_id, NomeAluno, Numero_Documento, Data_Nascimento, Email, Telefone, Estado) VALUES (4, 44, 'Ana Melo', '000.000.004-12', '1992-11-15', 'aluno4@edugest.edu.br', '(31) 95074-6810', 'Ativo');
INSERT INTO ALUNO (IDaluno, curso_id, NomeAluno, Numero_Documento, Data_Nascimento, Email, Telefone, Estado) VALUES (5, 49, 'Juliana Almeida', '000.000.005-15', '2007-10-27', 'aluno5@edugest.edu.br', '(31) 93975-7040', 'Ativo');
INSERT INTO ALUNO (IDaluno, curso_id, NomeAluno, Numero_Documento, Data_Nascimento, Email, Telefone, Estado) VALUES (6, 43, 'Diego Nunes', '000.000.006-18', '2005-03-10', 'aluno6@edugest.edu.br', '(31) 92286-1957', 'Ativo');
INSERT INTO ALUNO (IDaluno, curso_id, NomeAluno, Numero_Documento, Data_Nascimento, Email, Telefone, Estado) VALUES (7, 39, 'Débora Barbosa', '000.000.007-21', '1997-03-24', 'aluno7@edugest.edu.br', '(31) 97478-1455', 'Trancado');
INSERT INTO ALUNO (IDaluno, curso_id, NomeAluno, Numero_Documento, Data_Nascimento, Email, Telefone, Estado) VALUES (8, 35, 'Thiago Ferreira', '000.000.008-24', '2004-12-08', 'aluno8@edugest.edu.br', '(31) 92986-1399', 'Desistente');
INSERT INTO ALUNO (IDaluno, curso_id, NomeAluno, Numero_Documento, Data_Nascimento, Email, Telefone, Estado) VALUES (9, 49, 'Juliana Martins', '000.000.009-27', '2005-12-22', 'aluno9@edugest.edu.br', '(31) 99419-4467', 'Transferido');
INSERT INTO ALUNO (IDaluno, curso_id, NomeAluno, Numero_Documento, Data_Nascimento, Email, Telefone, Estado) VALUES (10, 84, 'Leonardo Ribeiro', '000.000.010-30', '2006-05-25', 'aluno10@edugest.edu.br', '(31) 93121-9507', 'Ativo');
INSERT INTO ALUNO (IDaluno, curso_id, NomeAluno, Numero_Documento, Data_Nascimento, Email, Telefone, Estado) VALUES (11, 18, 'Ana Pinto', '000.000.011-33', '1987-03-15', 'aluno11@edugest.edu.br', '(31) 92818-8755', 'Ativo');
INSERT INTO ALUNO (IDaluno, curso_id, NomeAluno, Numero_Documento, Data_Nascimento, Email, Telefone, Estado) VALUES (12, 82, 'Débora Santos', '000.000.012-36', '1990-09-19', 'aluno12@edugest.edu.br', '(31) 95846-8306', 'Desistente');
INSERT INTO ALUNO (IDaluno, curso_id, NomeAluno, Numero_Documento, Data_Nascimento, Email, Telefone, Estado) VALUES (13, 38, 'Tatiane Pinto', '000.000.013-39', '1997-12-18', 'aluno13@edugest.edu.br', '(31) 92898-5575', 'Ativo');
INSERT INTO ALUNO (IDaluno, curso_id, NomeAluno, Numero_Documento, Data_Nascimento, Email, Telefone, Estado) VALUES (14, 90, 'Tatiane Freitas', '000.000.014-42', '1993-08-21', 'aluno14@edugest.edu.br', '(31) 96121-5344', 'Formado');
INSERT INTO ALUNO (IDaluno, curso_id, NomeAluno, Numero_Documento, Data_Nascimento, Email, Telefone, Estado) VALUES (15, 18, 'Rogério Araújo', '000.000.015-45', '2005-11-12', 'aluno15@edugest.edu.br', '(31) 94355-3637', 'Formado');
INSERT INTO ALUNO (IDaluno, curso_id, NomeAluno, Numero_Documento, Data_Nascimento, Email, Telefone, Estado) VALUES (16, 36, 'Patrícia Silva', '000.000.016-48', '1995-01-06', 'aluno16@edugest.edu.br', '(31) 96666-4491', 'Ativo');
INSERT INTO ALUNO (IDaluno, curso_id, NomeAluno, Numero_Documento, Data_Nascimento, Email, Telefone, Estado) VALUES (17, 6, 'Carlos Costa', '000.000.017-51', '1995-10-22', 'aluno17@edugest.edu.br', '(31) 94799-3100', 'Formado');
INSERT INTO ALUNO (IDaluno, curso_id, NomeAluno, Numero_Documento, Data_Nascimento, Email, Telefone, Estado) VALUES (18, 80, 'Patrícia Teixeira', '000.000.018-54', '1991-02-06', 'aluno18@edugest.edu.br', '(31) 96052-7755', 'Ativo');
INSERT INTO ALUNO (IDaluno, curso_id, NomeAluno, Numero_Documento, Data_Nascimento, Email, Telefone, Estado) VALUES (19, 28, 'Gustavo Ribeiro', '000.000.019-57', '1994-12-24', 'aluno19@edugest.edu.br', '(31) 91672-4999', 'Ativo');
INSERT INTO ALUNO (IDaluno, curso_id, NomeAluno, Numero_Documento, Data_Nascimento, Email, Telefone, Estado) VALUES (20, 30, 'Bruno Freitas', '000.000.020-60', '1998-04-03', 'aluno20@edugest.edu.br', '(31) 98603-8551', 'Formado');
INSERT INTO ALUNO (IDaluno, curso_id, NomeAluno, Numero_Documento, Data_Nascimento, Email, Telefone, Estado) VALUES (21, 24, 'Eduardo Moreira', '000.000.021-63', '2004-08-02', 'aluno21@edugest.edu.br', '(31) 97238-8977', 'Ativo');
INSERT INTO ALUNO (IDaluno, curso_id, NomeAluno, Numero_Documento, Data_Nascimento, Email, Telefone, Estado) VALUES (22, 92, 'Vinícius Martins', '000.000.022-66', '1990-09-04', 'aluno22@edugest.edu.br', '(31) 91145-1510', 'Transferido');
INSERT INTO ALUNO (IDaluno, curso_id, NomeAluno, Numero_Documento, Data_Nascimento, Email, Telefone, Estado) VALUES (23, 67, 'Rodrigo Moreira', '000.000.023-69', '2005-01-21', 'aluno23@edugest.edu.br', '(31) 92026-8220', 'Ativo');
INSERT INTO ALUNO (IDaluno, curso_id, NomeAluno, Numero_Documento, Data_Nascimento, Email, Telefone, Estado) VALUES (24, 53, 'Diego Teixeira', '000.000.024-72', '1997-08-16', 'aluno24@edugest.edu.br', '(31) 95345-4054', 'Ativo');
INSERT INTO ALUNO (IDaluno, curso_id, NomeAluno, Numero_Documento, Data_Nascimento, Email, Telefone, Estado) VALUES (25, 82, 'Larissa Nascimento', '000.000.025-75', '1987-03-06', 'aluno25@edugest.edu.br', '(31) 97734-6136', 'Ativo');
INSERT INTO ALUNO (IDaluno, curso_id, NomeAluno, Numero_Documento, Data_Nascimento, Email, Telefone, Estado) VALUES (26, 99, 'Priscila Ribeiro', '000.000.026-78', '2002-12-04', 'aluno26@edugest.edu.br', '(31) 97032-9736', 'Ativo');
INSERT INTO ALUNO (IDaluno, curso_id, NomeAluno, Numero_Documento, Data_Nascimento, Email, Telefone, Estado) VALUES (27, 11, 'Juliana Nunes', '000.000.027-81', '1992-08-11', 'aluno27@edugest.edu.br', '(31) 98743-5771', 'Ativo');
INSERT INTO ALUNO (IDaluno, curso_id, NomeAluno, Numero_Documento, Data_Nascimento, Email, Telefone, Estado) VALUES (28, 31, 'Vinícius Martins', '000.000.028-84', '1993-04-22', 'aluno28@edugest.edu.br', '(31) 96167-6189', 'Trancado');
INSERT INTO ALUNO (IDaluno, curso_id, NomeAluno, Numero_Documento, Data_Nascimento, Email, Telefone, Estado) VALUES (29, 96, 'Paula Barbosa', '000.000.029-87', '1998-04-21', 'aluno29@edugest.edu.br', '(31) 95327-4335', 'Trancado');
INSERT INTO ALUNO (IDaluno, curso_id, NomeAluno, Numero_Documento, Data_Nascimento, Email, Telefone, Estado) VALUES (30, 70, 'Rogério Nunes', '000.000.030-90', '1990-02-24', 'aluno30@edugest.edu.br', '(31) 94039-5347', 'Formado');
INSERT INTO ALUNO (IDaluno, curso_id, NomeAluno, Numero_Documento, Data_Nascimento, Email, Telefone, Estado) VALUES (31, 62, 'Leonardo Teixeira', '000.000.031-93', '2002-05-08', 'aluno31@edugest.edu.br', '(31) 99225-5211', 'Ativo');
INSERT INTO ALUNO (IDaluno, curso_id, NomeAluno, Numero_Documento, Data_Nascimento, Email, Telefone, Estado) VALUES (32, 78, 'Lucas Batista', '000.000.032-96', '1994-10-03', 'aluno32@edugest.edu.br', '(31) 94329-9811', 'Ativo');
INSERT INTO ALUNO (IDaluno, curso_id, NomeAluno, Numero_Documento, Data_Nascimento, Email, Telefone, Estado) VALUES (33, 2, 'Cristina Pinto', '000.000.033-99', '2002-09-26', 'aluno33@edugest.edu.br', '(31) 94883-8048', 'Trancado');
INSERT INTO ALUNO (IDaluno, curso_id, NomeAluno, Numero_Documento, Data_Nascimento, Email, Telefone, Estado) VALUES (34, 88, 'Gustavo Almeida', '000.000.034-02', '2004-12-06', 'aluno34@edugest.edu.br', '(31) 98065-4148', 'Ativo');
INSERT INTO ALUNO (IDaluno, curso_id, NomeAluno, Numero_Documento, Data_Nascimento, Email, Telefone, Estado) VALUES (35, 38, 'Aline Carvalho', '000.000.035-05', '1991-11-22', 'aluno35@edugest.edu.br', '(31) 95271-7508', 'Ativo');
INSERT INTO ALUNO (IDaluno, curso_id, NomeAluno, Numero_Documento, Data_Nascimento, Email, Telefone, Estado) VALUES (36, 76, 'Larissa Souza', '000.000.036-08', '2006-06-09', 'aluno36@edugest.edu.br', '(31) 97129-6587', 'Ativo');
INSERT INTO ALUNO (IDaluno, curso_id, NomeAluno, Numero_Documento, Data_Nascimento, Email, Telefone, Estado) VALUES (37, 66, 'João Almeida', '000.000.037-11', '2006-03-08', 'aluno37@edugest.edu.br', '(31) 94043-2692', 'Ativo');
INSERT INTO ALUNO (IDaluno, curso_id, NomeAluno, Numero_Documento, Data_Nascimento, Email, Telefone, Estado) VALUES (38, 29, 'Patrícia Pinto', '000.000.038-14', '2003-03-11', 'aluno38@edugest.edu.br', '(31) 99625-2383', 'Ativo');
INSERT INTO ALUNO (IDaluno, curso_id, NomeAluno, Numero_Documento, Data_Nascimento, Email, Telefone, Estado) VALUES (39, 7, 'Paula Freitas', '000.000.039-17', '2003-10-06', 'aluno39@edugest.edu.br', '(31) 93761-7503', 'Ativo');
INSERT INTO ALUNO (IDaluno, curso_id, NomeAluno, Numero_Documento, Data_Nascimento, Email, Telefone, Estado) VALUES (40, 39, 'Ricardo Cavalcanti', '000.000.040-20', '1986-03-05', 'aluno40@edugest.edu.br', '(31) 94050-7226', 'Trancado');
INSERT INTO ALUNO (IDaluno, curso_id, NomeAluno, Numero_Documento, Data_Nascimento, Email, Telefone, Estado) VALUES (41, 58, 'Patrícia Ribeiro', '000.000.041-23', '1997-06-04', 'aluno41@edugest.edu.br', '(31) 94351-9422', 'Formado');
INSERT INTO ALUNO (IDaluno, curso_id, NomeAluno, Numero_Documento, Data_Nascimento, Email, Telefone, Estado) VALUES (42, 13, 'Lucas Lima', '000.000.042-26', '1986-02-13', 'aluno42@edugest.edu.br', '(31) 96522-9996', 'Ativo');
INSERT INTO ALUNO (IDaluno, curso_id, NomeAluno, Numero_Documento, Data_Nascimento, Email, Telefone, Estado) VALUES (43, 94, 'Paula Almeida', '000.000.043-29', '1987-12-13', 'aluno43@edugest.edu.br', '(31) 91881-9588', 'Ativo');
INSERT INTO ALUNO (IDaluno, curso_id, NomeAluno, Numero_Documento, Data_Nascimento, Email, Telefone, Estado) VALUES (44, 19, 'Priscila Rocha', '000.000.044-32', '2000-02-11', 'aluno44@edugest.edu.br', '(31) 92661-8476', 'Ativo');
INSERT INTO ALUNO (IDaluno, curso_id, NomeAluno, Numero_Documento, Data_Nascimento, Email, Telefone, Estado) VALUES (45, 84, 'Simone Freitas', '000.000.045-35', '2000-05-20', 'aluno45@edugest.edu.br', '(31) 91934-7740', 'Ativo');
INSERT INTO ALUNO (IDaluno, curso_id, NomeAluno, Numero_Documento, Data_Nascimento, Email, Telefone, Estado) VALUES (46, 7, 'Letícia Almeida', '000.000.046-38', '1992-08-09', 'aluno46@edugest.edu.br', '(31) 95452-7990', 'Ativo');
INSERT INTO ALUNO (IDaluno, curso_id, NomeAluno, Numero_Documento, Data_Nascimento, Email, Telefone, Estado) VALUES (47, 95, 'Leonardo Ribeiro', '000.000.047-41', '1995-04-11', 'aluno47@edugest.edu.br', '(31) 96934-5656', 'Formado');
INSERT INTO ALUNO (IDaluno, curso_id, NomeAluno, Numero_Documento, Data_Nascimento, Email, Telefone, Estado) VALUES (48, 37, 'Simone Silva', '000.000.048-44', '2005-02-09', 'aluno48@edugest.edu.br', '(31) 92142-2923', 'Desistente');
INSERT INTO ALUNO (IDaluno, curso_id, NomeAluno, Numero_Documento, Data_Nascimento, Email, Telefone, Estado) VALUES (49, 84, 'Paula Lima', '000.000.049-47', '1998-06-13', 'aluno49@edugest.edu.br', '(31) 94727-9617', 'Ativo');
INSERT INTO ALUNO (IDaluno, curso_id, NomeAluno, Numero_Documento, Data_Nascimento, Email, Telefone, Estado) VALUES (50, 18, 'Eduardo Barbosa', '000.000.050-50', '1987-04-12', 'aluno50@edugest.edu.br', '(31) 97626-9681', 'Ativo');
INSERT INTO ALUNO (IDaluno, curso_id, NomeAluno, Numero_Documento, Data_Nascimento, Email, Telefone, Estado) VALUES (51, 66, 'Gustavo Martins', '000.000.051-53', '1988-09-25', 'aluno51@edugest.edu.br', '(31) 93378-2423', 'Formado');
INSERT INTO ALUNO (IDaluno, curso_id, NomeAluno, Numero_Documento, Data_Nascimento, Email, Telefone, Estado) VALUES (52, 52, 'Fábio Ferreira', '000.000.052-56', '1998-04-08', 'aluno52@edugest.edu.br', '(31) 95525-4376', 'Ativo');
INSERT INTO ALUNO (IDaluno, curso_id, NomeAluno, Numero_Documento, Data_Nascimento, Email, Telefone, Estado) VALUES (53, 84, 'Juliana Souza', '000.000.053-59', '1995-10-13', 'aluno53@edugest.edu.br', '(31) 94239-2813', 'Desistente');
INSERT INTO ALUNO (IDaluno, curso_id, NomeAluno, Numero_Documento, Data_Nascimento, Email, Telefone, Estado) VALUES (54, 37, 'Rafael Freitas', '000.000.054-62', '2003-05-25', 'aluno54@edugest.edu.br', '(31) 91594-5004', 'Desistente');
INSERT INTO ALUNO (IDaluno, curso_id, NomeAluno, Numero_Documento, Data_Nascimento, Email, Telefone, Estado) VALUES (55, 50, 'Leonardo Araújo', '000.000.055-65', '1986-06-16', 'aluno55@edugest.edu.br', '(31) 95463-1412', 'Ativo');
INSERT INTO ALUNO (IDaluno, curso_id, NomeAluno, Numero_Documento, Data_Nascimento, Email, Telefone, Estado) VALUES (56, 17, 'Mariana Martins', '000.000.056-68', '2002-10-13', 'aluno56@edugest.edu.br', '(31) 96161-8600', 'Formado');
INSERT INTO ALUNO (IDaluno, curso_id, NomeAluno, Numero_Documento, Data_Nascimento, Email, Telefone, Estado) VALUES (57, 11, 'Márcio Batista', '000.000.057-71', '1993-11-22', 'aluno57@edugest.edu.br', '(31) 91824-5292', 'Formado');
INSERT INTO ALUNO (IDaluno, curso_id, NomeAluno, Numero_Documento, Data_Nascimento, Email, Telefone, Estado) VALUES (58, 40, 'Eduardo Moreira', '000.000.058-74', '1986-03-20', 'aluno58@edugest.edu.br', '(31) 93769-1598', 'Formado');
INSERT INTO ALUNO (IDaluno, curso_id, NomeAluno, Numero_Documento, Data_Nascimento, Email, Telefone, Estado) VALUES (59, 66, 'Patrícia Ribeiro', '000.000.059-77', '2004-09-08', 'aluno59@edugest.edu.br', '(31) 91412-2357', 'Ativo');
INSERT INTO ALUNO (IDaluno, curso_id, NomeAluno, Numero_Documento, Data_Nascimento, Email, Telefone, Estado) VALUES (60, 89, 'Rafael Cavalcanti', '000.000.060-80', '2001-06-13', 'aluno60@edugest.edu.br', '(31) 98772-8785', 'Formado');
INSERT INTO ALUNO (IDaluno, curso_id, NomeAluno, Numero_Documento, Data_Nascimento, Email, Telefone, Estado) VALUES (61, 33, 'Beatriz Martins', '000.000.061-83', '2005-12-28', 'aluno61@edugest.edu.br', '(31) 96573-4994', 'Ativo');
INSERT INTO ALUNO (IDaluno, curso_id, NomeAluno, Numero_Documento, Data_Nascimento, Email, Telefone, Estado) VALUES (62, 44, 'Marcos Silva', '000.000.062-86', '1990-08-23', 'aluno62@edugest.edu.br', '(31) 97471-3692', 'Ativo');
INSERT INTO ALUNO (IDaluno, curso_id, NomeAluno, Numero_Documento, Data_Nascimento, Email, Telefone, Estado) VALUES (63, 2, 'Paula Almeida', '000.000.063-89', '1987-03-06', 'aluno63@edugest.edu.br', '(31) 95269-1661', 'Ativo');
INSERT INTO ALUNO (IDaluno, curso_id, NomeAluno, Numero_Documento, Data_Nascimento, Email, Telefone, Estado) VALUES (64, 85, 'Letícia Rodrigues', '000.000.064-92', '2000-11-21', 'aluno64@edugest.edu.br', '(31) 94302-4313', 'Desistente');
INSERT INTO ALUNO (IDaluno, curso_id, NomeAluno, Numero_Documento, Data_Nascimento, Email, Telefone, Estado) VALUES (65, 62, 'Débora Souza', '000.000.065-95', '1989-03-21', 'aluno65@edugest.edu.br', '(31) 96699-5632', 'Ativo');
INSERT INTO ALUNO (IDaluno, curso_id, NomeAluno, Numero_Documento, Data_Nascimento, Email, Telefone, Estado) VALUES (66, 36, 'Bruno Araújo', '000.000.066-98', '1997-06-07', 'aluno66@edugest.edu.br', '(31) 94006-6584', 'Desistente');
INSERT INTO ALUNO (IDaluno, curso_id, NomeAluno, Numero_Documento, Data_Nascimento, Email, Telefone, Estado) VALUES (67, 5, 'Thiago Rodrigues', '000.000.067-01', '2001-05-21', 'aluno67@edugest.edu.br', '(31) 99881-7674', 'Ativo');
INSERT INTO ALUNO (IDaluno, curso_id, NomeAluno, Numero_Documento, Data_Nascimento, Email, Telefone, Estado) VALUES (68, 77, 'Débora Lima', '000.000.068-04', '1989-09-01', 'aluno68@edugest.edu.br', '(31) 91792-1605', 'Formado');
INSERT INTO ALUNO (IDaluno, curso_id, NomeAluno, Numero_Documento, Data_Nascimento, Email, Telefone, Estado) VALUES (69, 21, 'Fábio Melo', '000.000.069-07', '1998-08-28', 'aluno69@edugest.edu.br', '(31) 99601-3531', 'Formado');
INSERT INTO ALUNO (IDaluno, curso_id, NomeAluno, Numero_Documento, Data_Nascimento, Email, Telefone, Estado) VALUES (70, 67, 'Leonardo Carvalho', '000.000.070-10', '2006-11-08', 'aluno70@edugest.edu.br', '(31) 93422-9688', 'Desistente');
INSERT INTO ALUNO (IDaluno, curso_id, NomeAluno, Numero_Documento, Data_Nascimento, Email, Telefone, Estado) VALUES (71, 67, 'Sandra Souza', '000.000.071-13', '1995-08-04', 'aluno71@edugest.edu.br', '(31) 99254-7984', 'Ativo');
INSERT INTO ALUNO (IDaluno, curso_id, NomeAluno, Numero_Documento, Data_Nascimento, Email, Telefone, Estado) VALUES (72, 55, 'Lucas Nascimento', '000.000.072-16', '1985-05-08', 'aluno72@edugest.edu.br', '(31) 95999-8711', 'Formado');
INSERT INTO ALUNO (IDaluno, curso_id, NomeAluno, Numero_Documento, Data_Nascimento, Email, Telefone, Estado) VALUES (73, 24, 'Beatriz Lima', '000.000.073-19', '1995-08-24', 'aluno73@edugest.edu.br', '(31) 96642-8261', 'Ativo');
INSERT INTO ALUNO (IDaluno, curso_id, NomeAluno, Numero_Documento, Data_Nascimento, Email, Telefone, Estado) VALUES (74, 92, 'Leonardo Araújo', '000.000.074-22', '2007-08-08', 'aluno74@edugest.edu.br', '(31) 99389-4069', 'Transferido');
INSERT INTO ALUNO (IDaluno, curso_id, NomeAluno, Numero_Documento, Data_Nascimento, Email, Telefone, Estado) VALUES (75, 32, 'Otávio Martins', '000.000.075-25', '2004-02-13', 'aluno75@edugest.edu.br', '(31) 93810-2250', 'Ativo');
INSERT INTO ALUNO (IDaluno, curso_id, NomeAluno, Numero_Documento, Data_Nascimento, Email, Telefone, Estado) VALUES (76, 20, 'Simone Pinto', '000.000.076-28', '2003-05-18', 'aluno76@edugest.edu.br', '(31) 98753-7299', 'Transferido');
INSERT INTO ALUNO (IDaluno, curso_id, NomeAluno, Numero_Documento, Data_Nascimento, Email, Telefone, Estado) VALUES (77, 11, 'Juliana Ribeiro', '000.000.077-31', '1994-10-20', 'aluno77@edugest.edu.br', '(31) 94673-9532', 'Ativo');
INSERT INTO ALUNO (IDaluno, curso_id, NomeAluno, Numero_Documento, Data_Nascimento, Email, Telefone, Estado) VALUES (78, 42, 'Diego Nascimento', '000.000.078-34', '2006-09-26', 'aluno78@edugest.edu.br', '(31) 96291-1341', 'Ativo');
INSERT INTO ALUNO (IDaluno, curso_id, NomeAluno, Numero_Documento, Data_Nascimento, Email, Telefone, Estado) VALUES (79, 97, 'Ana Ribeiro', '000.000.079-37', '1994-08-04', 'aluno79@edugest.edu.br', '(31) 93757-2184', 'Ativo');
INSERT INTO ALUNO (IDaluno, curso_id, NomeAluno, Numero_Documento, Data_Nascimento, Email, Telefone, Estado) VALUES (80, 31, 'Leonardo Oliveira', '000.000.080-40', '2004-11-13', 'aluno80@edugest.edu.br', '(31) 93600-4335', 'Ativo');
INSERT INTO ALUNO (IDaluno, curso_id, NomeAluno, Numero_Documento, Data_Nascimento, Email, Telefone, Estado) VALUES (81, 3, 'Letícia Oliveira', '000.000.081-43', '2006-08-14', 'aluno81@edugest.edu.br', '(31) 91574-3185', 'Ativo');
INSERT INTO ALUNO (IDaluno, curso_id, NomeAluno, Numero_Documento, Data_Nascimento, Email, Telefone, Estado) VALUES (82, 56, 'Márcio Ferreira', '000.000.082-46', '1989-11-28', 'aluno82@edugest.edu.br', '(31) 91032-1955', 'Ativo');
INSERT INTO ALUNO (IDaluno, curso_id, NomeAluno, Numero_Documento, Data_Nascimento, Email, Telefone, Estado) VALUES (83, 83, 'Priscila Pereira', '000.000.083-49', '1991-05-25', 'aluno83@edugest.edu.br', '(31) 99425-2571', 'Ativo');
INSERT INTO ALUNO (IDaluno, curso_id, NomeAluno, Numero_Documento, Data_Nascimento, Email, Telefone, Estado) VALUES (84, 53, 'Priscila Moreira', '000.000.084-52', '1997-02-23', 'aluno84@edugest.edu.br', '(31) 95254-9835', 'Ativo');
INSERT INTO ALUNO (IDaluno, curso_id, NomeAluno, Numero_Documento, Data_Nascimento, Email, Telefone, Estado) VALUES (85, 40, 'Mariana Carvalho', '000.000.085-55', '1992-01-05', 'aluno85@edugest.edu.br', '(31) 95993-8912', 'Trancado');
INSERT INTO ALUNO (IDaluno, curso_id, NomeAluno, Numero_Documento, Data_Nascimento, Email, Telefone, Estado) VALUES (86, 59, 'Beatriz Nascimento', '000.000.086-58', '2005-12-26', 'aluno86@edugest.edu.br', '(31) 99780-6731', 'Ativo');
INSERT INTO ALUNO (IDaluno, curso_id, NomeAluno, Numero_Documento, Data_Nascimento, Email, Telefone, Estado) VALUES (87, 81, 'Sandra Monteiro', '000.000.087-61', '1987-10-28', 'aluno87@edugest.edu.br', '(31) 91600-6109', 'Ativo');
INSERT INTO ALUNO (IDaluno, curso_id, NomeAluno, Numero_Documento, Data_Nascimento, Email, Telefone, Estado) VALUES (88, 34, 'Leonardo Nunes', '000.000.088-64', '1988-06-01', 'aluno88@edugest.edu.br', '(31) 93503-6554', 'Ativo');
INSERT INTO ALUNO (IDaluno, curso_id, NomeAluno, Numero_Documento, Data_Nascimento, Email, Telefone, Estado) VALUES (89, 56, 'Carlos Batista', '000.000.089-67', '2007-11-05', 'aluno89@edugest.edu.br', '(31) 96118-6695', 'Ativo');
INSERT INTO ALUNO (IDaluno, curso_id, NomeAluno, Numero_Documento, Data_Nascimento, Email, Telefone, Estado) VALUES (90, 51, 'Fernanda Pereira', '000.000.090-70', '1996-01-07', 'aluno90@edugest.edu.br', '(31) 93340-4023', 'Ativo');
INSERT INTO ALUNO (IDaluno, curso_id, NomeAluno, Numero_Documento, Data_Nascimento, Email, Telefone, Estado) VALUES (91, 82, 'Adriana Cavalcanti', '000.000.091-73', '1999-09-04', 'aluno91@edugest.edu.br', '(31) 95249-8316', 'Ativo');
INSERT INTO ALUNO (IDaluno, curso_id, NomeAluno, Numero_Documento, Data_Nascimento, Email, Telefone, Estado) VALUES (92, 21, 'Rodrigo Souza', '000.000.092-76', '1996-02-14', 'aluno92@edugest.edu.br', '(31) 92312-5671', 'Formado');
INSERT INTO ALUNO (IDaluno, curso_id, NomeAluno, Numero_Documento, Data_Nascimento, Email, Telefone, Estado) VALUES (93, 83, 'Thiago Nunes', '000.000.093-79', '1987-04-12', 'aluno93@edugest.edu.br', '(31) 94775-9200', 'Ativo');
INSERT INTO ALUNO (IDaluno, curso_id, NomeAluno, Numero_Documento, Data_Nascimento, Email, Telefone, Estado) VALUES (94, 42, 'Eduardo Martins', '000.000.094-82', '1994-02-28', 'aluno94@edugest.edu.br', '(31) 96034-3952', 'Ativo');
INSERT INTO ALUNO (IDaluno, curso_id, NomeAluno, Numero_Documento, Data_Nascimento, Email, Telefone, Estado) VALUES (95, 99, 'Rodrigo Carvalho', '000.000.095-85', '2004-07-01', 'aluno95@edugest.edu.br', '(31) 95532-5400', 'Ativo');
INSERT INTO ALUNO (IDaluno, curso_id, NomeAluno, Numero_Documento, Data_Nascimento, Email, Telefone, Estado) VALUES (96, 79, 'Aline Barbosa', '000.000.096-88', '1999-11-06', 'aluno96@edugest.edu.br', '(31) 94822-2410', 'Transferido');
INSERT INTO ALUNO (IDaluno, curso_id, NomeAluno, Numero_Documento, Data_Nascimento, Email, Telefone, Estado) VALUES (97, 57, 'Simone Araújo', '000.000.097-91', '1999-02-19', 'aluno97@edugest.edu.br', '(31) 95935-2946', 'Ativo');
INSERT INTO ALUNO (IDaluno, curso_id, NomeAluno, Numero_Documento, Data_Nascimento, Email, Telefone, Estado) VALUES (98, 25, 'Fernanda Oliveira', '000.000.098-94', '1992-01-21', 'aluno98@edugest.edu.br', '(31) 96535-1683', 'Desistente');
INSERT INTO ALUNO (IDaluno, curso_id, NomeAluno, Numero_Documento, Data_Nascimento, Email, Telefone, Estado) VALUES (99, 97, 'Fernanda Barbosa', '000.000.099-97', '1995-09-17', 'aluno99@edugest.edu.br', '(31) 99320-3044', 'Formado');
INSERT INTO ALUNO (IDaluno, curso_id, NomeAluno, Numero_Documento, Data_Nascimento, Email, Telefone, Estado) VALUES (100, 39, 'Adriana Cavalcanti', '000.000.100-00', '1999-01-12', 'aluno100@edugest.edu.br', '(31) 98468-3157', 'Ativo');
 
-- ---------------- DISCIPLINA ----------------
INSERT INTO DISCIPLINA (IDdisciplina, IDcurso, NomeDisciplina, Creditos, Carga_horaria) VALUES (1, 32, 'Ética Profissional B', 8, 120);
INSERT INTO DISCIPLINA (IDdisciplina, IDcurso, NomeDisciplina, Creditos, Carga_horaria) VALUES (2, 26, 'Psicologia do Desenvolvimento II', 6, 90);
INSERT INTO DISCIPLINA (IDdisciplina, IDcurso, NomeDisciplina, Creditos, Carga_horaria) VALUES (3, 27, 'Desenvolvimento Web II', 4, 60);
INSERT INTO DISCIPLINA (IDdisciplina, IDcurso, NomeDisciplina, Creditos, Carga_horaria) VALUES (4, 18, 'Programação III', 6, 90);
INSERT INTO DISCIPLINA (IDdisciplina, IDcurso, NomeDisciplina, Creditos, Carga_horaria) VALUES (5, 94, 'Estrutura de Dados B', 8, 120);
INSERT INTO DISCIPLINA (IDdisciplina, IDcurso, NomeDisciplina, Creditos, Carga_horaria) VALUES (6, 65, 'Metodologia Científica I', 2, 30);
INSERT INTO DISCIPLINA (IDdisciplina, IDcurso, NomeDisciplina, Creditos, Carga_horaria) VALUES (7, 32, 'Fisiologia B', 2, 30);
INSERT INTO DISCIPLINA (IDdisciplina, IDcurso, NomeDisciplina, Creditos, Carga_horaria) VALUES (8, 58, 'Química Geral III', 4, 60);
INSERT INTO DISCIPLINA (IDdisciplina, IDcurso, NomeDisciplina, Creditos, Carga_horaria) VALUES (9, 46, 'Psicologia do Desenvolvimento II', 8, 120);
INSERT INTO DISCIPLINA (IDdisciplina, IDcurso, NomeDisciplina, Creditos, Carga_horaria) VALUES (10, 23, 'Química Geral III', 2, 30);
INSERT INTO DISCIPLINA (IDdisciplina, IDcurso, NomeDisciplina, Creditos, Carga_horaria) VALUES (11, 75, 'Álgebra Linear A', 2, 30);
INSERT INTO DISCIPLINA (IDdisciplina, IDcurso, NomeDisciplina, Creditos, Carga_horaria) VALUES (12, 68, 'Inteligência Artificial II', 2, 30);
INSERT INTO DISCIPLINA (IDdisciplina, IDcurso, NomeDisciplina, Creditos, Carga_horaria) VALUES (13, 85, 'Empreendedorismo II', 6, 90);
INSERT INTO DISCIPLINA (IDdisciplina, IDcurso, NomeDisciplina, Creditos, Carga_horaria) VALUES (14, 90, 'Engenharia de Software III', 6, 90);
INSERT INTO DISCIPLINA (IDdisciplina, IDcurso, NomeDisciplina, Creditos, Carga_horaria) VALUES (15, 77, 'Gestão de Projetos', 4, 60);
INSERT INTO DISCIPLINA (IDdisciplina, IDcurso, NomeDisciplina, Creditos, Carga_horaria) VALUES (16, 90, 'Redes de Computadores B', 6, 90);
INSERT INTO DISCIPLINA (IDdisciplina, IDcurso, NomeDisciplina, Creditos, Carga_horaria) VALUES (17, 41, 'Sociologia A', 2, 30);
INSERT INTO DISCIPLINA (IDdisciplina, IDcurso, NomeDisciplina, Creditos, Carga_horaria) VALUES (18, 48, 'Cálculo B', 8, 120);
INSERT INTO DISCIPLINA (IDdisciplina, IDcurso, NomeDisciplina, Creditos, Carga_horaria) VALUES (19, 60, 'Direito Constitucional I', 6, 90);
INSERT INTO DISCIPLINA (IDdisciplina, IDcurso, NomeDisciplina, Creditos, Carga_horaria) VALUES (20, 15, 'Contabilidade Geral III', 2, 30);
INSERT INTO DISCIPLINA (IDdisciplina, IDcurso, NomeDisciplina, Creditos, Carga_horaria) VALUES (21, 66, 'Psicologia do Desenvolvimento A', 6, 90);
INSERT INTO DISCIPLINA (IDdisciplina, IDcurso, NomeDisciplina, Creditos, Carga_horaria) VALUES (22, 52, 'Redes de Computadores I', 2, 30);
INSERT INTO DISCIPLINA (IDdisciplina, IDcurso, NomeDisciplina, Creditos, Carga_horaria) VALUES (23, 31, 'Cálculo I', 4, 60);
INSERT INTO DISCIPLINA (IDdisciplina, IDcurso, NomeDisciplina, Creditos, Carga_horaria) VALUES (24, 10, 'Álgebra Linear A', 8, 120);
INSERT INTO DISCIPLINA (IDdisciplina, IDcurso, NomeDisciplina, Creditos, Carga_horaria) VALUES (25, 84, 'Marketing Digital III', 8, 120);
INSERT INTO DISCIPLINA (IDdisciplina, IDcurso, NomeDisciplina, Creditos, Carga_horaria) VALUES (26, 54, 'Anatomia Humana A', 4, 60);
INSERT INTO DISCIPLINA (IDdisciplina, IDcurso, NomeDisciplina, Creditos, Carga_horaria) VALUES (27, 20, 'Inteligência Artificial B', 2, 30);
INSERT INTO DISCIPLINA (IDdisciplina, IDcurso, NomeDisciplina, Creditos, Carga_horaria) VALUES (28, 73, 'Banco de Dados B', 2, 30);
INSERT INTO DISCIPLINA (IDdisciplina, IDcurso, NomeDisciplina, Creditos, Carga_horaria) VALUES (29, 80, 'Redes de Computadores A', 6, 90);
INSERT INTO DISCIPLINA (IDdisciplina, IDcurso, NomeDisciplina, Creditos, Carga_horaria) VALUES (30, 32, 'Redes de Computadores', 2, 30);
INSERT INTO DISCIPLINA (IDdisciplina, IDcurso, NomeDisciplina, Creditos, Carga_horaria) VALUES (31, 5, 'Filosofia I', 8, 120);
INSERT INTO DISCIPLINA (IDdisciplina, IDcurso, NomeDisciplina, Creditos, Carga_horaria) VALUES (32, 29, 'Literatura Brasileira A', 8, 120);
INSERT INTO DISCIPLINA (IDdisciplina, IDcurso, NomeDisciplina, Creditos, Carga_horaria) VALUES (33, 3, 'Inteligência Artificial II', 6, 90);
INSERT INTO DISCIPLINA (IDdisciplina, IDcurso, NomeDisciplina, Creditos, Carga_horaria) VALUES (34, 66, 'Sociologia A', 4, 60);
INSERT INTO DISCIPLINA (IDdisciplina, IDcurso, NomeDisciplina, Creditos, Carga_horaria) VALUES (35, 20, 'Gestão de Projetos I', 8, 120);
INSERT INTO DISCIPLINA (IDdisciplina, IDcurso, NomeDisciplina, Creditos, Carga_horaria) VALUES (36, 56, 'Economia Geral II', 2, 30);
INSERT INTO DISCIPLINA (IDdisciplina, IDcurso, NomeDisciplina, Creditos, Carga_horaria) VALUES (37, 70, 'Programação I', 2, 30);
INSERT INTO DISCIPLINA (IDdisciplina, IDcurso, NomeDisciplina, Creditos, Carga_horaria) VALUES (38, 63, 'Desenvolvimento Web A', 2, 30);
INSERT INTO DISCIPLINA (IDdisciplina, IDcurso, NomeDisciplina, Creditos, Carga_horaria) VALUES (39, 11, 'Economia Geral A', 2, 30);
INSERT INTO DISCIPLINA (IDdisciplina, IDcurso, NomeDisciplina, Creditos, Carga_horaria) VALUES (40, 58, 'Cálculo III', 4, 60);
INSERT INTO DISCIPLINA (IDdisciplina, IDcurso, NomeDisciplina, Creditos, Carga_horaria) VALUES (41, 100, 'Química Geral II', 4, 60);
INSERT INTO DISCIPLINA (IDdisciplina, IDcurso, NomeDisciplina, Creditos, Carga_horaria) VALUES (42, 13, 'Literatura Brasileira B', 6, 90);
INSERT INTO DISCIPLINA (IDdisciplina, IDcurso, NomeDisciplina, Creditos, Carga_horaria) VALUES (43, 39, 'Sociologia', 8, 120);
INSERT INTO DISCIPLINA (IDdisciplina, IDcurso, NomeDisciplina, Creditos, Carga_horaria) VALUES (44, 30, 'Redes de Computadores I', 2, 30);
INSERT INTO DISCIPLINA (IDdisciplina, IDcurso, NomeDisciplina, Creditos, Carga_horaria) VALUES (45, 75, 'Empreendedorismo A', 6, 90);
INSERT INTO DISCIPLINA (IDdisciplina, IDcurso, NomeDisciplina, Creditos, Carga_horaria) VALUES (46, 63, 'Segurança da Informação', 8, 120);
INSERT INTO DISCIPLINA (IDdisciplina, IDcurso, NomeDisciplina, Creditos, Carga_horaria) VALUES (47, 59, 'Gestão de Projetos II', 6, 90);
INSERT INTO DISCIPLINA (IDdisciplina, IDcurso, NomeDisciplina, Creditos, Carga_horaria) VALUES (48, 86, 'Sistemas Operacionais III', 6, 90);
INSERT INTO DISCIPLINA (IDdisciplina, IDcurso, NomeDisciplina, Creditos, Carga_horaria) VALUES (49, 78, 'Metodologia Científica III', 8, 120);
INSERT INTO DISCIPLINA (IDdisciplina, IDcurso, NomeDisciplina, Creditos, Carga_horaria) VALUES (50, 6, 'Segurança da Informação II', 4, 60);
INSERT INTO DISCIPLINA (IDdisciplina, IDcurso, NomeDisciplina, Creditos, Carga_horaria) VALUES (51, 76, 'Contabilidade Geral B', 2, 30);
INSERT INTO DISCIPLINA (IDdisciplina, IDcurso, NomeDisciplina, Creditos, Carga_horaria) VALUES (52, 43, 'Estatística II', 8, 120);
INSERT INTO DISCIPLINA (IDdisciplina, IDcurso, NomeDisciplina, Creditos, Carga_horaria) VALUES (53, 39, 'Ética Profissional B', 2, 30);
INSERT INTO DISCIPLINA (IDdisciplina, IDcurso, NomeDisciplina, Creditos, Carga_horaria) VALUES (54, 12, 'Desenvolvimento Web B', 8, 120);
INSERT INTO DISCIPLINA (IDdisciplina, IDcurso, NomeDisciplina, Creditos, Carga_horaria) VALUES (55, 99, 'Segurança da Informação II', 6, 90);
INSERT INTO DISCIPLINA (IDdisciplina, IDcurso, NomeDisciplina, Creditos, Carga_horaria) VALUES (56, 64, 'Psicologia do Desenvolvimento III', 2, 30);
INSERT INTO DISCIPLINA (IDdisciplina, IDcurso, NomeDisciplina, Creditos, Carga_horaria) VALUES (57, 24, 'Física Geral II', 8, 120);
INSERT INTO DISCIPLINA (IDdisciplina, IDcurso, NomeDisciplina, Creditos, Carga_horaria) VALUES (58, 3, 'Literatura Brasileira A', 4, 60);
INSERT INTO DISCIPLINA (IDdisciplina, IDcurso, NomeDisciplina, Creditos, Carga_horaria) VALUES (59, 11, 'História da Arte A', 6, 90);
INSERT INTO DISCIPLINA (IDdisciplina, IDcurso, NomeDisciplina, Creditos, Carga_horaria) VALUES (60, 78, 'Fisiologia B', 8, 120);
INSERT INTO DISCIPLINA (IDdisciplina, IDcurso, NomeDisciplina, Creditos, Carga_horaria) VALUES (61, 23, 'Psicologia do Desenvolvimento I', 2, 30);
INSERT INTO DISCIPLINA (IDdisciplina, IDcurso, NomeDisciplina, Creditos, Carga_horaria) VALUES (62, 33, 'Ética Profissional III', 2, 30);
INSERT INTO DISCIPLINA (IDdisciplina, IDcurso, NomeDisciplina, Creditos, Carga_horaria) VALUES (63, 51, 'Sistemas Operacionais II', 6, 90);
INSERT INTO DISCIPLINA (IDdisciplina, IDcurso, NomeDisciplina, Creditos, Carga_horaria) VALUES (64, 44, 'Inglês Instrumental I', 4, 60);
INSERT INTO DISCIPLINA (IDdisciplina, IDcurso, NomeDisciplina, Creditos, Carga_horaria) VALUES (65, 7, 'Sistemas Operacionais II', 2, 30);
INSERT INTO DISCIPLINA (IDdisciplina, IDcurso, NomeDisciplina, Creditos, Carga_horaria) VALUES (66, 4, 'Banco de Dados A', 6, 90);
INSERT INTO DISCIPLINA (IDdisciplina, IDcurso, NomeDisciplina, Creditos, Carga_horaria) VALUES (67, 10, 'Química Geral III', 6, 90);
INSERT INTO DISCIPLINA (IDdisciplina, IDcurso, NomeDisciplina, Creditos, Carga_horaria) VALUES (68, 90, 'Filosofia III', 2, 30);
INSERT INTO DISCIPLINA (IDdisciplina, IDcurso, NomeDisciplina, Creditos, Carga_horaria) VALUES (69, 23, 'Psicologia do Desenvolvimento', 4, 60);
INSERT INTO DISCIPLINA (IDdisciplina, IDcurso, NomeDisciplina, Creditos, Carga_horaria) VALUES (70, 72, 'Física Geral III', 8, 120);
INSERT INTO DISCIPLINA (IDdisciplina, IDcurso, NomeDisciplina, Creditos, Carga_horaria) VALUES (71, 24, 'Desenvolvimento Web III', 2, 30);
INSERT INTO DISCIPLINA (IDdisciplina, IDcurso, NomeDisciplina, Creditos, Carga_horaria) VALUES (72, 96, 'Programação A', 2, 30);
INSERT INTO DISCIPLINA (IDdisciplina, IDcurso, NomeDisciplina, Creditos, Carga_horaria) VALUES (73, 98, 'História da Arte A', 2, 30);
INSERT INTO DISCIPLINA (IDdisciplina, IDcurso, NomeDisciplina, Creditos, Carga_horaria) VALUES (74, 18, 'Gestão de Projetos I', 6, 90);
INSERT INTO DISCIPLINA (IDdisciplina, IDcurso, NomeDisciplina, Creditos, Carga_horaria) VALUES (75, 10, 'Literatura Brasileira I', 8, 120);
INSERT INTO DISCIPLINA (IDdisciplina, IDcurso, NomeDisciplina, Creditos, Carga_horaria) VALUES (76, 29, 'Química Geral', 8, 120);
INSERT INTO DISCIPLINA (IDdisciplina, IDcurso, NomeDisciplina, Creditos, Carga_horaria) VALUES (77, 21, 'Banco de Dados A', 4, 60);
INSERT INTO DISCIPLINA (IDdisciplina, IDcurso, NomeDisciplina, Creditos, Carga_horaria) VALUES (78, 42, 'Gestão de Projetos A', 6, 90);
INSERT INTO DISCIPLINA (IDdisciplina, IDcurso, NomeDisciplina, Creditos, Carga_horaria) VALUES (79, 4, 'Inteligência Artificial I', 2, 30);
INSERT INTO DISCIPLINA (IDdisciplina, IDcurso, NomeDisciplina, Creditos, Carga_horaria) VALUES (80, 65, 'Segurança da Informação I', 2, 30);
INSERT INTO DISCIPLINA (IDdisciplina, IDcurso, NomeDisciplina, Creditos, Carga_horaria) VALUES (81, 56, 'Estatística A', 4, 60);
INSERT INTO DISCIPLINA (IDdisciplina, IDcurso, NomeDisciplina, Creditos, Carga_horaria) VALUES (82, 55, 'Inglês Instrumental B', 4, 60);
INSERT INTO DISCIPLINA (IDdisciplina, IDcurso, NomeDisciplina, Creditos, Carga_horaria) VALUES (83, 2, 'Psicologia do Desenvolvimento II', 8, 120);
INSERT INTO DISCIPLINA (IDdisciplina, IDcurso, NomeDisciplina, Creditos, Carga_horaria) VALUES (84, 98, 'Estrutura de Dados III', 8, 120);
INSERT INTO DISCIPLINA (IDdisciplina, IDcurso, NomeDisciplina, Creditos, Carga_horaria) VALUES (85, 41, 'Segurança da Informação', 2, 30);
INSERT INTO DISCIPLINA (IDdisciplina, IDcurso, NomeDisciplina, Creditos, Carga_horaria) VALUES (86, 19, 'Sociologia B', 8, 120);
INSERT INTO DISCIPLINA (IDdisciplina, IDcurso, NomeDisciplina, Creditos, Carga_horaria) VALUES (87, 81, 'Marketing Digital A', 2, 30);
INSERT INTO DISCIPLINA (IDdisciplina, IDcurso, NomeDisciplina, Creditos, Carga_horaria) VALUES (88, 7, 'Sistemas Operacionais I', 4, 60);
INSERT INTO DISCIPLINA (IDdisciplina, IDcurso, NomeDisciplina, Creditos, Carga_horaria) VALUES (89, 36, 'Física Geral', 6, 90);
INSERT INTO DISCIPLINA (IDdisciplina, IDcurso, NomeDisciplina, Creditos, Carga_horaria) VALUES (90, 18, 'Literatura Brasileira I', 6, 90);
INSERT INTO DISCIPLINA (IDdisciplina, IDcurso, NomeDisciplina, Creditos, Carga_horaria) VALUES (91, 99, 'Sistemas Operacionais A', 2, 30);
INSERT INTO DISCIPLINA (IDdisciplina, IDcurso, NomeDisciplina, Creditos, Carga_horaria) VALUES (92, 99, 'Física Geral II', 4, 60);
INSERT INTO DISCIPLINA (IDdisciplina, IDcurso, NomeDisciplina, Creditos, Carga_horaria) VALUES (93, 45, 'Empreendedorismo II', 4, 60);
INSERT INTO DISCIPLINA (IDdisciplina, IDcurso, NomeDisciplina, Creditos, Carga_horaria) VALUES (94, 92, 'Contabilidade Geral I', 2, 30);
INSERT INTO DISCIPLINA (IDdisciplina, IDcurso, NomeDisciplina, Creditos, Carga_horaria) VALUES (95, 21, 'História da Arte B', 6, 90);
INSERT INTO DISCIPLINA (IDdisciplina, IDcurso, NomeDisciplina, Creditos, Carga_horaria) VALUES (96, 7, 'Sistemas Operacionais B', 4, 60);
INSERT INTO DISCIPLINA (IDdisciplina, IDcurso, NomeDisciplina, Creditos, Carga_horaria) VALUES (97, 3, 'Segurança da Informação', 2, 30);
INSERT INTO DISCIPLINA (IDdisciplina, IDcurso, NomeDisciplina, Creditos, Carga_horaria) VALUES (98, 48, 'Economia Geral B', 6, 90);
INSERT INTO DISCIPLINA (IDdisciplina, IDcurso, NomeDisciplina, Creditos, Carga_horaria) VALUES (99, 87, 'História da Arte I', 8, 120);
INSERT INTO DISCIPLINA (IDdisciplina, IDcurso, NomeDisciplina, Creditos, Carga_horaria) VALUES (100, 57, 'Inteligência Artificial B', 6, 90);
 
-- ---------------- MENSALIDADE ----------------
INSERT INTO MENSALIDADE (IDmensalidade, IDaluno, IDperiodo, Competencia, valor, vencimento, Data_Pagamento, Estado_Pagamento, Metodo_Pagamento) VALUES (1, 3, 26, '2027-05', 1600.3, '2027-05-10', NULL, 'Pendente', NULL);
INSERT INTO MENSALIDADE (IDmensalidade, IDaluno, IDperiodo, Competencia, valor, vencimento, Data_Pagamento, Estado_Pagamento, Metodo_Pagamento) VALUES (2, 97, 28, '2028-12', 2142.97, '2028-12-10', '2028-12-09', 'Pago', 'Cartão de Crédito');
INSERT INTO MENSALIDADE (IDmensalidade, IDaluno, IDperiodo, Competencia, valor, vencimento, Data_Pagamento, Estado_Pagamento, Metodo_Pagamento) VALUES (3, 43, 53, '2041-04', 1333.1, '2041-04-10', '2041-04-05', 'Pago', 'Cartão de Crédito');
INSERT INTO MENSALIDADE (IDmensalidade, IDaluno, IDperiodo, Competencia, valor, vencimento, Data_Pagamento, Estado_Pagamento, Metodo_Pagamento) VALUES (4, 51, 58, '2043-05', 1201.76, '2043-05-10', '2043-05-07', 'Pago', 'Cartão de Crédito');
INSERT INTO MENSALIDADE (IDmensalidade, IDaluno, IDperiodo, Competencia, valor, vencimento, Data_Pagamento, Estado_Pagamento, Metodo_Pagamento) VALUES (5, 46, 77, '2053-02', 1151.25, '2053-02-10', '2053-02-06', 'Pago', 'Débito Automático');
INSERT INTO MENSALIDADE (IDmensalidade, IDaluno, IDperiodo, Competencia, valor, vencimento, Data_Pagamento, Estado_Pagamento, Metodo_Pagamento) VALUES (6, 77, 58, '2043-06', 672.22, '2043-06-10', '2043-06-06', 'Pago', 'Cartão de Crédito');
INSERT INTO MENSALIDADE (IDmensalidade, IDaluno, IDperiodo, Competencia, valor, vencimento, Data_Pagamento, Estado_Pagamento, Metodo_Pagamento) VALUES (7, 10, 41, '2035-04', 537.99, '2035-04-10', '2035-04-07', 'Pago', 'Cartão de Crédito');
INSERT INTO MENSALIDADE (IDmensalidade, IDaluno, IDperiodo, Competencia, valor, vencimento, Data_Pagamento, Estado_Pagamento, Metodo_Pagamento) VALUES (8, 86, 26, '2027-04', 1319.41, '2027-04-10', NULL, 'Pendente', NULL);
INSERT INTO MENSALIDADE (IDmensalidade, IDaluno, IDperiodo, Competencia, valor, vencimento, Data_Pagamento, Estado_Pagamento, Metodo_Pagamento) VALUES (9, 10, 76, '2052-10', 1716.06, '2052-10-10', '2052-10-09', 'Pago', 'Débito Automático');
INSERT INTO MENSALIDADE (IDmensalidade, IDaluno, IDperiodo, Competencia, valor, vencimento, Data_Pagamento, Estado_Pagamento, Metodo_Pagamento) VALUES (10, 21, 20, '2024-11', 838.69, '2024-11-10', NULL, 'Atrasado', NULL);
INSERT INTO MENSALIDADE (IDmensalidade, IDaluno, IDperiodo, Competencia, valor, vencimento, Data_Pagamento, Estado_Pagamento, Metodo_Pagamento) VALUES (11, 32, 44, '2036-07', 476.36, '2036-07-10', NULL, 'Atrasado', NULL);
INSERT INTO MENSALIDADE (IDmensalidade, IDaluno, IDperiodo, Competencia, valor, vencimento, Data_Pagamento, Estado_Pagamento, Metodo_Pagamento) VALUES (12, 30, 71, '2050-11', 613.42, '2050-11-10', '2050-11-07', 'Pago', 'Pix');
INSERT INTO MENSALIDADE (IDmensalidade, IDaluno, IDperiodo, Competencia, valor, vencimento, Data_Pagamento, Estado_Pagamento, Metodo_Pagamento) VALUES (13, 36, 76, '2052-10', 821.78, '2052-10-10', NULL, 'Pendente', NULL);
INSERT INTO MENSALIDADE (IDmensalidade, IDaluno, IDperiodo, Competencia, valor, vencimento, Data_Pagamento, Estado_Pagamento, Metodo_Pagamento) VALUES (14, 89, 97, '2063-03', 1646.61, '2063-03-10', '2063-03-10', 'Pago', 'Pix');
INSERT INTO MENSALIDADE (IDmensalidade, IDaluno, IDperiodo, Competencia, valor, vencimento, Data_Pagamento, Estado_Pagamento, Metodo_Pagamento) VALUES (15, 23, 57, '2043-09', 1259.2, '2043-09-10', '2043-09-10', 'Pago', 'Cartão de Crédito');
INSERT INTO MENSALIDADE (IDmensalidade, IDaluno, IDperiodo, Competencia, valor, vencimento, Data_Pagamento, Estado_Pagamento, Metodo_Pagamento) VALUES (16, 71, 33, '2031-12', 1927.82, '2031-12-10', '2031-12-06', 'Pago', 'Pix');
INSERT INTO MENSALIDADE (IDmensalidade, IDaluno, IDperiodo, Competencia, valor, vencimento, Data_Pagamento, Estado_Pagamento, Metodo_Pagamento) VALUES (17, 16, 68, '2048-12', 1096.9, '2048-12-10', '2048-12-06', 'Pago', 'Boleto');
INSERT INTO MENSALIDADE (IDmensalidade, IDaluno, IDperiodo, Competencia, valor, vencimento, Data_Pagamento, Estado_Pagamento, Metodo_Pagamento) VALUES (18, 31, 85, '2057-10', 1986.01, '2057-10-10', NULL, 'Atrasado', NULL);
INSERT INTO MENSALIDADE (IDmensalidade, IDaluno, IDperiodo, Competencia, valor, vencimento, Data_Pagamento, Estado_Pagamento, Metodo_Pagamento) VALUES (19, 1, 61, '2045-08', 526.83, '2045-08-10', '2045-08-10', 'Pago', 'Boleto');
INSERT INTO MENSALIDADE (IDmensalidade, IDaluno, IDperiodo, Competencia, valor, vencimento, Data_Pagamento, Estado_Pagamento, Metodo_Pagamento) VALUES (20, 93, 90, '2059-08', 2037.48, '2059-08-10', '2059-08-07', 'Pago', 'Cartão de Crédito');
INSERT INTO MENSALIDADE (IDmensalidade, IDaluno, IDperiodo, Competencia, valor, vencimento, Data_Pagamento, Estado_Pagamento, Metodo_Pagamento) VALUES (21, 44, 52, '2040-05', 512.68, '2040-05-10', '2040-05-06', 'Pago', 'Cartão de Crédito');
INSERT INTO MENSALIDADE (IDmensalidade, IDaluno, IDperiodo, Competencia, valor, vencimento, Data_Pagamento, Estado_Pagamento, Metodo_Pagamento) VALUES (22, 18, 23, '2026-02', 1927.19, '2026-02-10', NULL, 'Pendente', NULL);
INSERT INTO MENSALIDADE (IDmensalidade, IDaluno, IDperiodo, Competencia, valor, vencimento, Data_Pagamento, Estado_Pagamento, Metodo_Pagamento) VALUES (23, 67, 58, '2043-12', 2061.8, '2043-12-10', NULL, 'Atrasado', NULL);
INSERT INTO MENSALIDADE (IDmensalidade, IDaluno, IDperiodo, Competencia, valor, vencimento, Data_Pagamento, Estado_Pagamento, Metodo_Pagamento) VALUES (24, 52, 76, '2052-09', 1103.27, '2052-09-10', '2052-09-10', 'Pago', 'Pix');
INSERT INTO MENSALIDADE (IDmensalidade, IDaluno, IDperiodo, Competencia, valor, vencimento, Data_Pagamento, Estado_Pagamento, Metodo_Pagamento) VALUES (25, 32, 44, '2036-04', 1657.61, '2036-04-10', '2036-04-08', 'Pago', 'Pix');
INSERT INTO MENSALIDADE (IDmensalidade, IDaluno, IDperiodo, Competencia, valor, vencimento, Data_Pagamento, Estado_Pagamento, Metodo_Pagamento) VALUES (26, 22, 95, '2062-07', 2490.54, '2062-07-10', NULL, 'Pendente', NULL);
INSERT INTO MENSALIDADE (IDmensalidade, IDaluno, IDperiodo, Competencia, valor, vencimento, Data_Pagamento, Estado_Pagamento, Metodo_Pagamento) VALUES (27, 19, 89, '2059-05', 2078.93, '2059-05-10', '2059-05-05', 'Pago', 'Débito Automático');
INSERT INTO MENSALIDADE (IDmensalidade, IDaluno, IDperiodo, Competencia, valor, vencimento, Data_Pagamento, Estado_Pagamento, Metodo_Pagamento) VALUES (28, 67, 91, '2060-03', 715.57, '2060-03-10', '2060-03-09', 'Pago', 'Pix');
INSERT INTO MENSALIDADE (IDmensalidade, IDaluno, IDperiodo, Competencia, valor, vencimento, Data_Pagamento, Estado_Pagamento, Metodo_Pagamento) VALUES (29, 80, 13, '2021-08', 1079.78, '2021-08-10', NULL, 'Pendente', NULL);
INSERT INTO MENSALIDADE (IDmensalidade, IDaluno, IDperiodo, Competencia, valor, vencimento, Data_Pagamento, Estado_Pagamento, Metodo_Pagamento) VALUES (30, 8, 43, '2036-05', 1253.68, '2036-05-10', '2036-05-08', 'Pago', 'Cartão de Crédito');
INSERT INTO MENSALIDADE (IDmensalidade, IDaluno, IDperiodo, Competencia, valor, vencimento, Data_Pagamento, Estado_Pagamento, Metodo_Pagamento) VALUES (31, 35, 70, '2049-12', 1003.81, '2049-12-10', '2049-12-09', 'Pago', 'Cartão de Crédito');
INSERT INTO MENSALIDADE (IDmensalidade, IDaluno, IDperiodo, Competencia, valor, vencimento, Data_Pagamento, Estado_Pagamento, Metodo_Pagamento) VALUES (32, 26, 40, '2034-03', 435.86, '2034-03-10', '2034-03-08', 'Pago', 'Cartão de Crédito');
INSERT INTO MENSALIDADE (IDmensalidade, IDaluno, IDperiodo, Competencia, valor, vencimento, Data_Pagamento, Estado_Pagamento, Metodo_Pagamento) VALUES (33, 82, 10, '2019-08', 2409.74, '2019-08-10', NULL, 'Atrasado', NULL);
INSERT INTO MENSALIDADE (IDmensalidade, IDaluno, IDperiodo, Competencia, valor, vencimento, Data_Pagamento, Estado_Pagamento, Metodo_Pagamento) VALUES (34, 68, 35, '2032-04', 2356.05, '2032-04-10', '2032-04-10', 'Pago', 'Boleto');
INSERT INTO MENSALIDADE (IDmensalidade, IDaluno, IDperiodo, Competencia, valor, vencimento, Data_Pagamento, Estado_Pagamento, Metodo_Pagamento) VALUES (35, 65, 48, '2038-03', 1951.43, '2038-03-10', '2038-03-07', 'Pago', 'Cartão de Crédito');
INSERT INTO MENSALIDADE (IDmensalidade, IDaluno, IDperiodo, Competencia, valor, vencimento, Data_Pagamento, Estado_Pagamento, Metodo_Pagamento) VALUES (36, 32, 23, '2026-12', 1661.2, '2026-12-10', '2026-12-06', 'Pago', 'Cartão de Crédito');
INSERT INTO MENSALIDADE (IDmensalidade, IDaluno, IDperiodo, Competencia, valor, vencimento, Data_Pagamento, Estado_Pagamento, Metodo_Pagamento) VALUES (37, 96, 55, '2042-10', 1291.95, '2042-10-10', '2042-10-08', 'Pago', 'Boleto');
INSERT INTO MENSALIDADE (IDmensalidade, IDaluno, IDperiodo, Competencia, valor, vencimento, Data_Pagamento, Estado_Pagamento, Metodo_Pagamento) VALUES (38, 47, 11, '2020-09', 1614.36, '2020-09-10', NULL, 'Pendente', NULL);
INSERT INTO MENSALIDADE (IDmensalidade, IDaluno, IDperiodo, Competencia, valor, vencimento, Data_Pagamento, Estado_Pagamento, Metodo_Pagamento) VALUES (39, 98, 93, '2061-08', 964.21, '2061-08-10', '2061-08-05', 'Pago', 'Pix');
INSERT INTO MENSALIDADE (IDmensalidade, IDaluno, IDperiodo, Competencia, valor, vencimento, Data_Pagamento, Estado_Pagamento, Metodo_Pagamento) VALUES (40, 8, 90, '2059-01', 1075.97, '2059-01-10', '2059-01-07', 'Pago', 'Débito Automático');
INSERT INTO MENSALIDADE (IDmensalidade, IDaluno, IDperiodo, Competencia, valor, vencimento, Data_Pagamento, Estado_Pagamento, Metodo_Pagamento) VALUES (41, 29, 17, '2023-11', 1347.04, '2023-11-10', '2023-11-08', 'Pago', 'Pix');
INSERT INTO MENSALIDADE (IDmensalidade, IDaluno, IDperiodo, Competencia, valor, vencimento, Data_Pagamento, Estado_Pagamento, Metodo_Pagamento) VALUES (42, 20, 18, '2023-08', 633.84, '2023-08-10', NULL, 'Cancelado', NULL);
INSERT INTO MENSALIDADE (IDmensalidade, IDaluno, IDperiodo, Competencia, valor, vencimento, Data_Pagamento, Estado_Pagamento, Metodo_Pagamento) VALUES (43, 11, 51, '2040-11', 1852.69, '2040-11-10', NULL, 'Pendente', NULL);
INSERT INTO MENSALIDADE (IDmensalidade, IDaluno, IDperiodo, Competencia, valor, vencimento, Data_Pagamento, Estado_Pagamento, Metodo_Pagamento) VALUES (44, 15, 52, '2040-11', 2008.84, '2040-11-10', NULL, 'Pendente', NULL);
INSERT INTO MENSALIDADE (IDmensalidade, IDaluno, IDperiodo, Competencia, valor, vencimento, Data_Pagamento, Estado_Pagamento, Metodo_Pagamento) VALUES (45, 59, 82, '2055-02', 1964.57, '2055-02-10', '2055-02-06', 'Pago', 'Boleto');
INSERT INTO MENSALIDADE (IDmensalidade, IDaluno, IDperiodo, Competencia, valor, vencimento, Data_Pagamento, Estado_Pagamento, Metodo_Pagamento) VALUES (46, 83, 39, '2034-02', 2390.2, '2034-02-10', '2034-02-06', 'Pago', 'Pix');
INSERT INTO MENSALIDADE (IDmensalidade, IDaluno, IDperiodo, Competencia, valor, vencimento, Data_Pagamento, Estado_Pagamento, Metodo_Pagamento) VALUES (47, 41, 90, '2059-01', 2266.04, '2059-01-10', '2059-01-08', 'Pago', 'Pix');
INSERT INTO MENSALIDADE (IDmensalidade, IDaluno, IDperiodo, Competencia, valor, vencimento, Data_Pagamento, Estado_Pagamento, Metodo_Pagamento) VALUES (48, 10, 10, '2019-08', 1012.54, '2019-08-10', '2019-08-06', 'Pago', 'Boleto');
INSERT INTO MENSALIDADE (IDmensalidade, IDaluno, IDperiodo, Competencia, valor, vencimento, Data_Pagamento, Estado_Pagamento, Metodo_Pagamento) VALUES (49, 70, 83, '2056-01', 1525.9, '2056-01-10', '2056-01-09', 'Pago', 'Cartão de Crédito');
INSERT INTO MENSALIDADE (IDmensalidade, IDaluno, IDperiodo, Competencia, valor, vencimento, Data_Pagamento, Estado_Pagamento, Metodo_Pagamento) VALUES (50, 51, 96, '2062-05', 972.2, '2062-05-10', '2062-05-07', 'Pago', 'Pix');
INSERT INTO MENSALIDADE (IDmensalidade, IDaluno, IDperiodo, Competencia, valor, vencimento, Data_Pagamento, Estado_Pagamento, Metodo_Pagamento) VALUES (51, 29, 85, '2057-03', 979.29, '2057-03-10', '2057-03-08', 'Pago', 'Boleto');
INSERT INTO MENSALIDADE (IDmensalidade, IDaluno, IDperiodo, Competencia, valor, vencimento, Data_Pagamento, Estado_Pagamento, Metodo_Pagamento) VALUES (52, 97, 68, '2048-06', 1161.71, '2048-06-10', '2048-06-05', 'Pago', 'Cartão de Crédito');
INSERT INTO MENSALIDADE (IDmensalidade, IDaluno, IDperiodo, Competencia, valor, vencimento, Data_Pagamento, Estado_Pagamento, Metodo_Pagamento) VALUES (53, 68, 14, '2021-05', 2212.46, '2021-05-10', NULL, 'Atrasado', NULL);
INSERT INTO MENSALIDADE (IDmensalidade, IDaluno, IDperiodo, Competencia, valor, vencimento, Data_Pagamento, Estado_Pagamento, Metodo_Pagamento) VALUES (54, 53, 7, '2018-08', 1932.66, '2018-08-10', NULL, 'Atrasado', NULL);
INSERT INTO MENSALIDADE (IDmensalidade, IDaluno, IDperiodo, Competencia, valor, vencimento, Data_Pagamento, Estado_Pagamento, Metodo_Pagamento) VALUES (55, 44, 35, '2032-08', 1805.09, '2032-08-10', '2032-08-06', 'Pago', 'Boleto');
INSERT INTO MENSALIDADE (IDmensalidade, IDaluno, IDperiodo, Competencia, valor, vencimento, Data_Pagamento, Estado_Pagamento, Metodo_Pagamento) VALUES (56, 50, 53, '2041-10', 1076.91, '2041-10-10', NULL, 'Pendente', NULL);
INSERT INTO MENSALIDADE (IDmensalidade, IDaluno, IDperiodo, Competencia, valor, vencimento, Data_Pagamento, Estado_Pagamento, Metodo_Pagamento) VALUES (57, 57, 72, '2050-07', 1182.37, '2050-07-10', NULL, 'Pendente', NULL);
INSERT INTO MENSALIDADE (IDmensalidade, IDaluno, IDperiodo, Competencia, valor, vencimento, Data_Pagamento, Estado_Pagamento, Metodo_Pagamento) VALUES (58, 5, 69, '2049-02', 1598.89, '2049-02-10', NULL, 'Pendente', NULL);
INSERT INTO MENSALIDADE (IDmensalidade, IDaluno, IDperiodo, Competencia, valor, vencimento, Data_Pagamento, Estado_Pagamento, Metodo_Pagamento) VALUES (59, 15, 53, '2041-08', 1758.36, '2041-08-10', '2041-08-05', 'Pago', 'Cartão de Crédito');
INSERT INTO MENSALIDADE (IDmensalidade, IDaluno, IDperiodo, Competencia, valor, vencimento, Data_Pagamento, Estado_Pagamento, Metodo_Pagamento) VALUES (60, 35, 21, '2025-02', 1107.19, '2025-02-10', '2025-02-08', 'Pago', 'Pix');
INSERT INTO MENSALIDADE (IDmensalidade, IDaluno, IDperiodo, Competencia, valor, vencimento, Data_Pagamento, Estado_Pagamento, Metodo_Pagamento) VALUES (61, 77, 8, '2018-05', 1929.62, '2018-05-10', '2018-05-09', 'Pago', 'Débito Automático');
INSERT INTO MENSALIDADE (IDmensalidade, IDaluno, IDperiodo, Competencia, valor, vencimento, Data_Pagamento, Estado_Pagamento, Metodo_Pagamento) VALUES (62, 52, 16, '2022-10', 608.29, '2022-10-10', '2022-10-07', 'Pago', 'Boleto');
INSERT INTO MENSALIDADE (IDmensalidade, IDaluno, IDperiodo, Competencia, valor, vencimento, Data_Pagamento, Estado_Pagamento, Metodo_Pagamento) VALUES (63, 4, 89, '2059-07', 806.35, '2059-07-10', '2059-07-05', 'Pago', 'Boleto');
INSERT INTO MENSALIDADE (IDmensalidade, IDaluno, IDperiodo, Competencia, valor, vencimento, Data_Pagamento, Estado_Pagamento, Metodo_Pagamento) VALUES (64, 60, 72, '2050-11', 1612.11, '2050-11-10', '2050-11-10', 'Pago', 'Cartão de Crédito');
INSERT INTO MENSALIDADE (IDmensalidade, IDaluno, IDperiodo, Competencia, valor, vencimento, Data_Pagamento, Estado_Pagamento, Metodo_Pagamento) VALUES (65, 87, 34, '2031-02', 572.52, '2031-02-10', '2031-02-10', 'Pago', 'Débito Automático');
INSERT INTO MENSALIDADE (IDmensalidade, IDaluno, IDperiodo, Competencia, valor, vencimento, Data_Pagamento, Estado_Pagamento, Metodo_Pagamento) VALUES (66, 77, 17, '2023-05', 787.01, '2023-05-10', '2023-05-10', 'Pago', 'Débito Automático');
INSERT INTO MENSALIDADE (IDmensalidade, IDaluno, IDperiodo, Competencia, valor, vencimento, Data_Pagamento, Estado_Pagamento, Metodo_Pagamento) VALUES (67, 34, 30, '2029-05', 476.69, '2029-05-10', '2029-05-10', 'Pago', 'Boleto');
INSERT INTO MENSALIDADE (IDmensalidade, IDaluno, IDperiodo, Competencia, valor, vencimento, Data_Pagamento, Estado_Pagamento, Metodo_Pagamento) VALUES (68, 63, 75, '2052-09', 447.27, '2052-09-10', NULL, 'Pendente', NULL);
INSERT INTO MENSALIDADE (IDmensalidade, IDaluno, IDperiodo, Competencia, valor, vencimento, Data_Pagamento, Estado_Pagamento, Metodo_Pagamento) VALUES (69, 54, 37, '2033-12', 1208.66, '2033-12-10', NULL, 'Atrasado', NULL);
INSERT INTO MENSALIDADE (IDmensalidade, IDaluno, IDperiodo, Competencia, valor, vencimento, Data_Pagamento, Estado_Pagamento, Metodo_Pagamento) VALUES (70, 97, 48, '2038-02', 2036.19, '2038-02-10', '2038-02-06', 'Pago', 'Pix');
INSERT INTO MENSALIDADE (IDmensalidade, IDaluno, IDperiodo, Competencia, valor, vencimento, Data_Pagamento, Estado_Pagamento, Metodo_Pagamento) VALUES (71, 55, 78, '2053-03', 2149.33, '2053-03-10', '2053-03-07', 'Pago', 'Débito Automático');
INSERT INTO MENSALIDADE (IDmensalidade, IDaluno, IDperiodo, Competencia, valor, vencimento, Data_Pagamento, Estado_Pagamento, Metodo_Pagamento) VALUES (72, 97, 2, '2015-03', 1630.94, '2015-03-10', '2015-03-09', 'Pago', 'Boleto');
INSERT INTO MENSALIDADE (IDmensalidade, IDaluno, IDperiodo, Competencia, valor, vencimento, Data_Pagamento, Estado_Pagamento, Metodo_Pagamento) VALUES (73, 33, 73, '2051-05', 794.54, '2051-05-10', '2051-05-07', 'Pago', 'Cartão de Crédito');
INSERT INTO MENSALIDADE (IDmensalidade, IDaluno, IDperiodo, Competencia, valor, vencimento, Data_Pagamento, Estado_Pagamento, Metodo_Pagamento) VALUES (74, 10, 71, '2050-10', 2368.56, '2050-10-10', '2050-10-10', 'Pago', 'Débito Automático');
INSERT INTO MENSALIDADE (IDmensalidade, IDaluno, IDperiodo, Competencia, valor, vencimento, Data_Pagamento, Estado_Pagamento, Metodo_Pagamento) VALUES (75, 84, 5, '2017-04', 662.03, '2017-04-10', '2017-04-09', 'Pago', 'Pix');
INSERT INTO MENSALIDADE (IDmensalidade, IDaluno, IDperiodo, Competencia, valor, vencimento, Data_Pagamento, Estado_Pagamento, Metodo_Pagamento) VALUES (76, 77, 66, '2047-04', 2300.56, '2047-04-10', '2047-04-07', 'Pago', 'Boleto');
INSERT INTO MENSALIDADE (IDmensalidade, IDaluno, IDperiodo, Competencia, valor, vencimento, Data_Pagamento, Estado_Pagamento, Metodo_Pagamento) VALUES (77, 88, 32, '2030-12', 2487.45, '2030-12-10', '2030-12-05', 'Pago', 'Pix');
INSERT INTO MENSALIDADE (IDmensalidade, IDaluno, IDperiodo, Competencia, valor, vencimento, Data_Pagamento, Estado_Pagamento, Metodo_Pagamento) VALUES (78, 94, 54, '2041-09', 1365.59, '2041-09-10', '2041-09-05', 'Pago', 'Débito Automático');
INSERT INTO MENSALIDADE (IDmensalidade, IDaluno, IDperiodo, Competencia, valor, vencimento, Data_Pagamento, Estado_Pagamento, Metodo_Pagamento) VALUES (79, 17, 60, '2044-06', 613.46, '2044-06-10', '2044-06-06', 'Pago', 'Pix');
INSERT INTO MENSALIDADE (IDmensalidade, IDaluno, IDperiodo, Competencia, valor, vencimento, Data_Pagamento, Estado_Pagamento, Metodo_Pagamento) VALUES (80, 5, 15, '2022-08', 886.03, '2022-08-10', '2022-08-09', 'Pago', 'Boleto');
INSERT INTO MENSALIDADE (IDmensalidade, IDaluno, IDperiodo, Competencia, valor, vencimento, Data_Pagamento, Estado_Pagamento, Metodo_Pagamento) VALUES (81, 38, 30, '2029-11', 2109.11, '2029-11-10', '2029-11-10', 'Pago', 'Pix');
INSERT INTO MENSALIDADE (IDmensalidade, IDaluno, IDperiodo, Competencia, valor, vencimento, Data_Pagamento, Estado_Pagamento, Metodo_Pagamento) VALUES (82, 99, 11, '2020-05', 1219.56, '2020-05-10', NULL, 'Cancelado', NULL);
INSERT INTO MENSALIDADE (IDmensalidade, IDaluno, IDperiodo, Competencia, valor, vencimento, Data_Pagamento, Estado_Pagamento, Metodo_Pagamento) VALUES (83, 54, 25, '2027-11', 1894.14, '2027-11-10', '2027-11-10', 'Pago', 'Débito Automático');
INSERT INTO MENSALIDADE (IDmensalidade, IDaluno, IDperiodo, Competencia, valor, vencimento, Data_Pagamento, Estado_Pagamento, Metodo_Pagamento) VALUES (84, 30, 40, '2034-04', 2340.82, '2034-04-10', '2034-04-07', 'Pago', 'Pix');
INSERT INTO MENSALIDADE (IDmensalidade, IDaluno, IDperiodo, Competencia, valor, vencimento, Data_Pagamento, Estado_Pagamento, Metodo_Pagamento) VALUES (85, 83, 26, '2027-04', 591.71, '2027-04-10', NULL, 'Atrasado', NULL);
INSERT INTO MENSALIDADE (IDmensalidade, IDaluno, IDperiodo, Competencia, valor, vencimento, Data_Pagamento, Estado_Pagamento, Metodo_Pagamento) VALUES (86, 52, 94, '2061-08', 2093.28, '2061-08-10', '2061-08-06', 'Pago', 'Boleto');
INSERT INTO MENSALIDADE (IDmensalidade, IDaluno, IDperiodo, Competencia, valor, vencimento, Data_Pagamento, Estado_Pagamento, Metodo_Pagamento) VALUES (87, 92, 46, '2037-01', 855.26, '2037-01-10', NULL, 'Pendente', NULL);
INSERT INTO MENSALIDADE (IDmensalidade, IDaluno, IDperiodo, Competencia, valor, vencimento, Data_Pagamento, Estado_Pagamento, Metodo_Pagamento) VALUES (88, 81, 79, '2054-06', 1887.71, '2054-06-10', NULL, 'Atrasado', NULL);
INSERT INTO MENSALIDADE (IDmensalidade, IDaluno, IDperiodo, Competencia, valor, vencimento, Data_Pagamento, Estado_Pagamento, Metodo_Pagamento) VALUES (89, 87, 6, '2017-08', 2425.81, '2017-08-10', NULL, 'Pendente', NULL);
INSERT INTO MENSALIDADE (IDmensalidade, IDaluno, IDperiodo, Competencia, valor, vencimento, Data_Pagamento, Estado_Pagamento, Metodo_Pagamento) VALUES (90, 31, 62, '2045-06', 1781.09, '2045-06-10', '2045-06-05', 'Pago', 'Débito Automático');
INSERT INTO MENSALIDADE (IDmensalidade, IDaluno, IDperiodo, Competencia, valor, vencimento, Data_Pagamento, Estado_Pagamento, Metodo_Pagamento) VALUES (91, 2, 10, '2019-08', 984.64, '2019-08-10', '2019-08-08', 'Pago', 'Pix');
INSERT INTO MENSALIDADE (IDmensalidade, IDaluno, IDperiodo, Competencia, valor, vencimento, Data_Pagamento, Estado_Pagamento, Metodo_Pagamento) VALUES (92, 48, 52, '2040-09', 1544.42, '2040-09-10', '2040-09-10', 'Pago', 'Pix');
INSERT INTO MENSALIDADE (IDmensalidade, IDaluno, IDperiodo, Competencia, valor, vencimento, Data_Pagamento, Estado_Pagamento, Metodo_Pagamento) VALUES (93, 57, 46, '2037-04', 2003.36, '2037-04-10', NULL, 'Atrasado', NULL);
INSERT INTO MENSALIDADE (IDmensalidade, IDaluno, IDperiodo, Competencia, valor, vencimento, Data_Pagamento, Estado_Pagamento, Metodo_Pagamento) VALUES (94, 12, 35, '2032-11', 1854.57, '2032-11-10', '2032-11-07', 'Pago', 'Pix');
INSERT INTO MENSALIDADE (IDmensalidade, IDaluno, IDperiodo, Competencia, valor, vencimento, Data_Pagamento, Estado_Pagamento, Metodo_Pagamento) VALUES (95, 73, 42, '2035-06', 621.56, '2035-06-10', '2035-06-09', 'Pago', 'Cartão de Crédito');
INSERT INTO MENSALIDADE (IDmensalidade, IDaluno, IDperiodo, Competencia, valor, vencimento, Data_Pagamento, Estado_Pagamento, Metodo_Pagamento) VALUES (96, 93, 99, '2064-08', 2373.66, '2064-08-10', '2064-08-07', 'Pago', 'Pix');
INSERT INTO MENSALIDADE (IDmensalidade, IDaluno, IDperiodo, Competencia, valor, vencimento, Data_Pagamento, Estado_Pagamento, Metodo_Pagamento) VALUES (97, 64, 19, '2024-10', 1389.85, '2024-10-10', '2024-10-05', 'Pago', 'Cartão de Crédito');
INSERT INTO MENSALIDADE (IDmensalidade, IDaluno, IDperiodo, Competencia, valor, vencimento, Data_Pagamento, Estado_Pagamento, Metodo_Pagamento) VALUES (98, 94, 56, '2042-06', 2315.56, '2042-06-10', NULL, 'Pendente', NULL);
INSERT INTO MENSALIDADE (IDmensalidade, IDaluno, IDperiodo, Competencia, valor, vencimento, Data_Pagamento, Estado_Pagamento, Metodo_Pagamento) VALUES (99, 65, 56, '2042-10', 1984.93, '2042-10-10', '2042-10-08', 'Pago', 'Débito Automático');
INSERT INTO MENSALIDADE (IDmensalidade, IDaluno, IDperiodo, Competencia, valor, vencimento, Data_Pagamento, Estado_Pagamento, Metodo_Pagamento) VALUES (100, 12, 65, '2047-01', 658.97, '2047-01-10', NULL, 'Cancelado', NULL);
 
-- ---------------- TURMA ----------------
INSERT INTO TURMA (IDturma, IDdisciplina, IDprofessor, IDperiodo, Horario, Sala, Vagas) VALUES (1, 84, 76, 70, 'Segunda - Noite (19h-18h)', 'Sala 14A', 41);
INSERT INTO TURMA (IDturma, IDdisciplina, IDprofessor, IDperiodo, Horario, Sala, Vagas) VALUES (2, 61, 70, 79, 'Sexta - Noite (7h-16h)', 'Sala 37B', 31);
INSERT INTO TURMA (IDturma, IDdisciplina, IDprofessor, IDperiodo, Horario, Sala, Vagas) VALUES (3, 88, 41, 6, 'Quinta - Manhã (8h-17h)', 'Sala 35B', 33);
INSERT INTO TURMA (IDturma, IDdisciplina, IDprofessor, IDperiodo, Horario, Sala, Vagas) VALUES (4, 13, 99, 71, 'Sexta - Manhã (17h-7h)', 'Sala 34B', 48);
INSERT INTO TURMA (IDturma, IDdisciplina, IDprofessor, IDperiodo, Horario, Sala, Vagas) VALUES (5, 92, 7, 40, 'Sábado - Tarde (9h-11h)', 'Sala 13C', 43);
INSERT INTO TURMA (IDturma, IDdisciplina, IDprofessor, IDperiodo, Horario, Sala, Vagas) VALUES (6, 15, 85, 88, 'Quarta - Noite (11h-10h)', 'Sala 13A', 27);
INSERT INTO TURMA (IDturma, IDdisciplina, IDprofessor, IDperiodo, Horario, Sala, Vagas) VALUES (7, 19, 28, 81, 'Terça - Noite (10h-13h)', 'Sala 10A', 24);
INSERT INTO TURMA (IDturma, IDdisciplina, IDprofessor, IDperiodo, Horario, Sala, Vagas) VALUES (8, 86, 73, 61, 'Segunda - Manhã (14h-14h)', 'Sala 10B', 42);
INSERT INTO TURMA (IDturma, IDdisciplina, IDprofessor, IDperiodo, Horario, Sala, Vagas) VALUES (9, 11, 38, 48, 'Quinta - Noite (15h-15h)', 'Sala 17C', 60);
INSERT INTO TURMA (IDturma, IDdisciplina, IDprofessor, IDperiodo, Horario, Sala, Vagas) VALUES (10, 6, 45, 44, 'Terça - Tarde (21h-8h)', 'Sala 33C', 26);
INSERT INTO TURMA (IDturma, IDdisciplina, IDprofessor, IDperiodo, Horario, Sala, Vagas) VALUES (11, 19, 39, 97, 'Segunda - Tarde (18h-8h)', 'Sala 25A', 56);
INSERT INTO TURMA (IDturma, IDdisciplina, IDprofessor, IDperiodo, Horario, Sala, Vagas) VALUES (12, 16, 79, 58, 'Quinta - Tarde (9h-16h)', 'Sala 10C', 26);
INSERT INTO TURMA (IDturma, IDdisciplina, IDprofessor, IDperiodo, Horario, Sala, Vagas) VALUES (13, 64, 9, 67, 'Quinta - Noite (21h-10h)', 'Sala 24A', 48);
INSERT INTO TURMA (IDturma, IDdisciplina, IDprofessor, IDperiodo, Horario, Sala, Vagas) VALUES (14, 99, 28, 73, 'Sábado - Noite (18h-7h)', 'Sala 28B', 58);
INSERT INTO TURMA (IDturma, IDdisciplina, IDprofessor, IDperiodo, Horario, Sala, Vagas) VALUES (15, 22, 21, 59, 'Sábado - Noite (15h-16h)', 'Sala 22B', 20);
INSERT INTO TURMA (IDturma, IDdisciplina, IDprofessor, IDperiodo, Horario, Sala, Vagas) VALUES (16, 42, 73, 99, 'Quarta - Manhã (15h-23h)', 'Sala 23C', 53);
INSERT INTO TURMA (IDturma, IDdisciplina, IDprofessor, IDperiodo, Horario, Sala, Vagas) VALUES (17, 97, 19, 48, 'Terça - Noite (20h-15h)', 'Sala 6A', 24);
INSERT INTO TURMA (IDturma, IDdisciplina, IDprofessor, IDperiodo, Horario, Sala, Vagas) VALUES (18, 64, 23, 43, 'Quinta - Manhã (11h-13h)', 'Sala 25B', 31);
INSERT INTO TURMA (IDturma, IDdisciplina, IDprofessor, IDperiodo, Horario, Sala, Vagas) VALUES (19, 54, 49, 66, 'Sábado - Tarde (13h-8h)', 'Sala 18C', 41);
INSERT INTO TURMA (IDturma, IDdisciplina, IDprofessor, IDperiodo, Horario, Sala, Vagas) VALUES (20, 77, 86, 18, 'Segunda - Manhã (21h-22h)', 'Sala 29C', 53);
INSERT INTO TURMA (IDturma, IDdisciplina, IDprofessor, IDperiodo, Horario, Sala, Vagas) VALUES (21, 18, 78, 78, 'Segunda - Tarde (18h-18h)', 'Sala 14C', 53);
INSERT INTO TURMA (IDturma, IDdisciplina, IDprofessor, IDperiodo, Horario, Sala, Vagas) VALUES (22, 69, 84, 78, 'Sexta - Noite (7h-11h)', 'Sala 2A', 33);
INSERT INTO TURMA (IDturma, IDdisciplina, IDprofessor, IDperiodo, Horario, Sala, Vagas) VALUES (23, 63, 3, 7, 'Sábado - Noite (19h-7h)', 'Sala 24C', 58);
INSERT INTO TURMA (IDturma, IDdisciplina, IDprofessor, IDperiodo, Horario, Sala, Vagas) VALUES (24, 5, 6, 10, 'Sábado - Noite (17h-21h)', 'Sala 31A', 46);
INSERT INTO TURMA (IDturma, IDdisciplina, IDprofessor, IDperiodo, Horario, Sala, Vagas) VALUES (25, 1, 23, 12, 'Sexta - Tarde (11h-14h)', 'Sala 16A', 25);
INSERT INTO TURMA (IDturma, IDdisciplina, IDprofessor, IDperiodo, Horario, Sala, Vagas) VALUES (26, 12, 89, 84, 'Sexta - Tarde (9h-22h)', 'Sala 34C', 58);
INSERT INTO TURMA (IDturma, IDdisciplina, IDprofessor, IDperiodo, Horario, Sala, Vagas) VALUES (27, 39, 94, 68, 'Quinta - Manhã (20h-17h)', 'Sala 36A', 42);
INSERT INTO TURMA (IDturma, IDdisciplina, IDprofessor, IDperiodo, Horario, Sala, Vagas) VALUES (28, 88, 91, 50, 'Sexta - Tarde (18h-12h)', 'Sala 37A', 30);
INSERT INTO TURMA (IDturma, IDdisciplina, IDprofessor, IDperiodo, Horario, Sala, Vagas) VALUES (29, 90, 74, 70, 'Quarta - Noite (14h-13h)', 'Sala 18A', 41);
INSERT INTO TURMA (IDturma, IDdisciplina, IDprofessor, IDperiodo, Horario, Sala, Vagas) VALUES (30, 62, 35, 35, 'Terça - Manhã (10h-12h)', 'Sala 2C', 32);
INSERT INTO TURMA (IDturma, IDdisciplina, IDprofessor, IDperiodo, Horario, Sala, Vagas) VALUES (31, 62, 17, 53, 'Sábado - Manhã (20h-21h)', 'Sala 4A', 50);
INSERT INTO TURMA (IDturma, IDdisciplina, IDprofessor, IDperiodo, Horario, Sala, Vagas) VALUES (32, 56, 3, 69, 'Sábado - Manhã (10h-7h)', 'Sala 34C', 37);
INSERT INTO TURMA (IDturma, IDdisciplina, IDprofessor, IDperiodo, Horario, Sala, Vagas) VALUES (33, 49, 9, 59, 'Sexta - Manhã (8h-20h)', 'Sala 39B', 44);
INSERT INTO TURMA (IDturma, IDdisciplina, IDprofessor, IDperiodo, Horario, Sala, Vagas) VALUES (34, 71, 53, 97, 'Quinta - Tarde (13h-12h)', 'Sala 33C', 60);
INSERT INTO TURMA (IDturma, IDdisciplina, IDprofessor, IDperiodo, Horario, Sala, Vagas) VALUES (35, 77, 87, 58, 'Terça - Tarde (15h-8h)', 'Sala 25B', 36);
INSERT INTO TURMA (IDturma, IDdisciplina, IDprofessor, IDperiodo, Horario, Sala, Vagas) VALUES (36, 10, 81, 37, 'Quarta - Tarde (11h-8h)', 'Sala 3C', 56);
INSERT INTO TURMA (IDturma, IDdisciplina, IDprofessor, IDperiodo, Horario, Sala, Vagas) VALUES (37, 46, 75, 23, 'Quarta - Manhã (16h-21h)', 'Sala 35B', 50);
INSERT INTO TURMA (IDturma, IDdisciplina, IDprofessor, IDperiodo, Horario, Sala, Vagas) VALUES (38, 42, 27, 8, 'Terça - Noite (13h-13h)', 'Sala 38A', 25);
INSERT INTO TURMA (IDturma, IDdisciplina, IDprofessor, IDperiodo, Horario, Sala, Vagas) VALUES (39, 22, 89, 56, 'Sexta - Noite (7h-14h)', 'Sala 32C', 58);
INSERT INTO TURMA (IDturma, IDdisciplina, IDprofessor, IDperiodo, Horario, Sala, Vagas) VALUES (40, 82, 29, 86, 'Sábado - Manhã (18h-10h)', 'Sala 10A', 22);
INSERT INTO TURMA (IDturma, IDdisciplina, IDprofessor, IDperiodo, Horario, Sala, Vagas) VALUES (41, 46, 52, 52, 'Terça - Manhã (11h-17h)', 'Sala 15B', 27);
INSERT INTO TURMA (IDturma, IDdisciplina, IDprofessor, IDperiodo, Horario, Sala, Vagas) VALUES (42, 20, 85, 71, 'Segunda - Manhã (13h-7h)', 'Sala 32B', 33);
INSERT INTO TURMA (IDturma, IDdisciplina, IDprofessor, IDperiodo, Horario, Sala, Vagas) VALUES (43, 16, 81, 59, 'Quinta - Manhã (11h-19h)', 'Sala 6A', 55);
INSERT INTO TURMA (IDturma, IDdisciplina, IDprofessor, IDperiodo, Horario, Sala, Vagas) VALUES (44, 85, 59, 95, 'Sexta - Noite (16h-14h)', 'Sala 12B', 37);
INSERT INTO TURMA (IDturma, IDdisciplina, IDprofessor, IDperiodo, Horario, Sala, Vagas) VALUES (45, 93, 58, 71, 'Quinta - Noite (12h-14h)', 'Sala 28A', 40);
INSERT INTO TURMA (IDturma, IDdisciplina, IDprofessor, IDperiodo, Horario, Sala, Vagas) VALUES (46, 64, 98, 37, 'Quarta - Tarde (7h-23h)', 'Sala 6A', 34);
INSERT INTO TURMA (IDturma, IDdisciplina, IDprofessor, IDperiodo, Horario, Sala, Vagas) VALUES (47, 45, 71, 33, 'Terça - Noite (12h-12h)', 'Sala 11B', 52);
INSERT INTO TURMA (IDturma, IDdisciplina, IDprofessor, IDperiodo, Horario, Sala, Vagas) VALUES (48, 87, 86, 100, 'Quinta - Tarde (10h-7h)', 'Sala 26B', 56);
INSERT INTO TURMA (IDturma, IDdisciplina, IDprofessor, IDperiodo, Horario, Sala, Vagas) VALUES (49, 53, 81, 51, 'Sexta - Noite (8h-17h)', 'Sala 31A', 26);
INSERT INTO TURMA (IDturma, IDdisciplina, IDprofessor, IDperiodo, Horario, Sala, Vagas) VALUES (50, 43, 3, 8, 'Quarta - Noite (12h-17h)', 'Sala 26C', 44);
INSERT INTO TURMA (IDturma, IDdisciplina, IDprofessor, IDperiodo, Horario, Sala, Vagas) VALUES (51, 46, 47, 99, 'Sexta - Manhã (7h-8h)', 'Sala 4C', 57);
INSERT INTO TURMA (IDturma, IDdisciplina, IDprofessor, IDperiodo, Horario, Sala, Vagas) VALUES (52, 96, 28, 8, 'Segunda - Noite (11h-23h)', 'Sala 22B', 52);
INSERT INTO TURMA (IDturma, IDdisciplina, IDprofessor, IDperiodo, Horario, Sala, Vagas) VALUES (53, 41, 62, 25, 'Terça - Tarde (17h-18h)', 'Sala 16A', 33);
INSERT INTO TURMA (IDturma, IDdisciplina, IDprofessor, IDperiodo, Horario, Sala, Vagas) VALUES (54, 6, 51, 36, 'Sábado - Tarde (12h-9h)', 'Sala 10C', 42);
INSERT INTO TURMA (IDturma, IDdisciplina, IDprofessor, IDperiodo, Horario, Sala, Vagas) VALUES (55, 63, 68, 64, 'Sexta - Manhã (15h-7h)', 'Sala 32B', 30);
INSERT INTO TURMA (IDturma, IDdisciplina, IDprofessor, IDperiodo, Horario, Sala, Vagas) VALUES (56, 60, 33, 57, 'Sábado - Manhã (20h-19h)', 'Sala 15A', 35);
INSERT INTO TURMA (IDturma, IDdisciplina, IDprofessor, IDperiodo, Horario, Sala, Vagas) VALUES (57, 8, 92, 25, 'Segunda - Tarde (21h-13h)', 'Sala 31A', 42);
INSERT INTO TURMA (IDturma, IDdisciplina, IDprofessor, IDperiodo, Horario, Sala, Vagas) VALUES (58, 1, 32, 60, 'Sábado - Noite (10h-23h)', 'Sala 8B', 20);
INSERT INTO TURMA (IDturma, IDdisciplina, IDprofessor, IDperiodo, Horario, Sala, Vagas) VALUES (59, 6, 78, 94, 'Sábado - Noite (19h-20h)', 'Sala 19B', 60);
INSERT INTO TURMA (IDturma, IDdisciplina, IDprofessor, IDperiodo, Horario, Sala, Vagas) VALUES (60, 58, 36, 21, 'Terça - Noite (14h-18h)', 'Sala 26C', 47);
INSERT INTO TURMA (IDturma, IDdisciplina, IDprofessor, IDperiodo, Horario, Sala, Vagas) VALUES (61, 55, 55, 43, 'Quinta - Tarde (19h-15h)', 'Sala 7A', 49);
INSERT INTO TURMA (IDturma, IDdisciplina, IDprofessor, IDperiodo, Horario, Sala, Vagas) VALUES (62, 48, 55, 75, 'Quarta - Manhã (12h-7h)', 'Sala 2A', 38);
INSERT INTO TURMA (IDturma, IDdisciplina, IDprofessor, IDperiodo, Horario, Sala, Vagas) VALUES (63, 45, 83, 23, 'Sábado - Tarde (17h-14h)', 'Sala 26B', 37);
INSERT INTO TURMA (IDturma, IDdisciplina, IDprofessor, IDperiodo, Horario, Sala, Vagas) VALUES (64, 27, 69, 89, 'Sexta - Tarde (20h-17h)', 'Sala 22A', 58);
INSERT INTO TURMA (IDturma, IDdisciplina, IDprofessor, IDperiodo, Horario, Sala, Vagas) VALUES (65, 76, 10, 76, 'Sábado - Tarde (8h-19h)', 'Sala 34B', 60);
INSERT INTO TURMA (IDturma, IDdisciplina, IDprofessor, IDperiodo, Horario, Sala, Vagas) VALUES (66, 89, 66, 89, 'Sexta - Noite (16h-9h)', 'Sala 26B', 30);
INSERT INTO TURMA (IDturma, IDdisciplina, IDprofessor, IDperiodo, Horario, Sala, Vagas) VALUES (67, 3, 11, 15, 'Terça - Manhã (17h-22h)', 'Sala 2C', 59);
INSERT INTO TURMA (IDturma, IDdisciplina, IDprofessor, IDperiodo, Horario, Sala, Vagas) VALUES (68, 49, 21, 83, 'Segunda - Manhã (9h-7h)', 'Sala 23C', 25);
INSERT INTO TURMA (IDturma, IDdisciplina, IDprofessor, IDperiodo, Horario, Sala, Vagas) VALUES (69, 56, 73, 26, 'Quinta - Manhã (19h-9h)', 'Sala 19A', 46);
INSERT INTO TURMA (IDturma, IDdisciplina, IDprofessor, IDperiodo, Horario, Sala, Vagas) VALUES (70, 38, 66, 91, 'Segunda - Tarde (12h-13h)', 'Sala 19A', 52);
INSERT INTO TURMA (IDturma, IDdisciplina, IDprofessor, IDperiodo, Horario, Sala, Vagas) VALUES (71, 23, 55, 38, 'Quinta - Tarde (10h-23h)', 'Sala 39B', 21);
INSERT INTO TURMA (IDturma, IDdisciplina, IDprofessor, IDperiodo, Horario, Sala, Vagas) VALUES (72, 73, 86, 43, 'Quinta - Manhã (9h-10h)', 'Sala 32A', 46);
INSERT INTO TURMA (IDturma, IDdisciplina, IDprofessor, IDperiodo, Horario, Sala, Vagas) VALUES (73, 38, 31, 26, 'Terça - Manhã (17h-9h)', 'Sala 21B', 59);
INSERT INTO TURMA (IDturma, IDdisciplina, IDprofessor, IDperiodo, Horario, Sala, Vagas) VALUES (74, 33, 78, 30, 'Segunda - Noite (14h-20h)', 'Sala 29C', 30);
INSERT INTO TURMA (IDturma, IDdisciplina, IDprofessor, IDperiodo, Horario, Sala, Vagas) VALUES (75, 72, 89, 31, 'Sexta - Manhã (8h-9h)', 'Sala 32A', 30);
INSERT INTO TURMA (IDturma, IDdisciplina, IDprofessor, IDperiodo, Horario, Sala, Vagas) VALUES (76, 92, 59, 43, 'Segunda - Tarde (7h-12h)', 'Sala 17A', 50);
INSERT INTO TURMA (IDturma, IDdisciplina, IDprofessor, IDperiodo, Horario, Sala, Vagas) VALUES (77, 51, 100, 7, 'Sábado - Manhã (7h-15h)', 'Sala 15B', 49);
INSERT INTO TURMA (IDturma, IDdisciplina, IDprofessor, IDperiodo, Horario, Sala, Vagas) VALUES (78, 43, 50, 63, 'Sexta - Tarde (17h-7h)', 'Sala 7A', 43);
INSERT INTO TURMA (IDturma, IDdisciplina, IDprofessor, IDperiodo, Horario, Sala, Vagas) VALUES (79, 61, 12, 4, 'Sábado - Noite (20h-8h)', 'Sala 36C', 38);
INSERT INTO TURMA (IDturma, IDdisciplina, IDprofessor, IDperiodo, Horario, Sala, Vagas) VALUES (80, 67, 49, 43, 'Terça - Tarde (7h-23h)', 'Sala 4A', 23);
INSERT INTO TURMA (IDturma, IDdisciplina, IDprofessor, IDperiodo, Horario, Sala, Vagas) VALUES (81, 49, 81, 82, 'Segunda - Manhã (14h-9h)', 'Sala 33C', 38);
INSERT INTO TURMA (IDturma, IDdisciplina, IDprofessor, IDperiodo, Horario, Sala, Vagas) VALUES (82, 87, 28, 76, 'Sexta - Noite (20h-16h)', 'Sala 21C', 28);
INSERT INTO TURMA (IDturma, IDdisciplina, IDprofessor, IDperiodo, Horario, Sala, Vagas) VALUES (83, 9, 27, 35, 'Segunda - Noite (9h-8h)', 'Sala 11C', 57);
INSERT INTO TURMA (IDturma, IDdisciplina, IDprofessor, IDperiodo, Horario, Sala, Vagas) VALUES (84, 2, 96, 99, 'Segunda - Noite (12h-16h)', 'Sala 23A', 36);
INSERT INTO TURMA (IDturma, IDdisciplina, IDprofessor, IDperiodo, Horario, Sala, Vagas) VALUES (85, 34, 9, 2, 'Segunda - Noite (7h-10h)', 'Sala 14B', 44);
INSERT INTO TURMA (IDturma, IDdisciplina, IDprofessor, IDperiodo, Horario, Sala, Vagas) VALUES (86, 77, 62, 47, 'Sexta - Tarde (14h-18h)', 'Sala 29C', 29);
INSERT INTO TURMA (IDturma, IDdisciplina, IDprofessor, IDperiodo, Horario, Sala, Vagas) VALUES (87, 72, 36, 94, 'Quinta - Tarde (10h-7h)', 'Sala 10C', 49);
INSERT INTO TURMA (IDturma, IDdisciplina, IDprofessor, IDperiodo, Horario, Sala, Vagas) VALUES (88, 85, 20, 27, 'Terça - Tarde (14h-7h)', 'Sala 33C', 28);
INSERT INTO TURMA (IDturma, IDdisciplina, IDprofessor, IDperiodo, Horario, Sala, Vagas) VALUES (89, 29, 83, 57, 'Segunda - Manhã (17h-20h)', 'Sala 18C', 43);
INSERT INTO TURMA (IDturma, IDdisciplina, IDprofessor, IDperiodo, Horario, Sala, Vagas) VALUES (90, 75, 98, 95, 'Quarta - Tarde (9h-20h)', 'Sala 25C', 57);
INSERT INTO TURMA (IDturma, IDdisciplina, IDprofessor, IDperiodo, Horario, Sala, Vagas) VALUES (91, 71, 26, 70, 'Quinta - Noite (17h-10h)', 'Sala 38B', 31);
INSERT INTO TURMA (IDturma, IDdisciplina, IDprofessor, IDperiodo, Horario, Sala, Vagas) VALUES (92, 31, 28, 17, 'Segunda - Manhã (10h-20h)', 'Sala 4B', 53);
INSERT INTO TURMA (IDturma, IDdisciplina, IDprofessor, IDperiodo, Horario, Sala, Vagas) VALUES (93, 68, 40, 35, 'Quinta - Tarde (21h-15h)', 'Sala 29C', 55);
INSERT INTO TURMA (IDturma, IDdisciplina, IDprofessor, IDperiodo, Horario, Sala, Vagas) VALUES (94, 14, 47, 27, 'Terça - Tarde (20h-11h)', 'Sala 8B', 40);
INSERT INTO TURMA (IDturma, IDdisciplina, IDprofessor, IDperiodo, Horario, Sala, Vagas) VALUES (95, 40, 31, 87, 'Terça - Tarde (17h-19h)', 'Sala 28A', 46);
INSERT INTO TURMA (IDturma, IDdisciplina, IDprofessor, IDperiodo, Horario, Sala, Vagas) VALUES (96, 83, 17, 24, 'Sábado - Manhã (12h-7h)', 'Sala 19B', 46);
INSERT INTO TURMA (IDturma, IDdisciplina, IDprofessor, IDperiodo, Horario, Sala, Vagas) VALUES (97, 14, 80, 52, 'Quinta - Manhã (16h-23h)', 'Sala 20A', 50);
INSERT INTO TURMA (IDturma, IDdisciplina, IDprofessor, IDperiodo, Horario, Sala, Vagas) VALUES (98, 33, 46, 2, 'Terça - Manhã (15h-9h)', 'Sala 30C', 35);
INSERT INTO TURMA (IDturma, IDdisciplina, IDprofessor, IDperiodo, Horario, Sala, Vagas) VALUES (99, 33, 76, 39, 'Segunda - Tarde (15h-13h)', 'Sala 36A', 52);
INSERT INTO TURMA (IDturma, IDdisciplina, IDprofessor, IDperiodo, Horario, Sala, Vagas) VALUES (100, 62, 27, 13, 'Quarta - Noite (17h-7h)', 'Sala 36A', 31);
 
-- ---------------- MATRICULA ----------------
INSERT INTO MATRICULA (IDmatricula, IDaluno, IDturma, Data_Matricula, Estado) VALUES (1, 26, 89, '2025-09-28', 'Cursando');
INSERT INTO MATRICULA (IDmatricula, IDaluno, IDturma, Data_Matricula, Estado) VALUES (2, 50, 19, '2022-04-14', 'Aprovado');
INSERT INTO MATRICULA (IDmatricula, IDaluno, IDturma, Data_Matricula, Estado) VALUES (3, 96, 62, '2025-04-20', 'Reprovado');
INSERT INTO MATRICULA (IDmatricula, IDaluno, IDturma, Data_Matricula, Estado) VALUES (4, 23, 72, '2025-08-26', 'Trancado');
INSERT INTO MATRICULA (IDmatricula, IDaluno, IDturma, Data_Matricula, Estado) VALUES (5, 9, 5, '2023-03-08', 'Cursando');
INSERT INTO MATRICULA (IDmatricula, IDaluno, IDturma, Data_Matricula, Estado) VALUES (6, 48, 50, '2022-09-10', 'Cursando');
INSERT INTO MATRICULA (IDmatricula, IDaluno, IDturma, Data_Matricula, Estado) VALUES (7, 20, 90, '2023-08-03', 'Cursando');
INSERT INTO MATRICULA (IDmatricula, IDaluno, IDturma, Data_Matricula, Estado) VALUES (8, 62, 12, '2022-08-08', 'Cursando');
INSERT INTO MATRICULA (IDmatricula, IDaluno, IDturma, Data_Matricula, Estado) VALUES (9, 9, 94, '2022-10-14', 'Aprovado');
INSERT INTO MATRICULA (IDmatricula, IDaluno, IDturma, Data_Matricula, Estado) VALUES (10, 42, 43, '2023-12-05', 'Cursando');
INSERT INTO MATRICULA (IDmatricula, IDaluno, IDturma, Data_Matricula, Estado) VALUES (11, 20, 48, '2022-04-15', 'Trancado');
INSERT INTO MATRICULA (IDmatricula, IDaluno, IDturma, Data_Matricula, Estado) VALUES (12, 11, 68, '2024-01-19', 'Cursando');
INSERT INTO MATRICULA (IDmatricula, IDaluno, IDturma, Data_Matricula, Estado) VALUES (13, 52, 50, '2023-11-26', 'Aprovado');
INSERT INTO MATRICULA (IDmatricula, IDaluno, IDturma, Data_Matricula, Estado) VALUES (14, 37, 63, '2023-11-09', 'Desistente');
INSERT INTO MATRICULA (IDmatricula, IDaluno, IDturma, Data_Matricula, Estado) VALUES (15, 99, 50, '2022-09-12', 'Cursando');
INSERT INTO MATRICULA (IDmatricula, IDaluno, IDturma, Data_Matricula, Estado) VALUES (16, 44, 92, '2022-03-22', 'Desistente');
INSERT INTO MATRICULA (IDmatricula, IDaluno, IDturma, Data_Matricula, Estado) VALUES (17, 63, 32, '2025-02-19', 'Aprovado');
INSERT INTO MATRICULA (IDmatricula, IDaluno, IDturma, Data_Matricula, Estado) VALUES (18, 94, 61, '2024-12-25', 'Aprovado');
INSERT INTO MATRICULA (IDmatricula, IDaluno, IDturma, Data_Matricula, Estado) VALUES (19, 18, 70, '2023-07-11', 'Aprovado');
INSERT INTO MATRICULA (IDmatricula, IDaluno, IDturma, Data_Matricula, Estado) VALUES (20, 82, 30, '2024-11-02', 'Cursando');
INSERT INTO MATRICULA (IDmatricula, IDaluno, IDturma, Data_Matricula, Estado) VALUES (21, 92, 64, '2022-04-10', 'Aprovado');
INSERT INTO MATRICULA (IDmatricula, IDaluno, IDturma, Data_Matricula, Estado) VALUES (22, 75, 8, '2025-03-28', 'Cursando');
INSERT INTO MATRICULA (IDmatricula, IDaluno, IDturma, Data_Matricula, Estado) VALUES (23, 100, 28, '2023-11-24', 'Cursando');
INSERT INTO MATRICULA (IDmatricula, IDaluno, IDturma, Data_Matricula, Estado) VALUES (24, 82, 87, '2023-09-14', 'Reprovado');
INSERT INTO MATRICULA (IDmatricula, IDaluno, IDturma, Data_Matricula, Estado) VALUES (25, 71, 33, '2025-02-16', 'Reprovado');
INSERT INTO MATRICULA (IDmatricula, IDaluno, IDturma, Data_Matricula, Estado) VALUES (26, 4, 69, '2022-05-11', 'Cursando');
INSERT INTO MATRICULA (IDmatricula, IDaluno, IDturma, Data_Matricula, Estado) VALUES (27, 38, 29, '2024-03-21', 'Aprovado');
INSERT INTO MATRICULA (IDmatricula, IDaluno, IDturma, Data_Matricula, Estado) VALUES (28, 16, 78, '2024-01-23', 'Trancado');
INSERT INTO MATRICULA (IDmatricula, IDaluno, IDturma, Data_Matricula, Estado) VALUES (29, 32, 65, '2024-11-29', 'Aprovado');
INSERT INTO MATRICULA (IDmatricula, IDaluno, IDturma, Data_Matricula, Estado) VALUES (30, 97, 86, '2024-12-30', 'Cursando');
INSERT INTO MATRICULA (IDmatricula, IDaluno, IDturma, Data_Matricula, Estado) VALUES (31, 14, 9, '2022-10-09', 'Desistente');
INSERT INTO MATRICULA (IDmatricula, IDaluno, IDturma, Data_Matricula, Estado) VALUES (32, 43, 54, '2024-07-09', 'Cursando');
INSERT INTO MATRICULA (IDmatricula, IDaluno, IDturma, Data_Matricula, Estado) VALUES (33, 28, 17, '2024-10-09', 'Cursando');
INSERT INTO MATRICULA (IDmatricula, IDaluno, IDturma, Data_Matricula, Estado) VALUES (34, 72, 52, '2025-02-03', 'Trancado');
INSERT INTO MATRICULA (IDmatricula, IDaluno, IDturma, Data_Matricula, Estado) VALUES (35, 44, 64, '2022-04-26', 'Cursando');
INSERT INTO MATRICULA (IDmatricula, IDaluno, IDturma, Data_Matricula, Estado) VALUES (36, 32, 45, '2025-02-07', 'Aprovado');
INSERT INTO MATRICULA (IDmatricula, IDaluno, IDturma, Data_Matricula, Estado) VALUES (37, 22, 71, '2023-08-13', 'Trancado');
INSERT INTO MATRICULA (IDmatricula, IDaluno, IDturma, Data_Matricula, Estado) VALUES (38, 93, 8, '2023-06-26', 'Trancado');
INSERT INTO MATRICULA (IDmatricula, IDaluno, IDturma, Data_Matricula, Estado) VALUES (39, 46, 58, '2024-09-01', 'Aprovado');
INSERT INTO MATRICULA (IDmatricula, IDaluno, IDturma, Data_Matricula, Estado) VALUES (40, 56, 84, '2025-04-10', 'Cursando');
INSERT INTO MATRICULA (IDmatricula, IDaluno, IDturma, Data_Matricula, Estado) VALUES (41, 46, 77, '2023-11-15', 'Cursando');
INSERT INTO MATRICULA (IDmatricula, IDaluno, IDturma, Data_Matricula, Estado) VALUES (42, 74, 30, '2025-07-29', 'Cursando');
INSERT INTO MATRICULA (IDmatricula, IDaluno, IDturma, Data_Matricula, Estado) VALUES (43, 72, 48, '2024-07-01', 'Reprovado');
INSERT INTO MATRICULA (IDmatricula, IDaluno, IDturma, Data_Matricula, Estado) VALUES (44, 81, 68, '2023-12-17', 'Cursando');
INSERT INTO MATRICULA (IDmatricula, IDaluno, IDturma, Data_Matricula, Estado) VALUES (45, 56, 21, '2022-07-10', 'Aprovado');
INSERT INTO MATRICULA (IDmatricula, IDaluno, IDturma, Data_Matricula, Estado) VALUES (46, 80, 49, '2022-02-15', 'Cursando');
INSERT INTO MATRICULA (IDmatricula, IDaluno, IDturma, Data_Matricula, Estado) VALUES (47, 54, 70, '2025-06-19', 'Aprovado');
INSERT INTO MATRICULA (IDmatricula, IDaluno, IDturma, Data_Matricula, Estado) VALUES (48, 61, 89, '2024-07-13', 'Reprovado');
INSERT INTO MATRICULA (IDmatricula, IDaluno, IDturma, Data_Matricula, Estado) VALUES (49, 53, 27, '2022-08-19', 'Cursando');
INSERT INTO MATRICULA (IDmatricula, IDaluno, IDturma, Data_Matricula, Estado) VALUES (50, 69, 83, '2023-07-01', 'Desistente');
INSERT INTO MATRICULA (IDmatricula, IDaluno, IDturma, Data_Matricula, Estado) VALUES (51, 4, 20, '2025-03-26', 'Reprovado');
INSERT INTO MATRICULA (IDmatricula, IDaluno, IDturma, Data_Matricula, Estado) VALUES (52, 14, 6, '2025-10-22', 'Cursando');
INSERT INTO MATRICULA (IDmatricula, IDaluno, IDturma, Data_Matricula, Estado) VALUES (53, 50, 81, '2025-01-13', 'Aprovado');
INSERT INTO MATRICULA (IDmatricula, IDaluno, IDturma, Data_Matricula, Estado) VALUES (54, 8, 58, '2023-03-19', 'Cursando');
INSERT INTO MATRICULA (IDmatricula, IDaluno, IDturma, Data_Matricula, Estado) VALUES (55, 99, 91, '2024-12-02', 'Cursando');
INSERT INTO MATRICULA (IDmatricula, IDaluno, IDturma, Data_Matricula, Estado) VALUES (56, 16, 15, '2024-02-07', 'Aprovado');
INSERT INTO MATRICULA (IDmatricula, IDaluno, IDturma, Data_Matricula, Estado) VALUES (57, 94, 81, '2023-08-16', 'Desistente');
INSERT INTO MATRICULA (IDmatricula, IDaluno, IDturma, Data_Matricula, Estado) VALUES (58, 79, 36, '2022-03-20', 'Cursando');
INSERT INTO MATRICULA (IDmatricula, IDaluno, IDturma, Data_Matricula, Estado) VALUES (59, 93, 1, '2022-03-22', 'Aprovado');
INSERT INTO MATRICULA (IDmatricula, IDaluno, IDturma, Data_Matricula, Estado) VALUES (60, 24, 22, '2023-08-09', 'Aprovado');
INSERT INTO MATRICULA (IDmatricula, IDaluno, IDturma, Data_Matricula, Estado) VALUES (61, 96, 83, '2025-03-10', 'Cursando');
INSERT INTO MATRICULA (IDmatricula, IDaluno, IDturma, Data_Matricula, Estado) VALUES (62, 41, 53, '2025-01-12', 'Cursando');
INSERT INTO MATRICULA (IDmatricula, IDaluno, IDturma, Data_Matricula, Estado) VALUES (63, 71, 56, '2022-07-08', 'Trancado');
INSERT INTO MATRICULA (IDmatricula, IDaluno, IDturma, Data_Matricula, Estado) VALUES (64, 97, 90, '2023-05-22', 'Aprovado');
INSERT INTO MATRICULA (IDmatricula, IDaluno, IDturma, Data_Matricula, Estado) VALUES (65, 27, 64, '2023-04-01', 'Aprovado');
INSERT INTO MATRICULA (IDmatricula, IDaluno, IDturma, Data_Matricula, Estado) VALUES (66, 46, 54, '2025-01-27', 'Aprovado');
INSERT INTO MATRICULA (IDmatricula, IDaluno, IDturma, Data_Matricula, Estado) VALUES (67, 87, 29, '2025-04-04', 'Cursando');
INSERT INTO MATRICULA (IDmatricula, IDaluno, IDturma, Data_Matricula, Estado) VALUES (68, 99, 29, '2022-07-02', 'Aprovado');
INSERT INTO MATRICULA (IDmatricula, IDaluno, IDturma, Data_Matricula, Estado) VALUES (69, 35, 12, '2022-04-07', 'Aprovado');
INSERT INTO MATRICULA (IDmatricula, IDaluno, IDturma, Data_Matricula, Estado) VALUES (70, 83, 46, '2023-09-20', 'Cursando');
INSERT INTO MATRICULA (IDmatricula, IDaluno, IDturma, Data_Matricula, Estado) VALUES (71, 86, 20, '2023-01-15', 'Trancado');
INSERT INTO MATRICULA (IDmatricula, IDaluno, IDturma, Data_Matricula, Estado) VALUES (72, 34, 37, '2022-07-13', 'Aprovado');
INSERT INTO MATRICULA (IDmatricula, IDaluno, IDturma, Data_Matricula, Estado) VALUES (73, 3, 11, '2025-09-29', 'Cursando');
INSERT INTO MATRICULA (IDmatricula, IDaluno, IDturma, Data_Matricula, Estado) VALUES (74, 77, 8, '2023-11-07', 'Desistente');
INSERT INTO MATRICULA (IDmatricula, IDaluno, IDturma, Data_Matricula, Estado) VALUES (75, 18, 51, '2022-03-07', 'Desistente');
INSERT INTO MATRICULA (IDmatricula, IDaluno, IDturma, Data_Matricula, Estado) VALUES (76, 38, 63, '2025-02-26', 'Cursando');
INSERT INTO MATRICULA (IDmatricula, IDaluno, IDturma, Data_Matricula, Estado) VALUES (77, 31, 7, '2022-12-03', 'Desistente');
INSERT INTO MATRICULA (IDmatricula, IDaluno, IDturma, Data_Matricula, Estado) VALUES (78, 83, 42, '2023-02-25', 'Desistente');
INSERT INTO MATRICULA (IDmatricula, IDaluno, IDturma, Data_Matricula, Estado) VALUES (79, 73, 14, '2025-02-22', 'Cursando');
INSERT INTO MATRICULA (IDmatricula, IDaluno, IDturma, Data_Matricula, Estado) VALUES (80, 12, 41, '2025-06-23', 'Cursando');
INSERT INTO MATRICULA (IDmatricula, IDaluno, IDturma, Data_Matricula, Estado) VALUES (81, 78, 93, '2025-10-16', 'Aprovado');
INSERT INTO MATRICULA (IDmatricula, IDaluno, IDturma, Data_Matricula, Estado) VALUES (82, 44, 83, '2023-09-13', 'Aprovado');
INSERT INTO MATRICULA (IDmatricula, IDaluno, IDturma, Data_Matricula, Estado) VALUES (83, 80, 76, '2025-04-18', 'Cursando');
INSERT INTO MATRICULA (IDmatricula, IDaluno, IDturma, Data_Matricula, Estado) VALUES (84, 39, 66, '2023-11-03', 'Trancado');
INSERT INTO MATRICULA (IDmatricula, IDaluno, IDturma, Data_Matricula, Estado) VALUES (85, 90, 46, '2024-05-05', 'Cursando');
INSERT INTO MATRICULA (IDmatricula, IDaluno, IDturma, Data_Matricula, Estado) VALUES (86, 72, 6, '2025-05-02', 'Cursando');
INSERT INTO MATRICULA (IDmatricula, IDaluno, IDturma, Data_Matricula, Estado) VALUES (87, 53, 38, '2025-03-11', 'Trancado');
INSERT INTO MATRICULA (IDmatricula, IDaluno, IDturma, Data_Matricula, Estado) VALUES (88, 97, 10, '2023-03-07', 'Aprovado');
INSERT INTO MATRICULA (IDmatricula, IDaluno, IDturma, Data_Matricula, Estado) VALUES (89, 50, 59, '2024-08-16', 'Cursando');
INSERT INTO MATRICULA (IDmatricula, IDaluno, IDturma, Data_Matricula, Estado) VALUES (90, 77, 69, '2023-05-12', 'Aprovado');
INSERT INTO MATRICULA (IDmatricula, IDaluno, IDturma, Data_Matricula, Estado) VALUES (91, 98, 94, '2023-10-09', 'Cursando');
INSERT INTO MATRICULA (IDmatricula, IDaluno, IDturma, Data_Matricula, Estado) VALUES (92, 41, 41, '2022-07-07', 'Aprovado');
INSERT INTO MATRICULA (IDmatricula, IDaluno, IDturma, Data_Matricula, Estado) VALUES (93, 25, 37, '2024-01-19', 'Trancado');
INSERT INTO MATRICULA (IDmatricula, IDaluno, IDturma, Data_Matricula, Estado) VALUES (94, 60, 10, '2025-03-22', 'Trancado');
INSERT INTO MATRICULA (IDmatricula, IDaluno, IDturma, Data_Matricula, Estado) VALUES (95, 35, 18, '2022-12-19', 'Cursando');
INSERT INTO MATRICULA (IDmatricula, IDaluno, IDturma, Data_Matricula, Estado) VALUES (96, 37, 27, '2024-09-15', 'Cursando');
INSERT INTO MATRICULA (IDmatricula, IDaluno, IDturma, Data_Matricula, Estado) VALUES (97, 27, 94, '2025-03-08', 'Aprovado');
INSERT INTO MATRICULA (IDmatricula, IDaluno, IDturma, Data_Matricula, Estado) VALUES (98, 40, 31, '2025-07-11', 'Aprovado');
INSERT INTO MATRICULA (IDmatricula, IDaluno, IDturma, Data_Matricula, Estado) VALUES (99, 6, 57, '2022-11-13', 'Reprovado');
INSERT INTO MATRICULA (IDmatricula, IDaluno, IDturma, Data_Matricula, Estado) VALUES (100, 10, 83, '2024-02-16', 'Desistente');
 
-- ---------------- FREQUENCIA ----------------
INSERT INTO FREQUENCIA (IDfrequencia, IDmatricula, Data_Aula, Presente, Justificacao) VALUES (1, 24, '2024-03-31', 1, NULL);
INSERT INTO FREQUENCIA (IDfrequencia, IDmatricula, Data_Aula, Presente, Justificacao) VALUES (2, 88, '2023-02-09', 1, NULL);
INSERT INTO FREQUENCIA (IDfrequencia, IDmatricula, Data_Aula, Presente, Justificacao) VALUES (3, 63, '2025-08-07', 1, NULL);
INSERT INTO FREQUENCIA (IDfrequencia, IDmatricula, Data_Aula, Presente, Justificacao) VALUES (4, 3, '2023-06-24', 0, 'Motivo pessoal');
INSERT INTO FREQUENCIA (IDfrequencia, IDmatricula, Data_Aula, Presente, Justificacao) VALUES (5, 86, '2023-09-21', 0, 'Problema de transporte');
INSERT INTO FREQUENCIA (IDfrequencia, IDmatricula, Data_Aula, Presente, Justificacao) VALUES (6, 64, '2022-12-03', 1, NULL);
INSERT INTO FREQUENCIA (IDfrequencia, IDmatricula, Data_Aula, Presente, Justificacao) VALUES (7, 12, '2023-12-21', 1, NULL);
INSERT INTO FREQUENCIA (IDfrequencia, IDmatricula, Data_Aula, Presente, Justificacao) VALUES (8, 40, '2023-05-18', 1, NULL);
INSERT INTO FREQUENCIA (IDfrequencia, IDmatricula, Data_Aula, Presente, Justificacao) VALUES (9, 74, '2023-12-24', 1, NULL);
INSERT INTO FREQUENCIA (IDfrequencia, IDmatricula, Data_Aula, Presente, Justificacao) VALUES (10, 42, '2022-09-11', 1, NULL);
INSERT INTO FREQUENCIA (IDfrequencia, IDmatricula, Data_Aula, Presente, Justificacao) VALUES (11, 27, '2023-01-09', 1, NULL);
INSERT INTO FREQUENCIA (IDfrequencia, IDmatricula, Data_Aula, Presente, Justificacao) VALUES (12, 25, '2024-10-13', 1, NULL);
INSERT INTO FREQUENCIA (IDfrequencia, IDmatricula, Data_Aula, Presente, Justificacao) VALUES (13, 41, '2022-11-30', 1, NULL);
INSERT INTO FREQUENCIA (IDfrequencia, IDmatricula, Data_Aula, Presente, Justificacao) VALUES (14, 82, '2024-04-21', 1, NULL);
INSERT INTO FREQUENCIA (IDfrequencia, IDmatricula, Data_Aula, Presente, Justificacao) VALUES (15, 59, '2024-03-01', 1, NULL);
INSERT INTO FREQUENCIA (IDfrequencia, IDmatricula, Data_Aula, Presente, Justificacao) VALUES (16, 37, '2024-02-29', 1, NULL);
INSERT INTO FREQUENCIA (IDfrequencia, IDmatricula, Data_Aula, Presente, Justificacao) VALUES (17, 64, '2025-10-15', 1, NULL);
INSERT INTO FREQUENCIA (IDfrequencia, IDmatricula, Data_Aula, Presente, Justificacao) VALUES (18, 42, '2025-09-03', 0, NULL);
INSERT INTO FREQUENCIA (IDfrequencia, IDmatricula, Data_Aula, Presente, Justificacao) VALUES (19, 55, '2023-09-17', 1, NULL);
INSERT INTO FREQUENCIA (IDfrequencia, IDmatricula, Data_Aula, Presente, Justificacao) VALUES (20, 78, '2022-11-02', 1, NULL);
INSERT INTO FREQUENCIA (IDfrequencia, IDmatricula, Data_Aula, Presente, Justificacao) VALUES (21, 99, '2022-10-26', 0, 'Falta não justificada');
INSERT INTO FREQUENCIA (IDfrequencia, IDmatricula, Data_Aula, Presente, Justificacao) VALUES (22, 82, '2023-05-09', 1, NULL);
INSERT INTO FREQUENCIA (IDfrequencia, IDmatricula, Data_Aula, Presente, Justificacao) VALUES (23, 58, '2024-04-17', 0, 'Motivo pessoal');
INSERT INTO FREQUENCIA (IDfrequencia, IDmatricula, Data_Aula, Presente, Justificacao) VALUES (24, 95, '2022-04-23', 1, NULL);
INSERT INTO FREQUENCIA (IDfrequencia, IDmatricula, Data_Aula, Presente, Justificacao) VALUES (25, 80, '2022-07-19', 1, NULL);
INSERT INTO FREQUENCIA (IDfrequencia, IDmatricula, Data_Aula, Presente, Justificacao) VALUES (26, 51, '2023-07-07', 1, NULL);
INSERT INTO FREQUENCIA (IDfrequencia, IDmatricula, Data_Aula, Presente, Justificacao) VALUES (27, 30, '2025-04-28', 1, NULL);
INSERT INTO FREQUENCIA (IDfrequencia, IDmatricula, Data_Aula, Presente, Justificacao) VALUES (28, 67, '2022-05-18', 1, NULL);
INSERT INTO FREQUENCIA (IDfrequencia, IDmatricula, Data_Aula, Presente, Justificacao) VALUES (29, 44, '2024-03-23', 1, NULL);
INSERT INTO FREQUENCIA (IDfrequencia, IDmatricula, Data_Aula, Presente, Justificacao) VALUES (30, 7, '2024-12-20', 1, NULL);
INSERT INTO FREQUENCIA (IDfrequencia, IDmatricula, Data_Aula, Presente, Justificacao) VALUES (31, 96, '2022-07-10', 1, NULL);
INSERT INTO FREQUENCIA (IDfrequencia, IDmatricula, Data_Aula, Presente, Justificacao) VALUES (32, 2, '2022-04-07', 0, 'Atestado médico');
INSERT INTO FREQUENCIA (IDfrequencia, IDmatricula, Data_Aula, Presente, Justificacao) VALUES (33, 48, '2023-02-10', 0, NULL);
INSERT INTO FREQUENCIA (IDfrequencia, IDmatricula, Data_Aula, Presente, Justificacao) VALUES (34, 18, '2023-03-25', 1, NULL);
INSERT INTO FREQUENCIA (IDfrequencia, IDmatricula, Data_Aula, Presente, Justificacao) VALUES (35, 15, '2024-02-09', 0, NULL);
INSERT INTO FREQUENCIA (IDfrequencia, IDmatricula, Data_Aula, Presente, Justificacao) VALUES (36, 62, '2025-04-20', 1, NULL);
INSERT INTO FREQUENCIA (IDfrequencia, IDmatricula, Data_Aula, Presente, Justificacao) VALUES (37, 80, '2022-05-09', 1, NULL);
INSERT INTO FREQUENCIA (IDfrequencia, IDmatricula, Data_Aula, Presente, Justificacao) VALUES (38, 17, '2024-06-27', 0, 'Atestado médico');
INSERT INTO FREQUENCIA (IDfrequencia, IDmatricula, Data_Aula, Presente, Justificacao) VALUES (39, 23, '2023-05-23', 0, 'Motivo pessoal');
INSERT INTO FREQUENCIA (IDfrequencia, IDmatricula, Data_Aula, Presente, Justificacao) VALUES (40, 43, '2024-05-14', 1, NULL);
INSERT INTO FREQUENCIA (IDfrequencia, IDmatricula, Data_Aula, Presente, Justificacao) VALUES (41, 42, '2022-11-16', 1, NULL);
INSERT INTO FREQUENCIA (IDfrequencia, IDmatricula, Data_Aula, Presente, Justificacao) VALUES (42, 91, '2023-08-20', 1, NULL);
INSERT INTO FREQUENCIA (IDfrequencia, IDmatricula, Data_Aula, Presente, Justificacao) VALUES (43, 71, '2024-02-07', 1, NULL);
INSERT INTO FREQUENCIA (IDfrequencia, IDmatricula, Data_Aula, Presente, Justificacao) VALUES (44, 14, '2025-01-12', 1, NULL);
INSERT INTO FREQUENCIA (IDfrequencia, IDmatricula, Data_Aula, Presente, Justificacao) VALUES (45, 53, '2024-05-03', 0, 'Motivo pessoal');
INSERT INTO FREQUENCIA (IDfrequencia, IDmatricula, Data_Aula, Presente, Justificacao) VALUES (46, 3, '2022-01-18', 1, NULL);
INSERT INTO FREQUENCIA (IDfrequencia, IDmatricula, Data_Aula, Presente, Justificacao) VALUES (47, 70, '2022-10-09', 0, 'Falta não justificada');
INSERT INTO FREQUENCIA (IDfrequencia, IDmatricula, Data_Aula, Presente, Justificacao) VALUES (48, 82, '2023-12-14', 1, NULL);
INSERT INTO FREQUENCIA (IDfrequencia, IDmatricula, Data_Aula, Presente, Justificacao) VALUES (49, 84, '2024-09-28', 1, NULL);
INSERT INTO FREQUENCIA (IDfrequencia, IDmatricula, Data_Aula, Presente, Justificacao) VALUES (50, 69, '2025-01-28', 1, NULL);
INSERT INTO FREQUENCIA (IDfrequencia, IDmatricula, Data_Aula, Presente, Justificacao) VALUES (51, 59, '2023-05-22', 1, NULL);
INSERT INTO FREQUENCIA (IDfrequencia, IDmatricula, Data_Aula, Presente, Justificacao) VALUES (52, 5, '2025-01-20', 1, NULL);
INSERT INTO FREQUENCIA (IDfrequencia, IDmatricula, Data_Aula, Presente, Justificacao) VALUES (53, 26, '2024-11-11', 1, NULL);
INSERT INTO FREQUENCIA (IDfrequencia, IDmatricula, Data_Aula, Presente, Justificacao) VALUES (54, 99, '2025-09-08', 1, NULL);
INSERT INTO FREQUENCIA (IDfrequencia, IDmatricula, Data_Aula, Presente, Justificacao) VALUES (55, 3, '2024-09-19', 1, NULL);
INSERT INTO FREQUENCIA (IDfrequencia, IDmatricula, Data_Aula, Presente, Justificacao) VALUES (56, 23, '2022-07-27', 1, NULL);
INSERT INTO FREQUENCIA (IDfrequencia, IDmatricula, Data_Aula, Presente, Justificacao) VALUES (57, 41, '2023-12-26', 1, NULL);
INSERT INTO FREQUENCIA (IDfrequencia, IDmatricula, Data_Aula, Presente, Justificacao) VALUES (58, 60, '2024-07-30', 1, NULL);
INSERT INTO FREQUENCIA (IDfrequencia, IDmatricula, Data_Aula, Presente, Justificacao) VALUES (59, 67, '2025-04-09', 1, NULL);
INSERT INTO FREQUENCIA (IDfrequencia, IDmatricula, Data_Aula, Presente, Justificacao) VALUES (60, 51, '2024-05-26', 1, NULL);
INSERT INTO FREQUENCIA (IDfrequencia, IDmatricula, Data_Aula, Presente, Justificacao) VALUES (61, 51, '2024-04-16', 1, NULL);
INSERT INTO FREQUENCIA (IDfrequencia, IDmatricula, Data_Aula, Presente, Justificacao) VALUES (62, 3, '2025-10-03', 1, NULL);
INSERT INTO FREQUENCIA (IDfrequencia, IDmatricula, Data_Aula, Presente, Justificacao) VALUES (63, 69, '2024-01-12', 1, NULL);
INSERT INTO FREQUENCIA (IDfrequencia, IDmatricula, Data_Aula, Presente, Justificacao) VALUES (64, 65, '2025-06-07', 0, 'Problema de transporte');
INSERT INTO FREQUENCIA (IDfrequencia, IDmatricula, Data_Aula, Presente, Justificacao) VALUES (65, 69, '2023-07-15', 1, NULL);
INSERT INTO FREQUENCIA (IDfrequencia, IDmatricula, Data_Aula, Presente, Justificacao) VALUES (66, 67, '2025-08-20', 1, NULL);
INSERT INTO FREQUENCIA (IDfrequencia, IDmatricula, Data_Aula, Presente, Justificacao) VALUES (67, 91, '2024-06-25', 1, NULL);
INSERT INTO FREQUENCIA (IDfrequencia, IDmatricula, Data_Aula, Presente, Justificacao) VALUES (68, 34, '2023-09-11', 1, NULL);
INSERT INTO FREQUENCIA (IDfrequencia, IDmatricula, Data_Aula, Presente, Justificacao) VALUES (69, 83, '2022-01-10', 1, NULL);
INSERT INTO FREQUENCIA (IDfrequencia, IDmatricula, Data_Aula, Presente, Justificacao) VALUES (70, 18, '2025-02-19', 1, NULL);
INSERT INTO FREQUENCIA (IDfrequencia, IDmatricula, Data_Aula, Presente, Justificacao) VALUES (71, 71, '2024-08-10', 1, NULL);
INSERT INTO FREQUENCIA (IDfrequencia, IDmatricula, Data_Aula, Presente, Justificacao) VALUES (72, 30, '2023-05-05', 1, NULL);
INSERT INTO FREQUENCIA (IDfrequencia, IDmatricula, Data_Aula, Presente, Justificacao) VALUES (73, 2, '2022-01-12', 0, 'Problema de transporte');
INSERT INTO FREQUENCIA (IDfrequencia, IDmatricula, Data_Aula, Presente, Justificacao) VALUES (74, 1, '2025-07-13', 1, NULL);
INSERT INTO FREQUENCIA (IDfrequencia, IDmatricula, Data_Aula, Presente, Justificacao) VALUES (75, 97, '2024-12-30', 1, NULL);
INSERT INTO FREQUENCIA (IDfrequencia, IDmatricula, Data_Aula, Presente, Justificacao) VALUES (76, 42, '2022-08-12', 1, NULL);
INSERT INTO FREQUENCIA (IDfrequencia, IDmatricula, Data_Aula, Presente, Justificacao) VALUES (77, 86, '2025-05-16', 0, NULL);
INSERT INTO FREQUENCIA (IDfrequencia, IDmatricula, Data_Aula, Presente, Justificacao) VALUES (78, 61, '2024-10-21', 1, NULL);
INSERT INTO FREQUENCIA (IDfrequencia, IDmatricula, Data_Aula, Presente, Justificacao) VALUES (79, 48, '2023-05-07', 1, NULL);
INSERT INTO FREQUENCIA (IDfrequencia, IDmatricula, Data_Aula, Presente, Justificacao) VALUES (80, 8, '2024-11-07', 0, NULL);
INSERT INTO FREQUENCIA (IDfrequencia, IDmatricula, Data_Aula, Presente, Justificacao) VALUES (81, 66, '2024-06-07', 0, 'Motivo pessoal');
INSERT INTO FREQUENCIA (IDfrequencia, IDmatricula, Data_Aula, Presente, Justificacao) VALUES (82, 47, '2025-09-17', 0, NULL);
INSERT INTO FREQUENCIA (IDfrequencia, IDmatricula, Data_Aula, Presente, Justificacao) VALUES (83, 98, '2025-01-21', 0, NULL);
INSERT INTO FREQUENCIA (IDfrequencia, IDmatricula, Data_Aula, Presente, Justificacao) VALUES (84, 31, '2023-07-23', 1, NULL);
INSERT INTO FREQUENCIA (IDfrequencia, IDmatricula, Data_Aula, Presente, Justificacao) VALUES (85, 7, '2023-02-05', 0, 'Motivo pessoal');
INSERT INTO FREQUENCIA (IDfrequencia, IDmatricula, Data_Aula, Presente, Justificacao) VALUES (86, 16, '2024-11-03', 1, NULL);
INSERT INTO FREQUENCIA (IDfrequencia, IDmatricula, Data_Aula, Presente, Justificacao) VALUES (87, 100, '2022-03-06', 0, 'Problema de transporte');
INSERT INTO FREQUENCIA (IDfrequencia, IDmatricula, Data_Aula, Presente, Justificacao) VALUES (88, 8, '2023-01-30', 0, 'Motivo pessoal');
INSERT INTO FREQUENCIA (IDfrequencia, IDmatricula, Data_Aula, Presente, Justificacao) VALUES (89, 69, '2022-04-22', 1, NULL);
INSERT INTO FREQUENCIA (IDfrequencia, IDmatricula, Data_Aula, Presente, Justificacao) VALUES (90, 79, '2022-03-17', 1, NULL);
INSERT INTO FREQUENCIA (IDfrequencia, IDmatricula, Data_Aula, Presente, Justificacao) VALUES (91, 91, '2024-07-11', 1, NULL);
INSERT INTO FREQUENCIA (IDfrequencia, IDmatricula, Data_Aula, Presente, Justificacao) VALUES (92, 25, '2022-03-19', 1, NULL);
INSERT INTO FREQUENCIA (IDfrequencia, IDmatricula, Data_Aula, Presente, Justificacao) VALUES (93, 89, '2022-01-07', 1, NULL);
INSERT INTO FREQUENCIA (IDfrequencia, IDmatricula, Data_Aula, Presente, Justificacao) VALUES (94, 87, '2023-05-15', 0, NULL);
INSERT INTO FREQUENCIA (IDfrequencia, IDmatricula, Data_Aula, Presente, Justificacao) VALUES (95, 35, '2025-06-29', 0, NULL);
INSERT INTO FREQUENCIA (IDfrequencia, IDmatricula, Data_Aula, Presente, Justificacao) VALUES (96, 52, '2024-10-19', 1, NULL);
INSERT INTO FREQUENCIA (IDfrequencia, IDmatricula, Data_Aula, Presente, Justificacao) VALUES (97, 44, '2025-04-06', 1, NULL);
INSERT INTO FREQUENCIA (IDfrequencia, IDmatricula, Data_Aula, Presente, Justificacao) VALUES (98, 72, '2025-01-16', 1, NULL);
INSERT INTO FREQUENCIA (IDfrequencia, IDmatricula, Data_Aula, Presente, Justificacao) VALUES (99, 6, '2025-01-06', 1, NULL);
INSERT INTO FREQUENCIA (IDfrequencia, IDmatricula, Data_Aula, Presente, Justificacao) VALUES (100, 46, '2024-12-16', 1, NULL);
 
-- ---------------- NOTA ----------------
INSERT INTO NOTA (IDnota, IDmatricula, Tipo_Avaliacao, Data_Avaliacao, Valor) VALUES (1, 74, 'Projeto Prático', '2023-05-30', 0.6);
INSERT INTO NOTA (IDnota, IDmatricula, Tipo_Avaliacao, Data_Avaliacao, Valor) VALUES (2, 95, 'Projeto Prático', '2023-06-05', 3.0);
INSERT INTO NOTA (IDnota, IDmatricula, Tipo_Avaliacao, Data_Avaliacao, Valor) VALUES (3, 6, 'Trabalho Final', '2023-08-07', 9.4);
INSERT INTO NOTA (IDnota, IDmatricula, Tipo_Avaliacao, Data_Avaliacao, Valor) VALUES (4, 86, 'Prova 2', '2024-12-17', 7.5);
INSERT INTO NOTA (IDnota, IDmatricula, Tipo_Avaliacao, Data_Avaliacao, Valor) VALUES (5, 87, 'Seminário', '2024-08-25', 4.1);
INSERT INTO NOTA (IDnota, IDmatricula, Tipo_Avaliacao, Data_Avaliacao, Valor) VALUES (6, 47, 'Prova 1', '2024-10-06', 3.3);
INSERT INTO NOTA (IDnota, IDmatricula, Tipo_Avaliacao, Data_Avaliacao, Valor) VALUES (7, 12, 'Projeto Prático', '2025-07-09', 2.6);
INSERT INTO NOTA (IDnota, IDmatricula, Tipo_Avaliacao, Data_Avaliacao, Valor) VALUES (8, 58, 'Seminário', '2024-06-18', 1.2);
INSERT INTO NOTA (IDnota, IDmatricula, Tipo_Avaliacao, Data_Avaliacao, Valor) VALUES (9, 36, 'Trabalho Final', '2023-07-30', 4.8);
INSERT INTO NOTA (IDnota, IDmatricula, Tipo_Avaliacao, Data_Avaliacao, Valor) VALUES (10, 35, 'Trabalho Final', '2025-06-28', 2.6);
INSERT INTO NOTA (IDnota, IDmatricula, Tipo_Avaliacao, Data_Avaliacao, Valor) VALUES (11, 7, 'Trabalho Final', '2022-06-19', 2.9);
INSERT INTO NOTA (IDnota, IDmatricula, Tipo_Avaliacao, Data_Avaliacao, Valor) VALUES (12, 68, 'Projeto Prático', '2025-02-03', 2.8);
INSERT INTO NOTA (IDnota, IDmatricula, Tipo_Avaliacao, Data_Avaliacao, Valor) VALUES (13, 50, 'Prova Substitutiva', '2023-12-17', 3.9);
INSERT INTO NOTA (IDnota, IDmatricula, Tipo_Avaliacao, Data_Avaliacao, Valor) VALUES (14, 54, 'Prova 1', '2022-11-27', 4.0);
INSERT INTO NOTA (IDnota, IDmatricula, Tipo_Avaliacao, Data_Avaliacao, Valor) VALUES (15, 34, 'Prova 1', '2022-08-20', 3.0);
INSERT INTO NOTA (IDnota, IDmatricula, Tipo_Avaliacao, Data_Avaliacao, Valor) VALUES (16, 9, 'Trabalho Final', '2022-01-26', 8.6);
INSERT INTO NOTA (IDnota, IDmatricula, Tipo_Avaliacao, Data_Avaliacao, Valor) VALUES (17, 62, 'Trabalho Final', '2024-09-05', 1.5);
INSERT INTO NOTA (IDnota, IDmatricula, Tipo_Avaliacao, Data_Avaliacao, Valor) VALUES (18, 57, 'Seminário', '2023-01-28', 5.1);
INSERT INTO NOTA (IDnota, IDmatricula, Tipo_Avaliacao, Data_Avaliacao, Valor) VALUES (19, 36, 'Seminário', '2024-05-29', 9.9);
INSERT INTO NOTA (IDnota, IDmatricula, Tipo_Avaliacao, Data_Avaliacao, Valor) VALUES (20, 86, 'Trabalho Final', '2023-07-21', 4.0);
INSERT INTO NOTA (IDnota, IDmatricula, Tipo_Avaliacao, Data_Avaliacao, Valor) VALUES (21, 54, 'Prova 2', '2023-07-19', 10.0);
INSERT INTO NOTA (IDnota, IDmatricula, Tipo_Avaliacao, Data_Avaliacao, Valor) VALUES (22, 18, 'Prova Substitutiva', '2024-04-03', 6.6);
INSERT INTO NOTA (IDnota, IDmatricula, Tipo_Avaliacao, Data_Avaliacao, Valor) VALUES (23, 29, 'Prova Substitutiva', '2022-08-22', 0.2);
INSERT INTO NOTA (IDnota, IDmatricula, Tipo_Avaliacao, Data_Avaliacao, Valor) VALUES (24, 5, 'Projeto Prático', '2025-05-11', 2.8);
INSERT INTO NOTA (IDnota, IDmatricula, Tipo_Avaliacao, Data_Avaliacao, Valor) VALUES (25, 33, 'Projeto Prático', '2023-09-20', 2.4);
INSERT INTO NOTA (IDnota, IDmatricula, Tipo_Avaliacao, Data_Avaliacao, Valor) VALUES (26, 8, 'Trabalho Final', '2025-03-30', 5.7);
INSERT INTO NOTA (IDnota, IDmatricula, Tipo_Avaliacao, Data_Avaliacao, Valor) VALUES (27, 9, 'Prova 2', '2022-04-23', 3.8);
INSERT INTO NOTA (IDnota, IDmatricula, Tipo_Avaliacao, Data_Avaliacao, Valor) VALUES (28, 37, 'Projeto Prático', '2024-08-12', 4.6);
INSERT INTO NOTA (IDnota, IDmatricula, Tipo_Avaliacao, Data_Avaliacao, Valor) VALUES (29, 51, 'Prova 2', '2022-02-08', 5.1);
INSERT INTO NOTA (IDnota, IDmatricula, Tipo_Avaliacao, Data_Avaliacao, Valor) VALUES (30, 31, 'Trabalho Final', '2023-02-22', 3.3);
INSERT INTO NOTA (IDnota, IDmatricula, Tipo_Avaliacao, Data_Avaliacao, Valor) VALUES (31, 13, 'Seminário', '2023-05-19', 1.6);
INSERT INTO NOTA (IDnota, IDmatricula, Tipo_Avaliacao, Data_Avaliacao, Valor) VALUES (32, 3, 'Trabalho Final', '2025-02-18', 6.4);
INSERT INTO NOTA (IDnota, IDmatricula, Tipo_Avaliacao, Data_Avaliacao, Valor) VALUES (33, 76, 'Trabalho Final', '2023-10-18', 2.2);
INSERT INTO NOTA (IDnota, IDmatricula, Tipo_Avaliacao, Data_Avaliacao, Valor) VALUES (34, 40, 'Prova 2', '2024-02-07', 3.7);
INSERT INTO NOTA (IDnota, IDmatricula, Tipo_Avaliacao, Data_Avaliacao, Valor) VALUES (35, 86, 'Prova 2', '2022-10-02', 6.8);
INSERT INTO NOTA (IDnota, IDmatricula, Tipo_Avaliacao, Data_Avaliacao, Valor) VALUES (36, 18, 'Prova 1', '2022-09-02', 2.3);
INSERT INTO NOTA (IDnota, IDmatricula, Tipo_Avaliacao, Data_Avaliacao, Valor) VALUES (37, 16, 'Projeto Prático', '2022-12-01', 7.1);
INSERT INTO NOTA (IDnota, IDmatricula, Tipo_Avaliacao, Data_Avaliacao, Valor) VALUES (38, 57, 'Trabalho Final', '2024-10-20', 9.8);
INSERT INTO NOTA (IDnota, IDmatricula, Tipo_Avaliacao, Data_Avaliacao, Valor) VALUES (39, 5, 'Projeto Prático', '2025-08-01', 0.0);
INSERT INTO NOTA (IDnota, IDmatricula, Tipo_Avaliacao, Data_Avaliacao, Valor) VALUES (40, 24, 'Projeto Prático', '2023-05-10', 1.8);
INSERT INTO NOTA (IDnota, IDmatricula, Tipo_Avaliacao, Data_Avaliacao, Valor) VALUES (41, 53, 'Trabalho Final', '2022-10-24', 7.4);
INSERT INTO NOTA (IDnota, IDmatricula, Tipo_Avaliacao, Data_Avaliacao, Valor) VALUES (42, 1, 'Prova 1', '2022-06-25', 7.9);
INSERT INTO NOTA (IDnota, IDmatricula, Tipo_Avaliacao, Data_Avaliacao, Valor) VALUES (43, 50, 'Prova 1', '2025-04-09', 6.7);
INSERT INTO NOTA (IDnota, IDmatricula, Tipo_Avaliacao, Data_Avaliacao, Valor) VALUES (44, 24, 'Prova 2', '2022-01-19', 9.5);
INSERT INTO NOTA (IDnota, IDmatricula, Tipo_Avaliacao, Data_Avaliacao, Valor) VALUES (45, 84, 'Trabalho Final', '2022-02-25', 3.8);
INSERT INTO NOTA (IDnota, IDmatricula, Tipo_Avaliacao, Data_Avaliacao, Valor) VALUES (46, 36, 'Projeto Prático', '2023-03-25', 6.2);
INSERT INTO NOTA (IDnota, IDmatricula, Tipo_Avaliacao, Data_Avaliacao, Valor) VALUES (47, 89, 'Prova 2', '2022-11-04', 6.4);
INSERT INTO NOTA (IDnota, IDmatricula, Tipo_Avaliacao, Data_Avaliacao, Valor) VALUES (48, 95, 'Prova Substitutiva', '2023-09-21', 0.9);
INSERT INTO NOTA (IDnota, IDmatricula, Tipo_Avaliacao, Data_Avaliacao, Valor) VALUES (49, 81, 'Seminário', '2023-11-25', 7.0);
INSERT INTO NOTA (IDnota, IDmatricula, Tipo_Avaliacao, Data_Avaliacao, Valor) VALUES (50, 82, 'Projeto Prático', '2023-02-05', 7.1);
INSERT INTO NOTA (IDnota, IDmatricula, Tipo_Avaliacao, Data_Avaliacao, Valor) VALUES (51, 12, 'Projeto Prático', '2022-05-14', 6.2);
INSERT INTO NOTA (IDnota, IDmatricula, Tipo_Avaliacao, Data_Avaliacao, Valor) VALUES (52, 40, 'Prova 1', '2023-05-25', 1.2);
INSERT INTO NOTA (IDnota, IDmatricula, Tipo_Avaliacao, Data_Avaliacao, Valor) VALUES (53, 58, 'Prova 1', '2025-02-17', 1.8);
INSERT INTO NOTA (IDnota, IDmatricula, Tipo_Avaliacao, Data_Avaliacao, Valor) VALUES (54, 86, 'Prova 1', '2025-03-28', 7.6);
INSERT INTO NOTA (IDnota, IDmatricula, Tipo_Avaliacao, Data_Avaliacao, Valor) VALUES (55, 13, 'Seminário', '2025-07-27', 6.7);
INSERT INTO NOTA (IDnota, IDmatricula, Tipo_Avaliacao, Data_Avaliacao, Valor) VALUES (56, 85, 'Prova Substitutiva', '2022-10-06', 0.1);
INSERT INTO NOTA (IDnota, IDmatricula, Tipo_Avaliacao, Data_Avaliacao, Valor) VALUES (57, 68, 'Prova Substitutiva', '2022-06-05', 9.9);
INSERT INTO NOTA (IDnota, IDmatricula, Tipo_Avaliacao, Data_Avaliacao, Valor) VALUES (58, 72, 'Prova Substitutiva', '2025-04-24', 0.0);
INSERT INTO NOTA (IDnota, IDmatricula, Tipo_Avaliacao, Data_Avaliacao, Valor) VALUES (59, 77, 'Prova Substitutiva', '2024-12-07', 6.5);
INSERT INTO NOTA (IDnota, IDmatricula, Tipo_Avaliacao, Data_Avaliacao, Valor) VALUES (60, 53, 'Projeto Prático', '2023-01-31', 3.3);
INSERT INTO NOTA (IDnota, IDmatricula, Tipo_Avaliacao, Data_Avaliacao, Valor) VALUES (61, 40, 'Prova 2', '2025-04-26', 4.3);
INSERT INTO NOTA (IDnota, IDmatricula, Tipo_Avaliacao, Data_Avaliacao, Valor) VALUES (62, 66, 'Prova Substitutiva', '2024-03-23', 4.0);
INSERT INTO NOTA (IDnota, IDmatricula, Tipo_Avaliacao, Data_Avaliacao, Valor) VALUES (63, 80, 'Prova 2', '2024-01-03', 5.4);
INSERT INTO NOTA (IDnota, IDmatricula, Tipo_Avaliacao, Data_Avaliacao, Valor) VALUES (64, 94, 'Prova Substitutiva', '2023-10-04', 4.4);
INSERT INTO NOTA (IDnota, IDmatricula, Tipo_Avaliacao, Data_Avaliacao, Valor) VALUES (65, 5, 'Trabalho Final', '2024-05-08', 8.4);
INSERT INTO NOTA (IDnota, IDmatricula, Tipo_Avaliacao, Data_Avaliacao, Valor) VALUES (66, 32, 'Prova 2', '2024-11-16', 9.0);
INSERT INTO NOTA (IDnota, IDmatricula, Tipo_Avaliacao, Data_Avaliacao, Valor) VALUES (67, 78, 'Seminário', '2022-02-18', 4.8);
INSERT INTO NOTA (IDnota, IDmatricula, Tipo_Avaliacao, Data_Avaliacao, Valor) VALUES (68, 61, 'Seminário', '2025-08-16', 6.1);
INSERT INTO NOTA (IDnota, IDmatricula, Tipo_Avaliacao, Data_Avaliacao, Valor) VALUES (69, 13, 'Prova 2', '2022-10-26', 8.9);
INSERT INTO NOTA (IDnota, IDmatricula, Tipo_Avaliacao, Data_Avaliacao, Valor) VALUES (70, 90, 'Projeto Prático', '2025-09-04', 8.9);
INSERT INTO NOTA (IDnota, IDmatricula, Tipo_Avaliacao, Data_Avaliacao, Valor) VALUES (71, 95, 'Prova 2', '2023-06-13', 5.3);
INSERT INTO NOTA (IDnota, IDmatricula, Tipo_Avaliacao, Data_Avaliacao, Valor) VALUES (72, 70, 'Seminário', '2025-10-02', 7.8);
INSERT INTO NOTA (IDnota, IDmatricula, Tipo_Avaliacao, Data_Avaliacao, Valor) VALUES (73, 98, 'Prova Substitutiva', '2022-06-18', 5.3);
INSERT INTO NOTA (IDnota, IDmatricula, Tipo_Avaliacao, Data_Avaliacao, Valor) VALUES (74, 36, 'Prova 1', '2023-08-07', 1.1);
INSERT INTO NOTA (IDnota, IDmatricula, Tipo_Avaliacao, Data_Avaliacao, Valor) VALUES (75, 13, 'Prova Substitutiva', '2025-03-02', 7.4);
INSERT INTO NOTA (IDnota, IDmatricula, Tipo_Avaliacao, Data_Avaliacao, Valor) VALUES (76, 86, 'Projeto Prático', '2025-04-29', 3.4);
INSERT INTO NOTA (IDnota, IDmatricula, Tipo_Avaliacao, Data_Avaliacao, Valor) VALUES (77, 8, 'Projeto Prático', '2025-01-20', 9.5);
INSERT INTO NOTA (IDnota, IDmatricula, Tipo_Avaliacao, Data_Avaliacao, Valor) VALUES (78, 84, 'Prova Substitutiva', '2023-11-05', 0.3);
INSERT INTO NOTA (IDnota, IDmatricula, Tipo_Avaliacao, Data_Avaliacao, Valor) VALUES (79, 62, 'Seminário', '2024-02-24', 7.6);
INSERT INTO NOTA (IDnota, IDmatricula, Tipo_Avaliacao, Data_Avaliacao, Valor) VALUES (80, 4, 'Trabalho Final', '2024-07-27', 0.3);
INSERT INTO NOTA (IDnota, IDmatricula, Tipo_Avaliacao, Data_Avaliacao, Valor) VALUES (81, 63, 'Prova 1', '2023-06-27', 9.7);
INSERT INTO NOTA (IDnota, IDmatricula, Tipo_Avaliacao, Data_Avaliacao, Valor) VALUES (82, 61, 'Prova Substitutiva', '2024-05-16', 7.6);
INSERT INTO NOTA (IDnota, IDmatricula, Tipo_Avaliacao, Data_Avaliacao, Valor) VALUES (83, 53, 'Prova 2', '2025-03-04', 4.8);
INSERT INTO NOTA (IDnota, IDmatricula, Tipo_Avaliacao, Data_Avaliacao, Valor) VALUES (84, 86, 'Trabalho Final', '2024-09-21', 6.4);
INSERT INTO NOTA (IDnota, IDmatricula, Tipo_Avaliacao, Data_Avaliacao, Valor) VALUES (85, 90, 'Prova Substitutiva', '2025-05-20', 2.4);
INSERT INTO NOTA (IDnota, IDmatricula, Tipo_Avaliacao, Data_Avaliacao, Valor) VALUES (86, 25, 'Projeto Prático', '2024-12-11', 3.6);
INSERT INTO NOTA (IDnota, IDmatricula, Tipo_Avaliacao, Data_Avaliacao, Valor) VALUES (87, 87, 'Prova 2', '2025-05-05', 2.2);
INSERT INTO NOTA (IDnota, IDmatricula, Tipo_Avaliacao, Data_Avaliacao, Valor) VALUES (88, 94, 'Trabalho Final', '2023-02-28', 4.3);
INSERT INTO NOTA (IDnota, IDmatricula, Tipo_Avaliacao, Data_Avaliacao, Valor) VALUES (89, 85, 'Trabalho Final', '2024-01-13', 1.3);
INSERT INTO NOTA (IDnota, IDmatricula, Tipo_Avaliacao, Data_Avaliacao, Valor) VALUES (90, 30, 'Prova 2', '2022-04-30', 7.6);
INSERT INTO NOTA (IDnota, IDmatricula, Tipo_Avaliacao, Data_Avaliacao, Valor) VALUES (91, 60, 'Prova Substitutiva', '2025-07-01', 8.4);
INSERT INTO NOTA (IDnota, IDmatricula, Tipo_Avaliacao, Data_Avaliacao, Valor) VALUES (92, 54, 'Prova 2', '2025-10-12', 3.4);
INSERT INTO NOTA (IDnota, IDmatricula, Tipo_Avaliacao, Data_Avaliacao, Valor) VALUES (93, 59, 'Prova 2', '2023-07-30', 2.0);
INSERT INTO NOTA (IDnota, IDmatricula, Tipo_Avaliacao, Data_Avaliacao, Valor) VALUES (94, 29, 'Prova 2', '2022-08-21', 9.0);
INSERT INTO NOTA (IDnota, IDmatricula, Tipo_Avaliacao, Data_Avaliacao, Valor) VALUES (95, 13, 'Prova 2', '2022-02-13', 3.6);
INSERT INTO NOTA (IDnota, IDmatricula, Tipo_Avaliacao, Data_Avaliacao, Valor) VALUES (96, 33, 'Prova 1', '2024-01-31', 8.7);
INSERT INTO NOTA (IDnota, IDmatricula, Tipo_Avaliacao, Data_Avaliacao, Valor) VALUES (97, 76, 'Prova Substitutiva', '2023-10-04', 9.8);
INSERT INTO NOTA (IDnota, IDmatricula, Tipo_Avaliacao, Data_Avaliacao, Valor) VALUES (98, 11, 'Prova Substitutiva', '2023-06-08', 7.9);
INSERT INTO NOTA (IDnota, IDmatricula, Tipo_Avaliacao, Data_Avaliacao, Valor) VALUES (99, 90, 'Prova Substitutiva', '2022-01-19', 5.0);
INSERT INTO NOTA (IDnota, IDmatricula, Tipo_Avaliacao, Data_Avaliacao, Valor) VALUES (100, 45, 'Prova 1', '2024-11-10', 3.4);
