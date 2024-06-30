%{
#include <stdio.h>
#include <string.h>
#include "y.tab.h"
%}

%% 
[ \t]*BLOCO[ \t]*_[a-zA-Z0-9]+_         {yylval.cadeia = strdup(yytext); return BLOCO_INICIO;}
[ \t]*FIM[ \t]*_[a-zA-Z0-9]+_           {yylval.cadeia = strdup(yytext); return BLOCO_FIM;}
[ \t]*NUMERO[ \t]*                      {return TIPO_NUMERO;}
[ \t]*CADEIA[ \t]*                      {return TIPO_CADEIA;}
[ \t]*PRINT[ \t]*                       {return PRINT;}
[ \t]*print[ \t]*                       {return PRINT;}
[ \t]*[0-9]+[ \t]*                      {yylval.numero = atoi(yytext); return TK_NUMERO;}
[ \t]*[a-z][a-zA-Z0-9_]*[ \t]*          {yylval.cadeia = strdup(yytext); return TK_IDENTIFICADOR;}
[ \t]*\"[^\"]*\"[ \t]*                  {yylval.cadeia = strdup(yytext); return TK_CADEIA;}
"+"                                     {return MAIS;}
"="                                     {return IGUAL;}
";"                                     {return ';';}
","                                     {return ',';}
[ \t\n]+                                { /* ignorar espaços em branco */ }
%%