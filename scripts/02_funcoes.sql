-- =============================================================================
-- 02 - FUNÇÕES
-- =============================================================================

-- Escalar: total de multas PENDENTES de um usuário.
CREATE OR REPLACE FUNCTION calcular_total_multas(p_usuario_id INT)
RETURNS NUMERIC
LANGUAGE plpgsql STABLE AS $$
DECLARE
    total NUMERIC;
BEGIN
    SELECT SUM(m.valor)
      INTO total
      FROM multas m
      JOIN emprestimos e ON e.id = m.emprestimo_id
     WHERE e.usuario_id = p_usuario_id
       AND m.status = 'pendente';

    RETURN COALESCE(total, 0);
END;
$$;

-- Retorna tabela: livros emprestados por um usuário.
CREATE OR REPLACE FUNCTION listar_livros_usuario(p_usuario_id INT)
RETURNS TABLE (titulo VARCHAR, data_emprestimo DATE, status VARCHAR)
LANGUAGE plpgsql STABLE AS $$
BEGIN
    RETURN QUERY
    SELECT l.titulo, e.data_emprestimo, e.status
      FROM emprestimos e
      JOIN livros l ON l.id = e.livro_id
     WHERE e.usuario_id = p_usuario_id
     ORDER BY e.data_emprestimo DESC;
END;
$$;

-- Tratamento de erro: lança exceção se o livro não existe ou não tem exemplar livre.
CREATE OR REPLACE FUNCTION verificar_disponibilidade(p_livro_id INT)
RETURNS BOOLEAN
LANGUAGE plpgsql STABLE AS $$
DECLARE
    disponivel INT;
BEGIN
    SELECT quantidade_disponivel INTO disponivel FROM livros WHERE id = p_livro_id;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Livro com ID % não encontrado.', p_livro_id;
    ELSIF disponivel < 1 THEN
        RAISE EXCEPTION 'Livro com ID % está indisponível para empréstimo.', p_livro_id;
    END IF;

    RETURN TRUE;
END;
$$;

-- Busca com filtros opcionais (antes era uma procedure com PERFORM, que
-- descartava o resultado; como função, o resultado pode ser consultado).
CREATE OR REPLACE FUNCTION buscar_usuarios(tipo_filtro VARCHAR DEFAULT NULL,
                                           nome_filtro VARCHAR DEFAULT NULL)
RETURNS SETOF usuarios
LANGUAGE sql STABLE AS $$
    SELECT *
      FROM usuarios
     WHERE (tipo_filtro IS NULL OR tipo = tipo_filtro)
       AND (nome_filtro IS NULL OR nome ILIKE '%' || nome_filtro || '%')
     ORDER BY nome;
$$;
