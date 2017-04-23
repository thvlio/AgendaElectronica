.text
######## PARSEPHONE: verificar se o telefone é composto apenas de dígitos ########
#### ENTRADAS ####
# a0 - buffer do numero de telefone contendo 10 digitos
#### VARIÁVEIS ####
# não tem
#### SAÍDAS ####
# v0 - resultado da operação (0 - OK, -1 - erro)
.globl	parsePhone
parsePhone:
	# retorna o resultado da verificacao
	move	$v0, $zero
	# iteradores
	move	$t0, $zero
	li	$t1, 10
parse_loop:
	add	$t2, $t0, $a0
	lbu	$t3, 0($t2)	# carrega o caractere
	blt	$t3, '0', failed
	bgt	$t3, '9', failed	# se o caractere for t3 > '9' e t3 < '0', deu erro
	addi	$t0, $t0, 1
	bne	$t0, $t1, parse_loop
	jr	$ra
failed:
	li	$v0, -1	# retorna um erro
	jr	$ra





######## CLEARARRAY: limpa um array de bytes, colocando '\0' em todos os elementos ########
#### ENTRADAS ####
# a0 - array a ser esvaziado
# a1 - tamanho do array
#### VARIÁVEIS ####
# não tem
#### SAÍDAS ####
# não tem
.globl	clearArray
clearArray:
	li	$t2, '\0'
	move	$t1, $zero
clear_loop:
	add	$t0, $a0, $t1
	sb	$t2, 0($t0)
	addi	$t1, $t1, 1
	bne	$t1, $a1, clear_loop
	jr	$ra





######## COPYSTR: copia uma string dentro de outra, sobrescrevendo os caracteres ########
#### ENTRADAS ####
# a0 - endereço da string de destino
# a1 - endereço da string de origem
# a2 - numero de caracteres a serem copiados (opcional)
#### VARIÁVEIS ####
# não tem
#### SAÍDAS ####
# não tem
.globl copyStr
copyStr:
	move	$t0, $a0	# destino
	move	$t1, $a1	# origem
	move	$t3, $a2	# tamanho (-1 pra nao considerar tamanho)
copy_loop:
	lbu	$t2, 0($t1)
	sb	$t2, 0($t0)
	beq	$t2, '\0', copy_done
	addi	$t3, $t3, -1
	beq	$t3, $zero, copy_done
	addi	$t0, $t0, 1
	addi	$t1, $t1, 1 
	j	copy_loop
copy_done:
	jr	$ra





######## STRSIZE: determina o tamanho de uma string terminada em '\0' ou '\n' ########
#### ENTRADAS ####
# a0 - string cujo tamanho vai ser determinado
#### VARIÁVEIS ####
# não tem
#### SAÍDAS ####
# v0 - tamanho da string (não conta '\0' ou '\n')
.globl strSize
strSize:
	move	$v0, $zero	# tamanho zero inicialmente
loop_size:
	add	$t0, $v0, $a0
	lbu	$t1, 0($t0)	# carrega um caracter da string
	beq	$t1, '\n', exit_strSize
	beq	$t1, '\0', exit_strSize	# se encontrar \n ou \0, é o fim da string
	addi	$v0, $v0, 1	# soma um se não tiver chegado ao fim
	j	loop_size
exit_strSize:
	jr	$ra





######## NUMTOSTR: transforma um número numa string que representa o número em ASCII ########
#### ENTRADAS ####
# a0 - endereço da string que armazenará o número
# a1 - numero a ser transformado em ASCII
# a2 - em quantos digitos o numero deve ser representado
#### VARIÁVEIS ####
# não tem
#### SAÍDAS ####
# não tem
.globl	numToStr
numToStr:
	move	$t0, $a1	# numero
	add	$t2, $a0, $a2	# posicao maxima da string, o numero eh escrito da direita p esquerda
	addi	$t2, $t2, -1
loopz:	# pega o n-esimo digito do numero, calcula o equivalente ASCII e guarda na string
	slt	$t3, $t2, $a0
	bne	$t3, $zero, exit_loopz
	divu	$t0, $t0, 10
	mfhi	$t1 # resto
	addi	$t1, $t1, '0'
	sb	$t1, 0($t2)
	addi	$t2, $t2, -1
	j	loopz
exit_loopz:
	jr	$ra





######## STRTONUM: transforma um número representado em ASCII num número decimal ########
#### ENTRADAS ####
# a0 - endereço da string contendo o número em ASCII
# a1 - em quantos caracteres este número está representado
#### VARIÁVEIS ####
# não tem
#### SAÍDAS ####
# v0 - número
.globl	strToNum
strToNum:
	move	$v0, $zero
	add	$t0, $a0, $a1
	addi	$t0, $t0, -1
	li	$t2, 1
interloper:
	lbu	$t1, 0($t0)	# carrega um numero
	addi	$t1, $t1, -48	# converte de ASCII p decimal
	mulu	$t1, $t1, $t2	# multiplica pelo peso do digito
	add	$v0, $v0, $t1	# acumula em $v0
	addi	$t0, $t0, -1
	mulu	$t2, $t2, 10
	slt	$t3, $t0, $a0
	beq	$t3, $zero, interloper
	jr	$ra