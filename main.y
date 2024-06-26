%{
int yylex(void);
void yyerror(char* s);
#include <stdlib.h>
#include <stdio.h>
#include <string.h>


typedef enum {
  TIPO_NUMERO,
  TIPO_CADEIA
} tipoVariavel;

typedef struct Variavel {
  tipoVariavel tipo_variavel;
  char *nome;
  union {
    int numero;
    char *cadeia;
  } valor;
} variavel;

typedef struct No {
    variavel* variavel;
    char *nome;
    int qtdVariaveis;
    struct No* prox;
} no;

typedef struct Pilha{
    no* topo;
} pilha;

void iniciar_pilha();
void empilhar(char *nomeNo);
void desempilhar(char* nomeNo);
void imprimir_variavel(variavel var);
void remover_espacos(char *str);
no* procurar_variavel_em_pilha(pilha* p, char* nome);
tipoVariavel procurar_tipo_variavel_em_pilha(pilha *p, char* nome);
variavel* criar_variavel(no *atual, char *nome, tipoVariavel tipo, void *valor);

int encontrado = 0;
pilha* p;
%}

%token BLOCO_INICIO BLOCO_FIM 
%token TIPO_NUMERO TIPO_CADEIA
%token PRINT
%token MAIS IGUAL
%token TK_IDENTIFICADOR 
%token TK_CADEIA TK_NUMERO

%union 
{
	int numero;
  char* cadeia;
}
%%
entrada:
  linha
  | entrada linha
  ;

linha:
  inicio_escopo
  | fim_escopo
  | declaracao  ';'
  | atribuicao  ';'
  | impressao   ';'
  | 
  ;

inicio_escopo:
  BLOCO_INICIO{
    remover_espacos($1.cadeia);
    empilhar($1.cadeia);
  }
  ;

fim_escopo:
  BLOCO_FIM{
    remover_espacos($1.cadeia);
    desempilhar($1.cadeia);
  }
  ;

declaracao:
  TIPO_CADEIA declaracao_cadeia
  | TIPO_CADEIA declaracao_multipla_cadeia
  | TIPO_NUMERO declaracao_numero
  | TIPO_NUMERO declaracao_multipla_numero
  ;

declaracao_cadeia:
  TK_IDENTIFICADOR IGUAL TK_CADEIA {
    remover_espacos($1.cadeia);
    no* no_atual = procurar_variavel_em_pilha(p, $1.cadeia);
    if (no_atual == NULL) {
      criar_variavel(no_atual, $1.cadeia, TIPO_CADEIA, $3.cadeia);
    }else{
      printf("Variavel '%s' ja declarada\n", $1.cadeia);
    }
  }
  | TK_IDENTIFICADOR {
    remover_espacos($1.cadeia);
    printf("cheguei aqui");
    no* no_atual = procurar_variavel_em_pilha(p, $1.cadeia);
    if (no_atual == NULL) {
      criar_variavel(no_atual, $1.cadeia, TIPO_CADEIA, "");
    }else{
      printf("Variavel '%s' ja declarada\n", $1.cadeia);
    }
  }
  ;

declaracao_numero:
  TK_IDENTIFICADOR IGUAL TK_NUMERO {
    char *s1 = $1.cadeia;
    no* no_atual = procurar_variavel_em_pilha(p, s1);
    if (no_atual == NULL) {
      int* valor = (int*)malloc(sizeof(int));
      *valor = $3.numero;
      criar_variavel(no_atual, s1, TIPO_NUMERO, valor);
    }else{
      printf("Variavel '%s' ja declarada\n", s1);
    }
  }
  | TK_NUMERO {
    char *s1 = $1.cadeia;
    no* no_atual = procurar_variavel_em_pilha(p, s1);
    if (no_atual == NULL) {
      criar_variavel(no_atual, s1, TIPO_NUMERO, 0);
    }else{
      printf("Variavel '%s' ja declarada\n", s1);
    }
  }
  ;

declaracao_multipla_cadeia:
  declaracao_cadeia
  | declaracao_multipla_cadeia ',' declaracao_cadeia
  ;

declaracao_multipla_numero:
  declaracao_numero
  | declaracao_multipla_numero ',' declaracao_numero
  ;

atribuicao:
  TK_IDENTIFICADOR IGUAL TK_NUMERO {
    char *s1 = $1.cadeia;
    no* no_atual = procurar_variavel_em_pilha(p, s1);
    if (no_atual != NULL){
      for (int i = 0; i < no_atual->qtdVariaveis; i++){
        if (strcmp(no_atual->variavel[i].nome, s1) == 0){
          no_atual -> variavel[i].valor.numero = $3.numero;
        }
      }
    }
  }
  | TK_IDENTIFICADOR IGUAL TK_CADEIA {
    char *s1 = $1.cadeia;
    no* no_atual = procurar_variavel_em_pilha(p, s1);
    if (no_atual != NULL){
      for (int i = 0; i < no_atual -> qtdVariaveis; i++){
        if (strcmp(no_atual->variavel[i].nome, s1) == 0){
          no_atual->variavel[i].valor.cadeia = $3.cadeia;
        }
      }
    }
  }
  | TK_IDENTIFICADOR IGUAL TK_IDENTIFICADOR {
    char *s1 = $1.cadeia;
    char *s2 = $3.cadeia;
    no* no_atual_1 = procurar_variavel_em_pilha(p, s1);
    no* no_atual_2 = procurar_variavel_em_pilha(p, s2);
    if (no_atual_1 != NULL && no_atual_2 != NULL){
      tipoVariavel tipo_1, tipo_2;
      tipo_1 = procurar_tipo_variavel_em_pilha(p, s1);
      tipo_2 = procurar_tipo_variavel_em_pilha(p, s2);
      if (tipo_1 == tipo_2){
        for (int i = 0; i < no_atual_1 -> qtdVariaveis; i++){
          if (strcmp(no_atual_1 -> variavel[i].nome, s1) == 0){
            for (int j = 0; j < no_atual_2 -> qtdVariaveis; j++){
              if (strcmp(no_atual_2 -> variavel[j].nome, s2) == 0){
                no_atual_1 -> variavel[i].valor = no_atual_2 -> variavel[j].valor;
              }
            }
          }
        }
      }
    }
  }
  | TK_IDENTIFICADOR IGUAL expressao
  ;

expressao:
  termo
  | expressao MAIS termo {
    tipoVariavel tipo_1, tipo_2;
    tipo_1 = procurar_tipo_variavel_em_pilha(p, $1.cadeia);
    tipo_2 = procurar_tipo_variavel_em_pilha(p, $3.cadeia);
    if(tipo_1 == TIPO_NUMERO && tipo_2 == TIPO_NUMERO){
      $$.numero = $1.numero + $3.numero;
    }else if(tipo_1 == TIPO_CADEIA && tipo_2 == TIPO_CADEIA){
      char* nova_cadeia = malloc(strlen($1.cadeia) + strlen($3.cadeia) + 1);
      strcpy(nova_cadeia, $1.cadeia);
      strcat(nova_cadeia, $3.cadeia);
      $$.cadeia = nova_cadeia;
    }else{
      printf("Tipos incompativeis\n");
    }
  }
  ;

termo:
  TK_NUMERO
  | TK_CADEIA
  | TK_IDENTIFICADOR
  ;

impressao:
  PRINT TK_IDENTIFICADOR {
    no* no_atual;
    no_atual = procurar_variavel_em_pilha(p, $2.cadeia);
    for (int i = 0; i < no_atual->qtdVariaveis; i++){
      if(strcmp(no_atual->variavel[i].nome, $2.cadeia) == 0){
        imprimir_variavel(no_atual -> variavel[i]);
      }
    }
  }
  ;
%%


extern FILE *yyin;
int main() {
  iniciar_pilha();
	do { 
		yyparse(); 
	} while (!feof(yyin));
}

void yyerror(char *s) {
   fprintf(stderr, "erro: %s\n", s);
}

/* FUNCIONANDO */
void iniciar_pilha() {
  printf("Iniciando pilha\n");
  p = (pilha *)malloc(sizeof(pilha));
  if (p != NULL) {
      p->topo = NULL;
  }
  printf("Pilha iniciada\n");
}

/* FUNCIONANDO */
void empilhar(char *nomeNo) {
  printf("Empilhando %s\n", nomeNo);
  no *novo = (no *)malloc(sizeof(no));
  if (novo == NULL) {
    printf("Erro ao alocar memória.\n");
    exit(1);
  }

  char *inicio = strchr(nomeNo, '_');
  char *fim = strrchr(nomeNo, '_');
  if (inicio != NULL && fim != NULL && fim > inicio) {
    // Mantendo os underlines, então não adicionamos 1 ao início nem subtraímos 1 do tamanho
    size_t tamanho = fim - inicio + 1; // +1 para incluir o último '_'
    char *nomeExtraido = (char *)malloc(tamanho + 1); // +1 para o '\0'
    if (nomeExtraido) {
      strncpy(nomeExtraido, inicio, tamanho);
      nomeExtraido[tamanho] = '\0'; // Garantindo que a string é terminada corretamente
      novo->nome = nomeExtraido;
    } else {
      printf("Erro ao alocar memória para o nome.\n");
      free(novo);
      exit(1);
    }
  } else {
    // Se não encontrar os '_', use o nomeNo como fallback
    novo->nome = strdup(nomeNo);
  }

  // Supondo que a estrutura de pilha e a lógica de empilhamento já existam
  novo->prox = p->topo;
  p->topo = novo;
  printf("No %s empilhado\n", novo->nome);
}

void desempilhar(char* nomeNo){
  printf("Desempilhando %s\n", nomeNo);
  if (p -> topo == NULL){
    printf("Pilha vazia\n");
    return;
  }

  char *nomeParaComparar = nomeNo;
  char *nomeExtraido = NULL;

  char *inicio = strchr(nomeNo, '_');
  char *fim = strrchr(nomeNo, '_');
  if (inicio != NULL && fim != NULL && fim > inicio) {
    size_t tamanho = fim - inicio + 1;
    nomeExtraido = (char *)malloc(tamanho + 1);
    if (nomeExtraido) {
      strncpy(nomeExtraido, inicio, tamanho);
      nomeExtraido[tamanho] = '\0';
      nomeParaComparar = nomeExtraido;
    } else {
      printf("Erro ao alocar memória para o nome.\n");
      exit(1);
    }
  }

  no* atual = p -> topo;
  no* anterior = NULL;

  while (atual != NULL && strcmp(atual->variavel->nome, nomeParaComparar) != 0) {
    anterior = atual;
    atual = atual->prox;
  }

  if (atual == NULL) {
    printf("Nó com o nome '%s' não encontrado.\n", nomeParaComparar);
  } else {
    if (atual == p->topo) {
      p->topo = atual->prox;
    } else if (anterior != NULL) {
      anterior->prox = atual->prox;
    }
    free(atual);
  }

  if (nomeExtraido) {
    free(nomeExtraido);
  }
  
  printf("Desempilhando %s\n", nomeNo);
}

void imprimir_variavel(variavel var){
  if (var.tipo_variavel == TIPO_NUMERO){
    printf("%d\n", var.valor.numero);
  }else if (var.tipo_variavel == TIPO_CADEIA){
    printf("%s\n", var.valor.cadeia);
  }
}

/* FUNCIONANDO */
void remover_espacos(char *str) { 
  char *dest = str; 
  while (*str != '\0') { 
    if (*str != ' ') { 
      *dest++ = *str; 
    } 
    str++; 
  } 
  *dest = '\0'; 
}

no* procurar_variavel_em_pilha(pilha* p, char* nome){
  no* atual = p -> topo;
  while (atual != NULL){
    for (int i = 0; i < atual->qtdVariaveis; i++){
      if (strcmp(atual->variavel[i].nome, nome) == 0){
        return atual;
      }
    }
    atual = atual->prox;
  }
  return NULL;
}

tipoVariavel procurar_tipo_variavel_em_pilha(pilha *p, char* nome) {
  no* atual = p->topo;
  encontrado = 0;
  while (atual != NULL) {
    for (int i = 0; i < atual->qtdVariaveis; i++) {
      if (strcmp(atual->variavel[i].nome, nome) == 0) {
        encontrado = 1;
        return atual->variavel[i].tipo_variavel;
      }
    }
    atual = atual->prox;
  }
  return (tipoVariavel)0;
}

/* ESTA QUEBRANDO AQUI */
variavel* criar_variavel(no *atual, char *nome, tipoVariavel tipo, void *valor){
  printf("asdasdad");
  variavel *var = (variavel *)malloc(sizeof(variavel));
  if (!var) {
    printf("Falha ao alocar memória\n");
    return NULL;
  }
  var->nome = strdup(nome);
  if (!var->nome) {
    printf("Falha ao alocar memória para o nome\n");
    free(var);
    return NULL;
  }

  var->tipo_variavel = tipo;

  if(var->tipo_variavel == TIPO_NUMERO){
    var->valor.numero = *(int *)valor;
  }else if (var->tipo_variavel == TIPO_CADEIA){
    var->valor.cadeia = strdup((char *)valor);
    if (!var->valor.cadeia) {
      printf("Falha ao alocar memória para a cadeia\n");
      free(var->nome);
      free(var);
      return NULL;
    }
  }

  atual->variavel = realloc(atual->variavel, (atual->qtdVariaveis + 1) * sizeof(variavel*));
  if (!atual->variavel) {
    printf("Falha ao realocar memória\n");
    if (var->tipo_variavel == TIPO_CADEIA) {
      free(var->valor.cadeia);
    }
    free(var->nome);
    free(var);
    return NULL;
  }
  atual->variavel[atual->qtdVariaveis] = *var;
  atual->qtdVariaveis++;
  return var;
}
