-- =============================================================================
-- JOINS
-- =============================================================================

-- INNER JOIN: quem pegou qual livro e quando
SELECT u.nome, l.titulo, e.data_emprestimo, e.status
  FROM usuarios u
  JOIN emprestimos e ON e.usuario_id = u.id
  JOIN livros l      ON l.id = e.livro_id
 ORDER BY e.data_emprestimo;

-- LEFT JOIN: todos os usuários, mesmo os que nunca pegaram livro
SELECT u.nome, COUNT(e.id) AS total_emprestimos
  FROM usuarios u
  LEFT JOIN emprestimos e ON e.usuario_id = u.id
 GROUP BY u.id
 ORDER BY total_emprestimos DESC, u.nome;

-- RIGHT JOIN: todos os livros, com ou sem empréstimo
SELECT l.titulo, e.id AS emprestimo_id
  FROM emprestimos e
 RIGHT JOIN livros l ON l.id = e.livro_id
 ORDER BY l.titulo;

-- FULL OUTER JOIN: usuários sem reserva e reservas sem usuário correspondente
SELECT u.nome, r.id AS reserva_id, r.status
  FROM usuarios u
  FULL OUTER JOIN reservas r ON r.usuario_id = u.id
 ORDER BY u.nome NULLS LAST;

-- JOIN com tabela derivada: usuários com mais de um empréstimo
SELECT u.nome, sub.total
  FROM usuarios u
  JOIN (SELECT usuario_id, COUNT(*) AS total
          FROM emprestimos
         GROUP BY usuario_id
        HAVING COUNT(*) > 1) AS sub ON sub.usuario_id = u.id;

-- Relatório: multas pendentes com usuário e livro (4 tabelas)
SELECT u.nome, l.titulo, m.valor, e.data_devolucao_prevista
  FROM multas m
  JOIN emprestimos e ON e.id = m.emprestimo_id
  JOIN usuarios u    ON u.id = e.usuario_id
  JOIN livros l      ON l.id = e.livro_id
 WHERE m.status = 'pendente'
 ORDER BY m.valor DESC;
