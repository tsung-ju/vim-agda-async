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

function agda#highlight#highlight(buf, items)
  if !getbufvar(a:buf, 'agda_highlight_inited', v:false)
    call s:init(a:buf)
    call setbufvar(a:buf, 'agda_highlight_inited', v:true)
  endif

  let l:lines = getbufline(a:buf, 1, '$')
  let l:state = s:chars2pos_init(l:lines)

  for l:item in a:items
    let l:start = s:chars2pos(l:item.range[0], l:state)
    let l:end = s:chars2pos(l:item.range[1], l:state)

    for l:atom in l:item.atoms
      call s:prop_add_multiline(a:buf, l:lines, l:start, l:end, 'agda_atom_' . l:atom)
      if index(s:atoms_error, l:atom) != -1
        call s:mark_error(a:buf, l:item, l:atom, l:start)
      endif
    endfor
  endfor
endfunction

function agda#highlight#clear(buf)
  if getbufvar(a:buf, 'agda_highlight_inited', v:false)
    for l:atom in s:atoms_all
      call prop_remove({'type': 'agda_atom_' . l:atom, 'bufnr': a:buf, 'all': v:true})
    endfor
    call setqflist([], 'f')
  endif
endfunction

function s:prop_add_multiline(buf, lines, start, end, type)
  let l:lnum = a:start[0]
  while l:lnum <= a:end[0]
    let l:start_col = l:lnum == a:start[0] ? a:start[1] : 1
    let l:end_col = l:lnum == a:end[0] ? a:end[1] : strlen(a:lines[l:lnum - 1]) + 1
    call prop_add(l:lnum, l:start_col, {
      \ 'end_lnum': l:lnum,
      \ 'end_col': l:end_col,
      \ 'bufnr': a:buf,
      \ 'type': a:type,
    \ })
    let l:lnum += 1
  endwhile
endfunction

function s:mark_error(buf, item, atom, pos)
  if has_key(a:item, 'note') && a:item.note != v:null
    let l:text = a:item.note
  else
    let l:text = a:atom
  endif

  call setqflist([{
    \ 'bufnr': a:buf,
    \ 'lnum': a:pos[0],
    \ 'col': a:pos[1],
    \ 'text': l:text,
  \ }], 'a')
endfunction

function s:chars2pos_init(lines)
  let l:lines = []
  let l:line_starts = []
  let l:acc = 1
  for l:line in a:lines
    call add(l:lines, l:line . "\n")
    call add(l:line_starts, l:acc)
    let acc += strchars(l:line) + 1
  endfor
  let l:lnum = 1
  return [l:lines, l:line_starts, l:lnum]
endfunction

function s:chars2pos(chars, state)
  let [l:lines, l:line_starts, l:lnum] = a:state
  let l:len = len(l:lines)
  while l:lnum < l:len && l:line_starts[l:lnum] < a:chars
    let l:lnum += 1
  endwhile
  let l:charcol = a:chars - l:line_starts[l:lnum - 1]
  let l:col = strlen(strcharpart(l:lines[l:lnum - 1], 0, l:charcol)) + 1
  let a:state[2] = l:lnum
  return [l:lnum, l:col]
endfunction

function s:init(buf)
  for l:atom in s:atoms_all
    let l:type = 'agda_atom_' . l:atom
    call prop_type_add(l:type, {'highlight': l:type, 'bufnr': a:buf, 'combine': 1})
  endfor
endfunction

let s:atoms_all = [
  \ 'keyword',
  \ 'comment',
  \ 'background',
  \ 'markup',
  \ 'string',
  \ 'number',
  \ 'symbol',
  \ 'primitivetype',
  \ 'bound',
  \ 'generalizable',
  \ 'argument',
  \ 'inductiveconstructor',
  \ 'coinductiveconstructor',
  \ 'datatype',
  \ 'field',
  \ 'function',
  \ 'module',
  \ 'postulate',
  \ 'pragma',
  \ 'primitive',
  \ 'macro',
  \ 'record',
  \ 'dottedpattern',
  \ 'operator',
  \ 'error',
  \ 'unsolvedmeta',
  \ 'unsolvedconstraint',
  \ 'terminationproblem',
  \ 'deadcode',
  \ 'coverageproblem',
  \ 'positivityproblem',
  \ 'incompletepattern',
  \ 'catchallclause',
  \ 'confluenceproblem',
  \ 'missingdefinition',
  \ 'typechecks',
\ ]

let s:atoms_error = [
  \ 'error',
  \ 'unsolvedmeta',
  \ 'unsolvedconstraint',
  \ 'terminationproblem',
  \ 'deadcode',
  \ 'coverageproblem',
  \ 'positivityproblem',
  \ 'incompletepattern',
  \ 'catchallclause',
  \ 'confluenceproblem',
  \ 'missingdefinition',
\ ]
