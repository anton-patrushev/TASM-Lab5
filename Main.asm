; .286
.model small
.stack 100h

.data
  buffer_size equ 50

  ; temp db buffer_size dup ('$')
  ; first_file_name db "c:\Lab5\file3.bin", 0, '$' ;mock
  ; second_file_name db "c:\Lab5\file2.bin", 0, '$' ;mock
  first_file_descriptor dw 0
  second_file_descriptor dw 0
  first_file_name db buffer_size dup ('$')
  second_file_name db buffer_size dup ('$')

  endl db 10, 13, '$'
  error_parsing db "Failed to parse command line args", 10, 13, '$'
  file db "File ", '$'
  successful_open db "was successfully opened", 10, 13, '$'
  error_open db "Failed to open file ", '$'
  successful_close db "was successfully closed", 10, 13, '$'
  error_close db "Failed to close file ", '$'
.code
jmp start

init macro
  mov ax, @data
  mov ds, ax
endm

exit macro
  mov ax, 4c00h
  int 21h
endm

log proc
  push bp
  mov bp, sp
  mov ax, 0900h
  mov dx, ss:[bp+4]
  int 21h
  pop bp
  ret
endp

call_log macro value
  push offset value
  call log
  pop dx
endm

open_file proc
  push bp
  mov bp, sp
  push ax
  push dx
  push bx

  mov ah, 3dh
  mov al, 0h                ; open for reading
  mov dx, ss:[bp + 6]       ; get file name
  int 21h

  ; if `CF` = 1
  jc open_file_error

  mov bx, ss:[bp + 4]       ; get file descriptor
  mov word ptr ds:[bx], ax  ; store opened file descriptor value
  call_log file
  mov dx, ss:[bp + 6]       ; get file name
  call_log dx
  call_log successful_open  ; log success message
  jmp open_file_end

  open_file_error:          ; handle error
  call_log error_open       ; log error
  mov dx, ss:[bp + 6]       ; get file name
  call_log dx
  call_log endl
  exit

  open_file_end:

  pop bx
  pop dx
  pop ax
  pop bp
  ret
endp

call_open_file macro file_name, file_descriptor
  push offset file_name
  push offset file_descriptor
  call open_file
  pop dx
  pop dx
endm

close_file proc
  push bp
  mov bp, sp
  push ax
  push bx

  mov ah, 3eh
  mov bx, ss:[bp + 4]
  int 21h

  jc close_file_error

  call_log file
  mov bx, ss:[bp + 6] ;get file name
  call_log bx
  call_log successful_close ; log message
  jmp close_file_end

  close_file_error:
  call_log error_close
  mov bx, ss:[bp + 6] ;get file name
  call_log bx
  call_log endl
  exit

  close_file_end:
  pop bx
  pop ax
  pop bp
  ret
endp

call_close_file macro file_name, file_descriptor
  push offset file_name
  push offset file_descriptor
  call close_file
  pop dx
  pop dx
endm

parse_command_line proc
  ; `es` contain `PSP` segment address
  ; store file name in `file_name`

  mov bx, es:[80h] ; cli args line
  add bx, 80h
  mov di, 81h
  
  cmp di, bx
  jae bad_args
  jmp parse_command_line_continue
  
  bad_args:
  call_log error_parsing
  exit

  parse_command_line_continue:
  mov al, ' '
  repz scasb ; skip all spaces
  dec di
  push di

  bin_end:
    cmp byte ptr es:[di], '.'
    jne bin_end_next_iteration
    inc di
    
    cmp byte ptr es:[di], 'b'
    je i_character
    cmp byte ptr es:[di], 'B'
    jne bin_end_next_iteration
    
    i_character:
    inc di
    
    cmp byte ptr es:[di], 'i'
    je n_character
    cmp byte ptr es:[di], 'I'
    jne bin_end_next_iteration

    n_character:
    inc di
    
    cmp byte ptr es:[di], 'n'
    je first_name_end
    cmp byte ptr es:[di], 'N'
    jne bin_end_next_iteration
    jmp first_name_end
    
    bin_end_next_iteration:
    inc di
  jmp bin_end

  first_name_end:
  inc di
  mov bx, di
  pop di

  mov si, offset first_file_name
  copy_first_name:
    mov dl, byte ptr es:[di]
    mov byte ptr ds:[si], dl
    inc si
    inc di
    cmp di, bx
  jne copy_first_name
  mov byte ptr ds:[si], 0

  mov al, ' '
  repz scasb ; skip all spaces
  dec di
  push di

  _bin_end:
    cmp byte ptr es:[di], '.'
    jne _bin_end_next_iteration
    inc di
    
    cmp byte ptr es:[di], 'b'
    je _i_character
    cmp byte ptr es:[di], 'B'
    jne _bin_end_next_iteration
    
    _i_character:
    inc di
    
    cmp byte ptr es:[di], 'i'
    je _n_character
    cmp byte ptr es:[di], 'I'
    jne _bin_end_next_iteration

    _n_character:
    inc di
    
    cmp byte ptr es:[di], 'n'
    je second_name_end
    cmp byte ptr es:[di], 'N'
    jne _bin_end_next_iteration
    jmp second_name_end
    
    _bin_end_next_iteration:
    inc di
  jmp _bin_end

  second_name_end:
  inc di
  mov bx, di
  pop di

  mov si, offset second_file_name
  copy_second_name:
    mov dl, byte ptr es:[di]
    mov byte ptr ds:[si], dl
    inc si
    inc di
    cmp di, bx
  jne copy_second_name
  mov byte ptr ds:[si], 0
  
  parse_command_line_end:
  ret
endp

start:
  init

  call parse_command_line

  call_open_file first_file_name, first_file_descriptor
  call_open_file second_file_name, second_file_descriptor

  ;comparing stuff

  call_close_file first_file_name, first_file_descriptor
  call_close_file second_file_name, second_file_descriptor
  exit
end start
