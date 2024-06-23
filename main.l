%{
#include <stdio.h>
#include "y.tab.h"
%}

%% 
[ \t]*BLOCO[ \t]* _[a-zA-Z][a-zA-Z]*_   {return BLOCO_INICIO;}
[ \t]*FIM[ \t]* _[a-zA-Z][a-zA-Z]*_     {return BLOCO_FIM;}
[ \t]*NUMERO[ \t]*                      {return TIPO_NUMERO;}
[ \t]*CADEIA[ \t]*                      {return TIPO_CADEIA;}
[ \t]*PRINT[ \t]*                       {return PRINT;}
[ \t]*[0-9]+[ \t]*                      {yyval.number = atoi(yytext);return TK_NUMERO;}
[ \t]*[a-z][a-zA-Z0-9_]*[ \t]*          {yyval.string = strdup(yytext); return TK_IDENTIFICADOR}
[ \t]*\"[^\"]*\"[ \t]*                  {yyval.string = strdup(yytext); return TK_CADEIA;}
\+                                      {return MAIS;}
\-                                      {return '-';}
=                                       {return IGUAL;}
;                                       {return ';';}
,                                       {return ',';}
[ \t]+                                  {/* ignorar espaços em branco */}
%%