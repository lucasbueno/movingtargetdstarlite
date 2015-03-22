/* Initial beliefs and rules */

// inicializacao das variaveis (serao atualizadas depois)
xSize(0).
ySize(0).
mapSize(0).
totalCost(0).

// valida a posicao (X,Y) no grid 
valid_pos(X,Y) :- ySize(Ymax) & xSize(Xmax)
    & X > 0 & X <= Xmax
    & Y > 0 & Y <= Ymax.

// 3 e um ancestral comum de 1 e 2 se 3 for ancestral de 1 e 2
common_ancestor(X1,Y1,X2,Y2,X3,Y3) :- 	ancestor(X3,Y3,X1,Y1) & 
    ancestor(X3,Y3,X2,Y2).

// 1 e ancestral de 2 se 1 e pai de 2 ou se existe 3, tal que 3 e filho de 1 e 
// e ancestral de 2
ancestor(X1,Y1,X2,Y2) :- 	parent(X1,Y1,X2,Y2) | 
    (parent(X1,Y1,X3,Y3) & ancestor(X3,Y3,X2,Y2)).

// insere um no na lista L, a lista resultante sera NL
insert(Node,L,NL) :- .concat(L,[Node],NL).

// insere todos os elementos da lista S na lista L, a lista resultante sera NL
insert_all(S,L,NL) :- .concat(L,S,NL).

// select(Elem, Lista1, Lista2) - remove a primeira ocorrencia de Elem em 
// Lista1, a lista resultante estara em Lista2. Creditos: SWI-Prolog
select(Elem, [Elem|Tail], Tail).
select(Elem, [Head|Tail], [Head|Rest]) :- select(Elem, Tail, Rest).

/* Plans */

/* grid(X,Y) - Atualiza o tamanho do grid nas variaveis xSize e ySize */
+grid(X,Y) : true
	<- 	-+xSize(X); -+ySize(Y);
		.print("ja sei o grid");
		+start.

/* cost(C,X,Y) - Valida a nova informacao de custo */
// se o custo e zero (invalido), descarta a informacao
+cost(C,X,Y) : C <= 0
	<- 	-cost(C,X,Y).
	
// Incrementa o tamanho do mapa explorado
+cost(C,X,Y) : true
	<-	//.print("+ adicionei o no (", X, ",", Y, ")");
		?mapSize(L);
		LPlus = L+1;
		-+mapSize(LPlus).
	
// busca completa
// imprime o caminho de menor custo, o custo e vai ate o destino
+ucs_completed(Xf,Yf) : true
	<- 	?costTo(CT,Xf,Yf);
		?totalCost(CTotal);
		.print("* busca completa *");
		.print("custo da busca = ", CTotal);
		.print("menor custo = ", CT);
		.print("caminho = ");
		!print_path(1,1,Xf,Yf).

// inicia a busca de custo uniforme
+start : xSize(Xmax) & ySize(Ymax) & pos(Xi,Yi) & target(Xf,Yf) 
  <- .print("Calculando custo:");
     .print("  A (",Xi,",",Yi,") -> T (",Xf,",",Yf,")");
     !ucs(Xi,Yi,Xf,Yf).

// atualiza o custo total da busca	
+!update_cost : true
	<-	?pos(X,Y);
		?totalCost(Cur);
		?cost(C,X,Y);
		New = Cur + C;
		-+totalCost(New).

// inicia a busca de custo uniforme
// inicia as listas 'open' e 'closed' e a iteracao
+!ucs(Xi,Yi,Xf,Yf) : true
	<-	+closed([]);
		+costTo(0,Xi,Yi);
		Root = costTo(0,Xi,Yi);
		?insert(Root,[],Open);
		+open(Open);
		!iterate(Open,Xf,Yf).

// e o loop principal
// se 'open' ficar vazio a busca falha
+!iterate(Open,Xf,Yf) : .length(Open,L) & L == 0 <- .fail.
	
// se esta no destino, encerra a busca
+!iterate(Open,Xf,Yf) : .member(costTo(_,Xf,Yf),Open)
	<-	!go_to(Xf,Yf);
		+ucs_completed(Xf,Yf).

// se nao esta no no escolhido, vai ate ele
+!iterate(Open,Xf,Yf) : Open = [Next|_] & Next =.. [costTo|[[_,Xn,Yn]|_]]
						& not pos(Xn,Yn)
	<-	!go_to(Xn,Yn);
		!iterate(Open,Xf,Yf).

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
	<-	?costs(Up,Right,Down,Left);
		+cost(Up,X,Y-1);
		+cost(Right,X+1,Y);
		+cost(Down,X,Y+1);
		+cost(Left,X-1,Y);
		!new_node(X,Y-1,X,Y,up,[],L1);
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

// cria um novo no		
+!new_node(Xn,Yn,Xp,Yp,A,L,NL) : cost(Cn,Xn,Yn)
	<- 	+parent(Xp,Yp,Xn,Yn);
		+action_for(Xn,Yn,A);
		?costTo(CTp,Xp,Yp);
		CT = CTp + Cn; 
		+costTo(CT,Xn,Yn);
		Node = costTo(CT,Xn,Yn);
		?insert(Node,L,NL).

// vai da posicao atual ate (Xn,Yn)
// se (Xn,Yn) e um estado filho, executa a acao para chegar nele
+!go_to(Xn,Yn) : pos(X,Y) & parent(X,Y,Xn,Yn)
	<-	?action_for(Xn,Yn,A);
		A;
		!update_cost.
		
// se (Xn,Yn) e um estado inferior, faz o backtracking
+!go_to(Xn,Yn) : pos(X,Y) & ancestor(X,Y,Xn,Yn)
	<-	!go_forward(Xn,Yn).

// se (Xn,Yn) esta em outro ramo, e ha estado superior comum (Xa,Ya), volta ate
// (Xa,Ya) e depois vai ate (Xn,Yn)
+!go_to(Xn,Yn) : pos(X,Y) & common_ancestor(Xn,Yn,X,Y,Xa,Ya)
	<- 	!go_backward(Xa,Ya);
		!go_forward(Xn,Yn).		

// faz o backtracking das acoes para ir a um estado inferior
+!go_forward(X,Y) : pos(X,Y) <- true.

+!go_forward(X,Y) : action_for(X,Y,A) & A == up
	<- 	!go_forward(X,Y+1);  up; !update_cost.
	
+!go_forward(X,Y) : action_for(X,Y,A) & A == right
	<- 	!go_forward(X-1,Y); right; !update_cost.
	
+!go_forward(X,Y) : action_for(X,Y,A) & A == down
	<- 	!go_forward(X,Y-1); down; !update_cost.
	
+!go_forward(X,Y) : action_for(X,Y,A) & A == left
	<- 	!go_forward(X+1,Y); left; !update_cost.

// faz o backtracking das acoes para ir a um estado superior
+!go_backward(X,Y) : pos(X,Y) <- true.

+!go_backward(X,Y) : pos(X2,Y2) & action_for(X2,Y2,A) & A == up
	<- 	down; !update_cost; !go_backward(X,Y).
	
+!go_backward(X,Y) : pos(X2,Y2) & action_for(X2,Y2,A) & A == right
	<- 	left; !update_cost; !go_backward(X,Y).
	
+!go_backward(X,Y) : pos(X2,Y2) & action_for(X2,Y2,A) & A == down
	<- 	up; !update_cost; !go_backward(X,Y).
	
+!go_backward(X,Y) : pos(X2,Y2) & action_for(X2,Y2,A) & A == left
	<- 	right; !update_cost; !go_backward(X,Y).
	

// faz o backtracking do caminho para chegar no destino e imprime as etapas
+!print_path(Xi,Yi,Xf,Yf) : Xi == Xf & Yi == Yf
	<- 	.print("(",Xf,",",Yf,")").

+!print_path(Xi,Yi,Xf,Yf) : action_for(Xf,Yf,A) & A == up
	<- 	!print_path(Xi,Yi,Xf,Yf+1); .print("(",Xf,",",Yf,")").
	
+!print_path(Xi,Yi,Xf,Yf) : action_for(Xf,Yf,A) & A == right
	<- 	!print_path(Xi,Yi,Xf-1,Yf); .print("(",Xf,",",Yf,")").
	
+!print_path(Xi,Yi,Xf,Yf) : action_for(Xf,Yf,A) & A == down
	<- 	!print_path(Xi,Yi,Xf,Yf-1); .print("(",Xf,",",Yf,")").
	
+!print_path(Xi,Yi,Xf,Yf) : action_for(Xf,Yf,A) & A == left
	<- 	!print_path(Xi,Yi,Xf+1,Yf); .print("(",Xf,",",Yf,")").
		
