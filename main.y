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
  variavel **variavel;
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
void imprimir_pilha();
void imprimir_variavel(variavel *var);
void remover_espacos(char *str);
no* procurar_variavel_em_pilha(char* nome);
tipoVariavel procurar_tipo_variavel_em_pilha(char* nome);
void criar_variavel(no *, char *, tipoVariavel, void *);

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
  | linha entrada
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

/* DANDO ERRO AQUI */
declaracao:
  TIPO_CADEIA declaracao_multipla_cadeia
  | TIPO_NUMERO declaracao_multipla_numero
  ;

declaracao_multipla_cadeia:
  declaracao_multipla_cadeia ',' declaracao_cadeia
  | declaracao_cadeia
  ;

declaracao_multipla_numero:
  declaracao_numero
  | declaracao_multipla_numero ',' declaracao_numero
  ;

declaracao_cadeia:
  TK_IDENTIFICADOR IGUAL TK_CADEIA {
    remover_espacos($1.cadeia);
    no* no_atual = procurar_variavel_em_pilha($1.cadeia);
    if (no_atual == NULL) {
      no_atual = p->topo;
      char *cadeia = $3.cadeia;
      criar_variavel(no_atual, $1.cadeia, TIPO_CADEIA, cadeia);
    }else{
      printf("Variavel '%s' ja declarada\n", $1.cadeia);
    }
  }
  | TK_IDENTIFICADOR {
    remover_espacos($1.cadeia);
    no* no_atual = procurar_variavel_em_pilha($1.cadeia);
    if (no_atual == NULL) {
      no_atual = p->topo;
      char *cadeia = "";
      criar_variavel(no_atual, $1.cadeia, TIPO_CADEIA, cadeia);
    }else{
      printf("Variavel '%s' ja declarada\n", $1.cadeia);
    }
  }
  | TK_IDENTIFICADOR IGUAL TK_CADEIA MAIS TK_CADEIA {
    remover_espacos($1.cadeia);
    remover_espacos($3.cadeia);
    remover_espacos($5.cadeia);

    int tamanho3 = strlen($3.cadeia);
    if ($3.cadeia[tamanho3 - 1] == '\"') {
      $3.cadeia[tamanho3 - 1] = '\0';
    }

    char* cadeia5Ajustada = $5.cadeia;
    if (cadeia5Ajustada[0] == '\"') {
      cadeia5Ajustada++;
    }

    no* no_atual = procurar_variavel_em_pilha($1.cadeia);
    if (no_atual == NULL) {
      no_atual = p->topo;
      char* valor = (char*)malloc(strlen($3.cadeia) + strlen(cadeia5Ajustada) + 1);
      strcpy(valor, $3.cadeia);
      strcat(valor, cadeia5Ajustada);
      criar_variavel(no_atual, $1.cadeia, TIPO_CADEIA, valor);
    }
  }
  | TK_IDENTIFICADOR IGUAL TK_CADEIA MAIS TK_IDENTIFICADOR {
    remover_espacos($1.cadeia);
    remover_espacos($3.cadeia);
    remover_espacos($5.cadeia);

    int tamanho3 = strlen($3.cadeia);
    if ($3.cadeia[tamanho3 - 1] == '\"') {
      $3.cadeia[tamanho3 - 1] = '\0';
    }

    no* no_atual1 = procurar_variavel_em_pilha($1.cadeia);
    no* no_atual2 = procurar_variavel_em_pilha($5.cadeia);

    if (no_atual1 == NULL && no_atual2 != NULL) {
      no_atual1 = p->topo;
      tipoVariavel tipo2;
      tipo2 = procurar_tipo_variavel_em_pilha($5.cadeia);
      if (tipo2 == TIPO_CADEIA) {
        for (int i = 0; i < no_atual2->qtdVariaveis; i++) {
          if (strcmp(no_atual2->variavel[i]->nome, $5.cadeia) == 0){
            char* valor5Ajustado = no_atual2->variavel[i]->valor.cadeia;
            if (valor5Ajustado[1] == '\"') {
              valor5Ajustado += 2;
            }

            char* valor = (char*)malloc(strlen($3.cadeia) + strlen(valor5Ajustado) + 1);
            strcpy(valor, $3.cadeia);
            strcat(valor, valor5Ajustado);
            criar_variavel(no_atual1, $1.cadeia, TIPO_CADEIA, valor);
          }
        }
      }
    }
  }
  | TK_IDENTIFICADOR IGUAL TK_IDENTIFICADOR MAIS TK_CADEIA {
    remover_espacos($1.cadeia);
    remover_espacos($3.cadeia);
    remover_espacos($5.cadeia);

    if ($5.cadeia[0] == '\"') {
      memmove($5.cadeia, $5.cadeia + 1, strlen($5.cadeia));
    }

    no* no_atual1 = procurar_variavel_em_pilha($1.cadeia);
    no* no_atual2 = procurar_variavel_em_pilha($3.cadeia);

    if (no_atual1 == NULL && no_atual2 != NULL) {
      no_atual1 = p->topo;
      tipoVariavel tipo2;
      tipo2 = procurar_tipo_variavel_em_pilha($3.cadeia);
      if (tipo2 == TIPO_CADEIA) {
        for (int i = 0; i < no_atual2->qtdVariaveis; i++) {
          if (strcmp(no_atual2->variavel[i]->nome, $3.cadeia) == 0){
            char* valor3Ajustado = no_atual2->variavel[i]->valor.cadeia;
            int tamanhoValor3Ajustado = strlen(valor3Ajustado);
            if (valor3Ajustado[tamanhoValor3Ajustado - 1] == '\"') {
              valor3Ajustado[tamanhoValor3Ajustado - 1] = '\0';
            }

            char* valor = (char*)malloc(strlen($5.cadeia) + strlen(valor3Ajustado) + 1);
            strcpy(valor, valor3Ajustado);
            strcat(valor, $5.cadeia);
            criar_variavel(no_atual1, $1.cadeia, TIPO_CADEIA, valor);
          }
        }
      }
    }
  }
  | TK_IDENTIFICADOR IGUAL TK_IDENTIFICADOR MAIS TK_IDENTIFICADOR {
    remover_espacos($1.cadeia);
    remover_espacos($3.cadeia);
    remover_espacos($5.cadeia);

    no* no_atual1 = procurar_variavel_em_pilha($1.cadeia);
    no* no_atual2 = procurar_variavel_em_pilha($3.cadeia);
    no* no_atual3 = procurar_variavel_em_pilha($5.cadeia);

    if (no_atual1 == NULL && no_atual2 != NULL && no_atual3 != NULL){
      no_atual1 = p->topo;
      tipoVariavel tipo2, tipo3;
      tipo2 = procurar_tipo_variavel_em_pilha($3.cadeia);
      tipo3 = procurar_tipo_variavel_em_pilha($5.cadeia);

      if (tipo2 == TIPO_CADEIA && tipo3 == TIPO_CADEIA) {
        for (int i = 0; i < no_atual2->qtdVariaveis; i++) {
          if (strcmp(no_atual2->variavel[i]->nome, $3.cadeia) == 0) {
            for (int j = 0; j < no_atual3->qtdVariaveis; j++) {
              if (strcmp(no_atual3->variavel[j]->nome, $5.cadeia) == 0) {
                char* valor2Ajustado = no_atual2->variavel[i]->valor.cadeia;
                int tamanhoValor2 = strlen(valor2Ajustado);
                if (valor2Ajustado[tamanhoValor2 - 1] == '\"') {
                  valor2Ajustado[tamanhoValor2 - 1] = '\0';
                }

                char* valor3Ajustado = no_atual3->variavel[j]->valor.cadeia;
                if (valor3Ajustado[0] == '\"') {
                  valor3Ajustado += 1;
                }

                char* valor = (char*)malloc(strlen(valor2Ajustado) + strlen(valor3Ajustado) + 1);
                strcpy(valor, valor2Ajustado);
                strcat(valor, valor3Ajustado);
                criar_variavel(no_atual1, $1.cadeia, TIPO_CADEIA, valor);
              }
            }
          }
        }
      }
    }
  }
  ;

declaracao_numero:
  TK_IDENTIFICADOR IGUAL TK_NUMERO {
    remover_espacos($1.cadeia);
    no* no_atual = procurar_variavel_em_pilha($1.cadeia);
    if (no_atual == NULL) {
      no_atual = p->topo;
      int* valor = (int*)malloc(sizeof(int));
      *valor = $3.numero;
      criar_variavel(no_atual, $1.cadeia, TIPO_NUMERO, valor);
    }else{
      printf("Variavel '%s' ja declarada\n", $1.cadeia);
    }
  }
  | TK_IDENTIFICADOR {
    remover_espacos($1.cadeia);
    no* no_atual = procurar_variavel_em_pilha($1.cadeia);
    if (no_atual == NULL) {
      no_atual = p->topo;
      int* valor = (int*)malloc(sizeof(int));
      *valor = 0;
      criar_variavel(no_atual, $1.cadeia, TIPO_NUMERO, valor);
    }else{
      printf("Variavel '%s' ja declarada\n", $1.cadeia);
    }
  }
  | TK_IDENTIFICADOR IGUAL TK_NUMERO MAIS TK_NUMERO {
    remover_espacos($1.cadeia);
    no* no_atual = procurar_variavel_em_pilha($1.cadeia);
    if (no_atual == NULL) {
      no_atual = p->topo;
      int* valor = (int*)malloc(sizeof(int));
      *valor = $3.numero + $5.numero;
      criar_variavel(no_atual, $1.cadeia, TIPO_NUMERO, valor);
      
    }
  }
  | TK_IDENTIFICADOR IGUAL TK_NUMERO MAIS TK_IDENTIFICADOR {
    remover_espacos($1.cadeia);
    remover_espacos($5.cadeia);
    no* no_atual1 = procurar_variavel_em_pilha($1.cadeia);
    no* no_atual2 = procurar_variavel_em_pilha($5.cadeia);
    if (no_atual1 == NULL && no_atual2 != NULL) {
      no_atual1 = p->topo;
      tipoVariavel tipo2;
      tipo2 = procurar_tipo_variavel_em_pilha($5.cadeia);
      if (tipo2 == TIPO_NUMERO) {
        int* valor = (int*)malloc(sizeof(int));
        *valor = $3.numero + no_atual2->variavel[0]->valor.numero;
        criar_variavel(no_atual1, $1.cadeia, TIPO_NUMERO, valor);
      }
    }
  }
  | TK_IDENTIFICADOR IGUAL TK_IDENTIFICADOR MAIS TK_NUMERO {
    remover_espacos($1.cadeia);
    remover_espacos($3.cadeia);
    no* no_atual1 = procurar_variavel_em_pilha($1.cadeia);
    no* no_atual2 = procurar_variavel_em_pilha($3.cadeia);
    if (no_atual1 == NULL && no_atual2 != NULL) {
      no_atual1 = p->topo;
      tipoVariavel tipo2;
      tipo2 = procurar_tipo_variavel_em_pilha($3.cadeia);
      if (tipo2 == TIPO_NUMERO) {
        int* valor = (int*)malloc(sizeof(int));
        *valor = no_atual2->variavel[0]->valor.numero + $5.numero;
        criar_variavel(no_atual1, $1.cadeia, TIPO_NUMERO, valor);
      }
    }
  }
  | TK_IDENTIFICADOR IGUAL TK_IDENTIFICADOR MAIS TK_IDENTIFICADOR {
    remover_espacos($1.cadeia);
    remover_espacos($3.cadeia);
    remover_espacos($5.cadeia);

    no* no_atual1 = procurar_variavel_em_pilha($1.cadeia);
    no* no_atual2 = procurar_variavel_em_pilha($3.cadeia);
    no* no_atual3 = procurar_variavel_em_pilha($5.cadeia);

    if (no_atual1 == NULL && no_atual2 != NULL && no_atual3 != NULL) {
      no_atual1 = p->topo;
      tipoVariavel tipo2, tipo3;
      tipo2 = procurar_tipo_variavel_em_pilha($3.cadeia);
      tipo3 = procurar_tipo_variavel_em_pilha($5.cadeia);

      if (tipo2 == TIPO_NUMERO && tipo3 == TIPO_NUMERO) {
        int* valor = (int*)malloc(sizeof(int));
        for (int i = 0; i < no_atual2->qtdVariaveis; i++) {
          if (strcmp(no_atual2->variavel[i]->nome, $3.cadeia) == 0) {
            for (int j = 0; j < no_atual3->qtdVariaveis; j++) {
              if (strcmp(no_atual3->variavel[j]->nome, $5.cadeia) == 0) {
                *valor = no_atual2->variavel[i]->valor.numero + no_atual3->variavel[j]->valor.numero;
                criar_variavel(no_atual1, $1.cadeia, TIPO_NUMERO, valor);
              }
            }
          }
        }
      }
    }
  }
  ;

atribuicao:
  TK_IDENTIFICADOR IGUAL TK_NUMERO {
    remover_espacos($1.cadeia);
    no* no_atual = procurar_variavel_em_pilha($1.cadeia);
    if (no_atual != NULL){
      printf("entrei aqui");
      int* valor = (int*)malloc(sizeof(int));
      *valor = $3.numero;
      for (int i = 0; i < no_atual->qtdVariaveis; i++){
        if (strcmp(no_atual->variavel[i]->nome, $1.cadeia) == 0){
          no_atual->variavel[i]->valor.numero = *valor;
        }
      }
    }
  }
  | TK_IDENTIFICADOR IGUAL TK_CADEIA {
    remover_espacos($1.cadeia);
    no* no_atual = procurar_variavel_em_pilha($1.cadeia);
    if (no_atual != NULL){
      no_atual = p->topo;
      char *cadeia = $3.cadeia;
      for (int i = 0; i < no_atual -> qtdVariaveis; i++){
        if (strcmp(no_atual->variavel[i]->nome, $1.cadeia) == 0){
          no_atual->variavel[i]->valor.cadeia = $3.cadeia;
        }
      }
    }
  }
  | TK_IDENTIFICADOR IGUAL TK_IDENTIFICADOR {
    remover_espacos($1.cadeia);
    remover_espacos($3.cadeia);
    no* no_atual_1 = procurar_variavel_em_pilha($1.cadeia);
    no* no_atual_2 = procurar_variavel_em_pilha($3.cadeia);
    if (no_atual_1 != NULL && no_atual_2 != NULL){
      tipoVariavel tipo_1, tipo_2;
      tipo_1 = procurar_tipo_variavel_em_pilha($1.cadeia);
      tipo_2 = procurar_tipo_variavel_em_pilha($3.cadeia);
      if (tipo_1 == tipo_2){
        for (int i = 0; i < no_atual_1 -> qtdVariaveis; i++){
          if (strcmp(no_atual_1 -> variavel[i]->nome, $1.cadeia) == 0){
            for (int j = 0; j < no_atual_2 -> qtdVariaveis; j++){
              if (strcmp(no_atual_2 -> variavel[j]->nome, $3.cadeia) == 0){
                no_atual_1 -> variavel[i]->valor = no_atual_2 -> variavel[j]->valor;
              }
            }
          }
        }
      }
    }
  }
  | TK_IDENTIFICADOR IGUAL TK_NUMERO MAIS TK_NUMERO {
    remover_espacos($1.cadeia);
    no* no_atual = procurar_variavel_em_pilha($1.cadeia);
    if (no_atual != NULL){
      tipoVariavel tipo = procurar_tipo_variavel_em_pilha($1.cadeia);
      if (tipo == TIPO_NUMERO){
        int* valor = (int*)malloc(sizeof(int));
        *valor = $3.numero + $5.numero;
        for (int i = 0; i < no_atual->qtdVariaveis; i++){
          if (strcmp(no_atual->variavel[i]->nome, $1.cadeia) == 0){
            no_atual->variavel[i]->valor.numero = *valor;
          }
        }
      }else{
        printf("Operacao invalida\n");
      }
    }
  }
  | TK_IDENTIFICADOR IGUAL TK_NUMERO MAIS TK_IDENTIFICADOR{
    remover_espacos($1.cadeia);
    remover_espacos($5.cadeia);
    no* no_atual_1 = procurar_variavel_em_pilha($1.cadeia);
    no* no_atual_2 = procurar_variavel_em_pilha($5.cadeia);
    if (no_atual_1 != NULL && no_atual_2 != NULL){
      tipoVariavel tipo_1, tipo_2;
      tipo_1 = procurar_tipo_variavel_em_pilha($1.cadeia);
      tipo_2 = procurar_tipo_variavel_em_pilha($5.cadeia);
      if (tipo_1 == TIPO_NUMERO && tipo_2 == TIPO_NUMERO){
        int* valor = (int*)malloc(sizeof(int));
        *valor = $3.numero + no_atual_2->variavel[0]->valor.numero;
        for (int i = 0; i < no_atual_1->qtdVariaveis; i++){
          if (strcmp(no_atual_1->variavel[i]->nome, $1.cadeia) == 0){
            no_atual_1->variavel[i]->valor.numero = *valor;
          }
        }
      }else{
        printf("Operacao invalida\n");
      }
    }
  }
  | TK_IDENTIFICADOR IGUAL TK_IDENTIFICADOR MAIS TK_NUMERO{
    remover_espacos($1.cadeia);
    remover_espacos($3.cadeia);
    no* no_atual_1 = procurar_variavel_em_pilha($1.cadeia);
    no* no_atual_2 = procurar_variavel_em_pilha($3.cadeia);
    if (no_atual_1 != NULL && no_atual_2 != NULL){
      tipoVariavel tipo_1, tipo_2;
      tipo_1 = procurar_tipo_variavel_em_pilha($1.cadeia);
      tipo_2 = procurar_tipo_variavel_em_pilha($3.cadeia);
      if (tipo_1 == TIPO_NUMERO && tipo_2 == TIPO_NUMERO){
        int* valor = (int*)malloc(sizeof(int));
        *valor = no_atual_1->variavel[0]->valor.numero + $5.numero;
        for (int i = 0; i < no_atual_1->qtdVariaveis; i++){
          if (strcmp(no_atual_1->variavel[i]->nome, $1.cadeia) == 0){
            no_atual_1->variavel[i]->valor.numero = *valor;
          }
        }
      }else{
        printf("Operacao invalida\n");
      }
    }
  }
  | TK_IDENTIFICADOR IGUAL TK_IDENTIFICADOR MAIS TK_IDENTIFICADOR{
    /* PRECISO ARRUMAR A PARTE DE CADEIA */
    remover_espacos($1.cadeia);
    remover_espacos($3.cadeia);
    remover_espacos($5.cadeia);

    no* no_atual1 = procurar_variavel_em_pilha($1.cadeia);
    no* no_atual2 = procurar_variavel_em_pilha($3.cadeia);
    no* no_atual3 = procurar_variavel_em_pilha($5.cadeia);

    if (no_atual1 != NULL && no_atual2 != NULL && no_atual3 != NULL) {
      tipoVariavel tipo1, tipo2, tipo3;
      tipo1 = procurar_tipo_variavel_em_pilha($1.cadeia);
      tipo2 = procurar_tipo_variavel_em_pilha($2.cadeia);
      tipo3 = procurar_tipo_variavel_em_pilha($3.cadeia);

      if (tipo1 == TIPO_NUMERO && tipo2 == TIPO_NUMERO && tipo3 == TIPO_NUMERO) {
        int* valor = (int*)malloc(sizeof(int));
        for (int i = 0; i < no_atual2->qtdVariaveis; i++) {
          if (strcmp(no_atual2->variavel[i]->nome, $3.cadeia) == 0) {
            for (int j = 0; j < no_atual3->qtdVariaveis; j++) {
              if (strcmp(no_atual2->variavel[i]->nome, $3.cadeia) == 0) {
                *valor = no_atual2->variavel[i]->valor.numero + no_atual3->variavel[j]->valor.numero;
              }
            }
          }
        }
        for (int i = 0; i < no_atual1->qtdVariaveis; i++) {
          if (strcmp(no_atual1->variavel[i]->nome, $1.cadeia) == 0) {
            no_atual1->variavel[i]->valor.numero = *valor;
          }
        }
      } else if (tipo1 == TIPO_CADEIA && tipo2 == TIPO_CADEIA && tipo3 == TIPO_CADEIA) {
        // Remover a última aspa de $3.cadeia, se houver
        int tamanho3 = strlen($3.cadeia);
        if ($3.cadeia[tamanho3 - 1] == '\"') {
            $3.cadeia[tamanho3 - 1] = '\0';
        }
        
        for (int i = 0; i < no_atual2->qtdVariaveis; i++) {
          if (strcmp(no_atual2->variavel[i]->nome, $3.cadeia) == 0) {
            for (int j = 0; j < no_atual3->qtdVariaveis; j++) {
              char* valor3Ajustado = no_atual3->variavel[j]->valor.cadeia;
              if (valor3Ajustado[0] == '\"') {
                valor3Ajustado++;
              }

              char* valorConcatenado = (char*)malloc(strlen(no_atual2->variavel[i]->valor.cadeia) + strlen(valor3Ajustado) + 1);
              strcpy(valorConcatenado, no_atual2->variavel[i]->valor.cadeia);
              strcat(valorConcatenado, valor3Ajustado);

              for (int k = 0; k < no_atual1->qtdVariaveis; k++) {
                if (strcmp(no_atual1->variavel[k]->nome, $1.cadeia) == 0) {
                  if (no_atual1->variavel[k]->valor.cadeia != NULL) {
                    free(no_atual1->variavel[k]->valor.cadeia);
                  }
                  no_atual1->variavel[k]->valor.cadeia = valorConcatenado;
                }
              }
            }
          }
        }
      }
    }
  }
  | TK_IDENTIFICADOR IGUAL TK_CADEIA MAIS TK_CADEIA {
    remover_espacos($1.cadeia);
    remover_espacos($3.cadeia);
    remover_espacos($5.cadeia);

    int tamanho3 = strlen($3.cadeia);
    if ($3.cadeia[tamanho3 - 1] == '\"') {
      $3.cadeia[tamanho3 - 1] = '\0';
    }

    char* cadeia5Ajustada = $5.cadeia;
    if (cadeia5Ajustada[0] == '\"') {
      cadeia5Ajustada++;
    }

    no* no_atual = procurar_variavel_em_pilha($1.cadeia);
    if (no_atual != NULL) {
      tipoVariavel tipo = procurar_tipo_variavel_em_pilha($1.cadeia);
      if (tipo == TIPO_CADEIA) {
        char* valor = (char*)malloc(strlen($3.cadeia) + strlen(cadeia5Ajustada) + 1);
        strcpy(valor, $3.cadeia);
        strcat(valor, cadeia5Ajustada);
        for (int i = 0; i < no_atual->qtdVariaveis; i++) {
          if (strcmp(no_atual->variavel[i]->nome, $1.cadeia) == 0) {
            no_atual->variavel[i]->valor.cadeia = valor;
          }
        }
      } else {
        printf("Operacao invalida\n");
      }
    }
  }
  | TK_IDENTIFICADOR IGUAL TK_CADEIA MAIS TK_IDENTIFICADOR {
    remover_espacos($1.cadeia);
    remover_espacos($3.cadeia);
    remover_espacos($5.cadeia);

    int tamanho3 = strlen($3.cadeia);
    if ($3.cadeia[tamanho3 - 1] == '\"') {
      $3.cadeia[tamanho3 - 1] = '\0';
    }

    no* no_atual1 = procurar_variavel_em_pilha($1.cadeia);
    no* no_atual2 = procurar_variavel_em_pilha($5.cadeia);

    if (no_atual1 != NULL && no_atual2 != NULL) {
      tipoVariavel tipo1, tipo2;
      tipo1 = procurar_tipo_variavel_em_pilha($1.cadeia);
      tipo2 = procurar_tipo_variavel_em_pilha($5.cadeia);
      if (tipo1 == TIPO_CADEIA && tipo2 == TIPO_CADEIA) {
        char* valor5Ajustado = no_atual2->variavel[0]->valor.cadeia;
        if (valor5Ajustado[1] == '\"') {
          valor5Ajustado += 2;
        }

        char* valor = (char*)malloc(strlen($3.cadeia) + strlen(valor5Ajustado) + 1);
        strcpy(valor, $3.cadeia);
        strcat(valor, valor5Ajustado);
        for (int i = 0; i < no_atual1->qtdVariaveis; i++) {
          if (strcmp(no_atual1->variavel[i]->nome, $1.cadeia) == 0) {
            no_atual1->variavel[i]->valor.cadeia = valor;
          }
        }
      } else {
        printf("Operacao invalida\n");
      }
    }
  }
  | TK_IDENTIFICADOR IGUAL TK_IDENTIFICADOR MAIS TK_CADEIA{
    remover_espacos($1.cadeia);
    remover_espacos($3.cadeia);
    remover_espacos($5.cadeia);

    int tamanho5 = strlen($5.cadeia);
    if ($5.cadeia[tamanho5 - 1] == '\"') {
      $5.cadeia[tamanho5 - 1] = '\0';
    }

    no* no_atual1 = procurar_variavel_em_pilha($1.cadeia);
    no* no_atual2 = procurar_variavel_em_pilha($3.cadeia);

    if (no_atual1 != NULL && no_atual2 != NULL) {
      tipoVariavel tipo1, tipo2;
      tipo1 = procurar_tipo_variavel_em_pilha($1.cadeia);
      tipo2 = procurar_tipo_variavel_em_pilha($3.cadeia);

      if (tipo1 == TIPO_CADEIA && tipo2 == TIPO_CADEIA) {
        char* valor3Ajustado = no_atual2->variavel[0]->valor.cadeia;
        if (valor3Ajustado[1] == '\"') {
          valor3Ajustado += 2;
        }

        char* valor = (char*)malloc(strlen($5.cadeia) + strlen(valor3Ajustado) + 1);
        strcpy(valor, $5.cadeia);
        strcat(valor, valor3Ajustado);
        for (int i = 0; i < no_atual1->qtdVariaveis; i++) {
          if (strcmp(no_atual1->variavel[i]->nome, $1.cadeia) == 0) {
            no_atual1->variavel[i]->valor.cadeia = valor;
          }
        }
      } else {
        printf("Operacao invalida\n");
      }
    }
  }
  ;

impressao:
  PRINT TK_IDENTIFICADOR {
    no* no_atual;
    no_atual = procurar_variavel_em_pilha($2.cadeia);
    for (int i = 0; i < no_atual->qtdVariaveis; i++){
      if(strcmp(no_atual->variavel[i]->nome, $2.cadeia) == 0){
        imprimir_variavel(no_atual->variavel[i]);
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
  p = (pilha *)malloc(sizeof(pilha));
  if (p != NULL) {
      p->topo = NULL;
  }
}

/* FUNCIONANDO */
void empilhar(char *nomeNo) {
  no *novo = (no *)malloc(sizeof(no));
  if (novo == NULL) {
    printf("Erro ao alocar memória.\n");
    exit(1);
  }

  char *nomeExtraido = NULL;
  char *inicio = strchr(nomeNo, '_');
  char *fim = strrchr(nomeNo, '_');

  if (inicio != NULL && fim != NULL && fim > inicio) {
    size_t tamanho = fim - inicio + 1; 
    nomeExtraido = (char *)malloc(tamanho + 1);

    if (nomeExtraido) {
      strncpy(nomeExtraido, inicio, tamanho);
      nomeExtraido[tamanho] = '\0';
      novo->nome = nomeExtraido;
    } else {
      printf("Erro ao alocar memória para o nome.\n");
      free(novo);
      exit(1);
    }
  } else {
    novo->nome = strdup(nomeNo);
  }

  novo->prox = p->topo;
  novo->qtdVariaveis = 0;
  novo->variavel = NULL;
  p->topo = novo;
}

/* FUNCIONANDO */
void desempilhar(char* nomeNo){
  if (p -> topo == NULL){
    printf("Pilha vazia\n");
    return;
  }

  char *nomeExtraido = NULL;
  char *inicio = strchr(nomeNo, '_');
  char *fim = strrchr(nomeNo, '_');

  if (inicio != NULL && fim != NULL && fim > inicio) {
    size_t tamanho = fim - inicio + 1;
    nomeExtraido = (char *)malloc(tamanho + 1);

    if (nomeExtraido) {
      strncpy(nomeExtraido, inicio, tamanho);
      nomeExtraido[tamanho] = '\0';
    } else {
      printf("Erro ao alocar memória para o nome.\n");
      exit(1);
    }
  }

  no* atual = p->topo;
  no* anterior = NULL;

  while (atual != NULL) {
    if (strcmp(atual->nome, nomeExtraido) == 0) {
      if (anterior == NULL) {
        p->topo = atual->prox;
      } else {
        anterior->prox = atual->prox;
      }
      free(atual->nome);
      free(atual);
      return;
    }
    anterior = atual;
    atual = atual->prox;
  }

  printf("Nó '%s' não encontrado.\n", nomeNo);
}

/* FUNCIONANDO */
void imprimir_pilha(){
  no *atual = p->topo;
  while (atual != NULL) {
    printf("%s\n", atual->nome);
    atual = atual->prox;
  }
}

/* FUNCIONANDO */
void imprimir_variavel(variavel *var){
  if (var->tipo_variavel == TIPO_NUMERO){
    printf("%d\n", var->valor.numero);
  } else if (var->tipo_variavel == TIPO_CADEIA){
    printf("%s\n", var->valor.cadeia);
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

/* FUNCIONANDO */
no* procurar_variavel_em_pilha(char* nome){
  no* atual = p->topo;
  while (atual != NULL){
    for (int i = 0; i < atual->qtdVariaveis; i++){
      if (strcmp(atual->variavel[i]->nome, nome) == 0){
        return atual;
      }
    }
    atual = atual->prox;
  }
  return NULL;
}

/* FUNCIONANDO */
tipoVariavel procurar_tipo_variavel_em_pilha(char* nome) {
  no* atual = p->topo;
  while (atual != NULL) {
    if (atual != NULL) {
      for (int i = 0; i < atual->qtdVariaveis; i++) {
        if (atual->variavel[i] != NULL && atual->variavel[i]->nome != NULL && nome != NULL) {
          if (strcmp(atual->variavel[i]->nome, nome) == 0) {
            return atual->variavel[i]->tipo_variavel;
          }
        }
      }
    }
    atual = atual->prox;
  }
} 

/* FUNCIONANDO */
void criar_variavel(no *atual, char *nome, tipoVariavel tipo, void *valor) {
  if (nome == NULL || atual == NULL) {
    printf("Parâmetros inválidos\n");
    return;
  }

  variavel *var = (variavel *)malloc(sizeof(variavel));
  if (!var) {
    printf("Falha ao alocar memória\n");
    return;
  }

  var->nome = strdup(nome);
  if (!var->nome) {
    printf("Falha ao alocar memória para o nome\n");
    free(var);
    return;
  }

  var->tipo_variavel = tipo;

  if (valor == NULL) {
    if (tipo == TIPO_NUMERO) {
      var->valor.numero = 0;
    } else if (tipo == TIPO_CADEIA) {
      var->valor.cadeia = strdup("");
        if (!var->valor.cadeia) {
          printf("Falha ao alocar memória para a cadeia\n");
          free(var->nome);
          free(var);
          return;
        }
    }
  } else {
    if (tipo == TIPO_NUMERO) {
      var->valor.numero = *((int *)valor);
    } else if (tipo == TIPO_CADEIA) {
      var->valor.cadeia = strdup((char *)valor);
      if (!var->valor.cadeia) {
        printf("Falha ao alocar memória para a cadeia\n");
        free(var->nome);
        free(var);
        return;
      }
    }
  }

  variavel **temp = (variavel **)realloc(atual->variavel, (atual->qtdVariaveis + 1) * sizeof(variavel *));
  if (temp == NULL) {
    printf("Erro ao realocar memória\n");
    if (var->tipo_variavel == TIPO_CADEIA) {
      free(var->valor.cadeia);
    }
    free(var->nome);
    free(var);
    return;
  } else {
    atual->variavel = temp;
    atual->variavel[atual->qtdVariaveis] = var;
    atual->qtdVariaveis += 1;
  }
}
