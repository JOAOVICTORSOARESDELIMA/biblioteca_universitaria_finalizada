-- =============================================================================
-- 03 - PROCEDURES
-- =============================================================================

-- Com cursor: marca como 'atrasado' os empréstimos não devolvidos e vencidos.
CREATE OR REPLACE PROCEDURE atualizar_status_emprestimos()
LANGUAGE plpgsql AS $$
DECLARE
    cur_atrasados CURSOR FOR
        SELECT id
          FROM emprestimos
         WHERE data_devolucao_real IS NULL
           AND data_devolucao_prevista < CURRENT_DATE
           AND status = 'ativo'
           FOR UPDATE;
    quantidade INT := 0;
BEGIN
    FOR emp IN cur_atrasados LOOP
        UPDATE emprestimos SET status = 'atrasado' WHERE CURRENT OF cur_atrasados;
        quantidade := quantidade + 1;
    END LOOP;
    RAISE NOTICE '% empréstimo(s) marcado(s) como atrasado.', quantidade;
END;
$$;

-- Novo empréstimo com validação de disponibilidade e de multas pendentes.
-- A baixa no estoque é feita pelo trigger trg_baixar_estoque.
CREATE OR REPLACE PROCEDURE realizar_emprestimo(p_usuario_id INT, p_livro_id INT, p_dias INT DEFAULT 14)
LANGUAGE plpgsql AS $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM usuarios WHERE id = p_usuario_id) THEN
        RAISE EXCEPTION 'Usuário com ID % não encontrado.', p_usuario_id;
    END IF;
    IF calcular_total_multas(p_usuario_id) > 0 THEN
        RAISE EXCEPTION 'Usuário % possui multas pendentes.', p_usuario_id;
    END IF;

    INSERT INTO emprestimos (usuario_id, livro_id, data_emprestimo, data_devolucao_prevista)
    VALUES (p_usuario_id, p_livro_id, CURRENT_DATE, CURRENT_DATE + p_dias);
END;
$$;

-- Devolução: registra a data, e se houver atraso gera multa de R$ 1,00 por dia.
-- A volta do exemplar ao estoque e o status 'finalizado' ficam com o trigger.
CREATE OR REPLACE PROCEDURE devolver_livro(p_emprestimo_id INT, p_data DATE DEFAULT CURRENT_DATE)
LANGUAGE plpgsql AS $$
DECLARE
    prevista    DATE;
    devolvido   DATE;
    dias_atraso INT;
BEGIN
    SELECT data_devolucao_prevista, data_devolucao_real
      INTO prevista, devolvido
      FROM emprestimos
     WHERE id = p_emprestimo_id
       FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Empréstimo % não encontrado.', p_emprestimo_id;
    ELSIF devolvido IS NOT NULL THEN
        RAISE EXCEPTION 'Empréstimo % já foi devolvido em %.', p_emprestimo_id, devolvido;
    END IF;

    UPDATE emprestimos SET data_devolucao_real = p_data WHERE id = p_emprestimo_id;

    dias_atraso := p_data - prevista;
    IF dias_atraso > 0 THEN
        INSERT INTO multas (emprestimo_id, valor) VALUES (p_emprestimo_id, dias_atraso * 1.00);
        RAISE NOTICE 'Devolução com % dia(s) de atraso: multa de R$ %.', dias_atraso, dias_atraso * 1.00;
    END IF;
END;
$$;

-- Reserva: no máximo uma reserva ativa por usuário para o mesmo livro.
CREATE OR REPLACE PROCEDURE registrar_reserva(p_usuario_id INT, p_livro_id INT)
LANGUAGE plpgsql AS $$
BEGIN
    IF EXISTS (SELECT 1 FROM reservas
                WHERE usuario_id = p_usuario_id AND livro_id = p_livro_id AND status = 'ativo') THEN
        RAISE EXCEPTION 'O usuário % já tem uma reserva ativa para o livro %.', p_usuario_id, p_livro_id;
    END IF;

    INSERT INTO reservas (usuario_id, livro_id) VALUES (p_usuario_id, p_livro_id);
END;
$$;
