" Copyright (C) 2019  ray851107
"
" This file is part of vim-agda-async.
"
" vim-agda-async is free software: you can redistribute it and/or modify
" it under the terms of the GNU General Public License as published by
" the Free Software Foundation, either version 3 of the License, or
" (at your option) any later version.
"
" vim-agda-async is distributed in the hope that it will be useful,
" but WITHOUT ANY WARRANTY; without even the implied warranty of
" MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
" GNU General Public License for more details.
"
" You should have received a copy of the GNU General Public License
" along with vim-agda-async.  If not, see <https://www.gnu.org/licenses/>.

" Copied from https://github.com/derekelkins/agda-vim/blob/master/syntax/agda.vim
syn match   agdaCharCode     contained "\\\([0-9]\+\|o[0-7]\+\|x[0-9a-fA-F]\+\|[\"\\'&\\abfnrtv]\|^[A-Z^_\[\\\]]\)"
syn match   agdaCharCode     contained "\v\\(NUL|SOH|STX|ETX|EOT|ENQ|ACK|BEL|BS|HT|LF|VT|FF|CR|SO|SI|DLE|DC1|DC2|DC3|DC4|NAK|SYN|ETB|CAN|EM|SUB|ESC|FS|GS|RS|US|SP|DEL)"
syn region  agdaString       start=+"+ skip=+\\\\\|\\"+ end=+"+ contains=agdaCharCode
syn match   agdaHole         "\v(^|\s|[.(){};])@<=(\?)($|\s|[.(){};])@="
syn region  agdaX            matchgroup=agdaHole start="{!" end="!}" contains=ALL
syn match   agdaLineComment  "\v(^|\s|[.(){};])@<=--.*$" contains=@agdaInComment
syn region  agdaBlockComment start="{-"  end="-}" contains=agdaBlockComment,@agdaInComment
syn region  agdaPragma       start="{-#" end="#-}"
syn cluster agdaInComment    contains=agdaTODO,agdaFIXME,agdaXXX
syn keyword agdaTODO         contained TODO
syn keyword agdaFIXME        contained FIXME
syn keyword agdaXXX          contained XXX

hi def link agdaHole WarningMsg
hi def      agdaTODO             cterm=bold,underline ctermfg=2 " green
hi def      agdaFIXME            cterm=bold,underline ctermfg=3 " yellow
hi def      agdaXXX cterm=bold,underline ctermfg=1 " red


hi def link agda_atom_keyword Keyword
hi def link agda_atom_comment Comment
hi def link agda_atom_background Comment
hi def link agda_atom_markup Comment
hi def link agda_atom_string String
hi def link agda_atom_number Number
hi def link agda_atom_symbol Special
hi def link agda_atom_primitivetype Type
hi def link agda_atom_argument Identifier
hi def link agda_atom_bound Identifier
hi def link agda_atom_generalizable Identifier
hi def link agda_atom_inductiveconstructor Normal
hi def link agda_atom_coinductiveconstructor Normal
hi def link agda_atom_datatype Type
hi def link agda_atom_field Normal
hi def link agda_atom_function Normal
hi def link agda_atom_module Structure
hi def link agda_atom_postulate Normal
hi def link agda_atom_pragma PreProc
hi def link agda_atom_primitive Normal
hi def link agda_atom_macro Macro
hi def link agda_atom_record Type
hi def link agda_atom_dottedpattern Normal
hi def link agda_atom_operator Operator
hi def link agda_atom_error Error
hi def link agda_atom_unsolvedmeta Underlined
hi def link agda_atom_unsolvedconstraint Underlined
hi def link agda_atom_terminationproblem Underlined
hi def link agda_atom_deadcode Underlined
hi def link agda_atom_coverageproblem Underlined
hi def link agda_atom_positivityproblem Underlined
hi def link agda_atom_incompletepattern Underlined
hi def link agda_atom_catchallclause Underlined
hi def link agda_atom_confluenceproblem Underlined
hi def link agda_atom_missingdefinition Underlined
hi def link agda_atom_typechecks Normal
