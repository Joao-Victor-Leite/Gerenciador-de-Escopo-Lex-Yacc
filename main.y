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

typedef struct pilha {
  tabela *variavel;
  struct pilha *prox;
} pilha;

typedef struct tabela{
  char *tipo;
  char *nome;
  TipoVariavel tipo_variavel;
  union {
    int numero;
    char *cadeia;
  } valor;
  struct variavel *prox;
} tabela;

pilha *criarPilha() {
  return NULL;
}

pilha *push(pilha *p) {
  pilha *novo = (pilha *)malloc(sizeof(pilha));
  novo -> variavel = NULL;
  novo -> prox = p;
  printf("push\n");
  return novo;
}

pilha *pop(pilha *p) {
  if (p == NULL) return NULL;
  pilha *temp = p->prox;
  free(p);
  printf("pop\n");
  return temp;
}

tabela* procurar_variavel_em_pilha(pilha *p, char *id){
  pilha *temp = p;
  while (temp != NULL){
    tabela *expressao = temp->variavel;
    while (expressao != NULL){
      if(strcmp(expressao->nome, id) == 0){
        return expressao;
      }
      expressao = expressao->prox;
    }
    temp = temp->prox;
  }
  return NULL;
}



tabela* procurar_tipo_variavel_em_pilha(pilha* p, char *tipo){
  pilha *temp = p;
  while (temp != NULL){
    tabela *expressao = temp->variavel;
    while (expressao != NULL){
      if(strcmp(expressao->tipo, tipo) == 0){
        return expressao;
      }
      expressao = expressao->prox;
    }
    temp = temp->prox;
  }
  return NULL;
}

tabela* procurar_variavel_em_pilha(pilha *, char *);
tabela* procurar_tipo_variavel_em_pilha(pilha*, char *);

%}

%token BLOCO_INICIO BLOCO_FIM
%token TIPO_NUMERO TIPO_CADEIA
%token PRINT
%token MAIS IGUAL
%token TK_IDENTIFICADOR TK_NUMERO TK_CADEIA


%%
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
    push(p);
  }

fim_escopo:
  BLOCO_FIM{
    printf("BLOCO_FIM\n");
    a = pop(p);
  }

declaracao:
  TIPO_CADEIA declaracao_cadeia
  | TIPO_NUMERO declaracao_numero
  ;

declaracao_cadeia:
  TK_IDENTIFICADOR IGUAL TK_CADEIA {
    char *s1 = $1;
    if (procurar_variavel_em_pilha() == NULL) {
      /* funcao para adicionar a variavel do tipo CADEIA naquele escopo ("CADEIA", s1, $3.string) */
    }else{
      printf("Variavel '%s' ja declarada\n", s1);
    }
  }
  | TK_IDENTIFICADOR {
    char *s1 = $1;
    if (procurar_variavel_em_pilha() == NULL){
      /* funcao para adicionar a variavel do tipo CADEIA naquele escopo ("CADEIA", s1, "") */
    }else{
      printf("Variavel '%s' ja declarada\n", s1);
    }
  }

declaracao_numero:
  TK_IDENTIFICADOR IGUAL TK_NUMERO {
    char *s1 = $1;
    if (procurar_variavel_em_pilha() == NULL){
      /* funcao para adicionar a variavel do tipo NUMERO naquele escopo ("NUMERO", s1, $3.numero) */
    }else{
      printf("Variavel '%s' ja declarada\n", s1);
    }
  }
  | TK_NUMERO {
    char *s1 = $1;
    if (procurar_variavel_em_pilha() == NULL){
      /* funcao para adicionar a variavel do tipo NUMERO naquele escopo ("NUMERO", s1, 0) */
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
  | TK_IDENTIFICADOR
  ;

impressao:
  PRINT TK_IDENTIFICADOR {
    /* funcao para imprimir a variavel */
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
