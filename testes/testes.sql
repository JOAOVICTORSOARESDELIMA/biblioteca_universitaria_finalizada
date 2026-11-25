-- =============================================================================
-- TESTES AUTOMATIZADOS
-- Cada bloco confere uma regra com ASSERT. Se algo falhar, o script para com erro.
-- Tudo roda dentro de uma transação desfeita no final: o banco não muda.
-- =============================================================================
\set ON_ERROR_STOP on
BEGIN;

-- Dados de exemplo: os empréstimos em aberto já baixaram o estoque
DO $$
BEGIN
    ASSERT (SELECT quantidade_disponivel FROM livros WHERE id = 1) = 4, 'estoque do livro 1 deveria ser 4';
    ASSERT (SELECT quantidade_disponivel FROM livros WHERE id = 3) = 7, 'estoque do livro 3 deveria ser 7';
    RAISE NOTICE 'OK - seed consistente com o estoque';
END $$;

-- Funções
DO $$
BEGIN
    ASSERT calcular_total_multas(3) = 10.50, 'multa pendente do usuário 3';
    ASSERT calcular_total_multas(1) = 0, 'usuário 1 sem multas';
    ASSERT (SELECT COUNT(*) FROM listar_livros_usuario(1)) = 1, 'livros do usuário 1';
    ASSERT (SELECT COUNT(*) FROM buscar_usuarios('aluno')) = 2, 'filtro por tipo';
    ASSERT (SELECT COUNT(*) FROM buscar_usuarios(nome_filtro => 'joão')) = 1, 'filtro por nome (sem diferenciar maiúsculas)';
    ASSERT (SELECT COUNT(*) FROM buscar_usuarios()) = 4, 'sem filtro';
    RAISE NOTICE 'OK - funções';
END $$;

-- verificar_disponibilidade lança erro para livro inexistente
DO $$
BEGIN
    PERFORM verificar_disponibilidade(999);
    RAISE EXCEPTION 'deveria ter falhado';
EXCEPTION WHEN raise_exception THEN
    ASSERT SQLERRM LIKE '%não encontrado%', SQLERRM;
    RAISE NOTICE 'OK - livro inexistente recusado';
END $$;

-- Empréstimo baixa o estoque, devolução atrasada gera multa e repõe o estoque
DO $$
DECLARE
    id_emp INT;
BEGIN
    CALL realizar_emprestimo(4, 2, 7);
    SELECT MAX(id) INTO id_emp FROM emprestimos;
    ASSERT (SELECT quantidade_disponivel FROM livros WHERE id = 2) = 1, 'estoque após empréstimo';

    CALL devolver_livro(id_emp, CURRENT_DATE + 10); -- 3 dias de atraso
    ASSERT (SELECT status FROM emprestimos WHERE id = id_emp) = 'finalizado', 'status após devolução';
    ASSERT (SELECT quantidade_disponivel FROM livros WHERE id = 2) = 2, 'estoque após devolução';
    ASSERT (SELECT valor FROM multas WHERE emprestimo_id = id_emp) = 3.00, 'multa de R$ 1 por dia';
    RAISE NOTICE 'OK - empréstimo, devolução e multa';
END $$;

-- Não empresta livro sem exemplar disponível
DO $$
BEGIN
    UPDATE livros SET quantidade_disponivel = 0 WHERE id = 3;
    INSERT INTO emprestimos (usuario_id, livro_id, data_devolucao_prevista) VALUES (1, 3, CURRENT_DATE + 7);
    RAISE EXCEPTION 'deveria ter falhado';
EXCEPTION WHEN raise_exception THEN
    ASSERT SQLERRM LIKE '%indisponível%', SQLERRM;
    RAISE NOTICE 'OK - livro esgotado não é emprestado';
END $$;

-- Usuário com multa pendente não pega livro
DO $$
BEGIN
    CALL realizar_emprestimo(3, 1);
    RAISE EXCEPTION 'deveria ter falhado';
EXCEPTION WHEN raise_exception THEN
    ASSERT SQLERRM LIKE '%multas pendentes%', SQLERRM;
    RAISE NOTICE 'OK - usuário com multa bloqueado';
END $$;

-- Procedure com cursor marca atrasados
DO $$
BEGIN
    CALL atualizar_status_emprestimos();
    ASSERT NOT EXISTS (SELECT 1 FROM emprestimos
                        WHERE status = 'ativo' AND data_devolucao_real IS NULL
                          AND data_devolucao_prevista < CURRENT_DATE), 'ainda há atrasados como ativo';
    RAISE NOTICE 'OK - atrasados marcados';
END $$;

-- Usuário com empréstimo em aberto (mesmo 'atrasado') não pode ser excluído
DO $$
BEGIN
    DELETE FROM usuarios WHERE id = 1;
    RAISE EXCEPTION 'deveria ter falhado';
EXCEPTION WHEN raise_exception THEN
    ASSERT SQLERRM LIKE '%empréstimos em aberto%', SQLERRM;
    RAISE NOTICE 'OK - exclusão bloqueada';
END $$;

-- Usuário sem pendências pode ser excluído, e a auditoria registra
DO $$
DECLARE
    novo INT;
BEGIN
    INSERT INTO usuarios (nome, email, tipo) VALUES ('Teste', 'teste@x.com', 'aluno') RETURNING id INTO novo;
    UPDATE usuarios SET nome = 'Teste 2' WHERE id = novo;
    DELETE FROM usuarios WHERE id = novo;
    ASSERT (SELECT COUNT(*) FROM log_auditoria WHERE tabela_afetada = 'usuarios' AND registro_id = novo) = 3,
           'auditoria deveria ter INSERT, UPDATE e DELETE';
    RAISE NOTICE 'OK - auditoria';
END $$;

-- Reserva duplicada é recusada
DO $$
BEGIN
    CALL registrar_reserva(1, 3);
    RAISE EXCEPTION 'deveria ter falhado';
EXCEPTION WHEN raise_exception THEN
    ASSERT SQLERRM LIKE '%já tem uma reserva%', SQLERRM;
    RAISE NOTICE 'OK - reserva duplicada recusada';
END $$;

ROLLBACK;
\echo 'Todos os testes passaram.'
