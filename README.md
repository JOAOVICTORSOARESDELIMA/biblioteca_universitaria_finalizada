[![Testes do banco](https://github.com/JOAOVICTORSOARESDELIMA/biblioteca_universitaria_finalizada/actions/workflows/testes.yml/badge.svg?branch=master)](https://github.com/JOAOVICTORSOARESDELIMA/biblioteca_universitaria_finalizada/actions/workflows/testes.yml)

# Sistema de Biblioteca Universitária: PostgreSQL

Projeto final da disciplina de **Banco de Dados Avançado** do curso de Sistemas para Internet (UNIESP, 3º período, prof. Aramis).

O objetivo foi construir o banco de uma biblioteca universitária usando recursos avançados de SQL (**subconsultas, joins, procedures, functions, triggers e índices**) para garantir automação, integridade e desempenho.

![Diagrama entidade-relacionamento](docs/diagrama_ER.png)

## O que o banco faz

- Cadastra **usuários** (alunos, professores e funcionários), **livros**, **empréstimos**, **reservas** e **multas**
- **Controla o estoque sozinho:** emprestar baixa um exemplar e devolver repõe. Livro esgotado não pode ser emprestado.
- **Gera multa automática** de R$ 1,00 por dia de atraso na devolução
- **Bloqueia** empréstimo para quem tem multa pendente e exclusão de usuário com livro não devolvido
- **Auditoria:** todo INSERT, UPDATE e DELETE em usuários, livros e empréstimos fica registrado em `log_auditoria`

## Estrutura

```
scripts/            # criam o banco, nesta ordem
├── 01_tabelas.sql      tabelas, chaves e restrições (CHECK, UNIQUE, FK)
├── 02_funcoes.sql      calcular_total_multas, listar_livros_usuario,
│                       verificar_disponibilidade, buscar_usuarios
├── 03_procedures.sql   atualizar_status_emprestimos (cursor), realizar_emprestimo,
│                       devolver_livro, registrar_reserva
├── 04_triggers.sql     auditoria, baixa/reposição de estoque, bloqueio de exclusão
├── 05_indices.sql      índices em FKs, composto e parcial
└── 06_dados.sql        dados de exemplo
consultas/
├── subconsultas.sql    5 subconsultas (FROM, SELECT correlacionada, EXISTS, IN, ALL)
├── joins.sql           INNER, LEFT, RIGHT, FULL OUTER, tabela derivada, relatório de multas
└── explain.sql         comparação de desempenho com e sem índice
testes/testes.sql       testes automatizados das regras do banco
executar_tudo.sql       roda todos os scripts de uma vez
docs/                   diagrama ER e relatório do projeto (PDF)
```

## Como executar

### Com Docker (mais fácil)

```bash
docker compose up -d
docker compose exec db psql -U postgres -d biblioteca                     # abre o banco
docker compose exec db psql -U postgres -d biblioteca -f /testes/testes.sql
```

### Com PostgreSQL instalado

```bash
createdb biblioteca
psql -d biblioteca -f executar_tudo.sql
psql -d biblioteca -f testes/testes.sql
```

## Exemplos de uso

```sql
CALL realizar_emprestimo(4, 2);         -- usuário 4 pega o livro 2 por 14 dias
CALL devolver_livro(5);                 -- devolve; se atrasou, gera a multa
CALL atualizar_status_emprestimos();    -- marca os vencidos como 'atrasado'

SELECT calcular_total_multas(3);        -- 10.50
SELECT * FROM listar_livros_usuario(1);
SELECT * FROM buscar_usuarios('aluno', 'joão');
```

## Testes

`testes/testes.sql` confere **11 regras** com `ASSERT`, entre elas: estoque após empréstimo e devolução, cálculo da multa, livro esgotado recusado, usuário com multa bloqueado, exclusão bloqueada, auditoria e reserva duplicada. Tudo roda dentro de uma transação desfeita no final, sem alterar os dados. O GitHub Actions cria o banco do zero e roda os testes a cada push.

## Desempenho

O `consultas/explain.sql` gera 100 mil empréstimos de teste e compara a busca de empréstimos em aberto e vencidos:

| | Plano | Tempo |
|---|---|---|
| Sem índice | Seq Scan (lê a tabela inteira) | ~5,1 ms |
| Com índice parcial | Bitmap Index Scan | ~0,2 ms |

Ficou cerca de **20 vezes mais rápido**. O índice é **parcial** (só guarda os empréstimos em aberto), então fica pequeno mesmo com muito histórico.

## O que mudou em relação à versão entregue

| Antes | Agora |
|---|---|
| Empréstimos de exemplo inseridos antes dos triggers, com estoque inconsistente (5 disponíveis com 1 emprestado) | Triggers criados antes dos dados, e o estoque fica sempre correto |
| Empréstimo de livro esgotado era aceito (estoque podia ficar negativo) | O trigger confere a disponibilidade antes, e um `CHECK` impede estoque negativo |
| Usuário com empréstimo **atrasado** podia ser excluído | O bloqueio considera qualquer livro não devolvido |
| Devolução não mudava o status do empréstimo | Muda para `finalizado` automaticamente |
| `buscar_usuarios` era procedure com `PERFORM` (descartava o resultado) | Virou função que retorna os usuários filtrados |
| Índices duplicados em `email` e `isbn` (o `UNIQUE` já cria índice) | Índices nas chaves estrangeiras, que o PostgreSQL não cria sozinho, e um índice parcial |
| `EXPLAIN` "sem índice" rodava depois de criar o índice | Comparação real, com volume de dados suficiente |
| Scripts misturavam criação, testes e consultas, e um deles terminava com erro proposital | Criação, consultas e testes separados, com testes automatizados |
| Novas procedures | `realizar_emprestimo` e `devolver_livro`, esta com multa automática |

## Equipe (Grupo 4)

- Lucas Accioly
- Maria Eduarda Maia
- **João Victor Soares de Lima**: [GitHub](https://github.com/JOAOVICTORSOARESDELIMA)
