-- Cria todo o banco a partir do zero. Uso, a partir da pasta do projeto:
--   createdb biblioteca
--   psql -d biblioteca -f executar_tudo.sql
\set ON_ERROR_STOP on
\i scripts/01_tabelas.sql
\i scripts/02_funcoes.sql
\i scripts/03_procedures.sql
\i scripts/04_triggers.sql
\i scripts/05_indices.sql
\i scripts/06_dados.sql
\echo 'Banco criado com sucesso.'
