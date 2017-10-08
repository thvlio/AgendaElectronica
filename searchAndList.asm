.data
# nome do arquivo texto
fileName:	.asciiz	"db.txt"
auxFileName:	.asciiz	"auxdb.txt"
# mensagens para mostrar na hora de mostrar a lista de contatos
listMsg:	.asciiz "Lista de contatos:\n(pagina 000 de 000)\n\n"	# addr 27 e addr 34 sao as paginas, tamanho 40
searchMsg:	.asciiz "Os contatos encontrados estao listado abaixo. Escolha um dos contatos ou escolha 0 para avancar:\n(pagina 000 de 000)\n\n"	# addr 105 e addr 112 sao as paginas, tamanho 118
tryagainmsg:	.asciiz	"ERRO: ENTRADA INVALIDA. TENTE NOVAMENTE"
cancelmsg:	.asciiz	"Tem certeza que deseja cancelar a operacao de busca?"
name:		.asciiz "Nome: "	# tamanho 6
short:		.asciiz "\nApelido: "	# tamanho 10
email:		.asciiz "\nE-mail: "	# tamanho 9
phone:		.asciiz "\nTelefone: "	# tamanho 11
# mensagem de confirmacao
confirmmsg1:	.asciiz	"Confirmar selecao do contato \""
confirmmsg2:	.space	250
# buffer temporario para armazenar 5 registros (para mostrar na lista de contatos)
contacts:	.space	2700
# buffer que armazena um registro da agenda temporariamente
regBuffer:	.space	500
# buffer que armazena cinco nomes de registros
nameBuffer:	.space	1100
namePos:	.word	0, 0, 0, 0, 0
# utilidade publica
fieldSizes:	.word	0, 0, 0, 0, 0
# tamanhos das variaveis
msgSizes:	.word	6, 10, 9, 11
msgAddr:	.word	name, short, email, phone





.text
######## FORMATDATA: formata os dados lidos para mostrar ao usu�rio ########
#### ENTRADAS ####
# a0 - posi��o de escrita no vetor contacts
#### VARI�VEIS ####
# s0 - posi��o vari�vel de escrita em contacts
# s1 - usado para iterar nas mensagens usadas na formata��o
# s2 - usado para iterar no buffer do registro
# s3 - posi��o inicial de escrita em contacts
#### SA�DAS ####
# v0 - quantos caracteres foram escritos em contacts
formatData:
	# salva registradores
	addi	$sp, $sp, -20
	sw	$ra, 0($sp)
	sw	$s0, 4($sp)
	sw	$s1, 8($sp)
	sw	$s2, 12($sp)
	sw	$s3, 16($sp)
	# posi��o atual em contacts
	move	$s0, $a0
	# itera nas mensagens
	move	$s1, $zero
	# itera no buffer do registro
	move	$s2, $zero
	# salva p comparar mais tarde
	move	$s3, $a0
format_loop:
	# prepara��o do campo
	la	$a0, contacts($s0)
	lw	$a1, msgAddr($s1)
	lw	$a2, msgSizes($s1)
	add	$s0, $s0, $a2	# d� um passo em contacts do tamanho da mensagem escrita
	jal	copyStr
	# copia o campo na string
	la	$a0, contacts($s0)
	la	$a1, regBuffer+20($s2)
	lw	$a2, fieldSizes+4($s1)
	add	$s0, $s0, $a2	# d� um passo em contacts do tamanho do registro
	add	$s2, $s2, $a2	# d� um passo em regBuffer do tamanho do registro
	addi	$s2, $s2, 2	# d� um passo de 2 em regBuffer por conta dos separadores
	jal	copyStr
	addi	$s1, $s1, 4	# avan�a a posi��o do array de mensagens/tamanhos
	bne	$s1, 16, format_loop
	# coloca dois '\n' ao final
	li	$t0, '\n'
	sb	$t0, contacts($s0)
	sb	$t0, contacts+1($s0)
	addi	$s0, $s0, 2
	# retorna quanto bytes escreveu em contacts
	sub	$v0, $s0, $s3
	# recupera registradores
	lw	$s3, 16($sp)
	lw	$s2, 12($sp)
	lw	$s1, 8($sp)
	lw	$s0, 4($sp)
	lw	$ra, 0($sp)
	addi	$sp, $sp, 20
	jr	$ra





######## PAGENUMBER: calcula e escreve o n�mero da p�gina numa string ########
#### ENTRADAS ####
# a0 - endere�o da string de destino
# a1 - numero de contatos
#### VARI�VEIS ####
# n�o tem
#### SA�DAS ####
# n�o tem
pageNumber:
	# salva registradores
	addi	$sp, $sp, -4
	sw	$ra, 0($sp)
	# pega o numero de contatos e calcula quantas paginas teremos/qual � a p�gina atual
	move	$t1, $s1
	div	$t1, $t1, 5
	mfhi	$t0
	beq	$t0, $zero, exact
	addi	$t1, $t1, 1	# pagina quebrada
exact:
	# escreve o n�mero de p�ginas no total
	move	$a1, $t1
	li	$a2, 3
	jal	numToStr
	# recupera registradores
	lw	$ra, 0($sp)
	addi	$sp, $sp, 4
	jr	$ra





######## LISTNAMES: lista todos os nomes da agenda para o usu�rio ########
#### ENTRADAS ####
# n�o tem
#### VARI�VEIS ####
# s0 - descritor do arquivo
# s1 - numero de contatos lidos no total
# s2 - posicao de escrita no array contacts / indica se leu EOF
#### SA�DAS ####
# n�o tem
.globl	listNames
listNames:
	# salva registradores
	addi	$sp, $sp, -16
	sw	$ra, 0($sp)
	sw	$s0, 4($sp)
	sw	$s1, 8($sp)
	sw	$s2, 12($sp)
	# n�mero total de contatos na agenda
	move	$s1, $a0
	# abre o arquivo p leitura
	la	$a0, fileName
	li	$a1, 0
	li	$v0, 13
	syscall
	move	$s0, $v0
	# determina o total de p�ginas e escreve em listMsg
	la	$a0, listMsg+34
	move	$a1, $s1
	jal	pageNumber
	move	$s1, $zero	# numero de contatos lidos
readandprint_loop:	
	move	$s2, $zero	# posi��o de escrita em contacts
readinfo_loop:
	# le um registro do arquivo
	move	$a0, $s0
	la	$a1, regBuffer
	la	$a2, fieldSizes
	jal	readRegLine
	beq	$v0, $zero, print_contacts	# end of file
	# escreve em contacts todas as informacoes do contato com texto formatado
	move	$a0, $s2
	jal	formatData
	add	$s2, $s2, $v0
	# soma um no numero de contatos lidos
	addi	$s1, $s1, 1
	rem	$t0, $s1, 5	# t0 � o n�mero de contatos lido nesta itera��o
	bne	$t0, $zero, readinfo_loop
print_contacts:
	# checa se chegou a ler pelo menos um contato
	rem	$t0, $s1, 5	# d� o n�mero de contatos lidos na itera��o
	bne	$v0, $zero, noteof	# se nao saiu por eof, parte para a impressao
	beq	$t0, $zero, list_exit	# se saiu por eof e nao leu nenhum contato, sai da funcao
noteof:		# ele entra aqui se leu pelo menos 1 contato e saiu por eof ou saiu por ter lido 5
	# acrescenta um '\0' ao final de contacts
	li	$t2, '\0'
	sb	$t2, contacts($s2)
	addi	$s2, $s2, 1
	# n�o precisa mais de s2, ent�o reutiliza pra guardar v0 (v0 � zero quando saiu por eof)
	move	$s2, $v0
	# calcula o n�mero da p�gina atual e escreve em listMsg
	la	$a0, listMsg+27
	move	$a1, $s1
	jal	pageNumber
	# imprime contacts para o usu�rio
	la	$a0, listMsg
	la	$a1, contacts 
	li	$v0, 59
	syscall
	# se tiver lido contatos mas saido por eof, nao volta pro la�o
	bne	$s2, $zero, readandprint_loop
list_exit:
	# fecha o arquivo
	move	$a0, $s0
	li	$v0, 16
	syscall
	# recupera os registradores
	lw	$s2, 12($sp)
	lw	$s1, 8($sp)
	lw	$s0, 4($sp)
	lw	$ra, 0($sp)
	addi	$sp, $sp, 16
	jr	$ra





######## SEARCHREG: procura no registro todas os registros que come�am com uma certa letra ########
#### ENTRADAS ####
# a0 - letra desejada
#### VARI�VEIS ####
# s0 - descritor do arquivo principal
# s1 - descritor do arquivo auxiliar
# s2 - letra sendo buscada
# s3 - numero de registros encontrados com a letra buscada
#### SA�DAS ####
# n�o tem
.globl	searchReg
searchReg:
	# salva registradores
	addi	$sp, $sp, -20
	sw	$ra, 0($sp)
	sw	$s0, 4($sp)
	sw	$s1, 8($sp)
	sw	$s2, 12($sp)
	sw	$s3, 16($sp)
	# salva a letra sendo buscada
	move	$s2, $a0
	# abre o arquivo principal para leitura
	la	$a0, fileName
	li	$a1, 0
	li	$v0, 13
	syscall
	move	$s0, $v0
	# abre arquivo auxiliar para escrita
	la	$a0, auxFileName
	li	$a1, 1		# sobrescreve o arquivo auxiliar
	li	$v0, 13
	syscall
	move	$s1, $v0
	# contagem de quantos registros foram encontrados com a letra buscada
	move	$s3, $zero
search_loop:
	# le o campo de informacoes do registro
	move	$a0, $s0
	la	$a1, regBuffer
	la	$a2, fieldSizes
	jal	readRegLine
	beq	$v0, $zero, done_searching	# end of file
	# carrega a primeira letra do nome completo
	lbu	$t0, regBuffer+20	# posi��o da primeira letra
	# se n�o for a letra, continua a busca
	bne	$t0, $s2, search_loop
	# se for a letra, soma um aos registros encontrados
	addi	$s3, $s3, 1
	# escreve no arquivo auxiliar e continua a busca
	move	$a0, $s1
	la	$a1, regBuffer
	lw	$a2, fieldSizes
	li	$v0, 15
	syscall
	j	search_loop
done_searching:
	# fecha o arquivo principal
	move	$a0, $s0
	li	$v0, 16
	syscall
	# fecha o arquivo auxiliar
	move	$a0, $s1
	li	$v0, 16
	syscall
	# retorna o n�mero de contatos encontrados na mem�ria
	move	$v0, $s3
	# recupera registradores
	lw	$ra, 0($sp)
	lw	$s0, 4($sp)
	lw	$s1, 8($sp)
	lw	$s2, 12($sp)
	lw	$s3, 16($sp)
	addi	$sp, $sp, 20
	jr	$ra





######## ENUMERATECONTACTS: enumera os contatos no array contacts ########
#### ENTRADAS ####
# a0 - n�mero do contato
# a1 - posi��o de escrita em contacts
#### VARI�VEIS ####
# s0 - n�mero do contato
# s1 - posi��o de escrita em contacts
#### SA�DAS ####
# n�o tem
enumerateContacts:
	# salva registradores
	addi	$sp, $sp, -12
	sw	$ra, 0($sp)
	sw	$s0, 4($sp)
	sw	$s1, 8($sp)
	# n�mero do contato
	move	$s0, $a0
	# posi��o de escrita em contacts
	move	$s1, $a1
	# enumera os contatos
	la	$a0, contacts($s1)
	addi	$a1, $s0, 1
	li	$a2, 3
	jal	numToStr
	li	$t0, ':'
	sb	$t0, contacts+3($s1)
	li	$t0, '\n'
	sb	$t0, contacts+4($s1)
	# recupera registradores
	lw	$ra, 0($sp)
	lw	$s0, 4($sp)
	lw	$s1, 8($sp)
	addi	$sp, $sp, 12
	jr	$ra





######## SETUPNAMEARRAY: salva o nome do contato e seu tamanho em nameBuffer e a posi��o do nome em namePos ########
#### ENTRADAS ####
# a0 - numero de contatos
# a1 - posicao de escrita em nameBuffer
#### VARI�VEIS ####
# s0 - numero de contatos
# s1 - posicao de escrita em nameBuffer
#### SA�DAS ####
# v0 - nova posicao de escrita em nameBuffer
setupNameArray:
	# salva registradores
	addi	$sp, $sp, -12
	sw	$ra, 0($sp)
	sw	$s0, 4($sp)
	sw	$s1, 8($sp)
	# salva o numero de contatos
	move	$s0, $a0
	# salva a posicao de escrita em nameBuffer
	move	$s1, $a1	
	# salva a posi��o em nameBuffer em namePos
	rem	$t0, $s0, 5
	sll	$t0, $t0, 2
	sw	$s1, namePos($t0)
	# copia o tamanho do nome em ASCII em nameBuffer
	la	$a0, nameBuffer($s1)
	lw	$a1, fieldSizes+4
	li	$a2, 3
	addi	$s1, $s1, 3
	jal	numToStr
	# copia o resto do nome em nameBuffer
	la	$a0, nameBuffer($s1)	
	la	$a1, regBuffer+20
	lw	$a2, fieldSizes+4
	add	$s1, $s1, $a2
	jal	copyStr
	# retorna a nova posicao de escrita
	move	$v0, $s1
	# recupera registradores
	lw	$ra, 0($sp)
	lw	$s0, 4($sp)
	lw	$s1, 8($sp)
	addi	$sp, $sp, 12
	jr	$ra





######## CONFIRMNAME: mostra o nome ao usu�rio e pergunta se ele confirma ########
#### ENTRADAS ####
# a0 - indice do contato escolhido
#### VARI�VEIS ####
# s0 - indice do contato escolhido
# s1 - tamanho do nome do contato
#### SA�DAS ####
# v0 - retorna o resultado da confirmacao
confirmName:
	# salva registradores
	addi	$sp, $sp, -12
	sw	$ra, 0($sp)
	sw	$s0, 4($sp)
	sw	$s1, 8($sp)
	# �ndice do contato escolhido
	move	$s0, $a0
	# acessa a posicao do nome e calcula o tamanho
	sll	$s0, $s0, 2
	lw	$t2, namePos($s0)
	lbu	$t3, nameBuffer($t2)
	lbu	$t4, nameBuffer+1($t2)
	lbu	$t5, nameBuffer+2($t2)
	subi	$t3, $t3, '0'
	mul	$s1, $t3, 100
	subi	$t4, $t4, '0'
	mul	$t7, $t4, 10
	add	$s1, $s1, $t7
	subi	$t5, $t5, '0'
	add	$s1, $s1, $t5	# tamanho do nome
	# copia a primeira parte da mensagem
	la	$a0, confirmmsg2
	la	$a1, confirmmsg1
	li	$a2, 30
	jal	copyStr
	# copia o nome na mensagem de confirmacao
	la	$a0, confirmmsg2+30
	lw	$a1, namePos($s0)
	la	$a1, nameBuffer+3($a1)
	move	$a2, $s1
	jal	copyStr
	# termina com alguns caracteres
	li	$t9, '"'
	sb	$t9, confirmmsg2+30($s1)
	li	$t9, '?'
	sb	$t9, confirmmsg2+31($s1)
	li	$t9, '\0'
	sb	$t9, confirmmsg2+32($s1)
	# confirma se este � o nome mesmo
	la	$a0, confirmmsg2
	li	$v0, 50
	syscall
	# retorna o resultado da confirmacao
	move	$v0, $a0
	# recupera os registradores
	lw	$ra, 0($sp)
	lw	$s0, 4($sp)
	lw	$s1, 8($sp)
	addi	$sp, $sp, 12
	jr	$ra





######## CHOOSENAME: mostra uma lista dos contatos encontrados ao usu�rio e pede para que ele escolha um ########
#### ENTRADAS ####
# a0 - numero total de contatos no arquivo auxiliar
#### VARI�VEIS ####
# s0 - descritor do arquivo auxiliar
# s1 - numero de contatos lidos do arquivo auxiliar para cada itera��o
# s2 - posicao de escrita em contacts / flag de eof
# s3 - numero do menor contato presente na pagina
# s4 - posi��o de escrita em nameBuffer
# s5 - numero total de contatos no arquivo auxiliar
#### SA�DAS ####
# v0 - n�mero do registro selecionado no arquivo auxiliar (n�o � o ID)
.globl	chooseName
chooseName:
	# salva registradores
	addi	$sp, $sp, -28
	sw	$ra, 0($sp)
	sw	$s0, 4($sp)
	sw	$s1, 8($sp)
	sw	$s2, 12($sp)
	sw	$s3, 16($sp)
	sw	$s4, 20($sp)
	sw	$s5, 24($sp)
	# n�mero total de contatos no arquivo auxiliar
	move	$s1, $a0
	move	$s5, $a0
	# abre o arquivo p leitura
	la	$a0, auxFileName
	li	$a1, 0
	li	$v0, 13
	syscall
	move	$s0, $v0
	# calcula e escreve o n�mero de p�ginas no total em searchMsg
	la	$a0, searchMsg+112
	move	$a1, $s1
	jal	pageNumber
	move	$s1, $zero	# numero de contatos lidos nos loops a seguir
	# escreve a string searchMsg no come�o de contacts
	la	$a0, contacts
	la	$a1, searchMsg
	li	$a2, 118	# tamanho de searchMsg
	jal	copyStr
loop_readandprint:	
	li	$s2, 118	# posi��o de escrita em contacts (offset do tamanho de listMsg)
	addi	$s3, $s1, 1
	move	$s4, $zero	# posi��o de escrita em nameBuffer
loop_readinfo:
	# le um registro do arquivo
	move	$a0, $s0
	la	$a1, regBuffer
	la	$a2, fieldSizes
	jal	readRegLine
	beq	$v0, $zero, contacts_print	# end of file
	# enumera o contato
	move	$a0, $s1
	move	$a1, $s2
	jal	enumerateContacts
	addi	$s2, $s2, 5
	# escreve em contacts todas as informacoes do contato com texto formatado
	move	$a0, $s2
	jal	formatData
	add	$s2, $s2, $v0
	# salva o nome do contato junto ao seu tamanho em nameBuffer
	move	$a0, $s1
	move	$a1, $s4
	jal	setupNameArray	# retorna a nova posi��o de escrita em nameBuffer
	move	$s4, $v0
	# soma um no numero de contatos lidos
	addi	$s1, $s1, 1
	rem	$t0, $s1, 5	# t0 � o n�mero de contatos lido nesta itera��o
	bne	$t0, $zero, loop_readinfo
contacts_print:
	# checa se chegou a ler pelo menos um contato
	rem	$t0, $s1, 5	# d� o n�mero de contatos lidos na itera��o
	bnez	$v0, notyeteof	# se nao saiu por eof, parte para a impressao
	beqz	$t0, choose_exit	# se saiu por eof e nao leu nenhum contato, sai da funcao
notyeteof:		# ele entra aqui se leu pelo menos 1 contato e saiu por eof ou saiu por ter lido 5
	# acrescenta um '\0' ao final de contacts
	li	$t2, '\0'
	sb	$t2, contacts($s2)
	addi	$s2, $s2, 1
	# n�o precisa mais de s2, ent�o reutiliza pra guardar v0 (v0 � zero quando saiu por eof)
	move	$s2, $v0
	# calcula escreve a p�gina atual em contacts (que est� armazenando searchMsg no come�o)
	la	$a0, contacts+105
	move	$a1, $s1
	jal	pageNumber
shownames:
	# imprime contacts para o usu�rio
	la	$a0, contacts
	li	$v0, 51
	syscall
	bnez	$a1, choose_error	# a1 = 0, a0 = ? -> deu erro
	# se escolheu a0 != 0, pula
	bnez	$a0, notzero
	# se escolheu a0 = 0, checa mais duas condicoes
	# se a0 = 0 e s2 = 0, escolheu avancar e sair, mesmo que cancelar
	beqz	$s2, choose_cancel
	# se a0 = 0 e s2 != 0 mas o programa tiver lido todos os contatos, avancar tambem eh cancelar
	beq	$s1, $s5, choose_cancel
	# se a0 = 0 e s2 != 0, volta ao loop
	j	loop_readandprint
notzero:
	# se a0 < 0 ou a0 < s3 ou a0 > s1, a entrada � inv�lida
	bltz	$a0, choose_error
	blt	$a0, $s3, choose_error
	bgt	$a0, $s1, choose_error
	# se a0 >= s3 e a0 <= s1, escolheu um numero valido, entao confirma o nome escolhido
	# salva o argumento
	addi	$sp, $sp, -4
	sw	$a0, 0($sp)
	# determina o numero, de 0 a 4, do contato escolhido
	addi	$t0, $a0, -1
	rem	$t0, $t0, 5	# indice do contato escolhido
	# confirma se este � o contato que o usu�rio escolheu
	move	$a0, $t0
	jal	confirmName	# retorna o resultado da confirmacao
	# recupera o argumento
	lw	$a0, 0($sp)
	addi	$sp, $sp, 4
	# se nao confirmar, mostra os nomes de novo
	bnez	$v0, shownames
	# a0 ser� o valor de retorno se confirmar
	move	$t0, $a0
	j	choose_exit
choose_error:	
	beq	$a1, -2, choose_cancel
	li 	$v0, 55
	la 	$a0, tryagainmsg
	li	$a1, 0
	syscall
	j	shownames
choose_cancel:
	# pergunta se o usu�rio quer realmente cancelar
	li 	$v0, 50
	la 	$a0, cancelmsg
	syscall
	bnez	$a0, shownames
	# retorna zero se cancelar
	move	$t0, $zero
choose_exit:
	# fecha o arquivo
	move	$a0, $s0
	li	$v0, 16
	syscall
	# valor de retorno
	move	$v0, $t0
	# recupera registradores
	lw	$s5, 24($sp)
	lw	$s4, 20($sp)
	lw	$s3, 16($sp)
	lw	$s2, 12($sp)
	lw	$s1, 8($sp)
	lw	$s0, 4($sp)
	lw	$ra, 0($sp)
	addi	$sp, $sp, 28
	jr	$ra





######## RECOVERID ########
#### ENTRADAS ####
# a0 - n�mero do registro no arquivo auxiliar (n�o � o ID, � a posi��o)
#### VARI�VEIS ####
# s0 - descritor do arquivo texto
# s1 - numero do registro
# s2 - variavel para iterar no numero de registros lidos
#### SA�DAS ####
# n�o tem
.globl	recoverID
recoverID:
	# salva registradores
	addi	$sp, $sp, -20
	sw	$ra, 0($sp)
	sw	$s0, 4($sp)
	sw	$s1, 8($sp)
	sw	$s2, 12($sp)
	sw	$s3, 16($sp)
	# numero do registro
	move	$s1, $a0
	# endere�o do buffer de registro selecionado
	move	$s3, $a1
	# abre o arquivo auxiliar p leitura
	la	$a0, auxFileName
	li	$a1, 0
	li	$v0, 13
	syscall
	move	$s0, $v0
	# itera no numero de registros
	move	$s2, $zero
recover_loop:
	# le um registro do arquivo
	move	$a0, $s0
	la	$a1, regBuffer
	la	$a2, fieldSizes
	jal	readRegLine
	beq	$v0, $zero, recover_exit	# end of file
	# escreve o nome no buffer de registro selecionado
	move	$a0, $s3
	la	$a1, regBuffer+20
	lw	$a2, fieldSizes+4
	jal	copyStr
	addi	$s2, $s2, 1
	bne	$s2, $s1, recover_loop
recover_exit:
	# converte o ID p um numero
	la	$a0, regBuffer+15
	li	$a1, 3
	jal	strToNum
	move	$s2, $v0	# aqui a fun��o strToNum bota v0 = ID, que ser� o valor retornado
	# escreve um '\0' pra terminar a string
	lw	$t2, fieldSizes+4
	add	$t2, $t2, $s3
	li	$t0, '\0'
	sb	$t0, 0($t2)
	# fecha o arquivo
	move	$a0, $s0
	li	$v0, 16
	syscall
	# valor de retorno
	move	$v0, $s2
	# recupera registradores
	lw	$s3, 16($sp)
	lw	$s2, 12($sp)
	lw	$s1, 8($sp)
	lw	$s0, 4($sp)
	lw	$ra, 0($sp)
	addi	$sp, $sp, 20
	jr	$ra
