-- IRON_FIT - INSERTS DE EXEMPLO
-- Popula as tabelas respeitando FKs, UNIQUEs e as regras de negócio
-- (idade mínima, capacidade máxima de aula, uma assinatura ativa por membro, etc.)
-- Ordem de inserção segue as dependências de chave estrangeira.

USE iron_fit;

-- =========================================================
-- 1) ACADEMIAS
-- =========================================================
INSERT INTO academias (NomeUnidade, Endereco, Cidade, Telefone, HorarioFuncionamento) VALUES
('IronFit Centro',    'Rua das Palmeiras, 120', 'São Paulo', '(11) 3344-5566', 'Seg a Sex 06h-22h, Sáb 08h-14h'),
('IronFit Zona Sul',  'Av. Ibirapuera, 850',    'São Paulo', '(11) 3355-7788', 'Seg a Sex 06h-23h, Sáb e Dom 08h-16h');

-- =========================================================
-- 2) MEMBROS (todos com 16+ anos, CPF/Email únicos)
-- =========================================================
INSERT INTO membros (IDAcademia, Nome, CPF, DataNascimento, Email, Telefone, Sexo) VALUES
(1, 'Carlos Eduardo Silva',  '12345678901', '1995-03-14', 'carlos.silva@email.com',  '(11) 98888-1111', 'M'),
(1, 'Fernanda Souza Lima',   '23456789012', '1998-07-22', 'fernanda.lima@email.com', '(11) 98888-2222', 'F'),
(1, 'Rafael Andrade Costa',  '34567890123', '2001-11-05', 'rafael.costa@email.com',  '(11) 98888-3333', 'M'),
(2, 'Juliana Pereira Rocha', '45678901234', '1990-01-30', 'juliana.rocha@email.com', '(11) 98888-4444', 'F'),
(2, 'Bruno Martins Alves',   '56789012345', '1993-09-18', 'bruno.alves@email.com',   '(11) 98888-5555', 'M'),
(2, 'Camila Ferreira Dias',  '67890123456', '2004-05-27', 'camila.dias@email.com',   '(11) 98888-6666', 'F');

-- =========================================================
-- 3) PERSONAL_TRAINERS (CREF único, vinculados a uma academia)
-- =========================================================
INSERT INTO personal_trainers (IDAcademia, Nome, CREF, Especialidade, Telefone, StatusAtivo, DataContratacao) VALUES
(1, 'André Luiz Barbosa', '012345-G/SP', 'Musculação', '(11) 97777-1111', TRUE, '2021-02-01'),
(1, 'Patrícia Nogueira',  '023456-G/SP', 'Funcional',  '(11) 97777-2222', TRUE, '2022-06-15'),
(2, 'Marcelo Tavares',    '034567-G/SP', 'Crossfit',   '(11) 97777-3333', TRUE, '2020-09-10'),
(2, 'Débora Santos',      '045678-G/SP', 'Pilates',    '(11) 97777-4444', TRUE, '2023-01-20');

-- =========================================================
-- 4) PLANOS_ASSINATURA (ValorMensal e DuracaoMeses > 0)
-- =========================================================
INSERT INTO planos_assinatura (NomePlano, ValorMensal, DuracaoMeses, Descricao, Status_ativo, AcessosSemanais) VALUES
('Plano Mensal',      129.90,   1, 'Acesso à musculação e aulas em grupo',      TRUE, 5),
('Plano Trimestral',  349.90,   3, 'Acesso completo com desconto progressivo',  TRUE, 6),
('Plano Anual',      1199.90,  12, 'Melhor custo-benefício, acesso ilimitado',  TRUE, 7);

-- =========================================================
-- 5) ASSINATURAS (no máximo 1 'ativa' por membro)
-- =========================================================
INSERT INTO assinaturas (IDMembro, IDPlano, DataInicio, DataFim, status, usuario_ultima_alteracao, FormaPagamento) VALUES
(1, 1, '2026-06-01', '2026-07-01', 'ativa',     'admin', 'Cartão de Crédito'),
(2, 2, '2026-05-15', '2026-08-15', 'ativa',     'admin', 'Pix'),
(3, 1, '2026-07-01', '2026-08-01', 'ativa',     'admin', 'Boleto'),
(4, 3, '2025-08-01', '2026-08-01', 'ativa',     'admin', 'Cartão de Crédito'),
(5, 2, '2026-01-10', '2026-04-10', 'cancelada', 'admin', 'Pix'),
(6, 1, '2026-08-01', '2026-09-01', 'ativa',     'admin', 'Cartão de Débito');

-- =========================================================
-- 6) AVALIACOES_FISICAS
-- (não é necessário informar IMC: o trigger trg_avaliacoes_fisicas_before_insert
--  calcula automaticamente PesoKg / AlturaM² antes do INSERT)
-- =========================================================
INSERT INTO avaliacoes_fisicas (IDMembro, IDTrainer, DataAvaliacao, PesoKg, AlturaM, PercentualGordura, ObservacoesInternas) VALUES
(1, 1, '2026-06-05', 82.50, 1.78, 18.50, 'Foco em hipertrofia, sem restrições'),
(2, 2, '2026-05-20', 61.20, 1.65, 22.30, 'Melhora na resistência cardiovascular'),
(3, 1, '2026-07-03', 75.00, 1.80, 15.80, 'Atleta iniciante, acompanhar evolução'),
(4, 3, '2026-01-15', 68.40, 1.70, 24.10, 'Recomendado reforço nutricional'),
(5, 4, '2026-02-02', 58.90, 1.60, 20.00, 'Boa evolução postural');

-- =========================================================
-- 7) AULAS_GRUPO (trainer deve pertencer à mesma academia da aula)
-- =========================================================
INSERT INTO aulas_grupo (IDAcademia, IDTrainer, NomeAula, DiaSemana, Horario, CapacidadeMaxima, NivelAula) VALUES
(1, 2, 'Funcional Intenso',   'segunda', '07:00:00', 15, 'Intermediário'),
(1, 1, 'Musculação Guiada',   'quarta',  '18:00:00', 10, 'Iniciante'),
(2, 3, 'Crossfit Avançado',   'terca',   '19:00:00', 12, 'Avançado'),
(2, 4, 'Pilates Suave',       'quinta',  '08:00:00',  8, 'Iniciante');

-- =========================================================
-- 8) MATRICULA_AULAS
-- (o trigger trg_matricula_aulas_before_insert bloqueia matrículas 'ativa'
--  além da CapacidadeMaxima; membro 5 está com assinatura cancelada,
--  por isso suas matrículas já entram como 'cancelada')
-- =========================================================
INSERT INTO matricula_aulas (IDAula, IDMembro, DataMatricula, status, usuario_ultima_alteracao, DataCancelamento) VALUES
(1, 4, '2026-06-10', 'ativa',     'admin', NULL),
(1, 5, '2026-06-10', 'cancelada', 'admin', '2026-04-10'),
(2, 1, '2026-06-12', 'ativa',     'admin', NULL),
(3, 4, '2026-06-15', 'ativa',     'admin', NULL),
(3, 5, '2026-06-15', 'cancelada', 'admin', '2026-04-10'),
(4, 6, '2026-06-20', 'ativa',     'admin', NULL),
(4, 2, '2026-06-20', 'ativa',     'admin', NULL);