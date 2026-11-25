-- =============================================================================
-- COMPARAÇÃO DE DESEMPENHO COM EXPLAIN ANALYZE
--
-- Com só 4 linhas, o PostgreSQL prefere ler a tabela inteira (Seq Scan) mesmo
-- com índice, porque é mais rápido. Por isso este script cria 100 mil
-- empréstimos fictícios dentro de uma transação que é desfeita no final.
-- =============================================================================
BEGIN;

ALTER TABLE emprestimos DISABLE TRIGGER USER; -- não mexe no estoque nem na auditoria

INSERT INTO emprestimos (usuario_id, livro_id, data_emprestimo, data_devolucao_prevista, data_devolucao_real, status)
SELECT 1 + (g % 4), 1 + (g % 4),
       DATE '2024-01-01' + (g % 500),
       DATE '2024-01-15' + (g % 500),
       CASE WHEN g % 50 = 0 THEN NULL ELSE DATE '2024-01-10' + (g % 500) END,
       CASE WHEN g % 50 = 0 THEN 'ativo' ELSE 'finalizado' END
  FROM generate_series(1, 100000) AS g;
ANALYZE emprestimos;

-- SEM o índice parcial
DROP INDEX idx_emprestimos_em_aberto;
EXPLAIN ANALYZE
SELECT * FROM emprestimos
 WHERE data_devolucao_real IS NULL AND data_devolucao_prevista < DATE '2024-03-01';

-- COM o índice parcial
CREATE INDEX idx_emprestimos_em_aberto ON emprestimos (data_devolucao_prevista)
 WHERE data_devolucao_real IS NULL;
ANALYZE emprestimos;
EXPLAIN ANALYZE
SELECT * FROM emprestimos
 WHERE data_devolucao_real IS NULL AND data_devolucao_prevista < DATE '2024-03-01';

ROLLBACK;
