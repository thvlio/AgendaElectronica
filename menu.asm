.data
# mensagens do menu inicial. tamanhos: 245, 34, 23 e 7
header:		.asciiz	"=====================\n   AGENDA ELETRÔNICA   \n=====================\nEscolha uma opção:\n1. Adicionar novo registro\n2. Mostrar lista de registros\n3. Buscar registro\n4. Editar registro selecionado\n5. Apagar registro selecionado\n6. Apagar toda a lista de contatos\n7. Sair do programa\n"
numregmsg:	.asciiz	"\nTotal de contatos na agenda: 000\n"	# numero começa em 30
regmsg:		.asciiz	"\nRegistro selecionado: "
placeholder:	.asciiz	"nenhum\n"
# todas as mensagens são concatenadas em mainmsg
mainmsg:	.space	550
# informações da database
selectedreg:	.space	210
selectedID:	.word	0
namesize:	.word	0
numContacts:	.word	0
# mensagens variadas
tryagainmsg:	.asciiz	"ERRO: ENTRADA INVÁLIDA. TENTE NOVAMENTE"
goodbyemsg:	.asciiz	"VALEU FERINHA"
lettermsg:	.asciiz	"Digite a primeira letra do nome."
cancelmsg:	.asciiz "Tem certeza que deseja cancelar a operação de busca?"
confirmexit:	.asciiz "Tem certeza que deseja sair do programa?"
noselectionmsg:	.asciiz	"Nenhum contato foi selecionado. Use a função de busca para selecionar um contato e tente novamente."
fullmsg:	.asciiz	"A agenda está com o limite máximo de contatos (999)."
emptymsg:	.asciiz	"Nao há contatos na agenda."
deletemsg:	.asciiz "Tem certeza que deseja apagar o contato selecionado?"
editmsg:	.asciiz	"Tem certeza que deseja editar o contato selecionado? Você só pode editar o contato inteiro, e não campos específicos."
deleteallmsg:	.asciiz	"Tem certeza que deseja apagar toda a lista? Esta operação não pode ser revertida."
letter:		.space	2





.text
######## MENU PRINCIPAL: a main do programa é esta função, que mostra o menu principal ao usuário ########
.globl main
main:
	# dentre outras coisas, prepareProgram retorna o número de contatos
	jal	prepareProgram
	sw	$v0, numContacts
	# limpa os arrays alocados
	la	$a0, mainmsg
	li	$a1, 550
	jal	clearArray
	la	$a0, selectedreg
	la	$a1, 210
	jal	clearArray
	# constrói a primeira parte da mensagem principal, que não precisa ser em loop
	jal	buildMessage1
menuloop:
	# constrói a segunda parte da mensagem principal, que pode mudar a cada iteração do menu
	jal	buildMessage2
	# imprime a mensagem principal
	la	$a0, mainmsg
	li	$v0, 51
	syscall
	# verificações de erro
	beq	$a1, -1, tryagain
	beq	$a1, -2, exit
	beq	$a1, -3, tryagain
	# escolha do usuario
	beq	$a0, 1, op1
	beq	$a0, 2, op2
	beq	$a0, 3, op3
	beq	$a0, 4, op4
	beq	$a0, 5, op5
	beq	$a0, 6, op6
	# adicionar opcoes aqui
	beq	$a0, 7, exit
	# se nao correspondeu a nenhuma opção, é porque é inválida
	j	tryagain

######## OPÇÕES DO MENU: abaixo estão as respostas à todas as possíveis entradas ########
#### OP1: insere novo registro na agenda ####
op1:
	# verifica se o número de contatos está no limite
	lw	$t0, numContacts
	beq	$t0, 999, error_op1
	# se estiver ok, manda o número de contatos como argumento para adicionarRegistro
	move	$a0, $t0
	move	$a1, $zero	# flag que indica escrita no arquivo principal
	jal	adicionarRegistro
	# aqui o número de contatos é atualizado
	lw	$t0, numContacts
	add	$t0, $t0, $v0	# v0 = 0 quando falha e v0 = 1 quando adiciona com sucesso
	sw	$t0, numContacts
	j	menuloop
error_op1:
	# a mensagem de agenda cheia é mostrada
	la	$a0, fullmsg
	li	$a1, 0
	li	$v0, 55
	syscall
	j	menuloop

#### OP2: mostra uma lista de registros ao usuário ####
op2:
	# verifica se ha algum contato para mostrar
	lw	$t0, numContacts
	beqz	$t0, error_op2
	# passa como argumento para a função o número de contatos
	lw	$a0, numContacts
	jal	mostrarRegistros
	j	menuloop
error_op2:
	# não há contatos para mostrar
	la	$a0, emptymsg
	li	$a1, 1
	li	$v0, 55
	syscall
	j	menuloop

#### OP3: permite que o usuário busque um registro na agenda ####
op3:
	# verifica se há contatos na agenda
	lw	$t0, numContacts
	beqz	$t0, error2_op3
	# pede para que o usuario entre com uma letra
	la	$a0, lettermsg
	la	$a1, letter
	li	$a2, 2
	li	$v0, 54
	syscall
	blt	$a1, -2, error1_op3	# checa por erros de entrada invalida
	beq	$a1, -2, cancel_op3	# checa por cancelamento
	lbu	$a0, letter	# se tudo estiver correto, carrega a letra como argumento
	la	$a1, selectedreg	# e a string onde estará o nome do registro
	jal	buscarRegistro		# retorna o ID
	sw	$v0, selectedID		# armazena o ID encontrado
	j	menuloop
error1_op3:
	la	$a0, tryagainmsg
	li	$a1, 0	# error message
	li	$v0, 55
	syscall
	j	op3
error2_op3:
	# não há contatos para mostrar
	la	$a0, emptymsg
	li	$a1, 1
	li	$v0, 55
	syscall
	j	menuloop
cancel_op3:
	la	$a0, cancelmsg	
	li	$v0, 50
	syscall
	beqz	$a0, menuloop
	j 	op3

#### OP4: permite ao usuário editar o registro selecionado pela op3 ####
op4:
	# se nao houver contato selecionado, nao faz nada
	lw	$t0, selectedID
	beqz	$t0, error_op4
	# pergunta se o usuario tem certeza que quer editar o contato selecionado
	la	$a0, editmsg	
	li	$v0, 50
	syscall
	bnez	$a0, menuloop	# se cancelar, volta ao menu
	# carrega alguns argumentos
	lw	$a0, selectedID
	la	$a1, selectedreg
	jal	editarRegistro
	j	menuloop
error_op4:
	la	$a0, noselectionmsg
	li	$a1, 0
	li	$v0, 55
	syscall
	j	menuloop

#### OP5: permite ao usuário apagar o registro selecionado pela op3 ####
op5:
	# se nao houver contato selecionado, nao faz nada
	lw	$t0, selectedID
	beqz	$t0, error_op5
	# pergunta se o usuario tem certeza que quer apagar o contato selecionado
	la	$a0, deletemsg	
	li	$v0, 50
	syscall
	bnez	$a0, menuloop	# se cancelar, volta ao menu
	# carrega os endereços de memória pra função atualizar
	la	$a0, selectedID
	la	$a1, numContacts
	la	$a2, selectedreg
	jal	apagarRegistro
	j	menuloop
error_op5:
	la	$a0, noselectionmsg
	li	$a1, 0
	li	$v0, 55
	syscall
	j	menuloop

#### OP6: permite ao usuário apagar toda a lista ####
op6:
	# se nao houver lista, nao faz nada
	lw	$t0, numContacts
	beqz	$t0, error_op6
	# pergunta se o usuario tem certeza que quer apagar toda a lista
	la	$a0, deleteallmsg	
	li	$v0, 50
	syscall
	bnez	$a0, menuloop	# se cancelar, volta ao menu
	# carrega os endereços de memória pra função atualizar
	la	$a0, selectedID
	la	$a1, numContacts
	la	$a2, selectedreg
	jal	apagarLista
	j	menuloop
error_op6:
	la	$a0, emptymsg
	li	$a1, 0
	li	$v0, 55
	syscall
	j	menuloop

#### TRYAGAIN: a entrada inserida é inválida, o usuário deve tentar novamente ####
tryagain:	# erro: escolha invalida
	la	$a0, tryagainmsg
	li	$a1, 0	# error message
	li	$v0, 55
	syscall
	j	menuloop

#### EXIT: sai do programa ####
exit:
	la	$a0, confirmexit
	li	$v0, 50
	syscall
	bne	$a0, 0, menuloop
	# sair do programa
	la	$a0, goodbyemsg
	li	$a1, 1	# info message
	li	$v0, 55
	syscall
	li	$v0, 10
	syscall





######## BUILDMESSAGE1: contrói a primeira parte da mensagem principal ########
buildMessage1:
	# ralva registradores
	addi	$sp, $sp, -4
	sw	$ra, 0($sp)
	# coloca header no começo de mainmsg
	la	$a0, mainmsg
	la	$a1, header
	li	$a2, 280
	jal	copyStr
	# coloca numregmsg depois de mainmsg
	la	$a0, mainmsg+280
	la	$a1, numregmsg
	li	$a2, 34
	jal	copyStr
	# coloca regmsg depois de numregmsg
	la	$a0, mainmsg+314
	la	$a1, regmsg
	li	$a2, 23
	jal	copyStr
	# recupera registradores
	lw	$ra, 0($sp)
	addi	$sp, $sp, 4
	jr	$ra





######## BUILDMESSAGE2: contrói a segunda parte da mensagem principal ########
buildMessage2:
	# ralva registradores
	addi	$sp, $sp, -4
	sw	$ra, 0($sp)
	# calcula o tamanho do nome
	la	$a0, selectedreg
	jal	strSize
	sw	$v0, namesize
	# se o nome estiver vazio
	beqz	$v0, loadplaceholder
	# coloca o nome depois de regmsg
	la	$a0, mainmsg+337
	la	$a1, selectedreg
	move	$a2, $v0
	jal	copyStr
	# coloca alguns caracteres finais no nome
	lw	$t0, namesize
	addi	$t0, $t0, 337
	li	$t1, '\n'
	sb	$t1, mainmsg($t0)
	li	$t1, '\0'
	sb	$t1, mainmsg+1($t0)
	j	messagebuilt
loadplaceholder:
	# limpa o nome que esta ali anteriormente
	la	$a0, mainmsg+337
	li	$a1, 210
	jal	clearArray
	# coloca o placeholder depois de regmsg
	la	$a0, mainmsg+337
	la	$a1, placeholder
	li	$a2, 7
	jal	copyStr
messagebuilt:
	# escreve o numero de contatos
	la	$a0, mainmsg+310	
	lw	$a1, numContacts
	li	$a2, 3
	jal	numToStr
	# recupera registradores
	lw	$ra, 0($sp)
	addi	$sp, $sp, 4
	jr	$ra