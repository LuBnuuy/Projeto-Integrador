-- ECOSTYLE_DB - STORED PROCEDURES

USE ecostyle_db;

DELIMITER //


-- 1) CLIENTE
-- REGRA DE NEGÓCIO: um cliente não pode ser cadastrado com CPF ou
-- e-mail já existentes na base, evitando cadastros duplicados.

CREATE PROCEDURE sp_CadastrarCliente (
    IN p_Nome     VARCHAR(150),
    IN p_Telefone VARCHAR(20),
    IN p_CPF      VARCHAR(11),
    IN p_Endereco VARCHAR(255),
    IN p_Email    VARCHAR(150)
)
BEGIN
    IF EXISTS (SELECT 1 FROM CLIENTE WHERE CPF = p_CPF) THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Já existe um cliente cadastrado com este CPF.';
    END IF;

    IF p_Email IS NOT NULL AND EXISTS (SELECT 1 FROM CLIENTE WHERE Email = p_Email) THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Já existe um cliente cadastrado com este e-mail.';
    END IF;

    INSERT INTO CLIENTE (Nome, Telefone, CPF, Endereco, Email)
    VALUES (p_Nome, p_Telefone, p_CPF, p_Endereco, p_Email);
END//



-- 2) FUNCIONARIOS
-- REGRA DE NEGÓCIO: impede a contratação de duas pessoas com o
-- mesmo CPF, garantindo unicidade cadastral do quadro de funcionários.

CREATE PROCEDURE sp_CadastrarFuncionario (
    IN p_Nome           VARCHAR(150),
    IN p_DataNascimento DATE,
    IN p_Endereco       VARCHAR(255),
    IN p_Telefone       VARCHAR(20),
    IN p_CPF            VARCHAR(11)
)
BEGIN
    IF EXISTS (SELECT 1 FROM FUNCIONARIOS WHERE CPF = p_CPF) THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Já existe um funcionário cadastrado com este CPF.';
    END IF;

    INSERT INTO FUNCIONARIOS (Nome, DataNascimento, Endereco, Telefone, CPF)
    VALUES (p_Nome, p_DataNascimento, p_Endereco, p_Telefone, p_CPF);
END//



-- 3) ENTREGADORES
-- REGRA DE NEGÓCIO: só é possível marcar um entregador como
-- "Certificado Carbono Neutro" se o órgão certificador e a data de
-- certificação forem informados — garante consistência do selo verde.

CREATE PROCEDURE sp_CadastrarEntregador (
    IN p_Nome                     VARCHAR(150),
    IN p_Telefone                 VARCHAR(20),
    IN p_CPF                      VARCHAR(14),
    IN p_Veiculo                  VARCHAR(100),
    IN p_CertificadoCarbonoNeutro BOOLEAN,
    IN p_OrgaoCertificador        VARCHAR(150),
    IN p_DataCertificacao         DATE
)
BEGIN
    IF p_CertificadoCarbonoNeutro = TRUE
       AND (p_OrgaoCertificador IS NULL OR p_DataCertificacao IS NULL) THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Entregador certificado precisa informar órgão certificador e data de certificação.';
    END IF;

    INSERT INTO ENTREGADORES (Nome, Telefone, CPF, Veiculo, CertificadoCarbonoNeutro, OrgaoCertificador, DataCertificacao)
    VALUES (p_Nome, p_Telefone, p_CPF, p_Veiculo, p_CertificadoCarbonoNeutro, p_OrgaoCertificador, p_DataCertificacao);
END//



-- 4) CATEGORIA
-- REGRA DE NEGÓCIO: não permite duas categorias com o mesmo nome,
-- evitando categorias duplicadas na vitrine da loja.

CREATE PROCEDURE sp_CadastrarCategoria (
    IN p_NomeCategoria VARCHAR(100),
    IN p_Descricao     VARCHAR(255)
)
BEGIN
    IF EXISTS (SELECT 1 FROM CATEGORIA WHERE NomeCategoria = p_NomeCategoria) THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Já existe uma categoria com este nome.';
    END IF;

    INSERT INTO CATEGORIA (NomeCategoria, Descricao)
    VALUES (p_NomeCategoria, p_Descricao);
END//



-- 5) FORNECEDOR
-- REGRA DE NEGÓCIO: impede o cadastro de fornecedores com CNPJ
-- duplicado, garantindo que cada empresa fornecedora seja única.

CREATE PROCEDURE sp_CadastrarFornecedor (
    IN p_NomeFornecedor VARCHAR(150),
    IN p_Material       VARCHAR(100),
    IN p_CNPJ           VARCHAR(14),
    IN p_Email          VARCHAR(150),
    IN p_Telefone       VARCHAR(20),
    IN p_Endereco       VARCHAR(255),
    IN p_Cidade         VARCHAR(100),
    IN p_Estado         VARCHAR(50),
    IN p_Pais           VARCHAR(50)
)
BEGIN
    IF EXISTS (SELECT 1 FROM FORNECEDOR WHERE CNPJ = p_CNPJ) THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Já existe um fornecedor cadastrado com este CNPJ.';
    END IF;

    INSERT INTO FORNECEDOR (NomeFornecedor, Material, CNPJ, Email, Telefone, Endereco, Cidade, Estado, Pais)
    VALUES (p_NomeFornecedor, p_Material, p_CNPJ, p_Email, p_Telefone, p_Endereco, p_Cidade, p_Estado, p_Pais);
END//



-- 6) PRODUTOS
-- REGRA DE NEGÓCIO: só permite cadastrar produto se a categoria e o
-- fornecedor informados realmente existirem, evitando produtos
-- "órfãos" e mensagens de erro genéricas de FK.

CREATE PROCEDURE sp_CadastrarProduto (
    IN p_IDCategoria  INT,
    IN p_IDFornecedor INT,
    IN p_NomeProdutos VARCHAR(150),
    IN p_Preco        DECIMAL(10,2),
    IN p_Tamanho      VARCHAR(20),
    IN p_Cor          VARCHAR(50),
    IN p_Quantidade   INT
)
BEGIN
    IF NOT EXISTS (SELECT 1 FROM CATEGORIA WHERE IDCategoria = p_IDCategoria) THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Categoria informada não existe.';
    END IF;

    IF NOT EXISTS (SELECT 1 FROM FORNECEDOR WHERE IDFornecedor = p_IDFornecedor) THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Fornecedor informado não existe.';
    END IF;

    INSERT INTO PRODUTOS (IDCategoria, IDFornecedor, NomeProdutos, Preco, Tamanho, Cor, Quantidade)
    VALUES (p_IDCategoria, p_IDFornecedor, p_NomeProdutos, p_Preco, p_Tamanho, p_Cor, p_Quantidade);
END//



-- 7) PEDIDOS
-- REGRA DE NEGÓCIO: todo pedido nasce com status 'PENDENTE' e valor
-- total zerado — o valor só é consolidado à medida que itens são
-- adicionados (ver sp_AdicionarItemPedido), evitando pedidos com
-- total incorreto no momento da abertura.

CREATE PROCEDURE sp_CriarPedido (
    IN p_IDCliente     INT,
    IN p_IDFuncionario INT,
    IN p_IDEntregador  INT,
    OUT p_IDPedidoGerado INT
)
BEGIN
    IF NOT EXISTS (SELECT 1 FROM CLIENTE WHERE IDCliente = p_IDCliente) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Cliente informado não existe.';
    END IF;

    IF NOT EXISTS (SELECT 1 FROM FUNCIONARIOS WHERE IDFuncionarios = p_IDFuncionario) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Funcionário informado não existe.';
    END IF;

    IF NOT EXISTS (SELECT 1 FROM ENTREGADORES WHERE IDEntregador = p_IDEntregador) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Entregador informado não existe.';
    END IF;

    INSERT INTO PEDIDOS (IDCliente, IDFuncionario, IDEntregador, ValorTotal, Status)
    VALUES (p_IDCliente, p_IDFuncionario, p_IDEntregador, 0.00, 'PENDENTE');

    SET p_IDPedidoGerado = LAST_INSERT_ID();
END//



-- 8) PEDIDO_ITENS
-- REGRA DE NEGÓCIO: um item só pode ser adicionado ao pedido se
-- houver estoque suficiente do produto. Ao confirmar o item, o
-- estoque do produto é baixado e o ValorTotal do pedido é atualizado
-- automaticamente, garantindo consistência entre estoque e vendas.

CREATE PROCEDURE sp_AdicionarItemPedido (
    IN p_IDPedido      INT,
    IN p_IDProduto     INT,
    IN p_Quantidade    INT,
    IN p_PrecoUnitario DECIMAL(10,2)
)
BEGIN
    DECLARE v_EstoqueAtual INT;

    SELECT Quantidade INTO v_EstoqueAtual
    FROM PRODUTOS
    WHERE IDProdutos = p_IDProduto
    FOR UPDATE;

    IF v_EstoqueAtual IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Produto informado não existe.';
    END IF;

    IF v_EstoqueAtual < p_Quantidade THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Estoque insuficiente para este produto.';
    END IF;

    INSERT INTO PEDIDO_ITENS (IDPedido, IDProduto, Quantidade, PrecoUnitario)
    VALUES (p_IDPedido, p_IDProduto, p_Quantidade, p_PrecoUnitario);

    UPDATE PRODUTOS
       SET Quantidade = Quantidade - p_Quantidade
     WHERE IDProdutos = p_IDProduto;

    UPDATE PEDIDOS
       SET ValorTotal = ValorTotal + (p_Quantidade * p_PrecoUnitario)
     WHERE IDPedido = p_IDPedido;
END//



-- 9) ESTOQUE
-- REGRA DE NEGÓCIO: toda movimentação de estoque reflete
-- automaticamente na quantidade disponível do produto: entradas
-- somam, saídas subtraem — e uma saída nunca pode deixar o estoque
-- negativo.

CREATE PROCEDURE sp_RegistrarMovimentoEstoque (
    IN p_IDProduto  INT,
    IN p_Tipo       VARCHAR(20),
    IN p_Quantidade INT
)
BEGIN
    DECLARE v_EstoqueAtual INT;

    SELECT Quantidade INTO v_EstoqueAtual
    FROM PRODUTOS
    WHERE IDProdutos = p_IDProduto
    FOR UPDATE;

    IF v_EstoqueAtual IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Produto informado não existe.';
    END IF;

    IF p_Tipo = 'SAIDA' AND v_EstoqueAtual < p_Quantidade THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Movimento de saída maior que o estoque disponível.';
    END IF;

    INSERT INTO ESTOQUE (IDProduto, Tipo, Quantidade)
    VALUES (p_IDProduto, p_Tipo, p_Quantidade);

    IF p_Tipo = 'ENTRADA' THEN
        UPDATE PRODUTOS SET Quantidade = Quantidade + p_Quantidade WHERE IDProdutos = p_IDProduto;
    ELSE
        UPDATE PRODUTOS SET Quantidade = Quantidade - p_Quantidade WHERE IDProdutos = p_IDProduto;
    END IF;
END//

DELIMITER ;