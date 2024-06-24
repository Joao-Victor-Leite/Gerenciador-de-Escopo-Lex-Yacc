%{
int yylex(void);
void yyerror(char* s);
#include <stdlib.h>
#include <stdio.h>
#include <string.h>

/* 
VERIFICAR SE A LOGICA DA CRIACAO DOS NOS TA CERTA
RESOLVER A AMBIGUIDADE DA GRAMATICA
*/

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

void iniciar_pilha(pilha *p);
void empilhar(pilha *p, char *nomeNo);
void desempilhar(pilha* p, char* nomeNo);
void imprimir_variavel(variavel var);
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
    printf("BLOCO_INICIO\n");
    empilhar(p, $1.cadeia);
  }
  ;

fim_escopo:
  BLOCO_FIM{
    printf("BLOCO_FIM\n");
    desempilhar(p, $1.cadeia);
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
    char *s1 = $1.cadeia;
    no* no_atual = procurar_variavel_em_pilha(p, s1);
    if (no_atual == NULL) {
      criar_variavel(no_atual, s1, TIPO_CADEIA, $3.cadeia);
    }else{
      printf("Variavel '%s' ja declarada\n", s1);
    }
  }
  | TK_IDENTIFICADOR {
    char *s1 = $1.cadeia;
    no* no_atual = procurar_variavel_em_pilha(p, s1);
    if (no_atual == NULL) {
      criar_variavel(no_atual, s1, TIPO_CADEIA, "");
    }else{
      printf("Variavel '%s' ja declarada\n", s1);
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
  iniciar_pilha(p);
	do { 
		yyparse(); 
	} while (!feof(yyin));
}

void yyerror(char *s) {
   fprintf(stderr, "erro: %s\n", s);
}

void iniciar_pilha(pilha *p) {
  p = (pilha *)malloc(sizeof(pilha));
  p -> topo = NULL;
}

void empilhar(pilha *p, char *nomeNo) {
  no *novo = (no *)malloc(sizeof(no));
  if (novo == NULL) {
    printf("Erro ao alocar memória.\n");
    exit(1);
  }

  novo->nome = strdup(nomeNo);
  novo->prox = p->topo;
  p->topo = novo;
}

void desempilhar(pilha* p, char* nomeNo){
  if (p -> topo == NULL){
    printf("Pilha vazia\n");
    return;
  }

  no* atual = p -> topo;
  no* anterior = NULL;

  while (atual != NULL && strcmp(atual->variavel->nome, nomeNo) != 0) {
    anterior = atual;
    atual = atual->prox;
    if (anterior != p->topo) {
      free(anterior);
    }
  }

  if (atual == NULL) {
    printf("Nó com o nome '%s' não encontrado.\n", nomeNo);
    return;
  }

  if (atual == p->topo) {
    p->topo = atual->prox;
  } else if (anterior != NULL){
    anterior->prox = atual->prox;
  }
  free(atual);
}

void imprimir_variavel(variavel var){
  if (var.tipo_variavel == TIPO_NUMERO){
    printf("%d\n", var.valor.numero);
  }else if (var.tipo_variavel == TIPO_CADEIA){
    printf("%s\n", var.valor.cadeia);
  }
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

variavel* criar_variavel(no *atual, char *nome, tipoVariavel tipo, void *valor){
  variavel *var = (variavel *)malloc(sizeof(variavel));
  if (!var) {
    printf("Falha ao alocar memória\n");
    return NULL;
  }
  var->nome = strdup(nome);
  var->tipo_variavel = tipo;

  if(var->tipo_variavel == TIPO_NUMERO){
    var->valor.numero = *(int *)valor;
  }else if (var->tipo_variavel == TIPO_CADEIA){
    var->valor.cadeia = strdup((char *)valor);
  }

  atual->variavel = realloc(atual->variavel, (atual->qtdVariaveis + 1) * sizeof(variavel*));
  if (atual->variavel == NULL){
    printf("Falha ao realocar memória\n");
    free(var);
    return NULL;
  }
  atual->variavel[atual->qtdVariaveis] = *var;
  atual->qtdVariaveis++;
  return var;
}
