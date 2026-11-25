-- =============================================================================
-- 04 - TRIGGERS
-- =============================================================================

-- Auditoria: registra INSERT, UPDATE e DELETE das tabelas principais.
CREATE OR REPLACE FUNCTION log_auditoria_func()
RETURNS TRIGGER
LANGUAGE plpgsql AS $$
BEGIN
    INSERT INTO log_auditoria (tabela_afetada, acao, registro_id, usuario_responsavel)
    VALUES (TG_TABLE_NAME,
            TG_OP,
            CASE WHEN TG_OP = 'DELETE' THEN OLD.id ELSE NEW.id END,
            current_user);
    RETURN NULL; -- trigger AFTER: o valor de retorno é ignorado
END;
$$;

CREATE TRIGGER trg_auditoria_usuarios
AFTER INSERT OR UPDATE OR DELETE ON usuarios
FOR EACH ROW EXECUTE FUNCTION log_auditoria_func();

CREATE TRIGGER trg_auditoria_livros
AFTER INSERT OR UPDATE OR DELETE ON livros
FOR EACH ROW EXECUTE FUNCTION log_auditoria_func();

CREATE TRIGGER trg_auditoria_emprestimos
AFTER INSERT OR UPDATE OR DELETE ON emprestimos
FOR EACH ROW EXECUTE FUNCTION log_auditoria_func();


-- Estoque (duas tabelas): ao emprestar, confere e baixa um exemplar.
-- Roda ANTES do insert, então um livro sem exemplar livre bloqueia o empréstimo.
CREATE OR REPLACE FUNCTION baixar_estoque()
RETURNS TRIGGER
LANGUAGE plpgsql AS $$
BEGIN
    IF NEW.data_devolucao_real IS NULL THEN
        PERFORM verificar_disponibilidade(NEW.livro_id);
        UPDATE livros
           SET quantidade_disponivel = quantidade_disponivel - 1
         WHERE id = NEW.livro_id;
    END IF;
    RETURN NEW;
END;
$$;

CREATE TRIGGER trg_baixar_estoque
BEFORE INSERT ON emprestimos
FOR EACH ROW EXECUTE FUNCTION baixar_estoque();


-- Devolução: quando a data de devolução é preenchida, finaliza o empréstimo
-- e devolve o exemplar ao estoque.
CREATE OR REPLACE FUNCTION registrar_devolucao()
RETURNS TRIGGER
LANGUAGE plpgsql AS $$
BEGIN
    IF NEW.data_devolucao_real IS NOT NULL AND OLD.data_devolucao_real IS NULL THEN
        NEW.status := 'finalizado';
        UPDATE livros
           SET quantidade_disponivel = quantidade_disponivel + 1
         WHERE id = NEW.livro_id;
    END IF;
    RETURN NEW;
END;
$$;

CREATE TRIGGER trg_registrar_devolucao
BEFORE UPDATE OF data_devolucao_real ON emprestimos
FOR EACH ROW EXECUTE FUNCTION registrar_devolucao();


-- Regra de negócio: não deixa excluir usuário com livro ainda não devolvido
-- (status 'ativo' OU 'atrasado').
CREATE OR REPLACE FUNCTION bloquear_exclusao_usuario()
RETURNS TRIGGER
LANGUAGE plpgsql AS $$
BEGIN
    IF EXISTS (SELECT 1
                 FROM emprestimos
                WHERE usuario_id = OLD.id
                  AND data_devolucao_real IS NULL) THEN
        RAISE EXCEPTION 'Usuário % possui empréstimos em aberto e não pode ser excluído.', OLD.id;
    END IF;
    RETURN OLD;
END;
$$;

CREATE TRIGGER trg_bloquear_exclusao_usuario
BEFORE DELETE ON usuarios
FOR EACH ROW EXECUTE FUNCTION bloquear_exclusao_usuario();
