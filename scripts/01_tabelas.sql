-- =============================================================================
-- 01 - TABELAS
-- Sistema de Biblioteca Universitária (PostgreSQL)
-- =============================================================================

CREATE TABLE usuarios (
    id            SERIAL PRIMARY KEY,
    nome          VARCHAR(100) NOT NULL,
    email         VARCHAR(100) NOT NULL UNIQUE,
    tipo          VARCHAR(20)  NOT NULL CHECK (tipo IN ('aluno', 'professor', 'funcionario')),
    data_cadastro DATE         NOT NULL DEFAULT CURRENT_DATE
);

CREATE TABLE livros (
    id                    SERIAL PRIMARY KEY,
    titulo                VARCHAR(200) NOT NULL,
    autor                 VARCHAR(100) NOT NULL,
    isbn                  VARCHAR(20)  UNIQUE,
    ano_publicacao        INT CHECK (ano_publicacao BETWEEN 1450 AND 2100),
    editora               VARCHAR(100),
    quantidade_total      INT NOT NULL CHECK (quantidade_total >= 0),
    quantidade_disponivel INT NOT NULL CHECK (quantidade_disponivel >= 0),
    CHECK (quantidade_disponivel <= quantidade_total)
);

CREATE TABLE emprestimos (
    id                      SERIAL PRIMARY KEY,
    usuario_id              INT  NOT NULL REFERENCES usuarios (id),
    livro_id                INT  NOT NULL REFERENCES livros (id),
    data_emprestimo         DATE NOT NULL DEFAULT CURRENT_DATE,
    data_devolucao_prevista DATE NOT NULL,
    data_devolucao_real     DATE,
    status                  VARCHAR(20) NOT NULL DEFAULT 'ativo'
                            CHECK (status IN ('ativo', 'finalizado', 'atrasado')),
    CHECK (data_devolucao_prevista >= data_emprestimo),
    CHECK (data_devolucao_real IS NULL OR data_devolucao_real >= data_emprestimo)
);

CREATE TABLE reservas (
    id           SERIAL PRIMARY KEY,
    usuario_id   INT NOT NULL REFERENCES usuarios (id),
    livro_id     INT NOT NULL REFERENCES livros (id),
    data_reserva TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    status       VARCHAR(20) NOT NULL DEFAULT 'ativo'
                 CHECK (status IN ('ativo', 'cancelado', 'finalizado'))
);

CREATE TABLE multas (
    id             SERIAL PRIMARY KEY,
    emprestimo_id  INT NOT NULL REFERENCES emprestimos (id),
    valor          NUMERIC(10, 2) NOT NULL CHECK (valor > 0),
    data_pagamento DATE,
    status         VARCHAR(20) NOT NULL DEFAULT 'pendente' CHECK (status IN ('pendente', 'pago'))
);

CREATE TABLE log_auditoria (
    id                  SERIAL PRIMARY KEY,
    tabela_afetada      VARCHAR(50) NOT NULL,
    acao                VARCHAR(10) NOT NULL CHECK (acao IN ('INSERT', 'UPDATE', 'DELETE')),
    registro_id         INT NOT NULL,
    data_hora           TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    usuario_responsavel VARCHAR(100)
);
