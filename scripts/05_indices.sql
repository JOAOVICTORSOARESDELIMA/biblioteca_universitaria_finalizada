-- =============================================================================
-- 05 - ÍNDICES
--
-- Observação: email (usuarios) e isbn (livros) já têm índice automático por
-- causa do UNIQUE. Criar outro índice nessas colunas só gastaria espaço e
-- deixaria as escritas mais lentas.
-- =============================================================================

-- Chaves estrangeiras: o PostgreSQL NÃO cria índice nelas automaticamente.
-- Aceleram os JOINs e as verificações de integridade.
CREATE INDEX idx_emprestimos_livro      ON emprestimos (livro_id);
CREATE INDEX idx_reservas_usuario       ON reservas (usuario_id);
CREATE INDEX idx_reservas_livro         ON reservas (livro_id);
CREATE INDEX idx_multas_emprestimo      ON multas (emprestimo_id);

-- Composto: serve para buscas por usuário e por usuário + livro
-- (a coluna da esquerda funciona sozinha também).
CREATE INDEX idx_emprestimos_usuario_livro ON emprestimos (usuario_id, livro_id);

-- Parcial: só os empréstimos em aberto, usados pela procedure de atrasos.
-- Fica bem menor que um índice na tabela inteira.
CREATE INDEX idx_emprestimos_em_aberto
    ON emprestimos (data_devolucao_prevista)
    WHERE data_devolucao_real IS NULL;

CREATE INDEX idx_emprestimos_status ON emprestimos (status);
CREATE INDEX idx_reservas_status    ON reservas (status);
