.data
# nome do arquivo texto
fileName:	.asciiz	"db.txt"
auxFileName:	.asciiz	"auxdb.txt"
# buffer que armazena um registro da agenda temporariamente
regBuffer:	.space	500
# utilidade publica
fieldSizes:	.word	0, 0, 0, 0, 0





.text
######## CORRECTFILE: copia todos os registros para outro arquivo menos o ID alvo ########
#### ENTRADAS ####
# a0 - ID a ser removido
#### VARIÁVEIS ####
# s0 - descritor do arquivo principal
# s1 - descritor do arquivo auxiliar
# s2 - serve para enumerar os IDs. começa em 1 e vai até o número de contatos
# s3 - ID a ser removido
#### SAÍDAS ####
# não tem
.globl	correctFile
correctFile:
	# salva os registradores
	addi	$sp, $sp, -20
	sw	$ra, 0($sp)
	sw	$s0, 4($sp)
	sw	$s1, 8($sp)
	sw	$s2, 12($sp)
	sw	$s3, 16($sp)
	# ID a ser removido
	move	$s3, $a0
	# abre o arquivo principal p leitura
	la	$a0, fileName
	li	$a1, 0
	li	$v0, 13
	syscall
	move	$s0, $v0
	# abre arquivo auxiliar p escrita
	la	$a0, auxFileName
	li	$a1, 1		# sobrescreve o arquivo auxiliar
	li	$v0, 13
	syscall
	move	$s1, $v0
	li	$s2, 1	# primeiro ID a ser escrito
correct_loop:
	# le um registro
	move	$a0, $s0
	la	$a1, regBuffer
	la	$a2, fieldSizes
	jal	readRegLine
	beq	$v0, $zero, theend	# sai se resultar em eof
	# transforma o ID lido num número
	la	$a0, regBuffer+15
	li	$a1, 3
	jal	strToNum
	# se for igual ao ID alvo, não escreve no arquivo auxiliar, nem atualiza $s2
	beq	$v0, $s3, correct_loop
	# se não for igual ao ID alvo, muda o campo de ID para $s2
	la	$a0, regBuffer+15	# posição de ID na string
	move	$a1, $s2
	li	$a2, 3
	jal	numToStr
	addi	$s2, $s2, 1
	# escreve no arquivo auxiliar
	move	$a0, $s1
	la	$a1, regBuffer
	lw	$a2, fieldSizes
	li	$v0, 15
	syscall
	j	correct_loop
theend:
	# fecha o arquivo principal
	move	$a0, $s0
	li	$v0, 16
	syscall
	# fecha o arquivo auxiliar
	move	$a0, $s1
	li	$v0, 16
	syscall
	# recupera os registradores
	lw	$s3, 16($sp)
	lw	$s2, 12($sp)
	lw	$s1, 8($sp)
	lw	$s0, 4($sp)
	lw	$ra, 0($sp)
	addi	$sp, $sp, 20
	jr	$ra





######## REFRESHFILE: copia o arquivo auxiliar para a database principal ########
#### ENTRADAS ####
# não tem
#### VARIÁVEIS ####
# s0 - descritor do arquivo principal
# s1 - descritor do arquivo auxiliar
# s2 - tamanho total de um registro
# s3 - número de contatos no arquivo auxiliar
#### SAÍDAS ####
# v0 - número de contatos no arquivo auxiliar
.globl	refreshFile
refreshFile:
	# salva registradores
	addi	$sp, $sp, -20
	sw	$ra, 0($sp)
	sw	$s0, 4($sp)
	sw	$s1, 8($sp)
	sw	$s2, 12($sp)
	sw	$s3, 16($sp)
	# abre o arquivo principal para escrita
	la	$a0, fileName
	li	$a1, 1		# sobrescreve o arquivo principal anterior
	li	$v0, 13
	syscall
	move	$s0, $v0
	# abre o arquivo auxiliar para leitura
	la	$a0, auxFileName
	li	$a1, 0
	li	$v0, 13
	syscall
	move	$s1, $v0
	# número de contatos lidos
	move	$s3, $zero
refresh_loop:
	# le o registro (do arquivo auxiliar)
	# le um registro
	move	$a0, $s1
	la	$a1, regBuffer
	la	$a2, fieldSizes
	jal	readRegLine
	beq	$v0, $zero, done_copying	# sai se resultar em eof
	# soma um no numero de contatos lidos
	addi	$s3, $s3, 1
	# escreve no arquivo principal
	move	$a0, $s0
	la	$a1, regBuffer
	lw	$a2, fieldSizes
	li	$v0, 15
	syscall
	j	refresh_loop
done_copying:
	# fecha o arquivo principal
	move	$a0, $s0
	li	$v0, 16
	syscall
	# fecha o arquivo auxiliar
	move	$a0, $s1
	li	$v0, 16
	syscall
	# retorna o num de contatos
	move	$v0, $s3
	# recupera os registradores
	lw	$s3, 16($sp)
	lw	$s2, 12($sp)
	lw	$s1, 8($sp)
	lw	$s0, 4($sp)
	lw	$ra, 0($sp)
	addi	$sp, $sp, 20
	jr	$ra





######## EDITREG: edita um registro selecionado ########
#### ENTRADAS ####
# a0 - ID a ser editado pelo usuário
#### VARIÁVEIS ####
# s0 - descritor do arquivo principal
# s1 - descritor do arquivo auxiliar
# s2 - serve para enumerar os IDs. começa em 1 e vai até o número de contatos
# s3 - ID a ser editado
# s4 - endereço do buffer que contem o novo nome
#### SAÍDAS ####
# v0 - endereço do buffer que contem o novo nome
.globl	editReg
editReg:
	# salva os registradores
	addi	$sp, $sp, -24
	sw	$ra, 0($sp)
	sw	$s0, 4($sp)
	sw	$s1, 8($sp)
	sw	$s2, 12($sp)
	sw	$s3, 16($sp)
	sw	$s4, 20($sp)
	# ID a ser removido
	move	$s3, $a0
	# abre o arquivo principal p leitura
	la	$a0, fileName
	li	$a1, 0
	li	$v0, 13
	syscall
	move	$s0, $v0
	# abre arquivo auxiliar p escrita
	la	$a0, auxFileName
	li	$a1, 1		# sobrescreve o arquivo auxiliar
	li	$v0, 13
	syscall
	move	$s1, $v0
	li	$s2, 1	# primeiro ID a ser escrito
searchforID_loop:
	# le um registro
	move	$a0, $s0
	la	$a1, regBuffer
	la	$a2, fieldSizes
	jal	readRegLine
	beq	$v0, $zero, editdone	# sai se resultar em eof
	# se for igual ao ID alvo, chama a edição do registro
	bne	$s2, $s3, skipedit
	# fecha o arquivo auxiliar
	move	$a0, $s1
	li	$v0, 16
	syscall
	# pede dados para o registro e insere no arquivo
	add	$a0, $s2, -1
	li	$a1, 1
	jal	adicionarRegistro
	move	$s4, $v1
	# abre o arquivo auxiliar pra write+append
	la	$a0, auxFileName
	li	$a1, 9		# não sobrescreve o arquivo auxiliar
	li	$v0, 13
	syscall
	move	$s1, $v0
	# incrementa o numero de contatos
	addi	$s2, $s2, 1
	j	searchforID_loop
skipedit:
	# se não for igual ao ID alvo, muda o campo de ID para $s2
	la	$a0, regBuffer+15	# posição de ID na string
	move	$a1, $s2
	li	$a2, 3
	jal	numToStr
	addi	$s2, $s2, 1
	# escreve no arquivo auxiliar
	move	$a0, $s1
	la	$a1, regBuffer
	lw	$a2, fieldSizes
	li	$v0, 15
	syscall
	j	searchforID_loop
editdone:
	# fecha o arquivo principal
	move	$a0, $s0
	li	$v0, 16
	syscall
	# fecha o arquivo auxiliar
	move	$a0, $s1
	li	$v0, 16
	syscall
	# retorna o endereço de bname
	move	$v0, $s4
	# recupera os registradores
	lw	$s4, 20($sp)
	lw	$s3, 16($sp)
	lw	$s2, 12($sp)
	lw	$s1, 8($sp)
	lw	$s0, 4($sp)
	lw	$ra, 0($sp)
	addi	$sp, $sp, 24
	jr	$ra
