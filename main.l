%{
#include <stdio.h>
#include <string.h>
#include "y.tab.h"
%}

%% 
[ \t]*BLOCO[ \t]*_[a-zA-Z]+_            {return BLOCO_INICIO;}
[ \t]*FIM[ \t]*_[a-zA-Z]+_              {return BLOCO_FIM;}
[ \t]*NUMERO[ \t]*                      {return TIPO_NUMERO;}
[ \t]*CADEIA[ \t]*                      {return TIPO_CADEIA;}
[ \t]*PRINT[ \t]*                       {return PRINT;}
[ \t]*[0-9]+[ \t]*                      {yylval.number = atoi(yytext); return TK_NUMERO;}
[ \t]*[a-z][a-zA-Z0-9_]*[ \t]*          {yylval.string = strdup(yytext); return TK_IDENTIFICADOR}
[ \t]*\"[^\"]*\"[ \t]*                  {yylval.string = strdup(yytext); return TK_CADEIA;}
\+                                      {return MAIS;}
\-                                      {return '-';}
=                                       {return IGUAL;}
;                                       {return ';';}
,                                       {return ',';}
[ \t]+                                  {/* ignorar espaços em branco */}
%%