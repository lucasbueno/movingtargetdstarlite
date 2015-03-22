/* Initial beliefs and rules */

// inicializacao das variaveis (serao atualizadas depois)
xSize(0).
ySize(0).
map([]).

// C e o custo da posicao (X,Y)
cost(C,X,Y) :- xSize(Width) & map(Costs) & .nth((Y-1)*Width + (X-1), Costs, C) & C > 0.

// valida a posicao (X,Y) no grid 
valid_pos(X,Y) :- ySize(Ymax) & xSize(Xmax)
    & X > 0 & X <= Xmax
    & Y > 0 & Y <= Ymax.

// X e 'functor' da estrutura F.
// ex: F = cost(X,Y,C) -> is_functor(F,cost) == true 
is_functor(F,X) :- F =.. [H|T] & X == H.

// insere um no na lista L, a lista resultante sera NL
insert(Node,L,NL) :- .concat(L,[Node],NL).

// insere todos os elementos da lista S na lista L, a lista resultante sera NL
insert_all(S,L,NL) :- .concat(L,S,NL).

// select(Elem, Lista1, Lista2) - remove a primeira ocorrencia de Elem em 
// Lista1, a lista resultante estara em Lista2. Creditos: SWI-Prolog
select(Elem, [Elem|Tail], Tail).
select(Elem, [Head|Tail], [Head|Rest]) :- select(Elem, Tail, Rest).

/* Plans */

// busca completa
// imprime o caminho de menor custo, o custo e vai ate o destino
+ucs_completed(Xf,Yf) : true
	<- 	?costTo(CT,Xf,Yf);
		.print("* busca completa *");
		.print("menor custo = ", CT);
		.print("caminho = ");
		!go_foward(Xf,Yf).

// inicia a busca de custo uniforme
+start : xSize(Xmax) & ySize(Ymax) & pos(Xi,Yi) & target(Xf,Yf) 
  <- !ucs(Xi,Yi,Xf,Yf).

// atualiza o tamanho do grid
+grid(X,Y) : true <- -+xSize(X); -+ySize(Y); .print("ja sei o grid").

// recebe o vetor de custos, verifica se o numero de elementos esta correto,
// armazena em 'values' e mostra os valores
+F : not start & is_functor(F,costs) 
	<- 	F =.. [costs|[Values|_]];
		.length(Values,Len);
		?xSize(X);
		?ySize(Y);
		Len == X*Y;
		-+map(Values);
		.print("ja sei os custos:");
		+start.

// inicia a busca de custo uniforme
// inicia as listas 'open' e 'closed' e a iteracao
+!ucs(Xi,Yi,Xf,Yf) : true
	<-	?map(G);
		+closed([]);
		+costTo(0,Xi,Yi);
		Root = costTo(0,Xi,Yi);
		?insert(Root,[],Open);
		+open(Open);
		!iterate(Open,Xf,Yf).

// e o loop principal
// se 'open' ficar vazio a busca falha
+!iterate(Open,Xf,Yf) : .length(Open,L) & L == 0 <- .fail.

// se o no escolhido e o destino, encerra a busca
+!iterate(Open,Xf,Yf) : Open = [Next|_] & Next =.. [costTo|[[_,X,Y]|_]]
						& X == Xf & Y == Yf
	<-	+ucs_completed(Xf,Yf).
	
// escolhe o no com menor custo e expande
// o no escolhido vai para 'closed' e os nos expandidos vao para 'open'
+!iterate(Open,Xf,Yf) : true
	<-	Open = [Next|Open1];
		Next =.. [costTo|[[_,X,Y]|_]];
		!expand(X,Y,S);
		?insert_all(S,Open1,Open2);
		?closed(Closed);
		?insert(Next,Closed,Closed1);
		-+closed(Closed1);
		.sort(Open2,Open3);
		-+open(Open3);
		!!iterate(Open3,Xf,Yf).
		
// expande o no indicado nas 4 direcoes e retorna os nos expandidos em S
+!expand(X,Y,S) : true
	<-	!new_node(X,Y-1,X,Y,up,[],L1);
		!new_node(X+1,Y,X,Y,right,L1,L2);
		!new_node(X,Y+1,X,Y,down,L2,L3);
		!new_node(X-1,Y,X,Y,left,L3,L4);
		S = L4.

// se for valido, cria um novo no e insere na lista L, tem NL como resultado
// (Xp,Yp) e pai de (Xn,Yn), pela acao A em (Xp,Yp) chega-se a (Xn,Yn)
+!new_node(Xn,Yn,Xp,Yp,A,L,NL) : not valid_pos(Xn,Yn) | not cost(_,Xn,Yn)
	<-	NL = L.

// (Xn,Yn) nao pode estar em 'closed'
+!new_node(Xn,Yn,Xp,Yp,A,L,NL) : 
	costTo(CT,Xn,Yn) & closed(Closed) & .member(costTo(CT,Xn,Yn),Closed)
	<-	NL = L.
	
// se (Xn,Yn) estiver em 'open' e o novo custo for maior, mantem o no
+!new_node(Xn,Yn,Xp,Yp,A,L,NL) : 
	costTo(CurCT,Xn,Yn) & open(Open) & .member(costTo(CurCT,Xn,Yn),Open)
	& costTo(CTp,Xp,Yp) & cost(Cn,Xn,Yn) & CTp + Cn >= CurCT
	<- NL = L.

// se (Xn,Yn) estiver em 'open' e o novo custo for menor, o no e substituido
+!new_node(Xn,Yn,Xp,Yp,A,L,NL) : 
	costTo(CurCT,Xn,Yn) & open(Open) & .member(costTo(CurCT,Xn,Yn),Open)
	& costTo(CTp,Xp,Yp) & cost(Cn,Xn,Yn) & CTp + Cn < CurCT
	<-	-+parent(Xp,Yp,Xn,Yn);
		?select(costTo(CurCT,Xn,Yn),Open,Open2);
		NewCT = CTp + Cn;
		-+costTo(NewCT,Xn,Yn);
		-+open(Open2);
		-+action_for(Xn,Yn,A);
		Node = costTo(NewCT,Xn,Yn);
		?insert(Node,L,NL).

// cria um novo no		
+!new_node(Xn,Yn,Xp,Yp,A,L,NL) : true
	<- 	+parent(Xp,Yp,Xn,Yn);
		+action_for(Xn,Yn,A);
		?cost(Cn,Xn,Yn);
		?costTo(CTp,Xp,Yp);
		CT = CTp + Cn; 
		+costTo(CT,Xn,Yn);
		Node = costTo(CT,Xn,Yn);
		?insert(Node,L,NL).

// faz o backtracking das acoes para chegar no destino e imprime as etapas
+!go_foward(X,Y) : pos(X,Y) <- .print("(",X,",",Y,")").

+!go_foward(X,Y) : action_for(X,Y,A) & A == up
	<- 	!go_foward(X,Y+1);  up; .print("(",X,",",Y,")").
	
+!go_foward(X,Y) : action_for(X,Y,A) & A == right
	<- 	!go_foward(X-1,Y); right; .print("(",X,",",Y,")").
	
+!go_foward(X,Y) : action_for(X,Y,A) & A == down
	<- 	!go_foward(X,Y-1); down; .print("(",X,",",Y,")").
	
+!go_foward(X,Y) : action_for(X,Y,A) & A == left
	<- 	!go_foward(X+1,Y); left; .print("(",X,",",Y,")").



