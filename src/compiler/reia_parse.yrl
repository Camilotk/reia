%
% reia_parse: Yecc grammar for the Reia language
% Copyright (C)2008-09 Tony Arcieri
% 
% Redistribution is permitted under the MIT license.  See LICENSE for details.
%

Nonterminals
  grammar
  expr_list
  exprs
  expr
  match_expr
  range_expr
  add_expr
  mult_expr
  pow_expr
  unary_expr
  call_expr
  max_expr
  function_identifier
  rebind_op
  add_op
  mult_op
  pow_op
  unary_op
  boolean
  call
  number
  list
  tail
  tuple
  dict
  dict_entries
  .
  
Terminals
  eol '(' ')' '[' ']' '{' '}'
  float integer string atom regexp true false nil 
  identifier punctuated_identifier erl
  '+' '-' '*' '/' '%' '**' ',' '.' '..' '=' '=>'
  '+=' '-=' '*=' '/=' '**='
  .

Rootsymbol grammar.

grammar -> expr_list : '$1'.

%% Expression lists (eol delimited)
expr_list -> expr : ['$1'].
expr_list -> expr eol : ['$1'].
expr_list -> eol expr_list : '$2'.
expr_list -> expr eol expr_list : ['$1'|'$3'].

%% Expressions (comma delimited)
exprs -> expr : ['$1'].
exprs -> expr eol : ['$1'].
exprs -> eol exprs : '$2'.
exprs -> expr ',' exprs : ['$1'|'$3'].

expr -> match_expr : '$1'.

match_expr -> match_expr '=' range_expr :
#match{
  line=?line('$2'), 
  left='$1', 
  right='$3'
}.
match_expr -> match_expr rebind_op range_expr :
#binary_op{
  line=?line('$1'), 
  type=op('$2'), 
  left='$1', 
  right='$3'
}.
match_expr -> range_expr : '$1'.

range_expr -> range_expr '..' add_expr :
#range{
  line=?line('$1'), 
  from='$1', 
  to='$3'
}.
range_expr -> add_expr : '$1'.

add_expr -> add_expr add_op mult_expr :
#binary_op{
  line=?line('$1'),
  type=op('$2'),
  left='$1',
  right='$3'
}.
add_expr -> mult_expr : '$1'.

mult_expr -> mult_expr mult_op pow_expr :
#binary_op{
  line=?line('$1'),
  type=op('$2'),
  left='$1',
  right='$3'
}.
mult_expr -> pow_expr : '$1'.

pow_expr -> pow_expr pow_op unary_expr :
#binary_op{
  line=?line('$1'), 
  type=op('$2'), 
  left='$1', 
  right='$3'
}.
pow_expr -> unary_expr : '$1'.

unary_expr -> unary_op unary_expr :
#unary_op{
  line=?line('$1'),
  type=op('$1'),
  val='$2'
}.
unary_expr -> call_expr : '$1'.

call_expr -> call : '$1'.
call_expr -> max_expr : '$1'.

max_expr -> number       : '$1'.
max_expr -> string       : '$1'.
max_expr -> list         : '$1'.
max_expr -> tuple        : '$1'.
max_expr -> dict         : '$1'.
max_expr -> identifier   : '$1'.
max_expr -> atom         : '$1'.
max_expr -> boolean      : '$1'.
max_expr -> regexp       : '$1'.
max_expr -> '(' expr ')' : '$2'.

%% Rebind operators
rebind_op -> '+='  : '$1'.
rebind_op -> '-='  : '$1'.
rebind_op -> '*='  : '$1'.
rebind_op -> '/='  : '$1'.
rebind_op -> '**=' : '$1'.

%% Addition operators
add_op -> '+' : '$1'.
add_op -> '-' : '$1'.

%% Multiplication operators
mult_op -> '*' : '$1'.
mult_op -> '/' : '$1'.
mult_op -> '%' : '$1'.

%% Exponentation operator
pow_op -> '**' : '$1'.

%% Unary operators
unary_op -> '+'   : '$1'.
unary_op -> '-'   : '$1'.

%% Boolean values
boolean -> true  : '$1'.
boolean -> false : '$1'.
boolean -> nil   : '$1'.

%% Function identifiers
function_identifier -> identifier : '$1'.
function_identifier -> punctuated_identifier : '$1'.

%% Function calls
call -> call_expr '.' function_identifier '(' ')' :
#remote_call{
  line      = ?line('$2'),
  receiver  = '$1',
  name      = ?identifier_name('$3'),
  arguments = [],
  block     = #nil{line=?line('$2')}
}.

call -> call_expr '.' function_identifier '(' exprs ')' :
#remote_call{
  line      = ?line('$2'),
  receiver  = '$1',
  name      = ?identifier_name('$3'),
  arguments = '$5',
  block     = #nil{line=?line('$2')}
}.

call -> erl '.' identifier '(' ')' :
#native_call{
  line      = ?line('$2'),
  module    = erlang,
  function  = ?identifier_name('$3'),
  arguments = []
}.

call -> erl '.' identifier '(' exprs ')' :
#native_call{
  line      = ?line('$2'),
  module    = 'erlang',
  function  = ?identifier_name('$3'),
  arguments = '$5'
}.

call -> erl '.' identifier '.' identifier '(' ')' :
#native_call{
  line      = ?line('$2'),
  module    = ?identifier_name('$3'),
  function  = ?identifier_name('$5'),
  arguments = []
}.

call -> erl '.' identifier '.' identifier '(' exprs ')' :
#native_call{
  line      = ?line('$2'),
  module    = ?identifier_name('$3'),
  function  = ?identifier_name('$5'),
  arguments = '$7'
}.

%% Index operation
call -> call_expr '[' expr ']' :
#binary_op{
  line=?line('$1'),
  type='[]',
  left='$1',
  right='$3'
}.

%% Numbers
number -> float : '$1'.
number -> integer : '$1'.

%% Lists
list -> '[' ']' :       #empty{line=?line('$1')}.
list -> '[' expr tail : #cons{line=?line('$1'), expr='$2', tail='$3'}.

tail -> ']' : #empty{line=?line('$1')}.
tail -> ',' '*' expr ']' : '$3'.
tail -> ',' expr tail : #cons{line=?line('$1'), expr='$2', tail='$3'}.

%% Tuples
tuple -> '(' ')' :               #tuple{line=?line('$1'), elements=[]}.
tuple -> '(' expr ',' ')' :      #tuple{line=?line('$1'), elements=['$2']}.
tuple -> '(' expr ',' exprs ')': #tuple{line=?line('$1'), elements=['$2'|'$4']}.

%% Dicts
dict -> '{' '}' :                #dict{line=?line('$1'), elements=[]}.
dict -> '{' dict_entries '}' :   #dict{line=?line('$1'), elements='$2'}.

dict_entries -> range_expr '=>' expr : [{'$1','$3'}]. % FIXME: change add_expr to 1 below match
dict_entries -> range_expr '=>' expr ',' dict_entries : [{'$1','$3'}|'$5'].

Erlang code.

-export([string/1]).
-include("reia_nodes.hrl").
-define(line(Node), element(2, Node)).
-define(identifier_name(Id), element(3, Id)).

%% Parse a given string with nicely formatted errors
string(String) ->
  case reia_scan:string(String) of
    {ok, Tokens, _} -> 
      case reia_parse:parse(Tokens) of
        {ok, Exprs} ->
          {ok, Exprs};
        {error, {Line, _, [Message, Token]}} ->
          {error, {Line, lists:flatten(io_lib:format("~s~s", [Message, Token]))}}
      end;
    {error, {Line, _, {Message, Token}}, _} ->
      {error, {Line, lists:flatten(io_lib:format("~p ~p", [Message, Token]))}}
  end.

%% Extract operators from op tokens
op({Op, _Line}) ->
  Op.