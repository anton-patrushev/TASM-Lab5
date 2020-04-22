; .286
.model small
.stack 100h

.data
  buffer_size equ 50

  ; file_name db buffer_size dup (0)
  temp db buffer_size dup ('$')
  first_file_descriptor dw 0
  first_file_name db "c:\Lab5\file3.bin", 0, '$' ;mock
  second_file_descriptor dw 0
  second_file_name db "c:\Lab5\file2.bin", 0, '$' ;mock

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

  je close_file_error

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
  mov si, 82h
  
  cmp si, bx
  jae bad_args

  
  bad_args:
  call_log error_parsing
  exit
  
  ret
endp

start:
  init

  ;parse_command_line

  call_open_file first_file_name, first_file_descriptor

  ;working stuff

  call_close_file first_file_name, first_file_descriptor
  exit
end start
