ASSUME CS:CODE,DS:DATA,ES:DATA,SS:STCK

;;Definindo constantes globais
CR        	EQU    	0DH ;caractere ASCII "CarriageReturn" 
LF        	EQU    	0AH ;caractere ASCII "LineFeed"
TAB			EQU		9	;caractere ASCII "Tab"
BCK			EQU		8	;caractere ASCII "BackSpace"
MAX			EQU		12	;Tamanho máximo do arquivo
ESCAPE		EQU		27	;caractere ASCII "Escape"
ESPACO		EQU		32	;caractere ASCII "Espaco"

;;Seguimento de dados
DATA     		SEGMENT 

MsgPedeNome			DB	'Digite o nome do arquivo:','$'
MsgFooter			DB	'Digite ESC para encerrar execucao.','$'
MsgFinalizacao		DB 	'Programa terminado :-)','$'
MsgErroMuitoGrande	DB	'Nome muito grande, digite algo de ate 8 caracteres','$'
MsgErroFuncaoInv	DB	'Funcao invalida','$'
MsgErroNaoEncontra	DB	'Arquivo nao encontrado','$'
MsgErroSemCaminho	DB	'Caminho nao encontrado','$'
MsgErroSemHandlers	DB	'Nao ha mais handlers','$'
MsgErroAcessoNegado	DB	'Acesso negado','$'
MsgErroModoInvalido	DB	'Modo de acesso invalido','$'
MsgHeader			DB	'Arquivo: ','$'
nomeDoArquivo		DB	12 DUP(0)
MsgHeader2			DB	' ','$'

buffer    			DB 	0
handler   			DW 	0 

displayAuxiliar		DW 	30 DUP(0)
contadorAuxiliar	DB 	0
temEspaco			DB 	0

nomeArquivoTamanho	DB	0
mensagemDoArquivo	DB 	3000 DUP(0)

DATA     		ENDS
;;Fim do seguimento de dados

;;Inicializando pilha (Não utilizado)
STCK			SEGMENT	stack
				DW 	128 DUP(?)
STCK			ENDS
;;Fim do seguimento de pilha

;;Seguimento de codigo
CODE			SEGMENT
;;IP e CS apontam para comeco
comeco:
	;;Inicializa registradores de seguimento
	MOV AX, DATA
	MOV DS, AX
	MOV ES, AX
	
;;Seta as variaveis para chamar interrupcao de limpeza de tela
limpaTela:
	MOV AH, 6
	MOV AL, 0
	MOV BH, 07H
	MOV CH, 0
	MOV CL, 0
	MOV DH, 24
	MOV DL, 79
	INT 10H	;;Chama a interrupcao 
	
;;Move o cursor pro inicio
	MOV AH, 2
	MOV DH, 0
	MOV DL, 0
	MOV BH, 0
	INT 10H
	
;;Coloca a mensagem inicial que pede o nome do arquivo na tela
	LEA DX, MsgPedeNome
	MOV AH, 9
	INT 21H

;;Inicializa variaveis
	MOV nomeArquivoTamanho, 0
	LEA DI, nomeDoArquivo
	
;;Lendo caracteres
lendo:
	MOV AH, 0
	INT 16H
	
	;;Verifica se foi enter
	CMP AL, CR
	JE	finalNome
	
	;;Verifica se foi backspace
	CMP	AL, BCK
	JE	trataBackspace
	
	;;Verifica se o atingiu o tamanho maximo
	CMP nomeArquivoTamanho, MAX
	JGE continuaEscrevendo ;;Se houver atingido tamanho maximo nao salva no seguimento
	MOV [DI], AL
	INC DI			;;Salva o caractere no seguimento e incrementa

continuaEscrevendo:
	MOV AH, 2
	MOV DL, AL
	INT 21H			;;Escreve o caractere na tela
	INC nomeArquivoTamanho ;;Incrementa o tamanho do arquivo
	JMP lendo		;;Le o proximo caractere
	
trataBackspace:
;;Representando backspace visualmente
	CMP nomeArquivoTamanho, 0
	JE	lendo
	MOV AH, 2
	MOV DL, BCK
	INT 21H
	
	MOV AH, 2
	MOV DL, ' '
	INT 21H
	
	MOV AH, 2
	MOV DL, BCK
	INT 21H
	
	CMP nomeArquivoTamanho, 13
	JG	decrementaApenasVar
	DEC DI ;;Se o tamanho do nome for menor que o tamanho maximo, decrementar do registrador
decrementaApenasVar:
	DEC nomeArquivoTamanho ;;Se nao, apenas decrementara a variavel
	
	JMP lendo
	
finalNome:
	CMP nomeArquivoTamanho, 0 ;;Se o usuario pressionou enter e nao escreveu nada
	JE	vaiProFim
	SUB DI, 4				;;Volta 4 casas
	CMP [DI], 742EH			;;Verifica se e ponto final
	JNE adicionaExtensao 	;;Se nao for, adiciona extensao
	ADD DI, 4				;;Se for termina finaliza string
finalizaNome:
	MOV [DI], 0
	INC DI
	MOV [DI], '$'
	JMP abreArquivo
	
vaiProFim:
	JMP termina

;;Adiciona extensao
adicionaExtensao:
	CMP	nomeArquivoTamanho, 8
	JG	erroMuitoGrande
	ADD DI,4
	MOV [DI],'.'
	INC DI
	MOV [DI],'t'
	INC DI
	MOV [DI],'x'
	INC DI
	MOV [DI],'t'
	INC DI
	
	JMP	finalizaNome

erroMuitoGrande:
;;Move o cursor pra segunda linha
	MOV AH, 2
	MOV DH, 2
	MOV DL, 0
	MOV BH, 0
	INT 10H
	
;;Coloca a mensagem de erro por nome ser grande demais
	LEA DX, MsgErroMuitoGrande
	MOV AH, 9
	INT 21H
	
	MOV AH, 0
	INT 16H
	
	MOV nomeArquivoTamanho, 0
	
	JMP limpaTela

abreArquivo:
	MOV AH, 3DH
	MOV AL, 0
	LEA DX, nomeDoArquivo
	INT 21H
	JC 	administradorDeErros
	MOV handler, AX	
	LEA DI, mensagemDoArquivo
	JMP leArquivo

administradorDeErros:
;;Move o cursor pra segunda linha
	MOV AH, 2
	MOV DH, 2
	MOV DL, 0
	MOV BH, 0
	INT 10H
	
	MOV nomeArquivoTamanho, 0
	
	CMP AL, 1
	JE 	funcaoInvalida
	CMP AL, 2
	JE 	arquivoNaoEncontrado
	CMP AL, 3
	JE 	caminhoNaoEncontrado
	CMP AL, 4
	JE 	naoHaMaisHandlers
	CMP AL, 5
	JE	acessoNegado
	CMP AL, 6
	JE	modoDeAcessoInvalido
	
funcaoInvalida:
;;Coloca a devida mensagem de erro na segunda linha
	LEA DX, MsgErroFuncaoInv
	MOV AH, 9
	INT 21H
	
	MOV AH, 0
	INT 16H
	
	JMP limpaTela
arquivoNaoEncontrado:
;;Coloca a devida mensagem de erro na segunda linha
	LEA DX, MsgErroNaoEncontra
	MOV AH, 9
	INT 21H
	
	MOV AH, 0
	INT 16H
	
	JMP limpaTela
caminhoNaoEncontrado:
;;Coloca a devida mensagem de erro na segunda linha
	LEA DX, MsgErroSemCaminho
	MOV AH, 9
	INT 21H
	
	MOV AH, 0
	INT 16H
	
	JMP limpaTela
naoHaMaisHandlers:
;;Coloca a devida mensagem de erro na segunda linha
	LEA DX, MsgErroSemHandlers
	MOV AH, 9
	INT 21H
	
	MOV AH, 0
	INT 16H
	
	JMP limpaTela
acessoNegado:
;;Coloca a devida mensagem de erro na segunda linha
	LEA DX, MsgErroAcessoNegado
	MOV AH, 9
	INT 21H
	
	MOV AH, 0
	INT 16H
	
	JMP limpaTela
modoDeAcessoInvalido:
;;Coloca a devida mensagem de erro na segunda linha
	LEA DX, MsgErroModoInvalido
	MOV AH, 9
	INT 21H
	
	MOV AH, 0
	INT 16H
	
	JMP limpaTela
	
leArquivo:
;;Le caractere
	MOV AH, 3FH
	MOV BX, handler
	MOV CX, 1
	LEA DX, buffer
	INT 21H
;;Verifica se terminou
	CMP AX, 0
	JE	fechaArquivo
;;Se nao verifica se é espaco
	MOV BL, buffer
	CMP BL, ESPACO
	JE	verificaEspacoDuplo
;;Se nao houver seta o flag para 0, passa o caractere pra memoria e incrementa DI
	MOV temEspaco, 0
;;Se o caractere for TAB não incrementa DI
	CMP BL, TAB
	JE 	leArquivo
	
	MOV [DI], BL
	INC DI
	
	JMP leArquivo
	
verificaEspacoDuplo:
;;Se houver espaco duplo repete a leitura sem incrementar DI
	CMP temEspaco, 1
	JE  leArquivo
;;Se nao houver espaco duplo liga o flag de que encontrou um espaco e incrementa DI
	MOV temEspaco, 1
	MOV [DI], BL
	INC DI

	JMP leArquivo
	
fechaArquivo:
;;Coloca o cifrao no final e fecha arquivo
	MOV [DI], '$'
	MOV AH, 3EH
	MOV BX, handler
	INT 21H

;;Header
	MOV	CH, 0
	MOV CL, 0
	MOV DH, 0
	MOV DL, 79
	MOV BH, 1FH
	MOV AL, 1
	MOV AH, 6
	INT 10H
;;Footer
	MOV CH, 24
	MOV CL, 0
	MOV DH, 24
	MOV DL, 79
	MOV BH, 1FH
	MOV AL, 1
	MOV AH, 6
	INT 10H
;;Mensagem footer
	MOV AH, 2 	;;Cursor
	MOV DH, 24
	MOV DL, 0
	MOV BH, 0
	INT 10H

	LEA	DX, MsgFooter
	MOV	AH, 9
	INT	21H

;;Move cursor para segunda linha
	MOV AH, 2
	MOV DH, 1
	MOV DL, 0
	MOV BH, 0
	INT 10H

;;Inicializando variaveis
	LEA	SI, mensagemDoArquivo
	LEA	DI, displayAuxiliar
	MOV	contadorAuxiliar, 0
	 
formata:
	MOV	[DI], SI
	 
procuraCarriageReturn:
	MOV	BL, [SI]
;;Verifica se e o fim da linha
	CMP	BL, '$'
	JE	fimFormatacao
;;Verifica se e CarriageReturn
	CMP	BL, CR
	JE	criaFimDaLinha
;;Incrementa contadorAuxiliar e verifica se esta no fim da linha, se nao estiver vai pro proximo caractere
	INC	SI
	INC	contadorAuxiliar
	CMP	contadorAuxiliar, 79
	JNE	procuraCarriageReturn
	 
;;Se nao ouver um carriageReturn, volta os indices para encontrar o ultimo espaço
encontraUltimoEspaco:
	MOV	contadorAuxiliar, 0
	MOV	BL, [SI]
	CMP	BL, ESPACO
	JE	criaFimDaLinha
	DEC	SI
	JMP	encontraUltimoEspaco
	
;;Quando encontrar um espaco ou carriage return, termina a linha e imprime na tela tudo que houve antes dele dando carriageReturn e lineFeed
criaFimDaLinha:
	MOV	DX, [DI]
	MOV	AL, '$'
	MOV	[SI], AL
	MOV AH, 9
	INT 21H
	
	MOV AH, 2
	MOV	DL, CR
	INT 21H
	
	MOV	AH, 2
	MOV	DL, LF
	INT	21H
	
	CMP	BL, CR
	JE	isCarriage
	
	CMP	BL, ESPACO
	JE	isSpace
	
isCarriage:
	ADD	SI, 2
	INC	DI
	MOV	contadorAuxiliar, 0
	JMP formata
	
isSpace:
	INC	SI
	INC	DI
	JMP	formata

fimFormatacao:
	MOV	DX, [DI]
	MOV AH, 9
	INT 21H

;;Testa se o usuario digitou escape
testaEsc:
	MOV AH, 0
	INT 16H
	CMP AL, ESCAPE
	JE	voltar
	JMP	testaEsc
voltar:
	JMP limpaTela
	
termina:
;;Limpa a tela
	MOV AH, 6
	MOV AL, 0
	MOV BH, 07H
	MOV CH, 0
	MOV CL, 0
	MOV DH, 24
	MOV DL, 79
	INT 10H		;;Chama a interrupcao
	
;;Move o cursor
	MOV AH, 2
	MOV DH, 0
	MOV DL, 0
	MOV BH, 0
	INT 10H
	
;;Coloca mensagem final na tela
	LEA	DX, MsgFinalizacao
	MOV AH, 9
	INT 21H
	
	MOV AX, 4C00H
	INT 21H

CODE			ENDS

				END	comeco ;;Aponta IP para comeco