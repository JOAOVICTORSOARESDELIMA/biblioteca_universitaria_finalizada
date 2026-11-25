-- =============================================================================
-- SUBCONSULTAS
-- =============================================================================

-- 1. Média de empréstimos por usuário (subconsulta no FROM)
SELECT ROUND(AVG(total_emprestimos), 2) AS media_emprestimos
  FROM (SELECT usuario_id, COUNT(*) AS total_emprestimos
          FROM emprestimos
         GROUP BY usuario_id) AS por_usuario;

-- 2. Total de empréstimos de cada livro (subconsulta correlacionada no SELECT)
SELECT l.titulo,
       (SELECT COUNT(*) FROM emprestimos e WHERE e.livro_id = l.id) AS total_emprestimos
  FROM livros l
 ORDER BY total_emprestimos DESC, l.titulo;

-- 3. Livros que nunca foram emprestados (NOT EXISTS)
SELECT l.titulo
  FROM livros l
 WHERE NOT EXISTS (SELECT 1 FROM emprestimos e WHERE e.livro_id = l.id);

-- 4. Usuários com livro ainda não devolvido (IN)
SELECT nome
  FROM usuarios
 WHERE id IN (SELECT usuario_id FROM emprestimos WHERE data_devolucao_real IS NULL)
 ORDER BY nome;

-- 5. Livro(s) mais emprestado(s), considerando empates (subconsulta com ALL)
SELECT l.titulo, l.autor, COUNT(*) AS total
  FROM livros l
  JOIN emprestimos e ON e.livro_id = l.id
 GROUP BY l.id
HAVING COUNT(*) >= ALL (SELECT COUNT(*) FROM emprestimos GROUP BY livro_id);
