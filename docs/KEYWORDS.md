# Klar — Keywords e símbolos

Referência rápida do vocabulário da linguagem. Estado em 7 de novembro de 2026.

Legenda: **Aprovado** = decidido · **Proposta** = direção sugerida, sem aval formal · **Provisório** = usado nos exemplos, design ainda em aberto.

---

## Keywords

### Declarações

| Keyword | Uso | Status |
| --- | --- | --- |
| `fn` | Declara função: `fn nome[caps](params) Tipo { ... }` | Aprovado |
| `const` | Variável imutável | Aprovado |
| `var` | Variável mutável; também marca ponteiro mutável (`*var T`) | Aprovado |
| `return` | Retorna de uma função | Aprovado |
| `struct` | Declara uma struct | Provisório |
| `type` | Tipo de um parâmetro de comptime (`#T: type`) | Aprovado |
| `module` | Declara um módulo | Provisório |

### Controle de fluxo

| Keyword | Uso | Status |
| --- | --- | --- |
| `if` | Condição inicial | Aprovado |
| `otherwise` | Condição alternativa (`else if`); também trata erro e nulo | Aprovado |
| `afterall` | Alternativa final (`else`), opcional, sempre com `{}`; braço padrão do `match` | Aprovado |
| `because` | Contexto em ramos, braços de `match` e erros; só texto constante na v1 | Aprovado |
| `match` | Casamento de padrões, exaustivo | Aprovado |

### Erros e recursos

| Keyword | Uso | Status |
| --- | --- | --- |
| `try` | Propaga o erro; só em função com `[fail]` | Aprovado |
| `error` | Valor de erro (`error.NotFound`) e padrão no `match` | Aprovado |
| `null` | Ausência de valor em `?T` e padrão no `match` | Aprovado |
| `as` | Dá nome ao erro capturado (`otherwise as err`) | Aprovado |
| `ensure` | Executa ao sair do bloco, sempre | Aprovado |

### Literais

| Keyword | Uso | Status |
| --- | --- | --- |
| `true`, `false` | Literais de `bool` | Provisório |

---

## Combinações

| Forma | Significado |
| --- | --- |
| `ensure x` | Roda ao sair do bloco, com sucesso ou erro |
| `ensure otherwise x` | Roda ao sair do bloco só se houver erro |
| `expr otherwise valor` | Fallback se `expr` falhar ou for nula (uma camada só) |
| `expr otherwise as err { ... }` | Trata o erro capturando-o |
| `expr otherwise { error as err => ..., null => ... }` | Forma explícita para erro e nulo juntos |
| `try expr because "..."` | Propaga adicionando contexto ao trace |
| `return error.X because "..."` | Cria o erro com contexto |

Regras: `ensure otherwise as err` é proibido. Usar `try` ou `otherwise` em algo que não pode falhar nem ser nulo é erro de compilação. Duas camadas com a forma curta do `otherwise` também.

---

## Capabilities

Nomes válidos dentro de `[ ]` logo após o nome da função. Função sem `[ ]` é pura.

| Capability | Significado | Status |
| --- | --- | --- |
| `alloc` | Aloca memória; sempre escrito, mesmo recebendo `Allocator` | Aprovado |
| `io` | Arquivo, rede, terminal | Aprovado |
| `block` | Pode parar esperando (lock, sleep, I/O síncrono) | Aprovado |
| `panic` | Aborta o programa de propósito | Aprovado |
| `fail` | Devolve erro; aceita lista: `[fail(NotFound, Denied)]` | Aprovado |
| `suspend` | Pode pausar a execução (async) | Proposta |
| nome de parâmetro | Herda as capabilities daquele callback (`[f]`) | Aprovado |

```klar
fn readConfig[io, fail](path: String) Config { ... }
fn map[alloc, f](#T: type, #U: type, alloc: Allocator, items: []T, f: fn(T) U) []U { ... }
```

---

## Símbolos e operadores

| Símbolo | Papel | Onde aparece | Status |
| --- | --- | --- | --- |
| `~>` | Encaminha o resultado para a próxima operação | Expressões | Aprovado |
| `-->` | Associa chave e descrição | Dentro de `@` | Aprovado |
| `=>` | Braço de `match` | `match` e forma explícita do `otherwise` | Aprovado |
| `[ ]` | Capabilities · arrays e slices · índice | Após o nome da função · tipos · expressões | Aprovado |
| `#` | Parâmetro avaliado em tempo de compilação | Generics | Aprovado |
| `@` | Atributo de documentação (nunca barra compilação) | Antes de declarações | Aprovado |
| `&` | Endereço de uma variável | Expressões | Aprovado |
| `.*` | Desreferência explícita | Ponteiros | Aprovado |
| `.` | Acesso a campo; nunca desreferencia sozinho | Expressões | Aprovado |
| `?` | Tipo opcional (`?T`, `?*T`) | Tipos | Aprovado |
| `!` | Somente o "não" booleano | Expressões | Aprovado |
| `:` | "Este nome tem este tipo" (parâmetros, campos, variáveis) | Declarações | Aprovado |
| `..` | Intervalo (`500..599`, `nums[0..2]`) | `match`, fatias | Provisório |
| `$"..."` | Prefixo de string usado nos exemplos | Literais | Em aberto |

Não existem `++` e `--`: use `x += 1`. O `:` não aparece antes do tipo de retorno.

---

## Tipos

| Forma | Significado | Status |
| --- | --- | --- |
| `*T` | Ponteiro para um item, só leitura, nunca nulo | Aprovado |
| `*var T` | Ponteiro para um item, leitura e escrita | Aprovado |
| `?*T` | Ponteiro que pode ser nulo | Aprovado |
| `?T` | Valor opcional | Aprovado |
| `[N]T` | Array de tamanho fixo | Aprovado |
| `[]T` | Slice: ponteiro mais tamanho | Aprovado |
| `[*]T` | Vários itens sem tamanho; só para interop com C | Aprovado |
| `fn[caps](T) U` | Tipo de função com capabilities | Aprovado |
| `i32`, `u8`, `u64`, `usize`, `bool`, `void` | Primitivos usados nos exemplos | Provisório |
| `String` | Usado nos exemplos, ainda não definido | Em aberto |

---

## Atributos

| Atributo | Uso | Status |
| --- | --- | --- |
| `@Glossary(nome --> "descrição", ...)` | Descreve campos e parâmetros | Conceito aprovado, sintaxe aberta |
| `@Purpose("...")` | Descreve a responsabilidade de um módulo | Proposta |
| `@Deprecated()` | Marca algo como obsoleto | Provisório |

---

## Convenção de nomes (padrão Zig)

| Elemento | Convenção | Exemplo |
| --- | --- | --- |
| Tipos | PascalCase | `User`, `DynamicList` |
| Funções | camelCase | `readConfig`, `tryGet` |
| Funções que retornam tipo | PascalCase | `DynamicList(T)` |
| Variáveis, campos, parâmetros | snake_case | `max_size` |
| Arquivos e módulos | snake_case | `auth_session` |

---

## Palavras que NÃO existem na Klar

Considerados e descartados. Não usar como keyword.

| Palavra | No lugar, use |
| --- | --- |
| `else` / `else if` | `afterall` / `otherwise` |
| `switch` | `match` |
| `catch`, `orelse` | `otherwise` |
| `defer` | `ensure` |
| `errdefer`, `rollback` | `ensure otherwise` |
| `effects`, `uses`, `does`, `@Uses` | capabilities em `[ ]` |
| `with` (para alocador) | alocador passado como valor |
| `synchronized` | `Mutex` como valor + `[block]` |
| `async` | capability `suspend` (proposta) |