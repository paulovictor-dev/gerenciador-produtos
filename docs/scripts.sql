/* ===========================
   BANCO: ProdutosDB
   Script completo (DDL + DML + Procs + Triggers + Function + Seeds)
   =========================== */

SET NOCOUNT ON;
------------------------------------------------------------
-- tabelas
------------------------------------------------------------
IF OBJECT_ID('dbo.Usuarios','U') IS NULL
BEGIN
  CREATE TABLE dbo.Usuarios (
    Id INT IDENTITY(1,1),
    Nome NVARCHAR(100) NOT NULL,
    Email NVARCHAR(100) NOT NULL UNIQUE,
    Senha NVARCHAR(100) NOT NULL,
    dataRegistro DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME()

    CONSTRAINT PK_UsuarioID PRIMARY KEY CLUSTERED (Id)
  );
END;

IF OBJECT_ID('dbo.Produtos','U') IS NULL
BEGIN
  CREATE TABLE dbo.Produtos(
    Id INT IDENTITY(1,1),
    Nome NVARCHAR(255) NOT NULL,       
    Preco DECIMAL(10,2) NOT NULL       

    CONSTRAINT PK_ProdutoID PRIMARY KEY CLUSTERED (Id)
  );
END;

IF OBJECT_ID('dbo.ProdutosLog','U') IS NULL
BEGIN
  CREATE TABLE dbo.ProdutosLog(
    LogId         BIGINT IDENTITY(1,1),
    ProdutoId     INT NULL,
    Operacao      NVARCHAR(20) NOT NULL,
    nomeAntigo    NVARCHAR(255) NULL,
    precoAntigo   DECIMAL(10,2) NULL,

    nomeNovo      NVARCHAR(255) NULL,
    precoNovo     DECIMAL(10,2) NULL,    

    dataLog       DATETIME NOT NULL,
    usuarioLogin  NVARCHAR(256) NULL,       

    CONSTRAINT PK_logID PRIMARY KEY CLUSTERED (LogId),
  );
  CREATE INDEX IDX_ProdutosLog_ProdutoData ON dbo.ProdutosLog(ProdutoId, dataLog DESC);
END;

IF OBJECT_ID('dbo.Tokens','U') IS NULL
BEGIN
  CREATE TABLE dbo.Tokens (
    TokenId UNIQUEIDENTIFIER NOT NULL DEFAULT NEWID(),
    UsuarioId INT NOT NULL,
    Token VARCHAR(200) NOT NULL UNIQUE,
    ExpiraEm DATETIME2 NOT NULL,
    CriadoEm DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME()

      CONSTRAINT PK_tokenID PRIMARY KEY CLUSTERED (TokenId)
  );
END;
  CREATE INDEX IDX_Tokens_ExpiraEm ON dbo.Tokens(ExpiraEm);

------------------------------------------------------------
-- function: validar Token
------------------------------------------------------------
GO
CREATE OR ALTER FUNCTION dbo.fn_ValidarToken(@Token NVARCHAR(200))
RETURNS BIT
AS
BEGIN
  DECLARE @ok BIT = 0;
  IF EXISTS (
    SELECT 1 FROM Tokens WITH (NOLOCK)
     WHERE Token = @Token AND ExpiraEm > SYSUTCDATETIME()
  )
    SET @ok = 1;
  RETURN @ok;
END;
GO

------------------------------------------------------------
-- procedures CRUD produtos
------------------------------------------------------------
GO
CREATE OR ALTER PROCEDURE dbo.PS_CriarProdutos
  @Nome NVARCHAR(255),
  @Preco DECIMAL(10,2)
AS
BEGIN
  SET NOCOUNT ON;
  INSERT INTO Produtos (Nome, Preco)
  VALUES (@Nome, @Preco);

  SELECT SCOPE_IDENTITY() AS NovoId;
END;
GO

CREATE OR ALTER PROCEDURE dbo.PS_AlterarProdutos
  @Id INT,
  @Nome NVARCHAR(255),
  @Preco DECIMAL(10,2)
AS
BEGIN
  SET NOCOUNT ON;
  UPDATE Produtos SET Nome=@Nome, Preco=@Preco WHERE Id=@Id;
END;
GO

CREATE OR ALTER PROCEDURE dbo.PS_ExcluirProdutos
  @Id INT
AS
BEGIN
  SET NOCOUNT ON;
  DELETE FROM Produtos WHERE Id=@Id;
END;
GO

CREATE OR ALTER PROCEDURE dbo.PS_ConsultarProdutos
  @Id       INT = NULL,
  @Nome     NVARCHAR(255) = NULL,
  @PrecoMin DECIMAL(10,2) = NULL,
  @PrecoMax DECIMAL(10,2) = NULL,
  @Pagina   INT = 1,
  @Tamanho  INT = 20
AS
BEGIN
  SET NOCOUNT ON;

  IF @Pagina  IS NULL OR @Pagina  < 1 SET @Pagina  = 1;
  IF @Tamanho IS NULL OR @Tamanho < 1 SET @Tamanho = 20;

  DECLARE @Offset INT = (@Pagina - 1) * @Tamanho;

  IF @Id IS NOT NULL
  BEGIN
    SELECT Id, Nome, Preco
    FROM Produtos
    WHERE Id = @Id;
    RETURN;
  END

  ;WITH FiltroTotal AS (
    SELECT 1 AS One
    FROM Produtos
    WHERE (@Nome     IS NULL OR Nome  LIKE '%' + @Nome + '%')
      AND (@PrecoMin IS NULL OR Preco >= @PrecoMin)
      AND (@PrecoMax IS NULL OR Preco <= @PrecoMax)
  )
  SELECT COUNT(1) AS Total
  FROM FiltroTotal;

  ;WITH FiltroDados AS (
    SELECT Id, Nome, Preco
    FROM Produtos
    WHERE (@Nome     IS NULL OR Nome  LIKE '%' + @Nome + '%')
      AND (@PrecoMin IS NULL OR Preco >= @PrecoMin)
      AND (@PrecoMax IS NULL OR Preco <= @PrecoMax)
  )
  SELECT Id, Nome, Preco
  FROM FiltroDados
  ORDER BY Id

  OFFSET @Offset ROWS FETCH NEXT @Tamanho ROWS ONLY;
END;
GO

------------------------------------------------------------
-- triggers de log
------------------------------------------------------------
GO
CREATE OR ALTER TRIGGER dbo.TR_ProdutoINS_Log
ON dbo.Produtos
AFTER INSERT
AS
BEGIN
  SET NOCOUNT ON;
  INSERT INTO ProdutosLog(ProdutoId, Operacao, nomeAntigo, precoAntigo, nomeNovo, precoNovo, dataLog, usuarioLogin)
  SELECT i.Id, 'INSERT', NULL, NULL, i.Nome, i.Preco, SYSUTCDATETIME(),
         ISNULL(CONVERT(NVARCHAR(256), SESSION_CONTEXT(N'AppUser')), SUSER_SNAME())
  FROM inserted i;
END;
GO

CREATE OR ALTER TRIGGER dbo.TR_ProdutoUPD_Log
ON dbo.Produtos
AFTER UPDATE
AS
BEGIN
  SET NOCOUNT ON;
  INSERT INTO ProdutosLog (ProdutoId, Operacao, nomeAntigo, precoAntigo, nomeNovo, precoNovo, dataLog, usuarioLogin)
    SELECT d.Id,
           'UPDATE',
           d.Nome,
           d.Preco,       
           i.Nome,
           i.Preco,
           getdate(),
           suser_sname()
    FROM deleted d
    JOIN inserted i ON d.Id = i.Id;
END;
GO

CREATE OR ALTER TRIGGER dbo.TR_ProdutoDEL_Log
ON dbo.Produtos
AFTER DELETE
AS
BEGIN
  SET NOCOUNT ON;
  INSERT INTO ProdutosLog (ProdutoId, Operacao, nomeAntigo, precoAntigo, dataLog, usuarioLogin)
    SELECT d.Id,
           'DELETE',
           d.Nome,
           d.Preco,
           getdate(),
           suser_sname()
    FROM deleted d;
END;
GO

------------------------------------------------------------
-- seeds
------------------------------------------------------------
IF NOT EXISTS (SELECT 1 FROM Usuarios)
BEGIN
  INSERT INTO Usuarios(Nome, Email, Senha)
  VALUES ('Admin', 'admin@local.com', 'admin'); 
END;

IF NOT EXISTS (SELECT 1 FROM Produtos)
BEGIN
  INSERT INTO Produtos(Nome, Preco) VALUES
  (N'camiseta insider preta', 79.90),
  (N'camiseta insider azul',  69.90),
  (N'camiseta insider tech premium',99.90),
  (N'camiseta insider vinho', 59.90);
END;

