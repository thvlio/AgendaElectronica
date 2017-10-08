.data
# mensagens para quando o programa pedir dados ao usu�rio
msg1:		.asciiz	"Nome completo (m�ximo de 200 caracteres):"
msg2:		.asciiz	"Apelido (m�ximo de 30 caracteres):"
msg3:		.asciiz	"Endereco de e-mail (m�ximo de 200 caracteres):"
msg4:		.asciiz	"Numero do telefone\n(insira 10 digitos, sendo os 2 primeiros o DDD e os 8 �ltimos o telefone):"
# buffers para os campos do registro
bid:		.space	11
bname:		.space	201
bnick:		.space	31
bemail:		.space	201
bphone:		.space	14
aux:		.space	11
# endere�o dos buffers de nome, nick, email e phone
baddr:		.word	bname, bnick, bemail, bphone
# tamanhos dos buffers de nome, nick, email e phone
bsizes:		.word	0, 0, 0, 0
# mensagens variadas ao usu�rio
nfoundmsg:	.asciiz "Nenhum registro encontrado na busca. Aperte OK para voltar ao menu. "
confirmmsg:	.asciiz "Confirmada a operacao de insercao de dados? Nao sendo confirmada, o programa ira requisitar os dados novamente."
cancelmsg:	.asciiz "Tem certeza de que deseja cancelar a insercao dos dados?"
tryagainmsg:	.asciiz "Entrada invalida! Tente digitar o dado requerido novamente."





.text
######## PREPAREPROGRAM: faz algumas prepara��es iniciais ao programa ########
.globl	prepareProgram
prepareProgram:
	# salva ra
	addi	$sp, $sp, -4
	sw	$ra, 0($sp)
	# preparacoes (tem q ser executado antes de qualquer coisa)
	jal	createFile	# cria o arquivo se ele nao existir
	move	$a0, $zero
	jal	correctFile	# re-enumera os IDs do arquivo principal
	jal	refreshFile	# copia o auxiliar no principal e retorna quantos contatos leu
	# recupera ra
	lw	$ra, 0($sp)
	addi	$sp, $sp, 4
	jr	$ra





######## ADICIONAR REGISTRO: adiciona um novo registro na agenda ########
# a0 - n�mero de contatos
# a1 - flag que indica em qual arquivo escrever (0 - principal, 1 - auxiliar)
# v0 - retorna 1 se escreveu com sucesso, 0 se nao escreveu
# v1 - retorna o endere�o para o buffer do nome, bname
.globl	adicionarRegistro
adicionarRegistro:
	# salva registradores
	addi	$sp, $sp, -12
	sw	$ra, 0($sp)
	sw	$s0, 4($sp)
	sw	$s1, 8($sp)
	# salva o n�mero de contatos
	move	$s0, $a0
	# salva a flag de escrita
	move	$s1, $a1
	# adiciona o registro
	jal	clearAllBuffers	# limpa todos os buffers
	jal	getData		# coleta os dados do usu�rio pra um novo registro
	beq	$v0, $zero, donotwrite
	jal	getSizes	# calcula os tamanhos das strings que o usu�rio inseriu
	la	$a0, bsizes	# vetor de tamanhos
	move	$a1, $s1
	jal	metaInfo	# adiciona as informacoes do registro ao arquivo
	la	$a0, baddr	# endere�o de baddr como argumento
	la	$a1, bsizes	# vetor de tamanhos
	move	$a2, $s0	# numero de contatos atual
	move	$a3, $s1
	jal	addReg		# adiciona o registro no arquivo
	li	$v0, 1
donotwrite:
	# retorna o endere�o do buffer do nome
	la	$v1, bname
	# recupera registradores
	lw	$s1, 8($sp)
	lw	$s0, 4($sp)
	lw	$ra, 0($sp)
	addi	$sp, $sp, 12
	jr	$ra





######## MOSTRAR REGISTROS: mostra todos os registros na agenda ########
.globl	mostrarRegistros
mostrarRegistros:
	# salva ra
	addi	$sp, $sp, -4
	sw	$ra, 0($sp)
	# lista todos os registros
	jal	listNames	# esta fun��o poderia ter sido chamada diretamente de menu.asm
	# recupera ra
	lw	$ra, 0($sp)
	addi	$sp, $sp, 4
	jr	$ra





######## BUSCARREGISTRO: busca um registro na agenda ########
.globl	buscarRegistro
buscarRegistro:
	# salva registradores
	addi	$sp, $sp, -8
	sw	$ra, 0($sp)
	sw	$s0, 4($sp)
	# endere�o de mem�ria do buffer de registro alvo
	move	$s0, $a1
	# procura os registros com a letra especificada
	jal	searchReg
	beqz	$v0, nfound	#$v0 cont�m o n�mero de registros achados. Se $v0 for 0, nfound � chamada
	move	$a0, $v0
	# pede que o usu�rio escolha um dos contatos
	jal	chooseName
	beqz	$v0, cancel_search
	# recupera o ID do contato
	move	$a0, $v0
	move	$a1, $s0
	jal	recoverID	# a fun��o retorna o ID
	j	sair
cancel_search:
	# usu�rio cancelou a opera��o
	li	$t0, '\0'
	sb	$t0, 0($s0)
	j 	sair
nfound:
	# mensagem informando ao usu�rio que n�o foi achado nenhum registro
	la	$a0, nfoundmsg
	li	$a1, 1
	li	$v0, 55
	syscall
sair:
	# recupera registradores
	lw	$s0, 4($sp)
	lw	$ra, 0($sp)
	addi	$sp, $sp, 8
	jr	$ra





######## EDITARREGISTRO: edita o registro selecionado atualmente pelo programa ########
.globl	editarRegistro
editarRegistro:
	# salva registradores
	addi	$sp, $sp, -8
	sw	$ra, 0($sp)
	sw	$s0, 4($sp)
	# salva o endere�o do nome
	move	$s0, $a1
	# edita o ID selecionado da agenda
	jal	editReg		# retorna o endere�o de bname
	# atualiza o nome na mem�ria
	move	$a0, $s0	# destino: selectedreg
	move	$a1, $v0	# origem: bname
	li	$a2, -1		# copia at� o \0
	jal	copyStr
	# copia o arquivo auxiliar no arquivo princiapal
	jal	refreshFile
	# recupera registradores
	lw	$s0, 4($sp)
	lw	$ra, 0($sp)
	addi	$sp, $sp, 4
	jr	$ra





######## APAGARREGISTRO: apaga o registro selecionado atualmente pelo programa ########
.globl	apagarRegistro
apagarRegistro:
	# salva ra
	addi	$sp, $sp, -4
	sw	$ra, 0($sp)
	# pega o ID alvo
	lw	$t1, 0($a0)	# ID alvo
	# atualiza os dados na mem�ria
	# a0 - selectedID
	sw	$zero, 0($a0)	# nao tem mais ID selecionado
	# a1 - numContacts
	lw	$t0, 0($a1)
	addi	$t0, $t0, -1
	sw	$t0, 0($a1)	# menos um contato
	# a2 - selectedreg
	li	$t0, '\0'
	sb	$t0, 0($a2)	# nome vazio
	# apaga o ID selecionado da agenda
	move	$a0, $t1
	jal	correctFile
	jal	refreshFile
	# recupera ra
	lw	$ra, 0($sp)
	addi	$sp, $sp, 4
	jr	$ra





######## APAGARLISTA: apaga toda a lista de contatos atual ########
.globl	apagarLista
apagarLista:
	# salva ra
	addi	$sp, $sp, -4
	sw	$ra, 0($sp)
	# atualiza os dados na mem�ria
	# a0 - selectedID
	sw	$zero, 0($a0)	# nao tem mais ID selecionado
	# a1 - numContacts
	sw	$zero, 0($a1)	# nao tem mais contatos
	# a2 - selectedreg
	li	$t0, '\0'
	sb	$t0, 0($a2)	# nome vazio
	# apaga tudo
	jal	eraseFile
	# recupera ra
	lw	$ra, 0($sp)
	addi	$sp, $sp, 4
	jr	$ra





######## GETSIZES: calcula os tamanhos de cada entrada do usu�rio e guarda num array ########
.globl	getSizes
getSizes:
	# salva registradores
	addi	$sp, $sp, -16
	sw	$s0, 12($sp)
	sw	$s1, 8($sp)
	sw	$s2, 4($sp)
	sw	$ra, 0($sp)
	# seta os negocios
	la	$s0, baddr
	la	$s1, bsizes
	li	$s2, 0
loop_baddr:	# calcula o tamanho e guarda na memoria
	add	$t0, $s0, $s2
	lw	$a0, 0($t0)
	jal	strSize
	add	$t1, $s1, $s2
	sw	$v0, 0($t1)
	addi	$s2, $s2, 4
	bne	$s2, 16, loop_baddr
	# recupera registradores
	lw	$ra, 0($sp)
	lw	$s2, 4($sp)
	lw	$s1, 8($sp)
	lw	$s0, 12($sp)
	addi	$sp, $sp, 16
	jr	$ra





######## CLEARALLBUFFERS: limpa todos os buffers, colocando '\0' em todos os caracteres ########
.globl	clearAllBuffers
clearAllBuffers:
	# salva registradores
	addi	$sp, $sp, -4
	sw	$ra, 0($sp)
	# limpa bid
	la	$a0, bid
	li	$a1, 11
	jal	clearArray
	# limpa bname
	la	$a0, bname
	li	$a1, 201
	jal	clearArray
	# limpa bnick
	la	$a0, bnick
	li	$a1, 31
	jal	clearArray
	# limpa bemail
	la	$a0, bemail
	li	$a1, 201
	jal	clearArray
	# limpa bphone
	la	$a0, bphone
	li	$a1, 14
	jal	clearArray
	# limpa aux
	la	$a0, aux
	li	$a1, 11
	jal	clearArray
	# recupera os registradores
	lw	$ra, 0($sp)
	addi	$sp, $sp, 4
	jr	$ra





######## GETDATA: pega os dados do registro do usu�rio ########
.globl	getData
getData:
	# salva os registradores usados
	addi	$sp, $sp, -12
	sw	$ra, 0($sp)
	sw	$s0, 4($sp)
	sw	$s1, 8($sp)
lnome:	# le o nome completo da pessoa
	li	$s0, 0	# leitura 0
	la	$a0, msg1
	la	$a1, bname
	li	$a2, 201
	li	$v0, 54
	syscall
	beq 	$a1, 0, lnick		# testa o que o usu�rio digitou/selecionou. se n�o deu problema, continua
	beq 	$a1, -2, lcancel	# vai para lcancel se o usu�rio apertou 'cancelar'
	jal	tryagain	# sequ�ncia de c�digo que faz o programa voltar � inser��o dos dados pendentes
	j	lnome
lnick:	# le o apelido da pessoa
	li	$s0, 1	# leitura 1
	la	$a0, msg2
	la	$a1, bnick
	li	$a2, 31
	li	$v0, 54
	syscall
	beq 	$a1, 0, lemail
	beq 	$a1, -2, lcancel
	jal	tryagain
	j	lnick
lemail:	# le o email da pessoa
	li	$s0, 2	# leitura 2
	la	$a0, msg3
	la	$a1, bemail
	li	$a2, 201
	li	$v0, 54
	syscall
	beq 	$a1, 0, lphone
	beq 	$a1, -2, lcancel
	jal	tryagain
	j	lemail
lphone:	# le o telefone da pessoa
	li	$s0, 3	# leitura 3
	la	$a0, msg4
	la	$a1, aux
	li	$a2, 11
	li	$v0, 54
	syscall
	beq 	$a1, -2, lcancel
	la	$a0, aux
	jal	strSize		# checa o tamanho de aux
	move	$s1, $v0		# $v0 � o tamanho da string
	add	$s1, $s1, $a1		# Se o status for 'OK', $a1=0 e $s1 n�o vai mudar
	bne	$v0, 10, notparsed	# se nao for tamanho 10, ja sai
	la	$a0, aux	# verifica se so tem numeros em aux
	jal	parsePhone	# retorna -1 se der erro
	bnez	$v0, notparsed		# s� est� ok se retornar 0
	beq	$s1, 10, convert	# S� converte para o padr�o de d�gitos se $t0 permanecer 10(n�mero de d�gitos do telefone)
notparsed:	
	jal	tryagain
	j	lphone
convert:
	li	$t2, '('	#seta os d�gitos 0, 3 e 8 como '(' , ')' e '-' , respectivamente
	li	$t3, ')'
	li	$t4, '-'
	sb	$t2, bphone
	sb	$t3, bphone + 3
	sb	$t4, bphone + 8
	move	$t8, $zero
	move 	$t9, $zero
ciclo:
	lb	$t1, aux($t9)	#la�o que iguala os d�gitos de bphone aos do aux, a n�o ser os d�gitos 0,3 e 8
	addi	$t8, $t8, 1	# faz isso independente de quantos caracteres foram inseridos
	beq	$t8, 3, ciclo
	beq	$t8, 8, ciclo
	sb	$t1, bphone($t8)
	addi	$t9, $t9,1
	beq	$t8, 13, confirm
	j 	ciclo
confirm:
	la	$a0, confirmmsg
	li	$v0, 50
	syscall
	bnez	$a0, lnome	# confirma se estes s�o os dados, sen�o volta ao in�cio da fun��o
	j	exit	# se confirmar, sai da fun��o
lcancel:
	li	$v0, 50	#Questionamento sobre o cancelamento da opera��o
	la	$a0, cancelmsg
	syscall
	# se confirmar a sa�da, sai da fun��o e retorna 0
	move	$v0, $zero
	beq	$a0, 0, exit
	# sen�o, volta de onde parou
	beq	$s0, 0, lnome
	beq	$s0, 1, lnick
	beq	$s0, 2, lemail
	beq	$s0, 3, lphone
exit:	# recupera os registradores e sai da fun��o
	lw	$ra, 0($sp)
	lw	$s0, 4($sp)
	lw	$s1, 8($sp)
	addi	$sp, $sp, 12
	jr	$ra
tryagain:			#Fun��o que avisa entrada inv�lida
	li 	$v0, 55
	la 	$a0, tryagainmsg
	li	$a1, 0
	syscall
	jr	$ra
