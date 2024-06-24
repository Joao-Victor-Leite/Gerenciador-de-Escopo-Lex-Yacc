%{
int yylex(void);
void yyerror(char* s);
#include <stdlib.h>
#include <stdio.h>
#include <string.h>


typedef struct Pilha{
    No* topo;
} pilha;

typedef struct No {
    variavel variavel;
    int qtdVariaveis;
    struct No* prox;
} no;

typedef enum {
  TIPO_NUMERO,
  TIPO_CADEIA
} tipoVariavel;

typedef struct Variavel {
  TipoVariavel tipo_variavel;
  char *nome;
  union {
    int numero;
    char *cadeia;
  } valor;
} variavel;

void iniciar_pilha(pilha *);
void empilhar(pilha *, variavel *s);
pilha* desempilhar(pilha *);

variavel* desempilhar(pilha *);
variavel* criar_variavel(Pilha *, char *, TipoVariavel, void *);
void imprimir_variavel(variavel);

no* procurar_variavel_em_pilha(pilha *, char *);
no* procurar_tipo_variavel_em_pilha(pilha*, char *);


%}

%token BLOCO_INICIO BLOCO_FIM
%token TIPO_NUMERO TIPO_CADEIA
%token PRINT
%token MAIS IGUAL
%token TK_IDENTIFICADOR TK_NUMERO TK_CADEIA


%%
entrada:}
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
  }

fim_escopo:
  BLOCO_FIM{
    printf("BLOCO_FIM\n");
  }

declaracao:
  TIPO_CADEIA declaracao_cadeia
  | TIPO_CADEIA declaracao_multipla_cadeia
  | TIPO_NUMERO declaracao_numero
  | TIPO_NUMERO declaracao_multipla_numero
  ;

declaracao_cadeia:
  TK_IDENTIFICADOR IGUAL TK_CADEIA {
    char *s1 = $1;
    no = procurar_variavel_em_pilha(p, s1);
    if (no == NULL) {
      criar_variavel(no, s1, TIPO_CADEIA, $3);
    }else{
      printf("Variavel '%s' ja declarada\n", s1);
    }
  }
  | TK_IDENTIFICADOR {
    char *s1 = $1;
    no = procurar_variavel_em_pilha(p, s1);
    if (no == NULL) {
      criar_variavel(no, s1, TIPO_CADEIA, "");
    }else{
      printf("Variavel '%s' ja declarada\n", s1);
    }
  }

declaracao_numero:
  TK_IDENTIFICADOR IGUAL TK_NUMERO {
    char *s1 = $1;
    no = procurar_variavel_em_pilha(p, s1);
    if (no == NULL) {
      criar_variavel(no, s1, TIPO_NUMERO, $3);
    }else{
      printf("Variavel '%s' ja declarada\n", s1);
    }
  }
  | TK_NUMERO {
    char *s1 = $1;
    no = procurar_variavel_em_pilha(p, s1);
    if (no == NULL) {
      criar_variavel(no, s1, TIPO_NUMERO, 0);
    }else{
      printf("Variavel '%s' ja declarada\n", s1);
    }
  }

declaracao_multipla_cadeia:
  declaracao_cadeia
  | declaracao_multipla_cadeia ',' declaracao_cadeia
  ;

declaracao_multipla_numero:
  declaracao_numero
  | declaracao_multipla_numero ',' declaracao_numero
  ;

atribuicao:
  TK_IDENTIFICADOR IGUAL TK_NUMERO {}
  | TK_IDENTIFICADOR IGUAL TK_CADEIA {}
  | TK_IDENTIFICADOR IGUAL TK_IDENTIFICADOR {}
  | TK_IDENTIFICADOR IGUAL expressao {}

expressao:
  termo
  | expressao MAIS termo {
    /* funcao para verificar se os tipos sao compativeis */
  }
  ;

termo:
  TK_NUMERO
  | TK_CADEIA
  | TK_IDENTIFICADOR
  ;

impressao:
  PRINT TK_IDENTIFICADOR {
    no = procurar_variavel_em_pilha(p, $2);
    for (int i = 0; i < no -> qtdVariaveis; i++){
      if(strcmp(no -> variavel[i].nome, $2) == 0){
        imprimir_variavel(no -> variavel[i]);
      }
    }
  }
%%


extern FILE *yyin;
int main() {
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

void empilhar(pilha *p, variavel *var) {
  no *novo = (no *)malloc(sizeof(no));
  if (novo_no == NULL) {
    printf("Erro ao alocar memória.\n");
    exit(1);
  }
  novo -> variavel = var;
  novo -> prox = p -> topo;
  p -> topo = novo;
}

variavel desempilhar(pilha* p){
  if (p -> topo == NULL){
    printf("Pilha vazia\n");
    exit(1);
  }
  no *temp = p -> topo;
  variavel var = temp -> variavel;
  p -> topo = temp -> prox;
  free(temp);
  return var;
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
  while (atual !- NULL){
    for (int i = 0; i < atual -> qtdVariaveis; i++){
      if (strcmp(atual -> variavel[i].nome, nome) == 0){
        return atual;
      }
    }
    atual = atual -> prox;
  }
  return NULL;
}

variavel* criar_variavel(no *atual, char *nome, TipoVariavel tipo, void *valor){
  variavel *var = (variavel *)malloc(sizeof(variavel));
  if (!var) {
    printf("Falha ao realocar memória\n");
    return NULL;
  }
  var->nome = strdup(nome);
  var->tipo_variavel = tipo;

  if(var -> tipo_variavel == TIPO_NUMERO){
    var -> valor.numero = *(int *)valor;
  }else if (var -> tipo_variavel == TIPO_CADEIA){
    var -> valor.cadeia = strdup((char *)valor);
  }

  atual->variavel = realloc(atual->variavel, (atual->qtdVariaveis + 1) * sizeof(variavel));
  if (atual->variavel == NULL){
    printf("Falha ao realocar memória\n");
    free(var);
    return NULL;
  }
  atual->variavel[atual->qtdVariaveis] = var;
  atual->qtdVariaveis++;
  return var;
}