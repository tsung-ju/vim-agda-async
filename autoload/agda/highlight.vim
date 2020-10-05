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
  let l:lines = getbufline(a:buf, 1, '$')
  let l:state = s:chars2pos_init(l:lines)

  for l:item in a:items
    let l:start = s:chars2pos(l:item.range[0], l:state)
    let l:end = s:chars2pos(l:item.range[1], l:state)

    let l:ranges = s:split_multiline_range(l:lines, l:start, l:end)

    for [l:range_start, l:range_end] in l:ranges
      for l:atom in l:item.atoms
        call prop_add(l:range_start[0], l:range_start[1], {
          \ 'end_lnum': l:range_end[0],
          \ 'end_col': l:range_end[1],
          \ 'bufnr': a:buf,
          \ 'type': 'agda_atom_' . l:atom,
        \ })
      endfor
    endfor

    if type(l:item.definitionSite) ==# v:t_dict
      for [l:range_start, l:range_end] in l:ranges
        call agda#definition#add(a:buf, l:range_start, l:range_end, l:item.definitionSite)
      endfor
    endif

    for l:atom in l:item.atoms
      if index(s:atoms_error, l:atom) != -1
        call s:mark_error(a:buf, l:item, l:atom, l:start)
      endif
    endfor
  endfor
endfunction

function agda#highlight#clear(buf)
  for l:atom in s:atoms_all
    call prop_remove({'type': 'agda_atom_' . l:atom, 'bufnr': a:buf, 'all': v:true})
  endfor
  call setqflist([], 'f')
endfunction

function s:split_multiline_range(lines, start, end)
  let l:result = range(a:start[0], a:end[0])
  call map(l:result, {_, lnum -> [[lnum, 1], [lnum, strlen(a:lines[lnum - 1]) + 1]]})
  let l:result[0][0][1] = a:start[1]
  let l:result[-1][1][1] = a:end[1]
  return l:result
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

function s:init()
  for l:atom in s:atoms_all
    let l:type = 'agda_atom_' . l:atom
    call prop_type_add(l:type, {'highlight': l:type, 'combine': 1})
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

call s:init()
