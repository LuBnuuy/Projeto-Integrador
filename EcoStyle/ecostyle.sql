-- ECOSTYLE

CREATE DATABASE ecostyle_db;

USE ecostyle_db;

-- TABELA: CLIENTE

CREATE TABLE CLIENTE (
    IDCliente     INT AUTO_INCREMENT PRIMARY KEY,
    Nome          VARCHAR(150) NOT NULL,
    Telefone      VARCHAR(20),
    CPF           VARCHAR(11) NOT NULL UNIQUE,
    Endereco      VARCHAR(255),
    Email         VARCHAR(150) UNIQUE
);


-- TABELA: FUNCIONARIOS

CREATE TABLE FUNCIONARIOS (
    IDFuncionarios  INT AUTO_INCREMENT PRIMARY KEY,
    Nome            VARCHAR(150) NOT NULL,
    DataNascimento  DATE,
    Endereco        VARCHAR(255),
    Telefone        VARCHAR(20),
    CPF             VARCHAR(11) NOT NULL UNIQUE
);


-- TABELA: ENTREGADORES

CREATE TABLE ENTREGADORES (
    IDEntregador              INT AUTO_INCREMENT PRIMARY KEY,
    Nome                      VARCHAR(150) NOT NULL,
    Telefone                  VARCHAR(20),
    CPF                       VARCHAR(14) NOT NULL UNIQUE,
    Veiculo                   VARCHAR(100),
    CertificadoCarbonoNeutro  BOOLEAN DEFAULT FALSE,
    OrgaoCertificador         VARCHAR(150),
    DataCertificacao          DATE
);


-- TABELA: CATEGORIA

CREATE TABLE CATEGORIA (
    IDCategoria   INT AUTO_INCREMENT PRIMARY KEY,
    NomeCategoria VARCHAR(100) NOT NULL,
    Descricao     VARCHAR(255)
);


-- TABELA: FORNECEDOR

CREATE TABLE FORNECEDOR (
    IDFornecedor   INT AUTO_INCREMENT PRIMARY KEY,
    NomeFornecedor VARCHAR(150) NOT NULL,
    Material       VARCHAR(100),
    CNPJ           VARCHAR(14) NOT NULL UNIQUE,
    Email          VARCHAR(150),
    Telefone       VARCHAR(20),
    Endereco       VARCHAR(255),
    Cidade         VARCHAR(100),
    Estado         VARCHAR(50),
    Pais           VARCHAR(50)
);


-- TABELA: PRODUTOS

CREATE TABLE PRODUTOS (
    IDProdutos    INT AUTO_INCREMENT PRIMARY KEY,
    IDCategoria   INT NOT NULL,
    IDFornecedor  INT NOT NULL,
    NomeProdutos  VARCHAR(150) NOT NULL,
    Preco         DECIMAL(10,2) NOT NULL DEFAULT 0.00,
    Tamanho       VARCHAR(20),
    Cor           VARCHAR(50),
    Quantidade    INT NOT NULL DEFAULT 0,
    CONSTRAINT fk_produtos_categoria
        FOREIGN KEY (IDCategoria) REFERENCES CATEGORIA(IDCategoria),
    CONSTRAINT fk_produtos_fornecedor
        FOREIGN KEY (IDFornecedor) REFERENCES FORNECEDOR(IDFornecedor)
        ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT chk_produtos_preco CHECK (Preco >= 0),
    CONSTRAINT chk_produtos_quantidade CHECK (Quantidade >= 0)
);


-- TABELA: PEDIDOS

CREATE TABLE PEDIDOS (
    IDPedido       INT AUTO_INCREMENT PRIMARY KEY,
    IDCliente      INT NOT NULL,
    IDFuncionario  INT NOT NULL,
    IDEntregador   INT NOT NULL,
    DataPedido     DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    ValorTotal     DECIMAL(10,2) NOT NULL DEFAULT 0.00,
    Status         VARCHAR(50) NOT NULL DEFAULT 'PENDENTE',
    CONSTRAINT fk_pedidos_cliente
        FOREIGN KEY (IDCliente) REFERENCES CLIENTE(IDCliente),
    CONSTRAINT fk_pedidos_funcionario
        FOREIGN KEY (IDFuncionario) REFERENCES FUNCIONARIOS(IDFuncionarios),
    CONSTRAINT fk_pedidos_entregador
        FOREIGN KEY (IDEntregador) REFERENCES ENTREGADORES(IDEntregador),
    CONSTRAINT chk_pedidos_status
        CHECK (Status IN ('PENDENTE','PROCESSANDO','ENVIADO','ENTREGUE','CANCELADO','DEVOLVIDO')) -- GARANTE QUE STATUS SEJA APENAS AS OPÇÕES DESCRITAS
);


-- TABELA: PEDIDO_ITENS

CREATE TABLE PEDIDO_ITENS (
    IDItem         INT AUTO_INCREMENT PRIMARY KEY,
    IDPedido       INT NOT NULL,
    IDProduto      INT NOT NULL,
    Quantidade     INT NOT NULL DEFAULT 1,
    PrecoUnitario  DECIMAL(10,2) NOT NULL,
    CONSTRAINT fk_itens_pedido
        FOREIGN KEY (IDPedido) REFERENCES PEDIDOS(IDPedido),
    CONSTRAINT fk_itens_produto
        FOREIGN KEY (IDProduto) REFERENCES PRODUTOS(IDProdutos),
    CONSTRAINT chk_itens_quantidade CHECK (Quantidade > 0) -- GARANTE QUE A QUANTIDADE NÃO SEJA NEGATIVA
);


-- TABELA: ESTOQUE

CREATE TABLE ESTOQUE (
    IDEstoque      INT AUTO_INCREMENT PRIMARY KEY,
    IDProduto      INT NOT NULL,
    Tipo           VARCHAR(20) NOT NULL,
    Quantidade     INT NOT NULL,
    DataMovimento  DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_estoque_produto
        FOREIGN KEY (IDProduto) REFERENCES PRODUTOS(IDProdutos),
    CONSTRAINT chk_estoque_tipo CHECK (Tipo IN ('ENTRADA','SAIDA')), -- GARANTE QUE TIPO SEJA APENAS AS OPÇÕES DESCRITAS
    CONSTRAINT chk_estoque_quantidade CHECK (Quantidade > 0) -- GARANTE QUE A QUANTIDADE NÃO SEJA NEGATIVA
);
